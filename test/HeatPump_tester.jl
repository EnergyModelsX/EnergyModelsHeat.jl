@testitem "Heat - HeatPump" begin
    using EnergyModelsBase
    using HiGHS
    using JuMP
    using TimeStruct

    const EMH = EnergyModelsHeat

    function generate_data()

        # Define the different resources and their emission intensity in tCO2/MWh
        power    = ResourceCarrier("Power", 0.0)
        heat_sur = ResourceCarrier("Heat_surplus", 0.0)
        heat_use = ResourceCarrier("Heat_usable", 0.0)
        CO₂      = ResourceEmit("CO₂", 1.0)
        products = [power, heat_sur, heat_use, CO₂]

        op_duration = 2 # Each operational period has a duration of 2
        op_number = 4   # There are in total 4 operational periods
        operational_periods = SimpleTimes(op_number, op_duration)

        op_per_strat = op_duration * op_number

        # Creation of the time structure and global data
        T = TwoLevel(2, 1, operational_periods; op_per_strat)
        model = OperationalModel(
            Dict(CO₂ => FixedProfile(10)),  # Emission cap for CO₂ in t/8h
            Dict(CO₂ => FixedProfile(0)),   # Emission price for CO₂ in EUR/t
            CO₂,                            # CO₂ instance
        )

        nodes = [
            RefSource(
                "surplus heat source",      # Node id
                FixedProfile(2),         # Capacity in MW
                FixedProfile(0),            # Variable OPEX in EUR/MW
                FixedProfile(0),            # Fixed OPEX in EUR/8h
                Dict(heat_sur => 1),        # Output from the Node, in this gase, heat_sur
            ),
            RefSource(
                "Power source",      # Node id
                FixedProfile(1),         # Capacity in MW
                FixedProfile(0),            # Variable OPEX in EUR/MW
                FixedProfile(0),            # Fixed OPEX in EUR/8h
                Dict(power => 1),        # Output from the Node, in this gase, heat_sur
            ),
            EMH.HeatPump(
                "HeatPump",
                FixedProfile(3),
                0,
                FixedProfile(29.475), # source temperature that leads to a COP of 3
                FixedProfile(90),
                FixedProfile(0.5),
                heat_sur,
                power,
                FixedProfile(0),
                FixedProfile(0),
                Dict(heat_use => 1),
            ),
            RefSink(
                "heat demand",              # Node id
                OperationalProfile([1, 2, 3, 2]), # Demand in MW
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                # Line above: Surplus and deficit penalty for the node in EUR/MWh
                Dict(heat_use => 1),           # Energy demand and corresponding ratio
            ),
        ]

        # Connect all nodes with the availability node for the overall energy/mass balance
        links = [
            Direct("suplus heat source-HP", nodes[1], nodes[3], Linear()),
            Direct("HP-demand", nodes[3], nodes[4], Linear()),
            Direct("power source-HP", nodes[2], nodes[3], Linear()),
        ]

        # Input data structure
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return (; case, model, nodes, products, T)
    end

    case, model, nodes, products, T = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    power = products[1]
    surplus = products[2]
    heat_use = products[3]

    # Test that the expected COP ratio is calculated
    COP = 3.0

    power_uptake = sum(JuMP.value(m[:flow_in][nodes[3], t, power]) for t ∈ T)
    heat_delivered = sum(JuMP.value(m[:flow_out][nodes[3], t, heat_use]) for t ∈ T)

    # Check the calculated COP
    calculated_COP = heat_delivered / power_uptake
    @test calculated_COP ≈ 3 atol = 0.01
end
