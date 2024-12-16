
"""
    ResourceHeat{IDT,TS<:TimeProfile,TR<:TimeProfile} <: Resource

    ResourceHeat(id, t_supply::TimeProfile, t_return::TimeProfile)
    ResourceHeat(id, t_supply::TimeProfile)
    ResourceHeat(id, t_supply::Real, t_return::Real)
    ResourceHeat(id, t_supply::Real)

A resource for heat.

# Fields
- **`id::IDT`** is the name/identifyer of the resource.
- **`t_supply::TS`** is the supply temperature in °C as a `TimeProfile`. Providing a single
  number will be translated to a `FixedProfile`.
- **`t_return::TR`** is the return temperature in °C as a `TimeProfile`. Providing a single
  number will be translated to a `FixedProfile`. This field is optional, and will be set to
  zero if no value is provided.
"""
struct ResourceHeat{IDT,TS<:TimeProfile,TR<:TimeProfile} <: Resource
    id::IDT
    t_supply::TS
    t_return::TR
end
ResourceHeat(id, t_supply::TimeProfile) =
    ResourceHeat(id, t_supply, FixedProfile(0))
ResourceHeat(id, t_supply::Real, t_return::Real) =
    ResourceHeat(id, FixedProfile(t_supply), FixedProfile(t_return))
ResourceHeat(id, t_supply::Real) =
    ResourceHeat(id, FixedProfile(t_supply), FixedProfile(0))

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
    is_heat(r)

Returns true for heat resources, false otherwise. Extend this by dispatching on the type for
any alternative heat resource type implemented.
"""
is_heat(r::Resource) = false
is_heat(r::ResourceHeat) = true

"""
    co2_int(::ResourceHeat)

Returns 0.0 for all `ResourceHeat`.
"""
EMB.co2_int(::ResourceHeat) = 0.0
