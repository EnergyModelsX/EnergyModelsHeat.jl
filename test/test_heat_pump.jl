@testitem "HeatPump" begin
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
        𝒫        = [power, heat_sur, heat_use, CO₂]

        op_duration = 2 # Each operational period has a duration of 2
        op_number = 4   # There are in total 4 operational periods
        operational_periods = SimpleTimes(op_number, op_duration)

        op_per_strat = op_duration * op_number

        # Creation of the time structure and global data
        𝒯 = TwoLevel(2, 1, operational_periods; op_per_strat)
        model = OperationalModel(
            Dict(CO₂ => FixedProfile(10)),  # Emission cap for CO₂ in t/8h
            Dict(CO₂ => FixedProfile(0)),   # Emission price for CO₂ in EUR/t
            CO₂,                            # CO₂ instance
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
            EMH.HeatPump(
                "HeatPump",
                FixedProfile(3),
                0,
                FixedProfile(29.475), # source temperature that leads to a COP of 3
                FixedProfile(90),
                FixedProfile(0.5),
                heat_sur,
                power,
                FixedProfile(0),
                FixedProfile(0),
                Dict(heat_use => 1),
            ),
            RefSink(
                "heat demand",              # Node id
                OperationalProfile([1, 2, 3, 2]), # Demand in MW
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                # Line above: Surplus and deficit penalty for the node in EUR/MWh
                Dict(heat_use => 1),           # Energy demand and corresponding ratio
            ),
        ]

        # Connect all 𝒩 with the availability node for the overall energy/mass balance
        links = [
            Direct("suplus heat source-HP", 𝒩[1], 𝒩[3], Linear()),
            Direct("HP-demand", 𝒩[3], 𝒩[4], Linear()),
            Direct("power source-HP", 𝒩[2], 𝒩[3], Linear()),
        ]

        # Input data structure
        case = Case(𝒯, 𝒫, [𝒩, links], [[get_nodes, get_links]])
        return (; case, model)
    end

    case, model = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)

    # Extract the required information from the node
    𝒯 = get_time_struct(case)
    𝒫 = get_products(case)
    𝒩 = get_nodes(case)
    power = 𝒫[1]
    surplus = 𝒫[2]
    heat_use = 𝒫[3]
    hp = 𝒩[3]

    @testset "Access functions" begin
        # Test that the input resources are correctly identified
        @test inputs(hp) == Resource[surplus, power]
        @test inputs(hp, surplus) == 1
        @test inputs(hp, power) == 1
        @test EMH.heat_in_resource(hp) == surplus
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
        @test EMH.cap_lower_bound(hp) == 0
    end

    @testset "Mathematical description" begin
        # Test that the expected COP ratio is calculated
        COP = 3.0
        power_uptake = sum(JuMP.value(m[:flow_in][hp, t, power]) for t ∈ 𝒯)
        heat_delivered = sum(JuMP.value(m[:flow_out][hp, t, heat_use]) for t ∈ 𝒯)

        # Check the calculated COP
        calculated_COP = heat_delivered / power_uptake
        @test calculated_COP ≈ 3 atol = 0.01
    end
end
