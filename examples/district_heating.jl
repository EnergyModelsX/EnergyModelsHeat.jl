using Pkg
# Activate the local environment including EnergyModelsHeat and PrettyTables
Pkg.activate(@__DIR__)
# Use dev version if run as part of tests
haskey(ENV, "EMX_TEST") && Pkg.develop(path = joinpath(@__DIR__, ".."))
# Install the dependencies.
Pkg.instantiate()

# Import the required packages
using EnergyModelsBase
using EnergyModelsHeat
using JuMP
using PrettyTables
using TimeStruct
using HiGHS

const EMB = EnergyModelsBase
const EMH = EnergyModelsHeat
const TS = TimeStruct

"""
    generate_district_heating_example_data()

Generate the data for an example consisting of a district heat source, electricity source,
heat pump, thermal energy storage (TES), and heat demand. The system represents a low-temperature
district heating grid supplying a higher-temperature heat demand. The heat pump upgrades district
heat and can store high-temperature heat in the TES before delivering it to the demand.

This example demonstrates the flexibility provided by the TES, accounting for heat losses in
district heating pipes and the TES, as well as the impact of electricity price variations
relative to heat demand.
"""
function generate_district_heating_example_data()
    @info "Generate case data - District Heating example"

    # Define the different resources and their emission intensity in t CO₂/MWh
    Power = ResourceCarrier("Power", 0.0)
    HeatLT = ResourceHeat("HeatLT", 30.0, 30.0) # Low-temperature heat for district heat
    HeatHT = ResourceHeat("HeatHT", 80.0, 30.0) # High-temperature heat for demand
    CO2 = ResourceEmit("CO2", 1.0)
    products = [Power, HeatLT, HeatHT, CO2]

    # Variables for the individual entries of the time structure
    op_duration = 2 # Each operational period has a duration of 1 h
    op_number = 12  # There are in total 365 operational periods in each strategic period
    operational_periods = SimpleTimes(op_number, op_duration)

    # The total time within a strategic period is given by 8760 h
    # This implies that the individual operational period are scaled:
    # Each operational period is scaled with a factor of 8760/(1*12) = 730
    op_per_strat = 8760

    # Creation of the time structure
    sp_duration = 1 # Each strategic period has a duration of 1 a
    sp_number = 1   # There is only a single strategic period
    T = TwoLevel(sp_number, sp_duration, operational_periods; op_per_strat)

    # Creation of the model type with global data
    model = OperationalModel(
        Dict(CO2 => FixedProfile(1e6)),     # Emission cap for CO₂ in t/a
        Dict(CO2 => FixedProfile(0)),       # Emission price for CO₂ in €/t
        CO2,                                # CO₂ instance
    )

    # Specify the high temperature heat demand
    # The demand could also be specified directly in the node
    HT_demand = OperationalProfile([zeros(2); ones(5) * 30; ones(3) * 10; ones(2) * 50])
    el_price = OperationalProfile([ones(4) * 10; ones(4) * 20; 30; 20; 10; 40])

    # Create the individual test nodes, corresponding to a system with an electricity
    # source (1), a district heat source (2), a heat pump (3), a thermal energy storage (4)
    # and a heat demand (5).
    nodes = [
        RefSource(
            "electricity source",   # Node id
            FixedProfile(30),       # Installed capacity in MW
            el_price,               # Variable OPEX in €/MWh
            FixedProfile(0),        # Fixed OPEX in €/MW/a
            Dict(Power => 1),       # Output from the node, in this case, Power
        ),
        RefSource(
            "district heat source", # Node id
            FixedProfile(50),       # Installed capacity in MW
            FixedProfile(10),       # Variable OPEX in €/MWh
            FixedProfile(0),        # Fixed OPEX in €/MW/a
            Dict(HeatLT => 1),      # Output from the node, in this case, low temperature heat
        ),
        HeatPump(
            "heat pump",            # Node id
            FixedProfile(30),       # Installed heating capacity in MW
            0,                      # Lower capacity bound, 0 means full range available
            EMH.t_supply(HeatLT),   # Source temperature profile
            EMH.t_supply(HeatHT),   # Sink temperature profile
            FixedProfile(0.5),      # Carnot efficiency profile
            HeatLT,                 # Heat resource that is upgraded
            Power,                  # Driving force needed for upgrade
            FixedProfile(0),        # Variable OPEX in €/MWh
            FixedProfile(0),        # Fixed OPEX in €/MW/a
            Dict(HeatHT => 1),      # Output from the node with output ratio
        ),
        ThermalEnergyStorage{CyclicStrategic}(
            "thermal energy storage",
            StorCap(FixedProfile(10)),  # Charge parameters, in this case only capacity in MW
            StorCap(FixedProfile(200)), # Level parameters, in this case only capacity in MWh
            HeatHT,                     # Stored resource
            0.02,                       # Heat loss factor
            Dict(HeatHT => 1),          # Input resource and corresponding input ratio
            Dict(HeatHT => 1),          # Output resource and corresponding output ratio
        ),
        RefSink(
            "heat demand",              # Node id
            HT_demand,                  # Required demand in MW
            Dict(:surplus => FixedProfile(100), :deficit => FixedProfile(100)),
            # Line above: Surplus and deficit penalty for the node in €/MWh
            Dict(HeatHT => 1),          # Energy carrier and corresponding ratio to demand
        ),
    ]

    # Connect all nodes for the overall energy/mass balance
    # Another possibility would be to instead couple the nodes with an `Availability` node
    links = [
        Direct("el_source-heat_pump", nodes[1], nodes[3], Linear())
        DHPipe(                     # District heating pipe link with thermal losses
            "dh_source-heat_pump",      # Id for the link
            nodes[2],                   # Input node
            nodes[3],                   # Output node
            FixedProfile(50),           # Capacity of the pipeline in MW
            2000000.0,                  # Pipe lenght in meters
            # Extreme example to visualize the effects of heat loss
            0.025 * 10^(-6),            # Heat loss factor in MW m⁻¹ K⁻¹
            FixedProfile(10.0),         # Ground temperature in °C
            HeatLT,                     # Heat resource that is transported
        )
        Direct("heat_pump-TES", nodes[3], nodes[4], Linear())
        Direct("heat_pump-demand", nodes[3], nodes[5], Linear())
        Direct("TES-demand", nodes[4], nodes[5], Linear())
    ]

    # Input data structure
    case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
    return case, model
end

"""
    process_district_heating_results(m, case)

Function for processing the results to be represented in the a table afterwards.
"""
function process_district_heating_results(m, case)
    # Extract the nodes and the first strategic period from the data
    electricity_source, district_heat_source, heat_pump, TES, heat_demand =
        get_nodes(case)[[1, 2, 3, 4, 5]]            # Extract all nodes
    HeatLT = get_products(case)[2]                  # Extract the requried resource
    dh_pipe = get_links(case)[2]                    # Extract the DH Pipe
    𝒯 = get_time_struct(case)

    # District heating variables
    DHPipe_input = JuMP.Containers.rowtable(        # Flow into the link
        value,
        m[:link_in][dh_pipe, collect(𝒯), HeatLT];
        header = [:t, :DHPipe_input],
    )
    DHPipe_output = JuMP.Containers.rowtable(       # Flow from the link
        value,
        m[:link_out][dh_pipe, collect(𝒯), HeatLT];
        header = [:t, :DHPipe_output],
    )

    # Heatpump and storage variables
    hp_use = JuMP.Containers.rowtable(              # Capacity utilization heat pump
        value,
        m[:cap_use][heat_pump, collect(𝒯)];
        header = [:t, :cap_use],
    )
    dem_use = JuMP.Containers.rowtable(             # Demand satisfaction
        value,
        m[:cap_use][heat_demand, collect(𝒯)];
        header = [:t, :cap_use],
    )
    stor_lvl = JuMP.Containers.rowtable(            # Storage level
        value,
        m[:stor_level][TES, collect(𝒯)];
        header = [:t, :level],
    )

    # Electricity variables
    el_price = [(t = op, price = opex_var(electricity_source, op)) for op ∈ 𝒯]
    el_use = JuMP.Containers.rowtable(             # Demand satisfaction
        value,
        m[:cap_use][electricity_source, collect(𝒯)];
        header = [:t, :cap_use],
    )

    # Set up the individual named tuples as a single named tuple
    table = [
        (
            t = repr(con_1.t),
            pipe_input = round(con_1.DHPipe_input, digits = 2),
            pipe_output = round(con_2.DHPipe_output, digits = 2),
            HP_use = round(con_3.cap_use, digits = 2),
            demand = round(con_4.cap_use, digits = 2),
            TES_level = round(con_5.level, digits = 2),
            power_cost = round(con_6.price, digits = 2),
            power_use = round(con_7.cap_use, digits = 2),
        ) for (con_1, con_2, con_3, con_4, con_5, con_6, con_7) ∈
        zip(DHPipe_input, DHPipe_output, hp_use, dem_use, stor_lvl, el_price, el_use)
    ]
    return table
end

# Generate the case and model data and run the model
case, model = generate_district_heating_example_data()
optimizer = optimizer_with_attributes(
    HiGHS.Optimizer,
    MOI.Silent() => true,
)
m = run_model(case, model, optimizer)

table = process_district_heating_results(m, case)

@info(
    "Operational periods 1-4:\n" *
    "The loss for the district heating pipeline is only depending on the temperature difference,\n" *
    "but not the amount of transported energy.\n" *
    "The heat pump is initially used at a reduced capacity due to the lack of demand for filling\n" *
    "the storage (at max rate), but starts being used to satisfy the demand in periods 3 and 4.\n" *
    "The losses in the thermal energy storage are proportional to the previous level, and hence,\n" *
    "higher at high storage volumes."
)
pretty_table(table[1:4])

@info(
    "Operational periods 5-8:\n" *
    "The heat pump is used at maximum to satisfy the demand while in period 8 its utilization \n" *
    "exceeds the demand to increase the storage level of the TES at the maximum charge capacity."
)
pretty_table(table[5:8])

@info(
    "Operational periods 9-12:\n" *
    "The storage level is increased in both period 9 and 10 to cover the high demand in the\n" *
    "subsequent periods. The slightly increased storage usage in period 12 compared to 11 is\n" *
    "due to the higher electricity price in period 12"
)
pretty_table(table[9:12])
