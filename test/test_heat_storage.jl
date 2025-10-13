@testitem "ThermalEnergyStorage" begin
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
            EMH.ThermalEnergyStorage{CyclicStrategic}(
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
                OperationalProfile([0.1, 0.1, 0.2, 0.8]), # Demand in MW
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

        # Input data structure
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return (; case, model, nodes, products, T, op_duration)
    end
    case, model, nodes, products, T, op_duration = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    heat_use = products[3]

    # Test that the expected heat loss ratio is calculated
    heatloss = EMH.heat_loss_factor(nodes[3])

    heat_input = sum(JuMP.value(m[:flow_in][nodes[3], t, heat_use]) for t ∈ T) * op_duration
    heat_output =
        sum(JuMP.value(m[:flow_out][nodes[3], t, heat_use]) for t ∈ T) * op_duration
    heat_stored = sum(JuMP.value(m[:stor_level][nodes[3], t]) for t ∈ T)

    # Check that the heat delivered matches the expected ratio of heat stored
    calculated_heatlosses = heat_stored * heatloss * op_duration
    real_heatlosses = heat_input - heat_output
    @test real_heatlosses ≈ calculated_heatlosses atol = 0.01
    @test real_heatlosses ≈ 1.3333 atol = 0.01
    @test heat_stored ≈ 3.3333 atol = 0.01
end

@testitem "FixedRateTES" begin
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
            EMH.FixedRateTES{CyclicStrategic}(
                "TES",
                StorCap(FixedProfile(1)),
                heat_use,
                0.2,
                0.25,
                0.1,
                Dict(heat_use => 1),
                Dict(heat_use => 1),
            ),
            RefSink(
                "heat demand",              # Node id
                OperationalProfile([0.1, 0.1, 0.2, 0.8]), # Demand in MW
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

        # Input data structure
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return (; case, model, nodes, products, T, op_duration)
    end
    case, model, nodes, products, T, op_duration = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    heat_use = products[3]

    # Test that the expected heat loss ratio is calculated
    heatloss = EMH.heat_loss_factor(nodes[3])

    heat_input = sum(JuMP.value(m[:flow_in][nodes[3], t, heat_use]) for t ∈ T) * op_duration
    heat_output =
        sum(JuMP.value(m[:flow_out][nodes[3], t, heat_use]) for t ∈ T) * op_duration
    heat_stored = sum(JuMP.value(m[:stor_level][nodes[3], t]) for t ∈ T)

    calculated_max_charge_rate = maximum([JuMP.value(m[:stor_charge_use][nodes[3], t]) for t in collect(T)])
    calculated_max_discharge_rate = maximum([JuMP.value(m[:stor_discharge_use][nodes[3], t]) for t in collect(T)])

    real_max_charge_rate = nodes[3].level_charge
    real_max_discharge_rate = nodes[3].level_discharge

    # Check that the heat delivered matches the expected ratio of heat stored
    calculated_heatlosses = heat_stored * heatloss * op_duration
    real_heatlosses = heat_input - heat_output
    @test real_heatlosses ≈ calculated_heatlosses atol = 0.01
    @test real_heatlosses ≈ 0.2666 atol = 0.01
    @test heat_stored ≈ 0.6666 atol = 0.01
    @test calculated_max_charge_rate ≤ real_max_charge_rate
    @test calculated_max_discharge_rate ≤ real_max_discharge_rate


end
