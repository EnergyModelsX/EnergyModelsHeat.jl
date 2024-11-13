""" `DHPipe <: EnergyModelsBase.Link`

A DH pipe between two nodes.

# Fields
- **`id`** is the name/identifier of the link.
- **`from::Node`** is the node from which there is flow into the link.
- **`to::Node`** is the node to which there is flow out of the link.
- **`length::Float64`** is the pipe length in meters
- **`heatlossfactor::Float64`** is the heat loss factor in [W m−2 K−1 ] 
- **`t_ground::Float64`** is the ground temperature in Celsius
- **`resource_heat::ResourceHeat` is the resource used by DHPipe
- **`formulation::Formulation`** is the used formulation of links. If not specified, a
  `Linear` link is assumed.
"""
struct DHPipe <: EMB.Link
    id::Any
    from::EMB.Node
    to::EMB.Node
    length::Float64
    heatlossfactor::Float64
    t_ground::Float64 # kan også bruke \theta (tab), kan også være tidsprofil
    resource_heat::EMH.ResourceHeat
    formulation::EMB.Formulation
    data::Vector{EMB.Data}                      # Optional Investment/Emission Data
end

DHPipe(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    length::Float64,
    heatlossfactor::Float64,
    t_ground::Float64,
    resource_heat::EMH.ResourceHeat,
) = DHPipe(id, from, to, length, heatlossfactor, t_ground, resource_heat, Linear(), Data[])


pipelength(l::DHPipe) = l.length
heatlossfactor(l::DHPipe) = l.heatlossfactor
t_ground(l::DHPipe) = l.t_ground
resource_heat(l::DHPipe) = l.resource_heat
t_supply(l::DHPipe) = resource_heat(l).t

"""
    link_res(l::Link)

Return the resources transported for a given link `l`.

The default approach is to use the intersection of the inputs of the `to` node and the
outputs of the `from` node.
"""
link_res(l::DHPipe) = intersect(inputs(l.to), outputs(l.from))
