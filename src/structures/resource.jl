
""" `ResourceHeat <: Resource`

A resource for heat.

# Fields
- **`id`** is the name/identifyer of the resource.
- **`co2_int::T`** is the CO₂ intensity, *e.g.*, t/MWh.
- **'t::Float64'** is the temperature in Celsius
"""
struct ResourceHeat{T<:Real} <: Resource
    id::Any
    co2_int::T
    t::Float64
end
