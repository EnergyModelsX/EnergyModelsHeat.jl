function EMB.check_node(
    n::DirectHeatUpgrade{A},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {A}
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
