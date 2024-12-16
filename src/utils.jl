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
"""
    dh_fraction
Return fraction of surpus heat that can be used for district heating.
Dispatch on HeatExchangerAssumptions when calculating d_fraction
"""
dh_fraction(::Type{EqualMassFlows}, T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold) =
    fraction_equal_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
dh_fraction(::Type{DifferentMassFlows}, T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold) =
    fraction_different_mass(T_SH_hot, T_SH_cold, ΔT_min, T_DH_hot, T_DH_cold)
dh_fraction(::Type{EqualMassFlows}, pd, t) = fraction_equal_mass(pd, t)
dh_fraction(::Type{DifferentMassFlows}, pd, t) = fraction_different_mass(pd, t)
"""
    dh_upgrade
Return needed power to upgrade to outflow of useable (for district heating) heat
"""
dh_upgrade(::Type{EqualMassFlows}, pd, t) = upgrade_equal_mass(pd, t)
dh_upgrade(::Type{DifferentMassFlows}, pd, t) = upgrade_different_mass(pd, t)
"""
    upgradeable_fraction
Return fraction of surplus heat that can be upgraded
"""
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

function pinch_data(n::AbstractHeatExchanger)
    heat_surplus = only(filter(is_heat, inputs(n)))
    heat_available = only(outputs(n))
    pd = PinchData(
        t_supply(heat_surplus), t_return(heat_surplus),
        FixedProfile(n.delta_t_min),
        t_supply(heat_available), t_return(heat_available))
    return pd
end

upgrade_fraction(pd, t) =
    upgrade_equal_mass(pd, t) / (upgrade_equal_mass(pd, t) + fraction_equal_mass(pd, t))
