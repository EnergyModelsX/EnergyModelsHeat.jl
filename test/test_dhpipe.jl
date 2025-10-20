@testmodule DHPipeTestData begin
    using HiGHS
    using JuMP

    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct

    function dh_pipe_test_case(;
        cap = FixedProfile(0.8),
        pipe_length = 1000.0,
        pipe_loss_factor = 0.25 * 10^(-6),
        t_ground = FixedProfile(10.0),
    )
        # Define the different resources
        dh_res = ResourceHeat("DHheat", FixedProfile(70.0), FixedProfile(30.0))
        co2 = ResourceEmit("CO₂", 0.0)
        𝒫 = [dh_res, co2]

        # Creation of the time structure and global data
        𝒯 = TwoLevel(2, 1, SimpleTimes(4, 2); op_per_strat = 8)
        modeltype = OperationalModel(
            Dict(co2 => FixedProfile(10)),
            Dict(co2 => FixedProfile(0)),
            co2,
        )

        # Create the Test nodes
        𝒩 = [
            RefSource(
                "heat source",
                FixedProfile(0.85),
                FixedProfile(10),
                FixedProfile(0),
                Dict(dh_res => 1),
            ),
            RefSink(
                "heat demand",
                OperationalProfile([0.2, 0.8, 0.4, 0.3]),
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                Dict(dh_res => 1),
            ),
        ]

        # Connect the nodes
        ℒ = [
            DHPipe(
                "DH pipe",
                𝒩[1],
                𝒩[2],
                cap,
                pipe_length,
                pipe_loss_factor,
                t_ground,
                dh_res,
            ),
        ]

        # Input data structure and modeltype creation
        case = Case(𝒯, 𝒫, [𝒩, ℒ])
        optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
        m = create_model(case, modeltype)
        set_optimizer(m, optimizer)
        return m, case, modeltype
    end
end

@testitem "DHPipe" setup = [DHPipeTestData] begin
    using JuMP
    using EnergyModelsBase
    using TimeStruct
    const EMH = EnergyModelsHeat

    # Create the case and modeltype
    m, case, modeltype = DHPipeTestData.dh_pipe_test_case()
    optimize!(m)

    # Extract the individual elements and resources
    src, snk = get_nodes(case)[1:2]
    pipe = get_links(case)[1]
    dh_res = get_products(case)[1]
    𝒯 = get_time_struct(case)

    @testset "DHPipe - Utility functions" begin
        @testset "EMX functions" begin
            # Test the identification functions
            @test has_capacity(pipe)

            # Test the extraction functions
            @test capacity(pipe) == FixedProfile(0.8)
            @test all(capacity(pipe, t) == 0.8 for t ∈ 𝒯)
            @test inputs(pipe) == [dh_res]
            @test outputs(pipe) == [dh_res]
        end

        @testset "EMHeat functions" begin
            # Test the extraction functions
            @test EMH.pipe_length(pipe) == 1000.0
            @test EMH.pipe_loss_factor(pipe) == 0.25 * 10^(-6)
            @test EMH.resource_heat(pipe) == dh_res
            @test EMH.t_ground(pipe) == FixedProfile(10.0)
            @test all(EMH.t_ground(pipe, t) == 10.0 for t ∈ 𝒯)
            @test EMH.t_supply(pipe) == FixedProfile(70.0)
            @test EMH.t_supply(pipe) == EMH.t_supply(dh_res)
            @test all(EMH.t_supply(pipe, t) == 70.0 for t ∈ 𝒯)
        end
    end

    @testset "DHPipe - Constructor" begin
        # Test that the individual constructors are working
        pipe_data = DHPipe(
            "DH pipe",
            src,
            snk,
            FixedProfile(0.8),
            1000.0,
            0.25 * 10^(-6),
            FixedProfile(10.0),
            dh_res,
            ExtensionData[],
        )
        pipe_form = DHPipe(
            "DH pipe",
            src,
            snk,
            FixedProfile(0.8),
            1000.0,
            0.25 * 10^(-6),
            FixedProfile(10.0),
            dh_res,
            Linear(),
        )
        pipe_all = DHPipe(
            "DH pipe",
            src,
            snk,
            FixedProfile(0.8),
            1000.0,
            0.25 * 10^(-6),
            FixedProfile(10.0),
            dh_res,
            Linear(),
            ExtensionData[],
        )
        for field ∈ fieldnames(DHPipe)
            @test getproperty(pipe, field) == getproperty(pipe_data, field)
            @test getproperty(pipe, field) == getproperty(pipe_form, field)
            @test getproperty(pipe, field) == getproperty(pipe_all, field)
        end
    end

    @testset "DHPipe - Constraints" begin
        # Test that the heat loss is accurately calculated
        # - create_link(m, l::DHPipe, 𝒯, 𝒫, modeltype::EnergyModel)
        @test all(
            value.(m[:flow_in][snk, t, dh_res]) ≈
            value.(m[:flow_out][src, t, dh_res]) - value.(m[:dh_pipe_loss][pipe, t])
            for t ∈ 𝒯)
        @test all(
            value.(m[:dh_pipe_loss][pipe, t]) ≈
            EMH.pipe_length(pipe) * EMH.pipe_loss_factor(pipe) *
            (EMH.t_supply(pipe, t) - EMH.t_ground(pipe, t))
            for t ∈ 𝒯)
        @test all(
            value.(m[:dh_pipe_loss][pipe, t]) ≈ 0.015
            for t ∈ 𝒯)

        # Test that the capacity constraint is hold in all periods
        @test all(value.(m[:link_in][pipe, t, dh_res]) ≤ 0.8 + 10^-6 for t ∈ 𝒯)

        # Test that we have exactly two deficits due to the limited capacity, given by the
        # loss in the pipeline
        @test sum(value.(m[:sink_deficit][snk, t]) ≈ 0.015 for t ∈ 𝒯) == 2

        # Test that the total loss is correct
        total_heat_in = sum(value(m[:flow_out][src, t, dh_res]) for t ∈ 𝒯)
        total_heat_out = sum(value(m[:flow_in][snk, t, dh_res]) for t ∈ 𝒯)
        heat_loss = total_heat_in - total_heat_out
        rel_heat_loss = heat_loss / total_heat_in
        rel_heat_loss_assumed = 0.0344
        @test rel_heat_loss_assumed ≈ rel_heat_loss rtol = 0.01
    end
end
