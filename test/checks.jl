@testitem "DirectHeatUpgrade checks" setup = [TestData] begin
    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct
    global EnergyModelsBase.ASSERTS_AS_LOG = false # Throw error when check fails

    case, model, nodes, products, T = TestData.generate_upgrade_data(; equal_mass = false)
    power, heat_sur, heat_use, CO₂ = products
    for A ∈ (EnergyModelsHeat.EqualMassFlows, EnergyModelsHeat.DifferentMassFlows)
        pd = EnergyModelsHeat.PinchData(
            FixedProfile(70),
            FixedProfile(60),
            FixedProfile(20),
            FixedProfile(70),
            FixedProfile(60),
        )
        nonsensical_heat_upgrade = EnergyModelsHeat.DirectHeatUpgrade{A}(
            "heat upgrade",
            FixedProfile(1.0),
            FixedProfile(0),
            FixedProfile(0),
            Dict(heat_sur => 1, power => 1),
            Dict(heat_use => 1),
            [pd],
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
@testitem "HeatPump" begin
    using EnergyModelsBase
    using EnergyModelsHeat
    using HiGHS
    using JuMP
    using Test
    using TimeStruct
    import Interpolations

    const EMB = EnergyModelsBase

    # Set the global to true to suppress the error message
    EMB.TEST_ENV = true

    # Resources used in the analysis
    Power = ResourceCarrier("Power", 0.0)
    Heat = ResourceCarrier("Heat", 0.0)
    CO2 = ResourceEmit("CO2", 1.0)

    # Function for setting up the system for testing a `HeatPump` node
    function check_graph(;
        cap = FixedProfile(20),
        cap_lower_bound = 0.2,
        t_source = FixedProfile(20),
        t_sink = FixedProfile(80),
        eff_carnot = FixedProfile(0.5),
        input_heat = Heat,
        driving_force = Power,
        opex_var = FixedProfile(0),
        opex_fixed = FixedProfile(0),
        output = Dict(Heat => 1),
    )
        products = [Power, Heat, CO2]
        # Creation of the source and sink module as well as the arrays used for nodes and links
        heat_pump = EnergyModelsHeat.HeatPump(
            "heat_pump",
            cap,
            cap_lower_bound,
            t_source,
            t_sink,
            eff_carnot,
            input_heat,
            driving_force,
            opex_var,
            opex_fixed,
            output,
        )
        heat_source = RefSource(
            "heat_source",
            FixedProfile(20),
            FixedProfile(0.1),
            FixedProfile(0),
            Dict(Heat => 1),
        )
        power_source = RefSource(
            "power_source",
            FixedProfile(20),
            FixedProfile(0.3),
            FixedProfile(0),
            Dict(Power => 1),
        )
        heat_demand = RefSink(
            "heat_demand",
            FixedProfile(10),
            Dict(:surplus => FixedProfile(0), :deficit => StrategicProfile([1e3, 2e2])),
            Dict(Power => 1),
        )

        nodes = [heat_pump, heat_source, power_source, heat_demand]
        links = [
            Direct("hp-sink", nodes[1], nodes[4]),
            Direct("heat_source-hp", nodes[2], nodes[1]),
            Direct("power_source-hp", nodes[3], nodes[1]),
        ]

        # Creation of the time structure and the used global data
        op_per_strat = 8760.0
        T = TwoLevel(2, 2, SimpleTimes(10, 1); op_per_strat)
        modeltype = OperationalModel(
            Dict(CO2 => FixedProfile(10)),
            Dict(CO2 => FixedProfile(0)),
            CO2,
        )

        # Creation of the case dictionary
        case = Dict(:nodes => nodes, :links => links, :products => products, :T => T)

        return create_model(case, modeltype), case, modeltype
    end

    # Test that a wrong capacity is caught by the checks
    @test_throws AssertionError check_graph(; cap = FixedProfile(-25))

    # Test that a wrong lower capacity bound is caught by the checks
    @test_throws AssertionError check_graph(; cap_lower_bound = -0.4)
    @test_throws AssertionError check_graph(; cap_lower_bound = 1.2)

    # Test that a wrong carnot efficiency is caught by the checks
    @test_throws AssertionError check_graph(; eff_carnot = FixedProfile(-0.4))
    @test_throws AssertionError check_graph(; eff_carnot = FixedProfile(1.2))

    # Test that a wrong source and sink temperature is caught by the checks
    @test_throws AssertionError check_graph(; t_source = FixedProfile(90))

    # Test that a wrong fixed OPEX is caught by the checks
    @test_throws AssertionError check_graph(; opex_fixed = FixedProfile(-5))

    # Test that a wrong output dictionary is caught
    @test_throws AssertionError check_graph(; output = Dict(Heat => -0.9))

    # Set the global again to false
    EMB.TEST_ENV = false
end

# Test that the fields of a ThermalEnergyStorage are correctly checked
# - check_node(n::ThermalEnergyStorage, 𝒯, modeltype::EnergyModel)
@testitem "ThermalEnergyStorage" begin
    using EnergyModelsBase
    using EnergyModelsHeat
    using HiGHS
    using JuMP
    using Test
    using TimeStruct
    import Interpolations

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
    )
        products = [Heat, CO2]
        # Creation of the source and sink module as well as the arrays used for nodes and links
        TES = EnergyModelsHeat.ThermalEnergyStorage{CyclicRepresentative}(
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
        T = TwoLevel(2, 2, SimpleTimes(10, 1); op_per_strat)
        modeltype = OperationalModel(
            Dict(CO2 => FixedProfile(10)),
            Dict(CO2 => FixedProfile(0)),
            CO2,
        )

        # Creation of the case dictionary
        case = Dict(:nodes => nodes, :links => links, :products => products, :T => T)

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

    # Set the global again to false
    EMB.TEST_ENV = false
end
