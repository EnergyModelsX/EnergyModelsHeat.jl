# [HeatPump](@id nodes-HeatPump)

[`HeatPump`](@ref) is a technology that converts low temperature heat to high(er) temperature heat by utilizing en exergy driving force (e.g. electricity).

## [Introduced type and its fields](@id nodes-HeatPump-fields)

The [`HeatPump`](@ref) is implemented as equivalent to a [`NetworkNode`](@extref EnergyModelsBase.NetworkNode).
Hence, it utilizes the same functions declared in `EnergyModelsBase`. The [`HeatPump`](@ref) node allows for variable coefficient of performance (COP) based on a source- and sink-temperature as well as a carnot efficiency.  Additionally there is an option to define a lower capacity bound that represents the lowest relative capacity that the heat pump can be regulated down to. Note that there is no option to shut down the heat pump (cap_use = 0) in case of cap_lower_bound > 0. This means that the heat pump must always operate between full capacity and the lower capacity bound. 

The fields of a [`HeatPump`](@ref) are given as:

- **`id`** :\
     The field `id` is only used for providing a name to the storage.
- **`cap::TimeProfile`** :\
    The installed heating capacity.
- **`cap_lower_bound`** :\
    The lower capacity bound for flexibility, value between 0 and 1 reflecting the lowest possible relative capacity. 
- **`t_source`** :\
    The temperature profile of the heat source
- **`t_sink`** :\
    The sink temperature of the condensator in Celsius
- **`eff_carnot`** :\
    The Carnot Efficiency COP_real/COP_carnot
- **`input_heat`** :\
    The resource for the low-temperature heat
- **`driving_force`** :\
    The resource of the driving force, e.g. electricity.
- **`opex_var::TimeProfile`** :\
    The variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** :\
    The fixed operating expense.
- **`input::Dict{<:Resource, <:Real}`** :\
    The input `Resource`s.
- **`output::Dict{<:Resource,<:Real}`** :\
    The generated `Resource`.
- **`data::Vector{Data}`** :\
    The additional data (e.g. for investments). The field `data` is conditional through usage of a constructor.

### [Mathematical description](@id nodes-HeatPump-math)

#### [Variables](@id nodes-HeatPump-math-var)

The [`HeatPump`](@ref) node utilizes all standard variables from the [`NetworkNode`](@extref EnergyModelsBase.NetworkNode) node type, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*. The variables include:

- [``\texttt{opex\_var}``](@extref man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref man-opt_var-flow)
- [``\texttt{emissions\_node}``](@extref man-opt_var-emissions) if `EmissionsData` is added to the field `data`

#### [Constraints](@id nodes-HeatPump-math-con)

The following standard constraints are implemented for a [`HeatPump`](@ref) node.
[`HeatPump`](@ref) nodes utilize the declared method for all nodes 𝒩.
The constraint functions are called within the function [`create_node`](@ref).
Hence, if you do not have to call additional functions, but only plan to include a method for one of the existing functions, you do not have to specify a new [`create_node`](@ref) method.

- `constraints_capacity`:

  ```math
  \texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
  ```

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.


- `constraints_flow_out`:

  ```math
  \texttt{flow\_out}[n, t, p] =
  outputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in outputs(n) \setminus \{\text{CO}_2\}
  ```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@ref man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@ref scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_data`:\
  This function is only called for specified data of the nodes, see above.

- `constraints_cap_bound`:

  ```math
  \texttt{cap\_use}[n, t] >= cap\_lower\_bound(n) \times \texttt{cap\_inst}[n, t]
  ```

- `constraints_COP_Heat`:

  ```math
  \texttt{flow\_in}[n, t, heat\_input\_resource(n)] = \texttt{cap\_use}[n, t] \times ( 1 - \frac{(\texttt{t\_sink}(n, t) - \texttt{t\_source}(n, t))}{eff\_carnot(n,t) \times (\texttt{t\_sink}(n, t) + 273.15)})
  ```
- `constraints_COP_Power`:

  ```math
  \texttt{flow\_in}[n, t, drivingforce\_resource(n)] = \texttt{cap\_use}[n, t] \times \frac{(\texttt{t\_sink}(n, t) - \texttt{t\_source}(n, t))}{eff\_carnot(n,t) \times (\texttt{t\_sink}(n, t) + 273.15)}
  ```

