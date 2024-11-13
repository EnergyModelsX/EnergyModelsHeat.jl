""" `DHPipe <: EnergyModelsBase.Direct`

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
struct DHPipe <: EnergyModelsBase.Direct
    id::Any
    from::Node
    to::Node
    length::Float64
    heatlossfactor::Float64
    t_ground::Float64 # kan også bruke \theta (tab), kan også være tidsprofil
    resource_heat::ResourceHeat
    formulation::Formulation
end

DHPipe(
    id::Any,
    from::Node,
    to::Node,
    length::Float64,
    heatlossfactor::Float64,
    t_ground::Float64,
) = DHPipe(id, from, to, length, heatlossfactor, t_ground, Linear())

"""
    create_link(m, 𝒯, 𝒫, l, formulation::Formulation)

Set the constraints for a simple `Link` (input = output). Can serve as fallback option for
all unspecified subtypes of `Link`.
"""
pipelength(l::DHPipe) = l.length
heatlossfactor(l::DHPipe) = l.heatlossfactor
t_ground(l::DHPipe) = l.t_ground
res_heat(l::DHPipe) = l.resource_heat
t_supply(l::DHPipe) = t_supply(res_heat(l))
