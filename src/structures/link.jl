"""
    DHPipe

A DH pipe between two nodes.

# Fields
- **`id`** is the name/identifier of the link.
- **`from::Node`** is the node from which there is flow into the link.
- **`to::Node`** is the node to which there is flow out of the link.
- **`cap::TimeProfile`** is the heat transport capacity of the pipe
- **`pipe_length::Float64`** is the pipe length in meters
- **`pipe_loss_factor::Float64`** is the heat loss factor in [W m⁻¹ K⁻¹].
- **`t_ground::TimeProfile`** is the ground temperature in °C.
- **`resource_heat::ResourceHeat` is the resource used by DHPipe
- **`formulation::Formulation`** is the used formulation of links. The field
  `formulation` is conditional through usage of a constructor.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*, for investments). The field
  `data` is conditional through usage of a constructor.
"""
struct DHPipe <: EMB.Link
    id::Any
    from::EMB.Node
    to::EMB.Node
    cap::TimeProfile
    pipe_length::Float64
    pipe_loss_factor::Float64
    t_ground::TimeProfile
    resource_heat::ResourceHeat
    formulation::EMB.Formulation
    data::Vector{EMB.Data}
end

function DHPipe(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    cap::TimeProfile,
    pipe_length::Float64,
    pipe_loss_factor::Float64,
    t_ground::TimeProfile,
    resource_heat::ResourceHeat,
    formulation::EMB.Formulation,
)
    return DHPipe(
        id,
        from,
        to,
        cap,
        pipe_length,
        pipe_loss_factor,
        t_ground,
        resource_heat,
        formulation,
        Data[],
    )
end
function DHPipe(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    cap::TimeProfile,
    pipe_length::Float64,
    pipe_loss_factor::Float64,
    t_ground::TimeProfile,
    resource_heat::ResourceHeat,
    data::Vector{EMB.Data},
)
    return DHPipe(
        id,
        from,
        to,
        cap,
        pipe_length,
        pipe_loss_factor,
        t_ground,
        resource_heat,
        Linear(),
        data,
    )
end
function DHPipe(
    id::Any,
    from::EMB.Node,
    to::EMB.Node,
    cap::TimeProfile,
    pipe_length::Float64,
    pipe_loss_factor::Float64,
    t_ground::TimeProfile,
    resource_heat::ResourceHeat,
)
    return DHPipe(
        id,
        from,
        to,
        cap,
        pipe_length,
        pipe_loss_factor,
        t_ground,
        resource_heat,
        Linear(),
        Data[],
    )
end

"""
    has_capacity(l::DHPipe)

The [`DHPipe`](@ref) has a capacity, and hence, requires the declaration of capacity
variables.
"""
EMB.has_capacity(l::DHPipe) = true

"""
    capacity(l::DHPipe)
    capacity(l::DHPipe, t)

Returns the capacity of a DHPipe `l` as `TimeProfile` or in operational period `t`.
"""
EMB.capacity(l::DHPipe) = l.cap
EMB.capacity(l::DHPipe, t) = l.cap[t]

"""
    pipe_length(l::DHPipe)

Returns the length of the pipe `l`.
"""
pipe_length(l::DHPipe) = l.pipe_length

"""
    pipe_loss_factor(l::DHPipe)

Returns the heat loss factor λ for the pipe `l`.
"""
pipe_loss_factor(l::DHPipe) = l.pipe_loss_factor

"""
    resource_heat(l::DHPipe)

Returns the transported ResourceHeat for pipe `l`.
"""
resource_heat(l::DHPipe) = l.resource_heat

"""
    t_ground(l::DHPipe)

Returns the ground temperature for the pipe `l`.
"""
t_ground(l::DHPipe) = l.t_ground
t_ground(l::DHPipe, t) = l.t_ground[t]

"""
    t_supply(l::DHPipe)

Returns the supply temperature of applied ResourceHeat.
"""
t_supply(l::DHPipe) = t_supply(resource_heat(l))
t_supply(l::DHPipe, t) = t_supply(resource_heat(l), t)

"""
    EMB.inputs(l::DHPipe)

Return the resources transported into a given DHPipe `l`.
This resource is in a standard [`DHPipe`](@ref) given by the function [`resource_heat`](@ref).
"""
EMB.inputs(l::DHPipe) = [resource_heat(l)]

"""
    EMB.outputs(l::DHPipe)

Return the resources transported out from a given DHPipe `l`.
This resource is in a standard [`DHPipe`](@ref) given by the function [`resource_heat`](@ref).
"""
EMB.outputs(l::DHPipe) = [resource_heat(l)]
