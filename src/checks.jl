"""
    check_node(
    n::DirectHeatUpgrade{A, T},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {A, T}

Check if a `DirectHeatUpgrade` node has reasonable values for the return/supply temperatures and error if the upgrade is ≥ 1 (should only happen with data errors).
"""
function EMB.check_node(
    n::DirectHeatUpgrade{A,T},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {A,T}
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

"""
    EMB.check_node(n::HeatPump, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that the *[`HeatPump`](@ref)* node is valid.

It reuses the standard checks of a `NetworkNode` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), but adds an
additional check on the data.

## Checks
 - The field `cap` is required to be non-negative (similar to the `NetworkNode` check).
 - The value of the field `fixed_opex` is required to be non-negative and
   accessible through a `StrategicPeriod` as outlined in the function
   `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`.
 - The values of the dictionary `input` and `output` are required to be non-negative
   (similar to the `NetworkNode` check).
 - The field `cap_lower_bound` is required to be in the range ``[0, 1]`` for all time steps
   ``t ∈ \\mathcal{T}``.
 - The field `eff_carnot` is required to be in the range ``[0, 1]`` for all time steps
   ``t ∈ \\mathcal{T}``.
 - The field `t_sink` is required to be greater than or equal to the field `t_source` for
   all time steps ``t ∈ \\mathcal{T}``.
"""
function EMB.check_node(n::HeatPump, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
    @assert_or_log(
        cap_lower_bound(n) ≤ 1,
        "The cap_lower_bound field must be less or equal to 1."
    )
    @assert_or_log(
        cap_lower_bound(n) ≥ 0,
        "The cap_lower_bound field must be non-negative."
    )
    @assert_or_log(
        all(eff_carnot(n, t) ≤ 1 for t ∈ 𝒯),
        "The eff_carnot field must be less or equal to 1."
    )
    @assert_or_log(
        all(eff_carnot(n, t) ≥ 0 for t ∈ 𝒯),
        "The eff_carnot field must be non-negative."
    )
    @assert_or_log(
        all(t_sink(n, t) ≥ t_source(n, t) for t ∈ 𝒯),
        "The t_sink field must be greater than or equal to the t_source field."
    )
end

"""
    EMB.check_node(n::ThermalEnergyStorage, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that the *[`ThermalEnergyStorage`](@ref)* node is valid.

It reuses the standard checks of a `Storage` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), but adds an
additional check on the data.

## Checks
- The `TimeProfile` of the field `capacity` in the type in the field `charge` is required
  to be non-negative if the chosen composite type has the field `capacity`.
- The `TimeProfile` of the field `capacity` in the type in the field `level` is required
  to be non-negative`.
- The `TimeProfile` of the field `capacity` in the type in the field `discharge` is required
  to be non-negative if the chosen composite type has the field `capacity`.
- The `TimeProfile` of the field `fixed_opex` is required to be non-negative and
  accessible through a `StrategicPeriod` as outlined in the function
  [`check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)`] for the chosen composite type .
- The values of the dictionary `input` are required to be non-negative.
- The values of the dictionary `output` are required to be non-negative.
- The value of the field `heat_loss_factor` is required to be in the range ``[0, 1]``.

"""
function EMB.check_node(
    n::ThermalEnergyStorage,
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
)
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    @assert_or_log(
        heat_loss_factor(n) ≥ 0,
        "The heat_loss_factor field must be non-negative."
    )

    @assert_or_log(
        heat_loss_factor(n) ≤ 1,
        "The heat_loss_factor field must be less or equal to 1."
    )
end

"""
    EMB.check_link(l::DHPipe, 𝒯,  modeltype::EnergyModel, check_timeprofiles::Bool)

This method checks that the *[`DHPipe`](@ref)* link is valid.

## Checks
 - The field `cap` is required to be non-negative.
 - The field `pipe_length` is required to be non-negative.
 - The field `pipe_loss_factor` is required to be non-negative.
"""
function EMB.check_link(l::DHPipe, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool)
    @assert_or_log(
        all(capacity(l, t) ≥ 0 for t ∈ 𝒯),
        "The capacity must be non-negative."
    )
    @assert_or_log(pipe_length(l) ≥ 0, "The pipeline length must be non-negative.")
    @assert_or_log(
        pipe_loss_factor(l) ≥ 0,
        "The pipeline loss factor must be non-negative."
    )
end
