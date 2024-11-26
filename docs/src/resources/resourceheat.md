
# [ResourceHeat](@id resources-ResourceHeat)

Thermal energy has the special feature that the quality or usefulness of the energy depends not just on the amount but also on the temperature level. 
[`ResourceHeat`](@ref) is introduced to be able to model thermal energy components and systems with specific temperature levels in [EnergyModelsX](https://github.com/EnergyModelsX), and is applied in technology models for generation, conversion, storage and transport of heat, introduced in the 'EnergyModelsHeat' package. [`ResourceHeat`](@ref)  extends on [Resource](https://github.com/EnergyModelsX/EnergyModelsBase.jl/blob/main/src/structures/resource.jl) from [EnergyModelsBase](https://github.com/EnergyModelsX/EnergyModelsBase.jl/tree/main), with the two additional fields for supply and return temperature:

- **`id`** :\
     The field `id` is only used for providing a name to the resource.
- **`co2_int::T`** :\
    The CO₂ intensity, *e.g.*, t/MWh.
- **`t_supply::Float64`** :\
    The supply temperature in Celsius
- **`t_return::Float64`** :\
    The return temperature in Celsius


