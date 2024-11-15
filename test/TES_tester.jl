@testitem "TEStest" begin
    using EnergyModelsBase
    using HiGHS
    using JuMP
    using TimeStruct
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
                FixedProfile(0.85),         # Capacity in MW
                FixedProfile(0),            # Variable OPEX in EUR/MW
                FixedProfile(0),            # Fixed OPEX in EUR/8h
                Dict(heat_sur => 1),        # Output from the Node, in this gase, heat_sur
            ),
            RefNetworkNode(
                "HeatPump",
                FixedProfile(0.5),
                FixedProfile(0),
                FixedProfile(0),
                Dict(heat_sur => 1),
                Dict(heat_use => 1),
            ),
            ThermalEnergyStorage(
                "TES",
                StorCap(FixedProfile(1)),
                StorCap(FixedProfile(1)),
                heat_use,
                0.2,
                Dict(heat_use => 1),
                Dict(heat_use => 1),
            ),
            RefSink(
                "heat demand",              # Node id
                OperationalProfile([0.1, 0.5, 0.5, 0.8]), # Demand in MW
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                # Line above: Surplus and deficit penalty for the node in EUR/MWh
                Dict(heat_use => 1),           # Energy demand and corresponding ratio
            ),
        ]

        # Connect all nodes with the availability node for the overall energy/mass balance
        links = [
            Direct("source-HP", nodes[1], nodes[2], Linear()),
            Direct("HP-demand", nodes[2], nodes[4], Linear()),
            Direct("HP-TES", nodes[2], nodes[3], Linear()),
            Direct("TES-demand", nodes[3], nodes[4], Linear()),
        ]

        # WIP data structure
        case = Dict(
            :nodes => nodes,
            :links => links,
            :products => products,
            :T => T,
        )
        return (; case, model, nodes, products, T)
    end
    case, model, nodes, products, T = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    surplus = products[2]
    usable = products[3]

    # Test that the expected heat loss ratio is calculated
    @test heatloss ≈ 0.2 atol = 0.01

    # Initialize variables for accumulation
    heat_stored = 0.0
    heat_delivered = 0.0

    # Calculate total heat stored and delivered over all time periods
    for t ∈ T
        heat_stored += JuMP.value(m[:flow_in][nodes[3], t, heat_use])
        heat_delivered += JuMP.value(m[:flow_out][nodes[3], t, heat_use])
    end

    # Check that the heat delivered matches the expected ratio of heat stored
    calculated_heat_delivered = heat_stored * (1 - heatloss)
    @test heat_delivered ≈ calculated_heat_delivered atol = 0.01
end
