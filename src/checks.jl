"""
    check_node(
        n::DirectHeatUpgrade{A, T},
        𝒯,
        modeltype::EnergyModel,
        check_timeprofiles::Bool,
    ) where {A, T}

Check if a `DirectHeatUpgrade` node has reasonable values for the return/supply temperatures
and error if the upgrade is ≥ 1 (should only happen with data errors).
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
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)
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
    EMB.check_node(n::AbstractTES{T}, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool) where {T<:StorageBehavior}

This method checks that nodes of the type AbstractTES are valid.

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

## Warnings
- The `StorageBehavior` should not be `CyclicStrategic` when using `RepresentativePeriods`.
"""
function EMB.check_node(
    n::AbstractTES{T},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {T<:EMB.StorageBehavior}
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    @assert_or_log(
        heat_loss_factor(n) ≥ 0,
        "The heat_loss_factor field must be non-negative."
    )

    @assert_or_log(
        heat_loss_factor(n) ≤ 1,
        "The heat_loss_factor field must be less or equal to 1."
    )

    if (T <: CyclicStrategic) &&
       isa(𝒯, TwoLevel{S,T,U} where {S,T,U<:RepresentativePeriods})
        @warn(
            "Using `CyclicStrategic` with a `$(typeof(n))` and `RepresentativePeriods` " *
            "results in errors for the calculation of the heat loss. It is not advised " *
            "to utilize this `StorageBehavior`. Use instead `CyclicRepresentative`.",
            maxlog = 1
        )
    end
end

"""
    EMB.check_node(n::BoundRateTES{T}, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool) where {T<:EMB.StorageBehavior}

This method checks that the *[`BoundRateTES`](@ref)* node is valid.

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
- The value of the field `level_discharge` is required to be non-negative.
- The value of the field `level_charge` is required to be non-negative.

## Warnings
- The `StorageBehavior` should not be `CyclicStrategic` when using `RepresentativePeriods`.
"""
function EMB.check_node(
    n::BoundRateTES{T},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {T<:EMB.StorageBehavior}
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    @assert_or_log(
        heat_loss_factor(n) ≥ 0,
        "The heat_loss_factor field must be non-negative."
    )

    @assert_or_log(
        heat_loss_factor(n) ≤ 1,
        "The heat_loss_factor field must be less or equal to 1."
    )

    @assert_or_log(
        level_discharge(n) ≥ 0,
        "The level_discharge field must be non-negative."
    )

    @assert_or_log(
        level_charge(n) ≥ 0,
        "The level_charge field must be non-negative."
    )

    if (T <: CyclicStrategic) &&
       isa(𝒯, TwoLevel{S,T,U} where {S,T,U<:RepresentativePeriods})
        @warn(
            "Using `CyclicStrategic` with a `BoundRateTES` and `RepresentativePeriods` " *
            "results in errors for the calculation of the heat loss. It is not advised " *
            "to utilize this `StorageBehavior`. Use instead `CyclicRepresentative`.",
            maxlog = 1
        )
    end
end

"""
    EMB.check_node(n::LevelDependentRateTES{T}, 𝒯, modeltype::EnergyModel, check_timeprofiles::Bool) where {T<:EMB.StorageBehavior}

This method checks that the *[`LevelDependentRateTES`](@ref)* node is valid.

It reuses the standard checks of a `Storage` node through calling the function
[`EMB.check_node_default`](@extref EnergyModelsBase.check_node_default), and adds checks on the
heat loss factor as well as on the c-rate anchor points that shape the state-of-charge
dependent charge and discharge limits.

## Checks
- The `TimeProfile` of the field `capacity` in the type in the field `charge` is required
  to be non-negative if the chosen composite type has the field `capacity`.
- The `TimeProfile` of the field `capacity` in the type in the field `level` is required
  to be non-negative.
- The `TimeProfile` of the field `capacity` in the type in the field `discharge` is required
  to be non-negative if the chosen composite type has the field `capacity`.
- The `TimeProfile` of the field `fixed_opex` is required to be non-negative and
  accessible through a `StrategicPeriod` as outlined in the function
  `check_fixed_opex(n, 𝒯ᴵⁿᵛ, check_timeprofiles)` for the chosen composite type.
- The values of the dictionary `input` are required to be non-negative.
- The values of the dictionary `output` are required to be non-negative.
- The value of the field `heat_loss_factor` is required to be in the range ``[0, 1]``.
- The fields `c_rate_points_charge` and `c_rate_points_discharge` are each required to hold
  between 1 and 3 points, where each point is a 2-element `[level, rate]` pair with a
  non-negative rate.
- The `level` values of `c_rate_points_charge` must be strictly ascending and lie in the
  range ``(0, capacity(level(n), t)]`` for all ``t ∈ \\mathcal{T}``.
- The `level` values of `c_rate_points_discharge` must be strictly descending and lie in the
  range ``[0, capacity(level(n), t))`` for all ``t ∈ \\mathcal{T}``.

## Warnings
- The `StorageBehavior` should not be `CyclicStrategic` when using `RepresentativePeriods`.
"""
function EMB.check_node(
    n::LevelDependentRateTES{T},
    𝒯,
    modeltype::EnergyModel,
    check_timeprofiles::Bool,
) where {T<:EMB.StorageBehavior}
    EMB.check_node_default(n, 𝒯, modeltype, check_timeprofiles)

    @assert_or_log(
        heat_loss_factor(n) ≥ 0,
        "The heat_loss_factor field must be non-negative."
    )
    @assert_or_log(
        heat_loss_factor(n) ≤ 1,
        "The heat_loss_factor field must be less or equal to 1."
    )

    # The smallest installed level capacity bounds the admissible anchor-point levels
    level_cap = minimum(capacity(level(n), t) for t ∈ 𝒯)

    # The expected format is repeated in every message so a user that hits one error
    # immediately sees the structure all anchor points must follow.
    format_charge =
        "The field c_rate_points_charge must contain 1 to 3 points, each a 2-element " *
        "[level, rate] pair with the levels in strictly ascending order and within " *
        "(0, installed level capacity], e.g. [[10.0, 30.0], [50.0, 20.0], [100.0, 10.0]]."
    format_discharge =
        "The field c_rate_points_discharge must contain 1 to 3 points, each a 2-element " *
        "[level, rate] pair with the levels in strictly descending order and within " *
        "[0, installed level capacity), e.g. [[75.0, 40.0], [50.0, 20.0], [25.0, 15.0]]."

    points_charge = c_rate_points_charge(n)
    points_discharge = c_rate_points_discharge(n)

    # --- Charge anchor points ---
    @assert_or_log(1 ≤ length(points_charge) ≤ 3, format_charge)
    @assert_or_log(all(length(p) == 2 for p ∈ points_charge), format_charge)
    @assert_or_log(all(p[2] ≥ 0 for p ∈ points_charge), format_charge)
    @assert_or_log(all(0 < p[1] ≤ level_cap for p ∈ points_charge), format_charge)
    @assert_or_log(
        issorted(points_charge; by = p -> p[1], lt = <) &&
        allunique(p[1] for p ∈ points_charge),
        format_charge
    )

    # --- Discharge anchor points ---
    @assert_or_log(1 ≤ length(points_discharge) ≤ 3, format_discharge)
    @assert_or_log(all(length(p) == 2 for p ∈ points_discharge), format_discharge)
    @assert_or_log(all(p[2] ≥ 0 for p ∈ points_discharge), format_discharge)
    @assert_or_log(all(0 ≤ p[1] < level_cap for p ∈ points_discharge), format_discharge)
    @assert_or_log(
        issorted(points_discharge; by = p -> p[1], rev = true, lt = <) &&
        allunique(p[1] for p ∈ points_discharge),
        format_discharge
    )

    if (T <: CyclicStrategic) &&
       isa(𝒯, TwoLevel{S,T,U} where {S,T,U<:RepresentativePeriods})
        @warn(
            "Using `CyclicStrategic` with a `LevelDependentRateTES` and `RepresentativePeriods` " *
            "results in errors for the calculation of the heat loss. It is not advised " *
            "to utilize this `StorageBehavior`. Use instead `CyclicRepresentative`.",
            maxlog = 1
        )
    end
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
