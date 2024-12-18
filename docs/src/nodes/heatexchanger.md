# [HeatExchanger](@id nodes-HeatExchanger)

The [`HeatExchanger`](@ref) node models a technology that converts higher-temperature heat from a surplus heat source into lower-temperature heat that can be used in a district heating system.

The [`HeatExchanger`](@ref) will compute the available energy, given the supply and return temperatures of the heat from the surplus heat circuit, the $\Delta T_{min}$ of the `HeatExchanger`, and the supply and return temperatures of the district heating circuit. These parameters may all be given as `TimeProfile` (which in many cases will be a `FixedProfile`).


## [Introduced type and its fields](@id nodes-HeatExchanger-fields)

The [`HeatExchanger`](@ref) is a subtype of the [`NetworkNode`](@extref EnergyModelsBase.NetworkNode). It uses the same functions as `NetworkNode` in `EnergyModelsBase`.

### [Standard fields](@id nodes-HeatExchanger-fields-stand)

- **`id`**:\
  The field `id` is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.

- **`cap::TimeProfile`**:\
  Specifies the installed heating capacity, that is the heat the heat exchanger can deliver.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.\
  In addition, all values have to be non-negative.

- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase man-opt_var-cap).
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.

- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.

- **`input::Dict{<:Resource, <:Real}`**:\
  The field `input` includes the input [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  In the case of a heat exchanger, `input` should always include exactly one resource: the *heat* resource used in the surplus heat system.
  The value of the *heat* resource is in general 1.
  All values have to be non-negative.

- **`output::Dict{<:Resource, <:Real}`**:\
  The field `output` includes the output [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  In the case of a heat exchanger, `output` should always include exactly one resource: the *heat* resource used within the district heating system.
  The value of the *heat* resource is in general 1.
  All values have to be non-negative.

- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is only relevant for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used or for additional emission data through [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess).
  The latter would correspond to uncaptured CO₂ that should be included in the analyses.

### [New fields](@id nodes-HeatExchanger-fields-new)

- **` delta_t_min`**:\
  The $\Delta T_{min}$ for the heat exchanger.

## [Mathematical description](@id nodes-HeatExchanger-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-HeatExchanger-math-var)

The [`HeatExchanger`](@ref) node uses standard `NetworkNode` variables, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)

### [Constraints](@id nodes-HeatExchanger-math-con)

The following sections omit the direct inclusion of the vector of heat exchanger nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{HeatExchanger}`` for all [`HeatExchanger`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id nodes-HeatExchanger-math-con-stand)

Heat exchanger nodes utilize in general the standard constraints described on *[Constraint functions](@extref EnergyModelsBase man-con)* for `NetworkNode`s.
These standard constraints are:

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.


- `constraints_flow_out`:

The `constraints_flow_out` function is replaced with a new implementation for `HeatExchangers` nodes.

The flow out of heat that can be used in the district heating system $p_{DH}$ is limited by the available fraction $dh\_fraction(A, pd, t)$ of the flow of the surplus heat resource $p_{SH}$ flow into the node. 

  ```math
  \texttt{flow\_out}[n, t, p_{SH}] =
  dh\_fraction(A, pd, t) \times \texttt{flow\_in}[n, t ,p_{DH} ]
  
  ```

The available fraction of heat available for the district heating system is calculated using the temperatures of the two resources $p_{SH}$ and $p_{DH}$ as well as the $\Delta T_{min}$ for the heat exchanger. 

The default assumption $A$ for a [`HeatExchanger`](@ref) in `EnergyModelsHeat` is that the medium in both circuits is the same, but mass flows may be adjusted individually in each circuit to optimise heat transfer (`DifferentMassFlow`). 
```math
\begin{align}
    \frac{\dot{Q}_{\text{DH}} }{\dot{Q}_{\text{SH}} } &= 0 \ \text{for} \ T_{\text{DH}_{\text{hot}}} > T_{\text{SH}_{\text{hot}}} - \Delta T_{\text{min}}  %lost because we don't allow the heat upgrade
    \\
    \frac{\dot{Q}_{\text{DH}} }{\dot{Q}_{\text{SH}} } &= \frac{T_{\text{SH}_{\text{hot}}} - (T_{\text{DH}_{\text{cold}}} + \Delta T_{\text{min}} )}{T_{\text{SH}_{\text{hot}}} - T_{\text{SH}_{\text{cold}}}} \ \text{for} \  T_{\text{SH}_{\text{cold}}} < T_{\text{DH}_{\text{cold}}} + \Delta T_{\text{min}}  \\ 
    \frac{\dot{Q}_{\text{DH}} }{\dot{Q}_{\text{SH}} }  &=  1\ \text{otherwise}
\end{align}
```
Alternatively, we can specify the more restrictive assumption that mass flows are the same in both circuits (`EqualMassFlow`)

```math
\begin{align}
    \frac{\dot{Q}_{\text{DH}} }{\dot{Q}_{\text{SH}} } &= 0 
    \ \text{for} \ T_{\text{DH}_{\text{hot}}} - T_{\text{DH}_{\text{cold}}} >   T_{\text{SH}_{\text{hot}}} - T_{\text{SH}_{\text{cold}}}
    \\
    \frac{\dot{Q}_{\text{DH}} }{\dot{Q}_{\text{SH}} } &= 0 
    \ \text{for} \ T_{\text{SH}_{\text{cold}}} < T_{\text{DH}_{\text{cold}}} + \Delta T_{\text{min}}  \ (\text{or}\ T_{\text{DH}_{\text{hot}}} > T_{\text{SH}_{\text{hot}}} - \Delta T_{\text{min}} )
    \\ 
    \frac{\dot{Q}_{\text{DH}} }{\dot{Q}_{\text{SH}} } &=  \frac{T_{\text{DH}_{\text{hot}}} - T_{\text{DH}_{\text{cold}}} }{ T_{\text{SH}_{\text{hot}}} - T_{\text{SH}_{\text{cold}}}} 
    \ \text{otherwise}
\end{align}
```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

*  `constraints_capacity` :

The original constraints limiting the capacity to the installed capacity:

```math
\texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
```

and calling the subfunction `constraints_capacity_installed` to provide bounds for the variable ``\texttt{cap\_inst}[n, t]`` are used.


#### [Additional constraints](@id nodes-HeatExchanger-math-con-add)

[`HeatExchanger`](@ref) modifies the following  constraint functions or constraints in the `create_node` function:





