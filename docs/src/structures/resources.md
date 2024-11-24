# Structures

## Resources
EnergyModelsHeat introduces the new resource ResourceHeat, extending on Resource from EnergyModelsBase. The fields of ResourceHeat are given as:

- **`id`** :\
     The field `id` is only used for providing a name to the resource.
- **`co2_int::T`** :\
    The CO₂ intensity, *e.g.*, t/MWh.
- **'t_supply::Float64'** :\
    The supply temperature in Celsius
- **'t_return::Float64'** :\
    The return temperature in Celsius


