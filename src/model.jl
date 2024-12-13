
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

"""
    create_node(m, n::HeatPump, 𝒯::TimeStructure, 𝒫, modeltype::EnergyModel)

Set all constraints for a `HeatPump`.
Calculates the input flows for various resources based on the COP of the HeatPump.
The COP is based on Source and Sink temperature profiles and the carnot efficiency.
It is also possible to inlude a lower capacity bound which the HeatPump cannot cross. This means, however, that cap_use cannot be zero either.

# Called constraint functions
- [`constraints_data`](@extref EnergyModelsBase.constraints_data) for all `node_data(n)`,
- [`constraints_flow_out`](@extref EnergyModelsBase.constraints_flow_out),
- [`constraints_capacity`](@extref EnergyModelsBase.constraints_capacity),
- [`constraints_opex_fixed`](@extref EnergyModelsBase.constraints_opex_fixed), and
- [`constraints_opex_var`](@extref EnergyModelsBase.constraints_opex_var).
- [`constraints_cap_bound`](@ref),
- [`constraints_COP_Heat`](@ref),
- [`constraints_COP_Power`](@ref),
"""
function EMB.create_node(m, n::HeatPump, 𝒯::TimeStructure, 𝒫, modeltype::EnergyModel)

    ## Use the same constraint functions as for a normal Network Node

    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Call of the function for the outlet flow from the `NetworkNode` node
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)

    # Call the function for the minimum used capacity (lower capacity bound)
    constraints_cap_bound(m, n, 𝒯, modeltype)

    # Constraint for the COP - Heat
    constraints_COP_Heat(m, n, 𝒯, modeltype)

    # Constraint for the COP - Electricity
    constraints_COP_Power(m, n, 𝒯, modeltype)
end

"""
    create_node(m, n::ThermalEnergyStorage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `ThermalEnergyStorage`.
Calls the constraint function constraints_level_iterate that includes the heatlossfactor in the calculation of the storage level.
!!!Currently this Node is only available in combination with CyclicPeriods!!!

# Called constraint functions
- [`constraints_level`](@extref EnergyModelsBase.constraints_level)
- [`constraints_data`](@extref EnergyModelsBase.constraints_data) for all `node_data(n)`,
- [`constraints_flow_in`](@extref EnergyModelsBase.constraints_flow_in),
- [`constraints_flow_out`](@extref EnergyModelsBase.constraints_flow_out),
- [`constraints_capacity`](@extref EnergyModelsBase.constraints_capacity),
- [`constraints_opex_fixed`](@extref EnergyModelsBase.constraints_opex_fixed), and
- [`constraints_opex_var`](@extref EnergyModelsBase.constraints_opex_var).
"""
function EMB.create_node(m, n::ThermalEnergyStorage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    constraints_level(m, n, 𝒯, 𝒫, modeltype)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Call of the function for the inlet flow to and outlet flow from the `Storage` node
    constraints_flow_in(m, n, 𝒯, modeltype)
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
