"""
    DHPipe <: EMB.Link

A district heating pipe between two nodes.

# Fields
- **`id`** is the name/identifier of the link.
- **`from::Node`** is the node from which there is flow into the link.
- **`to::Node`** is the node to which there is flow out of the link.
- **`length::Float64`** is the pipe length in meters.
- **`pipelossfactor::Float64`** is the heat loss factor in W m⁻¹ K⁻¹.
- **`t_ground::Float64`** is the ground temperature in °C.
- **`resource_heat::ResourceHeat`** is the resource used by the distric heating system.
- **`formulation::Formulation`** is the used formulation of links. If not specified, a
  `Linear` link is assumed.
"""
struct DHPipe <: EMB.Link
    id::Any
    from::EMB.Node
    to::EMB.Node
    length::Float64
    pipelossfactor::Float64
    t_ground::Float64
    resource_heat::ResourceHeat
    formulation::EMB.Formulation
    data::Vector{EMB.Data}
end

DHPipe(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    length::Float64,
    pipelossfactor::Float64,
    t_ground::Float64,
    resource_heat::ResourceHeat,
) = DHPipe(id, from, to, length, pipelossfactor, t_ground, resource_heat, Linear(), Data[])

"""
    pipelength(l::DHPipe)

Returns the length of disctrict heating `l`.
"""
pipelength(l::DHPipe) = l.length

"""
    pipelossfactor(l::DHPipe)

Returns the heat loss factor λ for disctrict heating `l`.
"""
pipelossfactor(l::DHPipe) = l.pipelossfactor

"""
    t_ground(l::DHPipe)

Returns the ground temperature for disctrict heating `l`.
"""
t_ground(l::DHPipe) = l.t_ground

"""
    resource_heat(l::DHPipe)

Returns the transported `ResourceHeat` for pipe `l`.
"""
resource_heat(l::DHPipe) = l.resource_heat

"""
    t_supply(l::DHPipe)

Returns the supply temperature of the transported `ResourceHeat`.
"""
t_supply(l::DHPipe) = resource_heat(l).t_supply

"""
    link_res(l::DHPipe)

Return the resources transported for a given link `l`.

The default approach is to use the intersection of the inputs of the `to` node and the
outputs of the `from` node.
"""
link_res(l::DHPipe) = intersect(inputs(l.to), outputs(l.from))