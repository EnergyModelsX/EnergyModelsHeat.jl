
""" `ResourceHeat <: Resource`

A resource for heat.

# Fields
- **`id`** is the name/identifyer of the resource.
- **`co2_int::T`** is the CO₂ intensity, *e.g.*, t/MWh.
- **`t_supply::Float64`** is the supply temperature in °C.
- **`t_return::Float64`** is the return temperature in °C.
"""
struct ResourceHeat{IDT,T<:TimeProfile} <: EnergyModelsBase.Resource
    id::IDT
    # co2_int::T
    t_supply::T
    t_return::T
end
t_supply(rh::ResourceHeat) = rh.t_supply
t_supply(rh::ResourceHeat, t) = rh.t_supply[t]
t_return(rh::ResourceHeat) = rh.t_return
t_return(rh::ResourceHeat, t) = rh.t_return[t]

"""
TO DO: Reconcile with ResourceHeat (above)
"""
# struct Heat{T} <: EnergyModelsBase.Resource
#     id::Any
#     T_supply::T
#     T_return::T
#     co2_int::T
# end
# Heat(id, T_supply, T_return) = Heat(id, T_supply, T_return, zero(T_return))
isheat(r) = false
isheat(r::ResourceHeat) = true
