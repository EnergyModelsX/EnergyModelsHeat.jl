@testitem "Simple EMX DH model" begin
    using EnergyModelsBase
    using HiGHS
    using JuMP
    using TimeStruct
    using EnergyModelsHeat
    #using PrettyTables

    const EMH = EnergyModelsHeat

    function generate_data()

        # Define the different resources and their emission intensity in tCO2/MWh
        dh_heat_in  = ResourceHeat("DHheat", 0.0, 70.0, 30.0)
        dh_heat_out  = ResourceHeat("DHheat", 0.0, 70.0, 30.0)
        CO₂      = ResourceEmit("CO₂", 0.0)
        products = [dh_heat_in, dh_heat_out]

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
        # 1) a heat surplus source
        # 2) a heat conversion from surplus to usable heat
        # 3) a heat sink representing the district heating demand
        nodes = [
            RefSource(
                "heat source",      # Node id
                FixedProfile(0.85),         # Capacity in MW
                FixedProfile(0),            # Variable OPEX in EUR/MW
                FixedProfile(0),            # Fixed OPEX in EUR/8h
                Dict(dh_heat_in => 1),        # Output from the Node, in this gase, dh_heat
            ),
            RefSink(
                "heat demand",              # Node id
                OperationalProfile([0.2, 0.3, 0.4, 0.3]), # Demand in MW
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                # Line above: Surplus and deficit penalty for the node in EUR/MWh
                Dict(dh_heat_out => 1),           # Input to the Node, in this gase, dh_heat
            ),
        ]

        # Connect all nodes with the availability node for the overall energy/mass balance
        links = [
            EMH.DHPipe("DH pipe 1", nodes[1], nodes[2], 1000.0, 0.25*10^(-6), 10.0, dh_heat_in),
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
    case, model, nodes, products, T = generate_data()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
    m = run_model(case, model, optimizer)
    
    dh_heat_in = products[1]
    dh_heat_out = products[2]


    total_heat_in = sum(JuMP.value(m[:flow_out][nodes[1], t, dh_heat_in]) for t ∈ T)
    total_heat_out = sum(JuMP.value(m[:flow_in][nodes[2], t, dh_heat_out]) for t ∈ T)
    

    heat_loss = total_heat_in - total_heat_out

    heat_loss_assumed = 0.01

    calculated_loss = heat_loss / total_heat_in
    println(calculated_loss)
    @test heat_loss_assumed ≈ calculated_loss rtol = 0.5
end
