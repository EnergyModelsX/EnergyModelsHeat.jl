@testitem "DHPipe" begin
    using EnergyModelsBase
    using HiGHS
    using JuMP
    using TimeStruct

    const EMH = EnergyModelsHeat

    function generate_data()

        # Define the different resources
        dh_res = ResourceHeat("DHheat", FixedProfile(70.0), FixedProfile(30.0))
        CO₂ = ResourceEmit("CO₂", 0.0)
        products = [dh_res, CO₂]

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

        # Create the individual test nodes for a system with
        # 1) a heat source
        # 2) a heat sink representing the district heating demand
        nodes = [
            RefSource(
                "heat source",              # Node id
                FixedProfile(0.85),         # Capacity in MW
                FixedProfile(10),            # Variable OPEX in EUR/MW
                FixedProfile(0),            # Fixed OPEX in EUR/8h
                Dict(dh_res => 1),          # Output from the Node, in this gase, dh_heat
            ),
            RefSink(
                "heat demand",              # Node id
                OperationalProfile([0.2, 0.8, 0.4, 0.3]), # Demand in MW
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                # Line above: Surplus and deficit penalty for the node in EUR/MWh
                Dict(dh_res => 1),           # Input to the Node, in this gase, dh_heat
            ),
        ]

        # Connect all nodes with the availability node for the overall energy/mass balance
        links = [
            DHPipe(
                "DH pipe",
                nodes[1],
                nodes[2],
                FixedProfile(0.8),
                1000.0,
                0.25 * 10^(-6),
                FixedProfile(10.0),
                dh_res,
            ),
        ]

        # Input data structure
        case = Case(T, products, [nodes, links], [[get_nodes, get_links]])
        return (; case, model)
    end
    case, model = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    # Extract the individual nodes
    src, snk = get_nodes(case)[1:2]
    pipe = get_links(case)[1]
    dh_res = get_products(case)[1]
    𝒯 = get_time_struct(case)

    # Test that the heat loss is accurately calculated
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

    # Test that we have exactly two deficits due to the limited capacity, given by the loss
    # in the pipeline
    @test sum(value.(m[:sink_deficit][snk, t]) ≈ 0.015 for t ∈ 𝒯) == 2

    # Test that the total loss is correct
    total_heat_in = sum(JuMP.value(m[:flow_out][src, t, dh_res]) for t ∈ 𝒯)
    total_heat_out = sum(JuMP.value(m[:flow_in][snk, t, dh_res]) for t ∈ 𝒯)
    heat_loss = total_heat_in - total_heat_out
    rel_heat_loss = heat_loss / total_heat_in
    rel_heat_loss_assumed = 0.0344
    @test rel_heat_loss_assumed ≈ rel_heat_loss rtol = 0.01

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
