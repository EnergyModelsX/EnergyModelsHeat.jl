
"""
    EMB.variables_link(m, ℒˢᵘᵇ::Vector{<:DHPipe}, 𝒯, modeltype::EnergyModel)

Creates the following additional variable for **ALL** district heating pipe links:
- `dh_loss[l, t]` is a continuous variable describing the heat los of [`DHPipe`](@ref) `l`
  operational period `t`.
"""
function EMB.variables_link(m, ℒˢᵘᵇ::Vector{<:DHPipe}, 𝒯, modeltype::EnergyModel)
    @variable(m, dh_pipe_loss[ℒˢᵘᵇ, 𝒯])
end

"""
    EMB.create_link(m, l::DHPipe, 𝒯, 𝒫, modeltype::EnergyModel)

When the link is a [`DHPipe`](@ref), the constraints for a link include a loss based on the
difference in the temperature of the district heating resource and the ground.

In addition, a [`DHPipe`](@ref) includes a capacity with the potential for investments.
"""
function EMB.create_link(
    m,
    l::DHPipe,
    𝒯,
    𝒫,
    modeltype::EnergyModel,
)

    # DH pipe in which each output corresponds to the input minus heat losses
    @constraint(m, [t ∈ 𝒯],
        m[:link_out][l, t, resource_heat(l)] ==
        m[:link_in][l, t, resource_heat(l)] - m[:dh_pipe_loss][l, t]
    )
    @constraint(m, [t ∈ 𝒯],
        m[:dh_pipe_loss][l, t] ==
        pipe_length(l) * pipe_loss_factor(l) * (t_supply(l, t) - t_ground(l, t))
    )

    # Add the capacity constraints
    @constraint(m, [t ∈ 𝒯, p ∈ inputs(l)], m[:link_in][l, t, p] ≤ m[:link_cap_inst][l, t])
    constraints_capacity_installed(m, l, 𝒯, modeltype)
end

"""
    EMB.variables_node(m, 𝒩::Vector{<:LevelDependentRateTES}, 𝒯, modeltype::OperationalModel)

Declare the auxiliary binary variables required by [`LevelDependentRateTES`](@ref) nodes.

For each node and operational period, two binaries per direction encode which of up to three
piecewise-linear regions of the state-of-charge dependent c-rate curve is active:
- `bin_region_charge[n, t, 1:2]` selects the active region of the charge curve.
- `bin_region_discharge[n, t, 1:2]` selects the active region of the discharge curve.

The variables are only declared for an [`OperationalModel`](@extref EnergyModelsBase.OperationalModel),
see the note on investment models in [`EMB.constraints_capacity`](@ref).
"""
function EMB.variables_node(
    m,
    𝒩::Vector{<:LevelDependentRateTES},
    𝒯,
    modeltype::OperationalModel,
)
    # Two binaries encode the active region of the piecewise charge curve (3 regions max)
    @variable(m, bin_region_charge[𝒩, 𝒯, 1:2], Bin)
    # Two binaries encode the active region of the piecewise discharge curve (3 regions max)
    @variable(m, bin_region_discharge[𝒩, 𝒯, 1:2], Bin)
end
