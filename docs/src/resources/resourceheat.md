
# [ResourceHeat](@id resources-ResourceHeat)

Thermal energy has the special feature that the quality or usefulness of the energy depends not just on the amount but also on the temperature level.
[`ResourceHeat`](@ref), which is a 'Resource' for converting or transporting thermal energy, is introduced to be able to model thermal energy components and systems with specific temperature levels in [EnergyModelsX](https://github.com/EnergyModelsX).
[`ResourceHeat`](@ref) is applied in technology models for generation, conversion, storage and transport of heat, introduced in the `EnergyModelsHeat` package.

## [Introduced type and its fields](@id resources-ResourceHeat-fields)

[`ResourceHeat`](@ref) extends on the abstract type [Resource](https://github.com/EnergyModelsX/EnergyModelsBase.jl/blob/main/src/structures/resource.jl) from [EnergyModelsBase](https://github.com/EnergyModelsX/EnergyModelsBase.jl/tree/main), with the two additional fields for supply and return temperature:

- **`id`** :\
    The field `id` is only used for providing a name to the resource.
- **`t_supply::TimeProfile`** :\
    The supply temperature in °C.
    This is the temperature for water flowing from a source to the sink in a thermal network.
    In district heating, supply temperature is typically in the range 80-120 °C for conventional high-temperature district heating networks, and 40-70 °C for modern, low-temperature networks.
- **`t_return::TimeProfile`** :\
    The return temperature in °C, *i.e.*, the temperature for water flowing from the sink back to the source in a thermal network.
    In district heating, the return temperature is typically 30-50 °C below the supply temperature.
    The use of the field return temperature is optional: if only the supply temperature is defined, the return temperature is set to zero.

!!! tip "Constant temperatures"
    If the constant for supply and return is not changing, it is also possible to provide a number as input.
    This is achieved through a constructor.
