"""
    constraints_cap_bound(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Function for creating the constraint on the minimum capacity utilization of a [`HeatPump`](@ref).
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
    constraints_flow_in(m, n::DirectHeatUpgrade, 𝒯::TimeStructure, modeltype::EnergyModel)
   
Create the constraints for flow in to [`DirectHeatUpgrade`](@ref). The constraint is only for power as the proportion of the inputs
    depends on the need for upgrade computed from the temperatures of the input/output [`ResourceHeat`](@ref) and the ΔT_min, and the
    capacity is linked to the power consumption.
"""
function EnergyModelsBase.constraints_flow_in(
    m,
    n::DirectHeatUpgrade,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Define capacity by power in
    power = only(filter(!isheat, inputs(n)))

    # Constraint for the individual input stream connections
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, power] == m[:cap_use][n, t] * inputs(n, power)
    )
end

"""
    EMB.constraints_flow_out(m, n::HeatExchanger{A,T}, 𝒯::TimeStructure, modeltype::EnergyModel)

Create the constraints for the flow out from a [`HeatExchanger`](@ref). The flow of available heat energy is calculated
    from the temperatures in the heat flows using the function [`dh_fraction`](@ref).

"""
function EMB.constraints_flow_out(
    m,
    n::HeatExchanger{A,T},
    𝒯::TimeStructure,
    modeltype::EnergyModel,
) where {A,T}
    heat_surplus = only(inputs(n))
    heat_available = only(outputs(n))
    pd = pinch_data(n)

    # Available heat output is a fraction `dh_fraction` of heat input
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, heat_available] ==
        dh_fraction(A, pd, t) * m[:flow_in][n, t, heat_surplus]
    )
end

"""
    constraints_flow_out(m, n::DirectHeatUpgrade{A,T}, 𝒯::TimeStructure, modeltype::EnergyModel) where {A,T}

Create the constraints for flow out from a [`DirectHeatUpgrade`](@ref). The flow of available heat energy is calculated
    from the temperatures in the heat flows using the function [`upgradeable_fraction`](@ref), and the heat needed to upgrade to 
    the  required temperature is calculated by the function [`dh_upgrade`](@ref). Note that the node may dump some of the ingoing heat
    energy, and the power needed for the upgrade is calculated from the resulting energy outflow.
"""
function EnergyModelsBase.constraints_flow_out(
    m,
    n::DirectHeatUpgrade{A,T},
    𝒯::TimeStructure,
    modeltype::EnergyModel,
) where {A,T}
    pd = pinch_data(n)
    # Only allow two inputs, one heat and one other (power)
    power = only(filter(!isheat, inputs(n)))
    heat_surplus = only(filter(isheat, inputs(n)))
    # Only allow one output, must be heat
    heat_available = only(filter(isheat, outputs(n)))

    # Available heat output is a fraction of heat input and the upgrade (using extra power)
    for t ∈ 𝒯
        if dh_upgrade(A, pd, t) > 0
            @constraint(m,
                m[:flow_out][n, t, heat_available] ≤
                m[:flow_in][n, t, power] +
                upgradeable_fraction(A, pd, t) * m[:flow_in][n, t, heat_surplus]
            )
            # Upgrade is powered by power in according to how much is used of the surplus heat in the upgraded flow out
            @constraint(m,
                m[:flow_in][n, t, power] ==
                dh_upgrade(A, pd, t) * m[:flow_out][n, t, heat_available]
            )
        else
            # No need for upgrade, heat can be used directly
            @constraint(m,
                m[:flow_out][n, t, heat_available] ≤
                dh_fraction(A, pd, t) * m[:flow_in][n, t, heat_surplus]
            )
        end
    end
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
            prev_level * heatlossfactor(n)
        )

        # Constraint for avoiding starting below 0 if the previous operational level is
        # nothing
        EMB.constraints_level_bounds(m, n, t, cyclic_pers, modeltype)
    end
end
