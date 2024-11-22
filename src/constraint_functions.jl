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

"""
    constraints_level_iterate(
    m,
    n::ThermalEnergyStorage,
    prev_pers::PreviousPeriods,
    cyclic_pers::CyclicPeriods,
    per,
    _::SimpleTimes,
    modeltype::EnergyModel,
)

Function for creating the constraint on the storage level considering the heat loss of  of a [`ThermalEnergyStorage`](@ref).

"""
function EMB.constraints_level_iterate(
    m,
    n::ThermalEnergyStorage,
    prev_pers::PreviousPeriods,
    cyclic_pers::CyclicPeriods,
    per,
    _::SimpleTimes,
    modeltype::EnergyModel,
)

    # Iterate through the operational structure
    for (t_prev, t) ∈ withprev(per)
        prev_pers = PreviousPeriods(strat_per(prev_pers), rep_per(prev_pers), t_prev)

        # Extract the previous level
        prev_level = previous_level(m, n, prev_pers, cyclic_pers, modeltype)

        # Mass balance constraint in the storage
        @constraint(m,
            m[:stor_level][n, t] ==
            prev_level + m[:stor_level_Δ_op][n, t] * duration(t) -
            prev_level * heatlossfactor(n)
        )

        # Constraint for avoiding starting below 0 if the previous operational level is
        # nothing
        EMB.constraints_level_bounds(m, n, t, cyclic_pers, modeltype)
    end
end
