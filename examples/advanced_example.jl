using Pkg
# Activate the local environment including EnergyModelsHeat and its dependencies
Pkg.activate(@__DIR__)
# Use dev version if run as part of tests
haskey(ENV, "EMX_TEST") && Pkg.develop(path = joinpath(@__DIR__, ".."))
# Install the dependencies.
Pkg.instantiate()

# Import the required packages
using EnergyModelsBase
using EnergyModelsHeat
using JuMP
using TimeStruct
using HiGHS
using DataFrames
# Loading `Plots` activates the `visualize_c_rates` plotting extension of EnergyModelsHeat
using Plots

const EMB = EnergyModelsBase
const EMH = EnergyModelsHeat
const TS = TimeStruct

"""
    generate_level_dependent_tes_example()

Generate the data for an example consisting of an electricity source, an electric boiler, a
[`LevelDependentRateTES`](@ref) and a heat demand. The boiler converts electricity to heat,
which can either be delivered directly to the demand or stored in the thermal energy storage.

The storage uses state-of-charge dependent charge and discharge rate limits: charging gets
slower as the storage fills up, and discharging gets slower as it empties. This example
demonstrates the flexibility this provides when the electricity price and the heat demand
vary over the day.
"""
function generate_level_dependent_tes_example()
    @info "Generate case data - LevelDependentRateTES example"

    # Define the different resources and their emission intensity in t CO₂/MWh
    Power = ResourceCarrier("Power", 0.0)
    Heat = ResourceCarrier("Heat", 0.0)
    CO2 = ResourceEmit("CO2", 1.0)
    products = [Power, Heat, CO2]

    # Creation of the time structure with 24 hourly operational periods in a single year
    op_number = 24
    operational_periods = SimpleTimes(op_number, 1)
    T = TwoLevel(1, 1, operational_periods; op_per_strat = op_number)

    # Creation of the model type with global data
    model = OperationalModel(
        Dict(CO2 => FixedProfile(1e6)),     # Emission cap for CO₂ in t/a
        Dict(CO2 => FixedProfile(0)),       # Emission price for CO₂ in €/t
        CO2,                                # CO₂ instance
    )

    # A deterministic daily heat demand (MW) with a morning and an evening peak
    heat_demand = OperationalProfile([
        10, 8, 6, 6, 8, 15, 30, 40, 35, 25, 20, 18,
        18, 20, 22, 25, 30, 40, 45, 40, 30, 22, 16, 12,
    ])
    # A deterministic electricity price (€/MWh) that is cheap at night and expensive at peaks
    el_price = OperationalProfile([
        5, 4, 4, 4, 5, 8, 15, 25, 20, 12, 10, 10,
        10, 10, 12, 15, 20, 30, 35, 28, 18, 12, 8, 6,
    ])

    ### Thermal energy storage parameters ###
    charge_capacity = 30
    level_capacity = 100
    discharge_capacity = 40
    # Anchor points [storage level, maximum rate]: charging slows down as the storage fills,
    # in ascending level order
    c_rate_points_charge = [[10.0, 30.0], [50.0, 20.0], [100.0, 10.0]]
    # Discharging slows down as the storage empties, in descending level order
    c_rate_points_discharge = [[75.0, 40.0], [50.0, 20.0], [25.0, 15.0]]

    # Create the individual nodes: an electricity source (1), an electric boiler (2),
    # a heat demand (3) and the thermal energy storage (4).
    nodes = [
        RefSource(
            "electricity source",   # Node id
            FixedProfile(50),       # Installed capacity in MW
            el_price,               # Variable OPEX in €/MWh
            FixedProfile(0),        # Fixed OPEX in €/MW/a
            Dict(Power => 1),       # Output from the node, in this case Power
        ),
        RefNetworkNode(
            "electric boiler",
            FixedProfile(50),               # Installed capacity in MW
            FixedProfile(0),                # Variable OPEX in €/MWh
            FixedProfile(0),                # Fixed OPEX in €/MW/a
            Dict(Power => 1),               # Input resource and corresponding input ratio
            Dict(Heat => 1),                # Output resource and corresponding output ratio
        ),
        RefSink(
            "heat demand",              # Node id
            heat_demand,                # Required demand in MW
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1000)),
            Dict(Heat => 1),            # Energy carrier and corresponding ratio to demand
        ),
        LevelDependentRateTES{CyclicRepresentative}(
            "thermal energy storage",
            StorCap(FixedProfile(charge_capacity)),     # Installed charge rate in MW
            StorCap(FixedProfile(level_capacity)),      # Installed storage capacity in MWh
            StorCap(FixedProfile(discharge_capacity)),  # Installed discharge rate in MW
            Heat,                                       # Stored resource
            0.01,                                       # Heat loss factor (fraction per period)
            c_rate_points_charge,
            c_rate_points_discharge,
            Dict(Heat => 1),                            # Input resource and input ratio
            Dict(Heat => 1),                            # Output resource and output ratio
        ),
    ]

    # Connect all nodes for the overall energy/mass balance
    links = [
        Direct("source-boiler", nodes[1], nodes[2], Linear()),
        Direct("boiler-demand", nodes[2], nodes[3], Linear()),
        Direct("boiler-storage", nodes[2], nodes[4], Linear()),
        Direct("storage-demand", nodes[4], nodes[3], Linear()),
    ]

    ### c-rate curves visualization ###
    # `visualize_c_rates` becomes available through the Plots extension of EnergyModelsHeat.
    # It shows the theoretical (dis-)charge curves the chosen anchor points produce.
    visualize_c_rates(
        charge_capacity,
        discharge_capacity,
        level_capacity,
        c_rate_points_charge,
        c_rate_points_discharge,
    )

    # Input data structure
    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
    return case, model
end

"""
    process_results(m, case)

Collect the storage results into a `DataFrame` and plot the realised charge and discharge
rates against the state of charge, illustrating the state-of-charge dependent rate limits.
"""
function process_results(m, case)
    # Extract the nodes and resources from the data
    _, _, _, tes = get_nodes(case)
    Heat = get_products(case)[2]
    𝒯 = get_time_struct(case)
    periods = collect(𝒯)

    # The rate limit in period t depends on the level at the end of the previous period
    level = [value(m[:stor_level][tes, t]) for t ∈ periods]
    prev_level = vcat(0.0, level[1:(end-1)])
    charge = [value(m[:flow_in][tes, t, Heat]) for t ∈ periods]
    discharge = [value(m[:flow_out][tes, t, Heat]) for t ∈ periods]

    results = DataFrame(
        period = 1:length(periods),
        prev_level = prev_level,
        charge = charge,
        discharge = discharge,
    )

    p = plot(layout = (1, 2), size = (1200, 500), legend = :topright)
    scatter!(
        p[1],
        results.prev_level,
        results.charge,
        label = "Charge",
        markercolor = :red,
        xlabel = "State of charge",
        ylabel = "Rate",
        title = "Charge rate vs state of charge",
    )
    scatter!(
        p[2],
        results.prev_level,
        results.discharge,
        label = "Discharge",
        markercolor = :blue,
        xlabel = "State of charge",
        ylabel = "Rate",
        title = "Discharge rate vs state of charge",
    )
    return results, p
end

# Generate the case and model data and run the model
case, model = generate_level_dependent_tes_example()
m = EMB.create_model(case, model)

@info "Solving the model..."
optimizer = optimizer_with_attributes(
    HiGHS.Optimizer,
    MOI.Silent() => true,
    "mip_rel_gap" => 0.01,
)
set_optimizer(m, optimizer)
optimize!(m)

results, combined_plot = process_results(m, case)
# Skip the interactive display when the example is run as part of the automated tests
haskey(ENV, "EMX_TEST") || display(combined_plot)
