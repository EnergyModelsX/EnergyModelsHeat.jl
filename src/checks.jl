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

    # Also perform the default checks (copy from EMB below)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    @assert_or_log(
        sum(capacity(n, t) ≥ 0 for t ∈ 𝒯) == length(𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(
        sum(inputs(n, p) ≥ 0 for p ∈ inputs(n)) == length(inputs(n)),
        "The values for the Dictionary `input` must be non-negative."
    )
    @assert_or_log(
        sum(outputs(n, p) ≥ 0 for p ∈ outputs(n)) == length(outputs(n)),
        "The values for the Dictionary `output` must be non-negative."
    )
    EMB.check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)
end
