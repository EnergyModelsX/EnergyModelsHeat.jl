struct HeatPump <: EMB.NetworkNode
    id::Any
    cap::TimeProfile                        # Heat Capacity
    cap_lower_bound::Union{Real,Nothing}    # Lower capacity bound for flexibility, value between 0 and 1 reflecting the lowest possible relative capacity 
    t_source::TimeProfile                   # Temperature profile of the heat source
    t_sink::TimeProfile                     # Sink temperature of the condensator in Celsius
    eff_carnot::TimeProfile                 # Carnot Efficiency COP_real/COP_carnot
    input_heat::Resource                     # Resource for the low temperature heat
    driving_force::Resource                  # Resource of the driving force, e.g. electricity
    opex_var::TimeProfile                   # Variable OPEX in EUR/MWh
    opex_fixed::TimeProfile                 # Fixed OPEX in EUR/h
    input::Dict{<:Resource,<:Real}          # Input Resource, number irrelevant: COP is calculated seperately
    output::Dict{<:Resource,<:Real}         # Output Resource (Heat), number irrelevant: COP is calculated seperately
    data::Vector{Data}                      # Optional Investment/Emission Data
end

function HeatPump(
    id::Any,
    cap::TimeProfile,
    cap_lower_bound::Union{Real,Nothing},
    t_source::TimeProfile,
    t_sink::TimeProfile,
    eff_carnot::TimeProfile,
    input_heat::Resource,
    driving_force::Resource,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return HeatPump(id, cap, cap_lower_bound, t_source, t_sink, eff_carnot, input_heat, driving_force, opex_var, opex_fixed, input, output, Data[])
end

function EMB.create_node(m, n::HeatPump, 𝒯::TimeStructure, 𝒫, modeltype::EnergyModel)

    ## Use the same constraint functions as for a normal Network Node

    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Call of the function for the outlet flow from the `NetworkNode` node
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)

    ## Custom constraints for COP calculation and flexibility

    eff_carnot(n::HeatPump, t) = n.eff_carnot[t]
    t_sink(n::HeatPump, t) = n.t_sink[t]
    t_source(n::HeatPump, t) = n.t_source[t]
    cap_lower_bound(n::HeatPump) = n.cap_lower_bound[1]
    heat_input_resource(n::HeatPump) = n.input_heat
    drivingforce_resource(n::HeatPump) = n.driving_force

    #Part Load Constraint
    @constraint(m, [t ∈ 𝒯],
        m[:cap_use][n, t] >= (m[:cap_inst][n, t] * cap_lower_bound(n))
    )

    # Constraint for the COP - Heat
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, heat_input_resource(n)] ==
        (m[:cap_use][n, t] * (1 - ((t_sink(n, t) - t_source(n, t)) / (eff_carnot(n, t) * (t_sink(n, t) + 273.15)))))
    )

    # Constraint for the COP - Electricity
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, drivingforce_resource(n)] ==
        (m[:cap_use][n, t] * (t_sink(n, t) - t_source(n, t))) / (eff_carnot(n, t) * (t_sink(n, t) + 273.15))
    )

end

#=
# Extract timesteps from the TwoLevel object
all_timesteps = [t for t in 𝒯]

# Define indices for valid timesteps (from 2 to end)
indices = 2:length(all_timesteps)

println(all_timesteps[2], all_timesteps[1])

@constraint(m, [i in indices],
    m[:cap_use][n, all_timesteps[i]] <= (100 * m[:cap_use][n, all_timesteps[i - 1]])
)
=#

#=
    # This ramping constraint is not suitable for larger models with higher resolution

    println("Starting setting up ramping constraints...")
    for (prev_t, t) ∈ withprev(𝒯)
        if prev_t !== nothing
            @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] <= (1.2 * m[:cap_use][n, prev_t]))    # !!! hard coded ramping factor !!!
            #@constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] >= (0.8 * m[:cap_use][n, prev_t]))
        end
    end
    println("Finished setting up ramping constraints!")

=#

