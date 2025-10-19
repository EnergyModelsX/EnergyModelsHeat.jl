@testitem "Checks - DirectHeatUpgrade" setup = [UpgradeTestData] begin
    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct
    global EnergyModelsBase.ASSERTS_AS_LOG = false # Throw error when check fails

    case, model, nodes, products, T =
        UpgradeTestData.generate_upgrade_data(70, 60, 70, 60; equal_mass = false)
    power, heat_sur, heat_use, CO₂ = products

    for A ∈ (EnergyModelsHeat.EqualMassFlows, EnergyModelsHeat.DifferentMassFlows)
        nonsensical_heat_upgrade = EnergyModelsHeat.DirectHeatUpgrade{A,Int}(
            "heat upgrade",
            FixedProfile(1.0),
            FixedProfile(0),
            FixedProfile(0),
            Dict(heat_sur => 1, power => 1),
            Dict(heat_use => 1),
            ExtensionData[],
            20,
        )

        @test_throws "upgrade ≤ 1" EnergyModelsBase.check_node(
            nonsensical_heat_upgrade,
            T,
            model,
            true,
        )
    end
end

# Test that the fields of a HeatPump are correctly checked
# - check_node(n::HeatPump, 𝒯, modeltype::EnergyModel)
@testitem "Checks - HeatPump" setup = [HeatPumpTestData] begin
    using EnergyModelsBase
    using TimeStruct

    # Set the global to true to suppress the error message
    EnergyModelsBase.TEST_ENV = true

    # Resources used in the analysis
    heat = ResourceCarrier("Heat", 0.0)

    # Function for setting up the system for testing a `HeatPump` node
    check_graph = HeatPumpTestData.hp_test_case

    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError check_graph(; cap = FixedProfile(-25))

    # Test that a wrong lower capacity bound is caught by the checks
    @test_throws AssertionError check_graph(; cap_lower_bound = -0.4)
    @test_throws AssertionError check_graph(; cap_lower_bound = 1.2)

    # Test that a wrong carnot efficiency is caught by the checks
    @test_throws AssertionError check_graph(; eff_carnot = FixedProfile(-0.4))
    @test_throws AssertionError check_graph(; eff_carnot = FixedProfile(1.2))

    # Test that a wrong source and sink temperature is caught by the checks
    @test_throws AssertionError check_graph(; t_source = FixedProfile(100))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError check_graph(; opex_fixed = FixedProfile(-5))

    # Test that a wrong output dictionary is caught
    @test_throws AssertionError check_graph(; output = Dict(heat => -0.9))

    # Set the global again to false
    EnergyModelsBase.TEST_ENV = false
end

# Test that the fields of a ThermalEnergyStorage are correctly checked
# - check_node(n::ThermalEnergyStorage, 𝒯, modeltype::EnergyModel)
@testitem "Checks - ThermalEnergyStorage" begin
    using EnergyModelsBase
    using TimeStruct

    const EMB = EnergyModelsBase

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    # Resources used in the analysis
    Heat = ResourceCarrier("Heat", 0.0)
    CO2 = ResourceEmit("CO2", 1.0)

    # Function for setting up the system for testing a `ThermalEnergyStorage` node
    function check_graph(;
        charge_cap = FixedProfile(5),
        level_cap = FixedProfile(20),
        charge_opex = FixedProfile(0.5),
        level_opex = FixedProfile(0.8),
        stor_res = Heat,
        heat_loss_factor = 0.05,
        input = Dict(Heat => 1),
        output = Dict(Heat => 1),
        oper = SimpleTimes(10, 1),
        stor_behav = CyclicRepresentative,
    )
        products = [Heat, CO2]
        # Creation of the source and sink module as well as the arrays used for nodes and links
        TES = EnergyModelsHeat.ThermalEnergyStorage{stor_behav}(
            "TES",
            StorCapOpexFixed(charge_cap, charge_opex),
            StorCapOpexFixed(level_cap, level_opex),
            stor_res,
            heat_loss_factor,
            input,
            output,
        )
        heat_source = RefSource(
            "Source",
            OperationalProfile([1, 2, 3, 4, 5, 4, 3, 2, 1, 0]),
            FixedProfile(0),
            FixedProfile(0),
            Dict(Heat => 1),
        )
        heat_demand = RefSink(
            "heat_demand",
            OperationalProfile([1, 1, 1, 1, 1, 3, 3, 3, 3, 3]),
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
            Dict(Heat => 1),
        )

        nodes = [TES, heat_source, heat_demand]
        links = [
            Direct("source-TES", nodes[2], nodes[1]),
            Direct("source-demand", nodes[2], nodes[3]),
            Direct("TES-demand", nodes[1], nodes[3]),
        ]

        # Creation of the time structure and the used global data
        op_per_strat = 8760.0
        T = TwoLevel(2, 2, oper; op_per_strat)
        modeltype = OperationalModel(
            Dict(CO2 => FixedProfile(10)),
            Dict(CO2 => FixedProfile(0)),
            CO2,
        )

        # Input data structure
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return create_model(case, modeltype), case, modeltype
    end

    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError check_graph(; charge_cap = FixedProfile(-25))
    @test_throws AssertionError check_graph(; level_cap = FixedProfile(-25))

    # Test that a wrong heat loss factor is caught by the checks
    @test_throws AssertionError check_graph(; heat_loss_factor = 1.2)
    @test_throws AssertionError check_graph(; heat_loss_factor = -0.4)

    # Test that a wrong input or output is caught by the checks
    @test_throws AssertionError check_graph(; input = Dict(Heat => -0.5))
    @test_throws AssertionError check_graph(; output = Dict(Heat => -0.5))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError check_graph(; charge_opex = FixedProfile(-5))
    @test_throws AssertionError check_graph(; charge_opex = OperationalProfile([10]))
    @test_throws AssertionError check_graph(; level_opex = FixedProfile(-5))
    @test_throws AssertionError check_graph(; level_opex = OperationalProfile([10]))

    # Test that the warning regarding the time structure is thrown
    msg =
        "Using `CyclicStrategic` with a `ThermalEnergyStorage{EnergyModelsBase.CyclicStrategic}` and " *
        "`RepresentativePeriods` " *
        "results in errors for the calculation of the heat loss. It is not advised " *
        "to utilize this `StorageBehavior`. Use instead `CyclicRepresentative`."
    oper = RepresentativePeriods(8760, [0.5, 0.5], SimpleTimes(10, 1))
    @test_logs (:warn, msg) check_graph(; stor_behav = CyclicStrategic, oper)

    # Set the global again to false
    EMB.TEST_ENV = false
end

# Test that the fields of a BoundRateTES are correctly checked
# - check_node(n::BoundRateTES, 𝒯, modeltype::EnergyModel)
@testitem "Checks - BoundRateTES" begin
    using EnergyModelsBase
    using TimeStruct

    const EMB = EnergyModelsBase

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    # Resources used in the analysis
    Heat = ResourceCarrier("Heat", 0.0)
    CO2 = ResourceEmit("CO2", 1.0)

    # Function for setting up the system for testing a `BoundRateTES` node
    function check_graph(;
        level_cap = FixedProfile(20),
        level_opex = FixedProfile(0.8),
        stor_res = Heat,
        heat_loss_factor = 0.05,
        level_charge = 0.5,
        level_discharge = 1.0,
        input = Dict(Heat => 1),
        output = Dict(Heat => 1),
        oper = SimpleTimes(10, 1),
        stor_behav = CyclicRepresentative,
    )
        products = [Heat, CO2]
        # Creation of the source and sink module as well as the arrays used for nodes and links
        TES = BoundRateTES{stor_behav}(
            "TES",
            StorCapOpexFixed(level_cap, level_opex),
            stor_res,
            heat_loss_factor,
            level_charge,
            level_discharge,
            input,
            output,
        )
        heat_source = RefSource(
            "Source",
            OperationalProfile([1, 2, 3, 4, 5, 4, 3, 2, 1, 0]),
            FixedProfile(0),
            FixedProfile(0),
            Dict(Heat => 1),
        )
        heat_demand = RefSink(
            "heat_demand",
            OperationalProfile([1, 1, 1, 1, 1, 3, 3, 3, 3, 3]),
            Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
            Dict(Heat => 1),
        )

        nodes = [TES, heat_source, heat_demand]
        links = [
            Direct("source-TES", nodes[2], nodes[1]),
            Direct("source-demand", nodes[2], nodes[3]),
            Direct("TES-demand", nodes[1], nodes[3]),
        ]

        # Creation of the time structure and the used global data
        op_per_strat = 8760.0
        T = TwoLevel(2, 2, oper; op_per_strat)
        modeltype = OperationalModel(
            Dict(CO2 => FixedProfile(10)),
            Dict(CO2 => FixedProfile(0)),
            CO2,
        )

        # Input data structure
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return create_model(case, modeltype), case, modeltype
    end

    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError check_graph(; level_cap = FixedProfile(-25))

    # Test that a wrong heat loss factor is caught by the checks
    @test_throws AssertionError check_graph(; heat_loss_factor = 1.2)
    @test_throws AssertionError check_graph(; heat_loss_factor = -0.4)

    # Test that a wrong input or output is caught by the checks
    @test_throws AssertionError check_graph(; input = Dict(Heat => -0.5))
    @test_throws AssertionError check_graph(; output = Dict(Heat => -0.5))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError check_graph(; level_opex = FixedProfile(-5))
    @test_throws AssertionError check_graph(; level_opex = OperationalProfile([10]))

    # Test that a wrong charge or discharge factor are caught by the checks
    @test_throws AssertionError check_graph(; level_charge = -0.4)
    @test_throws AssertionError check_graph(; level_discharge = -0.4)

    # Test that the warning regarding the time structure is thrown
    msg =
        "Using `CyclicStrategic` with a `BoundRateTES` and `RepresentativePeriods` " *
        "results in errors for the calculation of the heat loss. It is not advised " *
        "to utilize this `StorageBehavior`. Use instead `CyclicRepresentative`."
    oper = RepresentativePeriods(8760, [0.5, 0.5], SimpleTimes(10, 1))
    @test_logs (:warn, msg) check_graph(; stor_behav = CyclicStrategic, oper)

    # Set the global again to false
    EMB.TEST_ENV = false
end

# Test that the fields of a DHPipe are correctly checked
# - EMB.check_link(l::DHPipe, 𝒯,  modeltype::EnergyModel, check_timeprofiles::Bool)
@testitem "Checks - DHPipe" setup = [DHPipeTestData] begin
    using EnergyModelsBase
    using TimeStruct

    # Set the global to true to suppress the error message
    EnergyModelsBase.TEST_ENV = true

    # Function for setting up the system for testing a `DHPipe` link
    test_case = DHPipeTestData.dh_pipe_test_case

    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError test_case(; cap = FixedProfile(-25))

    # Test that a wrong lower capacity bound is caught by the checks
    @test_throws AssertionError test_case(; pipe_length = -0.4)
    @test_throws AssertionError test_case(; pipe_loss_factor = -0.4)

    # Set the global again to false
    EnergyModelsBase.TEST_ENV = false
end
