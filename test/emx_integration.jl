@testmodule TestData begin
    using EnergyModelsBase
    using HiGHS
    using JuMP
    using TimeStruct
    using EnergyModelsHeat
    const EMH = EnergyModelsHeat

    # Define the different resources and their emission intensity in tCO2/MWh
    power    = ResourceCarrier("Power", 0.0)
    
    CO₂      = ResourceEmit("CO₂", 1.0)
    
    function generate_data(SH_h=90, SH_c=60, DH_h=60, DH_c=40; equal_mass = true)
        
        heat_sur = EnergyModelsHeat.ResourceHeat("surplus_heat", FixedProfile(SH_h), FixedProfile(SH_c))
        heat_use = EnergyModelsHeat.ResourceHeat("useable_heat", FixedProfile(DH_h), FixedProfile(DH_c))
        products = [power, heat_sur, heat_use, CO₂]
        
        op_duration = 2 # Each operational period has a duration of 2
        op_number = 4   # There are in total 4 operational periods
        operational_periods = SimpleTimes(op_number, op_duration)

        op_per_strat = op_duration * op_number

        # Assumptions for heat exchange
        A = equal_mass ? EMH.EqualMassFlows : EMH.DifferentMassFlows

        # Creation of the time structure and global data
        T = TwoLevel(2, 1, operational_periods; op_per_strat)
        model = OperationalModel(
            Dict(CO₂ => FixedProfile(10)),  # Emission cap for CO₂ in t/8h
            Dict(CO₂ => FixedProfile(0)),   # Emission price for CO₂ in EUR/t
            CO₂,                            # CO₂ instance
        )

        # Create the individual test nodes for a system with 
        # 1) a heat surplus source
        # 2) a heat conversion from surplus to usable heat
        # 3) a heat sink representing the district heating demand
        nodes = [
            RefSource(
                "surplus heat source",      # Node id
                FixedProfile(0.85),         # Capacity in MW
                FixedProfile(0),            # Variable OPEX in EUR/MW
                FixedProfile(0),            # Fixed OPEX in EUR/8h
                Dict(heat_sur => 1),        # Output from the Node, in this gase, heat_sur
            ),
            HeatExchanger{A}(
                "heat exchanger",
                FixedProfile(1.0),
                FixedProfile(0),
                FixedProfile(0),
                Dict(heat_sur => 1),
                Dict(heat_use => 1),
                Data[],
                8, # delta_t_min
            ),
            RefSink(
                "heat demand",              # Node id
                OperationalProfile([0.2, 0.3, 0.4, 0.3]), # Demand in MW
                Dict(:surplus => FixedProfile(1e6), :deficit => FixedProfile(1e6)),
                # Line above: Surplus and deficit penalty for the node in EUR/MWh
                Dict(heat_use => 1),           # Energy demand and corresponding ratio
            ),
        ]

        # Connect all nodes with the availability node for the overall energy/mass balance
        links = [
            Direct("source-exchange", nodes[1], nodes[2], Linear()),
            Direct("exchange-demand", nodes[2], nodes[3], Linear()),
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

    function generate_upgrade_data(t1=60,t2=56,t3=70,t4=50; equal_mass = true)
        # Base case
        case, model, nodes, products, T = TestData.generate_data(t1, t2, t3, t4)

        # Assumptions for heat exchange
        A = equal_mass ? EMH.EqualMassFlows : EMH.DifferentMassFlows
        _, heat_sur, heat_use = products
        # Use temperatures that discriminate results for equal/different mass flows
        # pd = PinchData(
        #     FixedProfile(60),
        #     FixedProfile(56),
        #     FixedProfile(5),
        #     FixedProfile(70),
        #     FixedProfile(50),
        # )

        # Define upgrade node
        heat_upgrade = EnergyModelsHeat.DirectHeatUpgrade{A}(
            "heat upgrade",
            FixedProfile(1.0),
            FixedProfile(0),
            FixedProfile(0),
            Dict(heat_sur => 1, power => 1),
            Dict(heat_use => 1),
            Data[],
            5, # delta_t_min
        )
        power_source = RefSource(
            "power source",             # Node id
            FixedProfile(0.85),         # Capacity in MW
            FixedProfile(1.0),          # Variable OPEX in EUR/MW
            FixedProfile(0),            # Fixed OPEX in EUR
            Dict(power => 1),           # Output from the Node
        )

        heat_demand = RefSink(
            "heat demand",              # Node id
            OperationalProfile([0.2, 0.3, 0.4, 0.3]), # Demand in MW
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
            # Line above: Surplus and deficit penalty for the node in EUR/MWh
            Dict(heat_use => 1),           # Energy demand and corresponding ratio
        )

        nodes[3] = heat_demand
        push!(nodes, heat_upgrade)
        push!(nodes, power_source)

        links = [
            Direct("source-upgrade", nodes[1], nodes[4], Linear()),
            Direct("power-upgrade", nodes[5], nodes[4], Linear()),
            Direct("upgrade-demand", nodes[4], nodes[3], Linear()),
        ]
        case[:nodes] = nodes
        case[:links] = links

        return (; case, model, nodes, products, T)
    end
end

@testitem "Simple EMX model" setup = [TestData] begin
    using JuMP
    using HiGHS
    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct

    # Different mass flow assumption
    case, model, nodes, products, T = TestData.generate_data(; equal_mass = false)
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    surplus = products[2]
    usable = products[3]
    # Verify that test pinch data discriminates between assumptions:
    # pd = EnergyModelsHeat.pinch_data(nodes[2])
    # for t ∈ T
    #     @test EnergyModelsHeat.fraction_different_mass(pd, t) !=
    #           EnergyModelsHeat.fraction_equal_mass(pd, t)
    # end
    # ratio = EnergyModelsHeat.fraction_different_mass(pd, first(T))

    # # Test that ratio is calculated as expected
    # @test ratio ≈ 1
    # # Test that EMX model gives correct ratio of usable energy for all time periods
    # for t ∈ T
    #     @test JuMP.value(m[:flow_out][nodes[1], t, surplus]) * ratio ≈
    #           JuMP.value(m[:flow_out][nodes[2], t, usable])
    # end

    # Equal mass flow assumption
    case, model, nodes, products, T = TestData.generate_data(; equal_mass = true)
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    surplus = products[2]
    usable = products[3]
    # ratio = EnergyModelsHeat.fraction_equal_mass(pd, first(T))

    # Test that ratio is calculated as expected
    # @test ratio ≈ 2 / 3
    # Test that EMX model gives correct ratio of usable energy for all time periods
    # for t ∈ T
    #     @test JuMP.value(m[:flow_out][nodes[1], t, surplus]) * ratio ≈
    #           JuMP.value(m[:flow_out][nodes[2], t, usable])
    # end
end

@testitem "Simple Upgrade example" setup = [TestData] begin
    using JuMP
    using HiGHS
    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct
    const EMH = EnergyModelsHeat
    # Allow different mass flows
    case, model, nodes, products, T = TestData.generate_upgrade_data(; equal_mass = false)
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)

    m = run_model(case, model, optimizer)

    power = products[1]
    surplus_heat = products[2]
    usable_heat = products[3]
    upgrade_node = nodes[4]
    surplus_source = nodes[1]

    # pd = EnergyModelsHeat.pinch_data(upgrade_node)

    # Check that pd discriminates between equal and different mass flows
    # for t ∈ T
    #     @test EnergyModelsHeat.upgrade_different_mass(pd, t) !=
    #           EnergyModelsHeat.upgrade_equal_mass(pd, t)
    # end

    # Test that EMX model gives correct ratio of usable energy for all time periods
    # for t ∈ T
    #     # Check that actual power flow matches specified fraction of upgraded output heat flow
    #     @test JuMP.value(m[:flow_in][upgrade_node, t, power]) ≈
    #           EnergyModelsHeat.upgrade_different_mass(pd, t) *
    #           JuMP.value(m[:flow_out][upgrade_node, t, usable_heat])
    #     @test JuMP.value(m[:flow_out][upgrade_node, t, usable_heat]) ≤
    #           JuMP.value(m[:flow_in][upgrade_node, t, power]) +
    #           EMH.upgradeable_different_mass(pd, t) *
    #           JuMP.value(m[:flow_in][upgrade_node, t, surplus_heat])
    # end

    # Assume equal mass flows
    case, model, nodes, products, T = TestData.generate_upgrade_data(; equal_mass = true)
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)

    m = run_model(case, model, optimizer)

    power = products[1]
    usable_heat = products[3]
    upgrade_node = nodes[4]
    surplus_source = nodes[1]

    # pd = EnergyModelsHeat.pinch_data(upgrade_node)

    # Test that EMX model gives correct ratio of usable energy for all time periods
    # for t ∈ T
    #     # Check that actual power flow matches specified fraction of upgraded output heat flow
    #     @test JuMP.value(m[:flow_in][upgrade_node, t, power]) ≈
    #           EnergyModelsHeat.upgrade_equal_mass(pd, t) *
    #           JuMP.value(m[:flow_out][upgrade_node, t, usable_heat])
    #     @test JuMP.value(m[:flow_out][upgrade_node, t, usable_heat]) ≤
    #           JuMP.value(m[:flow_in][upgrade_node, t, power]) +
    #           EMH.upgradeable_equal_mass(pd, t) *
    #           JuMP.value(m[:flow_in][upgrade_node, t, surplus_heat])
    # end
end
