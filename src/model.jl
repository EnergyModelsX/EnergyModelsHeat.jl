
"""
    create_link(m, 𝒯, 𝒫, l::DHPipe, modeltype::EnergyModel, formulation::EMB.Formulation)

When the link is a [`DHPipe`](@ref), the constraints for a link include a loss based on the
difference in the temperature of the district heating resource and the ground.
"""
function EMB.create_link(
    m,
    𝒯,
    𝒫,
    l::DHPipe,
    modeltype::EnergyModel,
    formulation::EMB.Formulation,
)

    # DH pipe in which each output corresponds to the input minus heat losses
    @constraint(m, [t ∈ 𝒯, p ∈ link_res(l)],
        m[:link_out][l, t, p] ==
        m[:link_in][l, t, p] -
        pipelength(l) * pipelossfactor(l) * (t_supply(l) - t_ground(l))
    )
end

"""
    fraction_equal_mass(pd::PinchData)

Calculate fraction of heat available for district heating at pinch point `T_DH_cold`
"""
fraction_equal_mass(pd::PinchData, t) = fraction_equal_mass(
    pd.T_SH_hot[t],
    pd.T_SH_cold[t],
    pd.ΔT_min[t],
    pd.T_DH_hot[t],
    pd.T_DH_cold[t],
)

# Dispatch on HeatExchangerAssumptions when calculating d_fraction
dh_fraction(::Type{EqualMassFlows}, T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold) =
    fraction_equal_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
dh_fraction(::Type{DifferentMassFlows}, T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold) =
    fraction_different_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
dh_fraction(::Type{EqualMassFlows}, pd, t) = fraction_equal_mass(pd, t)
dh_fraction(::Type{DifferentMassFlows}, pd, t) = fraction_different_mass(pd, t)
dh_upgrade(::Type{EqualMassFlows}, pd, t) = upgrade_equal_mass(pd, t)
dh_upgrade(::Type{DifferentMassFlows}, pd, t) = upgrade_different_mass(pd, t)
upgradeable_fraction(::Type{EqualMassFlows}, pd, t) = upgradeable_equal_mass(pd, t)
upgradeable_fraction(::Type{DifferentMassFlows}, pd, t) = upgradeable_different_mass(pd, t)

# Assuming equal mass flows
function fraction_equal_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
    if T_DH_hot ≤ (T_SH_hot - ΔT_min)
        if (T_DH_hot - T_DH_cold) > (T_SH_hot - T_SH_cold)
            return zero(T_SH_hot)
        else
            return (T_DH_hot - T_DH_cold) / (T_SH_hot - T_SH_cold)
        end
    else
        return zero(T_SH_hot)
    end
end

# Allowing different mass flows
fraction_different_mass(pd::PinchData, t) =
    fraction_different_mass(
        pd.T_SH_hot[t],
        pd.T_SH_cold[t],
        pd.ΔT_min[t],
        pd.T_DH_hot[t],
        pd.T_DH_cold[t],
    )
function fraction_different_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
    if (T_DH_hot > (T_SH_hot - ΔT_min))
        return zero(T_SH_hot)
    elseif (T_SH_cold < (T_DH_cold + ΔT_min))
        return (T_SH_hot - (T_DH_cold + ΔT_min)) / (T_SH_hot - T_SH_cold)
    else
        return one(T_SH_hot)
    end
end

upgradeable_equal_mass(pd, t) = upgradeable_equal_mass(
    pd.T_SH_hot[t],
    pd.T_SH_cold[t],
    pd.ΔT_min[t],
    pd.T_DH_hot[t],
    pd.T_DH_cold[t],
)
function upgradeable_equal_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
    if (T_SH_cold < (T_DH_cold + ΔT_min))
        return max(
            zero(T_SH_hot),
            (T_SH_hot - (T_DH_cold + ΔT_min)) / (T_SH_hot - T_SH_cold),
        )
    else
        return one(T_DH_hot)
    end
end

upgradeable_different_mass(pd, t) = upgradeable_different_mass(
    pd.T_SH_hot[t],
    pd.T_SH_cold[t],
    pd.ΔT_min[t],
    pd.T_DH_hot[t],
    pd.T_DH_cold[t],
)
function upgradeable_different_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
    if (T_SH_cold < (T_DH_cold + ΔT_min))
        return max(
            zero(T_DH_hot),
            (T_SH_hot - (T_DH_cold + ΔT_min)) / (T_SH_hot - T_SH_cold),
        )
    else
        return one(T_DH_hot)
    end
end

"""
Assuming equal mass flows
"""
upgrade_equal_mass(pd::PinchData, t) =
    upgrade_equal_mass(
        pd.T_SH_hot[t],
        pd.T_SH_cold[t],
        pd.ΔT_min[t],
        pd.T_DH_hot[t],
        pd.T_DH_cold[t],
    )
function upgrade_equal_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
    if T_DH_hot > (T_SH_hot - ΔT_min)
        if T_SH_cold < (T_DH_cold + ΔT_min)
            return (T_DH_hot - T_SH_hot + ΔT_min) / (T_DH_hot - T_DH_cold)
        else
            return (T_DH_hot - (T_DH_cold + T_SH_hot - T_SH_cold)) / (T_DH_hot - T_DH_cold)
        end
    else
        return zero(T_SH_hot)
    end
end

upgrade_different_mass(pd::PinchData, t) =
    upgrade_different_mass(
        pd.T_SH_hot[t],
        pd.T_SH_cold[t],
        pd.ΔT_min[t],
        pd.T_DH_hot[t],
        pd.T_DH_cold[t],
    )
function upgrade_different_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
    if (T_DH_hot > (T_SH_hot - ΔT_min))
        return (T_DH_hot - T_SH_hot + ΔT_min) / (T_DH_hot - T_DH_cold)
    else
        return zero(T_SH_hot)
    end
end

pinch_data(n::AbstractHeatExchanger) =
    only(filter(data -> typeof(data) <: PinchData, node_data(n)))

function EMB.constraints_flow_out(
    m,
    n::HeatExchanger{A},
    𝒯::TimeStructure,
    modeltype::EnergyModel,
) where {A}
    pd = pinch_data(n)
    heat_surplus = only(inputs(n))
    heat_available = only(outputs(n))

    # Available heat output is a fraction `ψ` of heat input
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, heat_available] ==
        dh_fraction(A, pd, t) * m[:flow_in][n, t, heat_surplus]
    )
end

upgrade_fraction(pd, t) =
    upgrade_equal_mass(pd, t) / (upgrade_equal_mass(pd, t) + fraction_equal_mass(pd, t))

function EnergyModelsBase.constraints_flow_out(
    m,
    n::DirectHeatUpgrade{A},
    𝒯::TimeStructure,
    modeltype::EnergyModel,
) where {A}
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
