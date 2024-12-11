"""
    constraints_capacity(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the minimum capacity utilization of a [`HeatPump`](@ref).
"""
function EMB.constraints_capacity(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
    #Part Load Constraint
    @constraint(m, [t ∈ 𝒯],
        m[:cap_use][n, t] >= (m[:cap_inst][n, t] * cap_lower_bound(n))
    )

    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] <= m[:cap_inst][n, t])

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    constraints_flow_in(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the heat and electricity input of a [`HeatPump`](@ref).
"""
function EMB.constraints_flow_in(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Constraint for the COP - Heat
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, heat_in_resource(n)] ==
        (
            m[:cap_use][n, t] * (
                1 - (
                    (t_sink(n, t) - t_source(n, t)) /
                    (eff_carnot(n, t) * (t_sink(n, t) + 273.15))
                )
            )
        )
    )

    # Constraint for the COP - Electricity
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, driving_force_resource(n)] ==
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

In the case of a [`ThermalEnergyStorage`](@ref), the lowest level iterator is adjusted as
the loss is dependent on the level at the beginning of the operational period.
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
            prev_level * heat_loss_factor(n) * duration(t)
        )

        # Constraint for avoiding starting below 0 if the previous operational level is
        # nothing
        EMB.constraints_level_bounds(m, n, t, cyclic_pers, modeltype)
    end
end
