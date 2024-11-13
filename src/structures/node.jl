""" 
    HeatPump

A `HeatPump` node to convert low temp heat to high(er) temp heat by utilizing en exergy driving force (e.g. electricity).

# Fields
- **`id`** is the name/identifier of the node.\n
- **`cap::TimeProfile`** is the installed heating capacity.\n
- **`cap_lower_bound`** is the lower capacity bound for flexibility, value between 0 and 1 reflecting the lowest possible relative capacity 
- **`t_source`** is the temperature profile of the heat source
- **`t_sink`** is the sink temperature of the condensator in Celsius
- **`eff_carnot`** is the Carnot Efficiency COP_real/COP_carnot
- **`input_heat`** is the resource for the low temperature heat
- **`driving_force`** is the resource of the driving force, e.g. electricity
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operating expense.\n
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s.\n
- **`output::Dict{<:Resource, <:Real}`** is the generated `Resource`.\n
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field \
`data` is conditional through usage of a constructor.
"""
struct HeatPump <: EMB.NetworkNode
    id::Any
    cap::TimeProfile                        # Heat Capacity
    cap_lower_bound::Union{Real,Nothing}    # Lower capacity bound for flexibility, value between 0 and 1 reflecting the lowest possible relative capacity 
    t_source::TimeProfile                   # Temperature profile of the heat source
    t_sink::TimeProfile                     # Sink temperature of the condensator in Celsius
    eff_carnot::TimeProfile                 # Carnot Efficiency COP_real/COP_carnot
    input_heat::Resource                     # Resource for the low temperature heat
    driving_force::Resource                  # Resource of the driving force, e.g. electricity
    opex_var::TimeProfile                   # Variable OPEX in EUR/MWh
    opex_fixed::TimeProfile                 # Fixed OPEX in EUR/h
    input::Dict{<:Resource,<:Real}          # Input Resource, number irrelevant: COP is calculated seperately
    output::Dict{<:Resource,<:Real}         # Output Resource (Heat), number irrelevant: COP is calculated seperately
    data::Vector{Data}                      # Optional Investment/Emission Data
end

function HeatPump(
    id::Any,
    cap::TimeProfile,
    cap_lower_bound::Union{Real,Nothing},
    t_source::TimeProfile,
    t_sink::TimeProfile,
    eff_carnot::TimeProfile,
    input_heat::Resource,
    driving_force::Resource,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return HeatPump(
        id,
        cap,
        cap_lower_bound,
        t_source,
        t_sink,
        eff_carnot,
        input_heat,
        driving_force,
        opex_var,
        opex_fixed,
        input,
        output,
        Data[],
    )
end

eff_carnot(n::HeatPump, t) = n.eff_carnot[t]
t_sink(n::HeatPump, t) = n.t_sink[t]
t_source(n::HeatPump, t) = n.t_source[t]
cap_lower_bound(n::HeatPump) = n.cap_lower_bound[1]
heat_input_resource(n::HeatPump) = n.input_heat
drivingforce_resource(n::HeatPump) = n.driving_force

""" 
    HeatExchanger

A `HeatExchanger` node to convert "raw" surplus energy from other processes to "available"
energy that can be used in the District Heating network.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`cap::TimeProfile`** is the installed capacity.\n
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operating expense.\n
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.\n
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.\n
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field \
`data` is conditional through usage of a constructor.
"""
struct HeatExchanger <: EnergyModelsBase.NetworkNode
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end

"""
    PinchData{T}

Data for fixed temperature intervals used to calculate available energy from surplus energy source 
operating at `T_HOT` and `T_COLD`, with `ΔT_min` between surplus source and the district heating
network operating at `T_hot` and `T_cold`.
"""
struct PinchData{TP<:TimeProfile} <: EnergyModelsBase.Data
    T_HOT::TP
    T_COLD::TP
    ΔT_min::TP
    T_hot::TP
    T_cold::TP
end


