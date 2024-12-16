
""" ResourceHeat{IDT,TS<:TimeProfile,TR<:TimeProfile} <: Resource

A resource for heat.

# Fields
- **`id`** is the name/identifyer of the resource.
- **`t_supply`** is the supply temperature in °C as a `TimeProfile`. Providing a single
  number will be translated to a `FixedProfile`.
- **`t_return`** is the return temperature in °C as a `TimeProfile`. Providing a single
  number will be translated to a `FixedProfile`.
"""
struct ResourceHeat{IDT,TS<:TimeProfile,TR<:TimeProfile} <: Resource
    id::IDT
    t_supply::TS
    t_return::TR
end
ResourceHeat(id, t_supply::Real, t_return::Real) =
    ResourceHeat(id, FixedProfile(t_supply), FixedProfile(t_return))

"""
    t_supply(rh::ResourceHeat)
    t_supply(rh::ResourceHeat, t)

Return the supply temperature defined for a `ResourceHeat`.
"""
t_supply(rh::ResourceHeat) = rh.t_supply
t_supply(rh::ResourceHeat, t) = rh.t_supply[t]

"""
    t_return(rh::ResourceHeat)
    t_return(rh::ResourceHeat, t)

Return the return temperature defined for a `ResourceHeat`
"""
t_return(rh::ResourceHeat) = rh.t_return
t_return(rh::ResourceHeat, t) = rh.t_return[t]

"""
    isheat(r)

Returns true for heat resources, false otherwise. Extend this by dispatching on the type for
any alternative heat resource type implemented.
"""
isheat(r) = false
isheat(r::ResourceHeat) = true

"""
    co2_int(::ResourceHeat)

Returns 0.0 for all `ResourceHeat`.
"""
EMB.co2_int(::ResourceHeat) = 0.0
