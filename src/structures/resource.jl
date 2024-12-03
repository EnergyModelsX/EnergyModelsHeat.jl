
""" `ResourceHeat <: Resource`

A resource for heat.

# Fields
- **`id`** is the name/identifyer of the resource.
- **`co2_int::T`** is the CO₂ intensity, *e.g.*, t/MWh.
- **`t_supply::Float64`** is the supply temperature in °C.
- **`t_return::Float64`** is the return temperature in °C.
"""
struct ResourceHeat{T<:Real} <: Resource
    id::Any
    co2_int::T
    t_supply::Float64
    t_return::Float64
end

"""
TO DO: Reconcile with ResourceHeat (above)
"""
struct Heat{T} <: EnergyModelsBase.Resource
    id::Any
    T_supply::T
    T_return::T
    co2_int::T
end
Heat(id, T_supply, T_return) = Heat(id, T_supply, T_return, zero(T_return))
isheat(r) = false
isheat(r::Heat) = true
