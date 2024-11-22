"""
    constraints_cap_bound(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the minimum capacity of a [`HeatPump`](@ref).

"""
function constraints_cap_bound(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
    #Part Load Constraint
    @constraint(m, [t ∈ 𝒯],
        m[:cap_use][n, t] >= (m[:cap_inst][n, t] * cap_lower_bound(n))
    )
end

"""
    constraints_COP_Heat(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the heat input of a [`HeatPump`](@ref).

"""
function constraints_COP_Heat(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Constraint for the COP - Heat
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, heat_input_resource(n)] ==
        (
            m[:cap_use][n, t] * (
                1 - (
                    (t_sink(n, t) - t_source(n, t)) /
                    (eff_carnot(n, t) * (t_sink(n, t) + 273.15))
                )
            )
        )
    )
end

"""
    constraints_COP_Power(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the power input of a [`HeatPump`](@ref).

"""
function constraints_COP_Power(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Constraint for the COP - Electricity
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, drivingforce_resource(n)] ==
        (m[:cap_use][n, t] * (t_sink(n, t) - t_source(n, t))) /
        (eff_carnot(n, t) * (t_sink(n, t) + 273.15))
    )
end