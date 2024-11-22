## Nodes

### Heat pump

A `HeatPump` node convert low temperature heat to high(er) temperature heat by utilizing en exergy driving force (e.g. electricity). The node allows time-varying coefficient of performance (COP).

HeatPump has the following fields:
- **`id`** :\
     The field `id` is only used for providing a name to the storage.
- **`cap::TimeProfile`** :\
    The installed heating capacity.\n
- **`cap_lower_bound`** :\
    The lower capacity bound for flexibility, value between 0 and 1 reflecting the lowest possible relative capacity 
- **`t_source`** :\
    The temperature profile of the heat source
- **`t_sink`** :\
    The sink temperature of the condensator in Celsius
- **`eff_carnot`** :\
    The Carnot Efficiency COP_real/COP_carnot
- **`input_heat`** :\
    The resource for the low-temperature heat
- **`driving_force`** :\
    The resource of the driving force, e.g. electricity
- **`opex_var::TimeProfile`** :\
    The variable operating expense per energy unit produced.\n
- **`opex_fixed::TimeProfile`** :\
    The fixed operating expense.\n
- **`input::Dict{<:Resource, <:Real}`** :\
    The input `Resource`s.\n
- **`output::Dict{<:Resource, <:Real}`** :\ 
    The generated `Resource`.\n
- **`data::Vector{Data}`** :\
    The additional data (e.g. for investments). The field `data` is conditional through usage of a constructor.


### Thermal energy storage

The node `c` functions mostly like a RefStorage with the additional option to include thermal energy losses. 
Heat losses are quantified through a heat loss factor that describes the amount of thermal energy that is lost in relation to the storage level from the previous timeperiod. The main difference to RefStorage is that these heat losses occur independently of the storage use, i.e. unless the storage level is zero. 

ThermalEnergyStorage has the following fields:
- **`id`** :\
     The field `id` is only used for providing a name to the storage.
- **`charge::AbstractStorageParameters`** :\
    The charging parameters of the [`Storage`](@ref) node. Depending on the chosen type, the charge parameters can include variable OPEX, fixed OPEX,
  and/or a capacity.
- **`level::AbstractStorageParameters`** :\
    The level parameters of the [`Storage`](@ref) node. Depending on the chosen type, the charge parameters can include variable OPEX and/or fixed OPEX.
- **`stor_res::Resource`** :\
    The stored [`Resource`](@ref).
- **`heatlossfactor::Float64`** :\
    The relative heat losses in percent. 
- **`input::Dict{<:Resource,<:Real}`** :\
    The input [`Resource`](@ref)s with conversion
  value `Real`.
- **`output::Dict{<:Resource,<:Real}`** :\
    The generated [`Resource`](@ref)s with conversion  value `Real`. Only relevant for linking and the stored [`Resource`](@ref) as the output
  value is not utilized in the calculations.
- **`data::Vector{<:Data}`** :\
    The additional data (*e.g.*, for investments). The field `data` is conditional through usage of a constructor.


### Heat exchanger