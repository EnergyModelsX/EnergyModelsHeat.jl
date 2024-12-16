
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
        pipelength(l) * pipelossfactor(l) * (t_supply(l, t) - t_ground(l, t))
    )
end
