"""
    check_node(
    n::DirectHeatUpgrade{A, T},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {A, T}

Check if a `DirectHeatUpgrade` node has reasonable values for the return/supply temperatures and
    error if the upgrade is ≥ 1 (should only happen with data errors).
"""
function EMB.check_node(
    n::DirectHeatUpgrade{A, T},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {A, T}
    if check_timeprofiles
        pd = EMH.pinch_data(n)
        @assert_or_log(
            all(EMH.dh_upgrade(A, pd, t) ≤ 1 for t ∈ 𝒯),
            "Temperatures must give need for upgrade ≤ 1"
        )
    end

    # Also perform the default checks 
    EnergyModelsBase.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
end
