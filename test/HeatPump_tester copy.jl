@testitem "HPtest" begin
    using EnergyModelsBase
    using HiGHS
    using JuMP
    using TimeStruct
    using EnergyModelsHeat

    const EMH = EnergyModelsHeat

    function generate_data()
        power    = ResourceCarrier("Power", 0.0)
        heat_sur = ResourceCarrier("Heat_surplus", 0.0)
        heat_use = ResourceCarrier("Heat_usable", 0.0)
        CO₂      = ResourceEmit("CO₂", 1.0)
        products = [power, heat_sur, heat_use, CO₂]

        op_duration = 2
        op_number = 4
        operational_periods = SimpleTimes(op_number, op_duration)
        op_per_strat = op_duration * op_number
        T = SimpleTimes(op_number, op_duration)

        model = OperationalModel(
            Dict(CO₂ => FixedProfile(10)),
            Dict(CO₂ => FixedProfile(0)),
            CO₂
        )

        nodes = [
            RefSource("surplus heat source", FixedProfile(2), FixedProfile(0), FixedProfile(0), Dict(heat_sur => 1)),
            RefSource("Power source", FixedProfile(1), FixedProfile(0), FixedProfile(0), Dict(power => 1)),
            EMH.HeatPump(
                "HeatPump", FixedProfile(3), 0,
                FixedProfile(29.475), FixedProfile(90),
                FixedProfile(0.5), heat_sur, power,
                FixedProfile(0), FixedProfile(0),
                Dict(heat_sur => 1, power => 1), Dict(heat_use => 1)
            ),
            RefSink("heat demand", OperationalProfile([1, 2, 3, 2]),
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                Dict(heat_use => 1)
            ),
        ]

        links = [
            Direct("surplus heat source-HP", nodes[1], nodes[3], Linear()),
            Direct("HP-demand", nodes[3], nodes[4], Linear()),
            Direct("power source-HP", nodes[2], nodes[3], Linear())
        ]

        return Dict(:nodes => nodes, :links => links, :products => products, :T => T), model, nodes, products, T
    end

    case, model, nodes, products, T = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    power = products[1]
    heat_use = products[3]

    # Initialize variables
    power_uptake = 0.0
    heat_delivered = 0.0

    # Iterate over time periods
    for t in 1:length(T.operational_periods)
        power_uptake += JuMP.value(m[:flow_in][nodes[3], t, power])
        heat_delivered += JuMP.value(m[:flow_out][nodes[3], t, heat_use])
    end

    # Calculate and test COP
    calculated_COP = heat_delivered / power_uptake
    @test calculated_COP ≈ 3 atol = 0.01
end
