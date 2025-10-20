@testmodule HeatPumpTestData begin
    using HiGHS
    using JuMP

    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct

    # Define the different resources and their emission intensity in tCO2/MWh
    power = ResourceCarrier("Power", 0.0)
    heat_sur = ResourceCarrier("Heat_surplus", 0.0)
    heat_use = ResourceCarrier("Heat_usable", 0.0)
    co2 = ResourceEmit("CO₂", 1.0)

    function hp_test_case(;
        cap = FixedProfile(3),
        cap_lower_bound = 0.2,
        t_source = FixedProfile(29.475),  # source temperature that leads to a COP of 3
        t_sink = FixedProfile(90),
        eff_carnot = FixedProfile(0.5),
        input_heat = heat_sur,
        driving_force = power,
        opex_var = FixedProfile(0),
        opex_fixed = FixedProfile(0),
        output = Dict(heat_use => 1),
    )
        # Define the resources vector
        𝒫 = [power, heat_sur, heat_use, co2]

        # Creation of the time structure and global data
        𝒯 = TwoLevel(2, 1, SimpleTimes(4, 2); op_per_strat = 8.0)
        modeltype = OperationalModel(
            Dict(co2 => FixedProfile(10)),
            Dict(co2 => FixedProfile(0)),
            co2,
        )

        𝒩 = [
            RefSource(
                "surplus heat source",
                FixedProfile(2),
                FixedProfile(0),
                FixedProfile(0),
                Dict(heat_sur => 1),
            ),
            RefSource(
                "Power source",
                FixedProfile(1),
                FixedProfile(0),
                FixedProfile(0),
                Dict(power => 1),
            ),
            HeatPump(
                "HeatPump",
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
            ),
            RefSink(
                "heat demand",
                OperationalProfile([0.5, 2, 3, 2]),
                Dict(:surplus => FixedProfile(1e2), :deficit => FixedProfile(1e6)),
                Dict(heat_use => 1),
            ),
        ]

        # Connect all nodes
        ℒ = [
            Direct("suplus heat source-HP", 𝒩[1], 𝒩[3]),
            Direct("HP-demand", 𝒩[3], 𝒩[4]),
            Direct("power source-HP", 𝒩[2], 𝒩[3]),
        ]

        # Input data structure
        case = Case(𝒯, 𝒫, [𝒩, ℒ])
        optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
        m = create_model(case, modeltype)
        set_optimizer(m, optimizer)
        return m, case, modeltype
    end
end

@testitem "HeatPump" setup = [HeatPumpTestData] begin
    using EnergyModelsBase
    using HiGHS
    using JuMP
    using TimeStruct

    const EMH = EnergyModelsHeat
    const TEST_ATOL = 1e-6

    m, case, modeltype = HeatPumpTestData.hp_test_case()
    optimize!(m)

    # Extract the required information from the node
    𝒯 = get_time_struct(case)
    𝒫 = get_products(case)
    𝒩 = get_nodes(case)
    power = 𝒫[1]
    heat_sur = 𝒫[2]
    heat_use = 𝒫[3]
    hp = 𝒩[3]
    snk = 𝒩[4]

    @testset "HeatPump - Utility functions" begin
        # Test that the input resources are correctly identified
        @test inputs(hp) == Resource[heat_sur, power]
        @test inputs(hp, heat_sur) == 1
        @test inputs(hp, power) == 1
        @test EMH.heat_in_resource(hp) == heat_sur
        @test EMH.driving_force_resource(hp) == power

        # Test that the output resources are correctly identified
        @test outputs(hp) == ResourceCarrier[heat_use]

        # Test that the new functions are working
        @test EMH.eff_carnot(hp) == FixedProfile(0.5)
        @test all(EMH.eff_carnot(hp, t) == 0.5 for t ∈ 𝒯)
        @test EMH.t_sink(hp) == FixedProfile(90)
        @test all(EMH.t_sink(hp, t) == 90 for t ∈ 𝒯)
        @test EMH.t_source(hp) == FixedProfile(29.475)
        @test all(EMH.t_source(hp, t) == 29.475 for t ∈ 𝒯)
        @test EMH.cap_lower_bound(hp) == 0.2
    end

    @testset "HeatPump - Constructors" begin
        hp_data = HeatPump(
            "HeatPump",
            FixedProfile(3),
            0.2,
            FixedProfile(29.475),
            FixedProfile(90),
            FixedProfile(0.5),
            heat_sur,
            power,
            FixedProfile(0),
            FixedProfile(0),
            Dict(heat_use => 1),
            ExtensionData[],
        )

        for field ∈ fieldnames(HeatPump)
            @test getproperty(hp, field) == getproperty(hp_data, field)
        end
    end

    @testset "HeatPump - Constraints" begin
        # Reassign results
        cap_use = value.(m[:cap_use][hp, :])
        flow_in = value.(m[:flow_in][hp, :, :])

        # Test the capacity limitations
        # - EMB.constraints_capacity(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
        @test all(cap_use[t] ≥ 3 * 0.2 - TEST_ATOL for t ∈ 𝒯)
        @test all(
            cap_use[t] ≥ value(m[:cap_inst][hp, t]) * EMH.cap_lower_bound(hp) - TEST_ATOL
            for t ∈ 𝒯
        )
        @test all(cap_use[t] ≤ 3 + TEST_ATOL for t ∈ 𝒯)
        @test all(cap_use[t] ≤ value(m[:cap_inst][hp, t]) + TEST_ATOL for t ∈ 𝒯)
        @test all(value(m[:cap_inst][hp, t]) ≈ 3 for t ∈ 𝒯)

        # Test that a surplus is only existing once per strategic period
        @test count(>(0), [value.(m[:sink_surplus][snk, t]) for t ∈ 𝒯]) == 2

        # Test that the expected COP ratio is calculated
        # - EMB.constraints_flow_in(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

        # Calculate the multiplier
        mult(t) =
            (EMH.t_sink(hp, t) - EMH.t_source(hp, t)) /
            (EMH.eff_carnot(hp, t) * (EMH.t_sink(hp, t) + 273.15))
        @test mult(first(𝒯)) ≈ 1 / 3

        # Test the COP
        @test all(
            value(m[:flow_out][hp, t, heat_use]) / flow_in[t, power] ≈ 3
            for t ∈ 𝒯)

        # Test the flow constraints
        @test all(flow_in[t, power] ≈ cap_use[t] * mult(t) for t ∈ 𝒯)
        @test all(flow_in[t, heat_sur] ≈ cap_use[t] * (1 - mult(t)) for t ∈ 𝒯)
    end
end
