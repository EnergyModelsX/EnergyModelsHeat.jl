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
# - EMB.check_node(n::AbstractTES{T}, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
@testitem "Checks - ThermalEnergyStorage" setup = [TESTestData] begin
    using EnergyModelsBase
    using TimeStruct

    # Set the global to true to suppress the error message
    EnergyModelsBase.TEST_ENV = true

    # Function for setting up the system for testing a `ThermalEnergyStorage` node
    check_graph = TESTestData.tes_test_case

    # Resources used in the analysis
    heat = ResourceCarrier("Heat", 0.0)

    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError check_graph(; charge_cap = FixedProfile(-25))
    @test_throws AssertionError check_graph(; level_cap = FixedProfile(-25))
    @test_throws AssertionError check_graph(; discharge_cap = FixedProfile(-25))

    # Test that a wrong heat loss factor is caught by the checks
    @test_throws AssertionError check_graph(; heat_loss_factor = 1.2)
    @test_throws AssertionError check_graph(; heat_loss_factor = -0.4)

    # Test that a wrong input or output is caught by the checks
    @test_throws AssertionError check_graph(; input = Dict(heat => -0.5))
    @test_throws AssertionError check_graph(; output = Dict(heat => -0.5))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError check_graph(; charge_opex = FixedProfile(-5))
    @test_throws AssertionError check_graph(; charge_opex = OperationalProfile([10]))
    @test_throws AssertionError check_graph(; level_opex = FixedProfile(-5))
    @test_throws AssertionError check_graph(; level_opex = OperationalProfile([10]))
    @test_throws AssertionError check_graph(; discharge_opex = FixedProfile(-5))
    @test_throws AssertionError check_graph(; discharge_opex = OperationalProfile([10]))

    # Test that the warning regarding the time structure is thrown
    msg =
        "Using `CyclicStrategic` with a `ThermalEnergyStorage{EnergyModelsBase.CyclicStrategic}` and " *
        "`RepresentativePeriods` " *
        "results in errors for the calculation of the heat loss. It is not advised " *
        "to utilize this `StorageBehavior`. Use instead `CyclicRepresentative`."
    type = ThermalEnergyStorage{CyclicStrategic}
    oper = RepresentativePeriods(8760, [0.5, 0.5], SimpleTimes(4, 1))
    @test_logs (:warn, msg) check_graph(; type, oper)

    # Set the global again to false
    EnergyModelsBase.TEST_ENV = false
end

# Test that the fields of a BoundRateTES are correctly checked
# - EMB.check_node(n::BoundRateTES{T}, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
@testitem "Checks - BoundRateTES" setup = [TESTestData] begin
    using EnergyModelsBase
    using TimeStruct

    # Set the global to true to suppress the error message
    EnergyModelsBase.TEST_ENV = true

    # Function for setting up the system for testing a `BoundRateTES` node
    check_graph = TESTestData.tes_test_case

    # Resources used in the analysis
    heat = ResourceCarrier("Heat", 0.0)

    # Test that a wrong capacity is caught by the checks
    type = BoundRateTES
    @test_throws AssertionError check_graph(; type, level_cap = FixedProfile(-25))

    # Test that a wrong heat loss factor is caught by the checks
    @test_throws AssertionError check_graph(; type, heat_loss_factor = 1.2)
    @test_throws AssertionError check_graph(; type, heat_loss_factor = -0.4)

    # Test that a wrong input or output is caught by the checks
    @test_throws AssertionError check_graph(; type, input = Dict(heat => -0.5))
    @test_throws AssertionError check_graph(; type, output = Dict(heat => -0.5))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError check_graph(; type, level_opex = FixedProfile(-5))
    @test_throws AssertionError check_graph(; type, level_opex = OperationalProfile([10]))

    # Test that a wrong charge or discharge factor are caught by the checks
    @test_throws AssertionError check_graph(; type, level_charge = -0.4)
    @test_throws AssertionError check_graph(; type, level_discharge = -0.4)

    # Test that the warning regarding the time structure is thrown
    msg =
        "Using `CyclicStrategic` with a `BoundRateTES` and `RepresentativePeriods` " *
        "results in errors for the calculation of the heat loss. It is not advised " *
        "to utilize this `StorageBehavior`. Use instead `CyclicRepresentative`."
    type = BoundRateTES{CyclicStrategic}
    oper = RepresentativePeriods(8760, [0.5, 0.5], SimpleTimes(4, 1))
    @test_logs (:warn, msg) check_graph(; type, oper)

    # Set the global again to false
    EnergyModelsBase.TEST_ENV = false
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
