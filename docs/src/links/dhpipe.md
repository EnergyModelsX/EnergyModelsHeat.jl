# [DHPipe](@id links-DHPipe)

## [Introduced type and its fields](@id nodes-DHPipe-fields)

[`DHPipe`](@ref) enables to model transport of heat in the form of hot water in thermal energy systems, including district heating (DH) networks, taking into account the supply temperature level and related heat losses. The [`DHPipe`](@ref) is implemented as equivalent to an abstract type [`Link`](@extref EnergyModelsBase.Link). Hence, it utilizes the same functions declared in `EnergyModelsBase`.

DHPipe has the following fields:
- **`id`** :\
     The field `id` is only used for providing a name to the link.
- **`from::Node`** :\
     The node from which there is flow into the link.
- **`to::Node`** :\
     The node from which there is flow out of the link.
- **`length::Float64`** :\
    The pipe length in meters
- **`heatlossfactor::Float64`** :\
    The heat loss factor per meter pipe in [W/(m*K)], [kW/(m*K)] or [MW/(m*K)], depending on the applied unit for energy. Typical values for heat loss factors in DH pipes can be found at the website of the DH pipe manufacturer [LOGSTOR](https://www.logstor.com/district-heating/logstor-lab/lambda-values). 
- **`t_ground::Float64`** :\
    The ground temperature in Celsius
- **`resource_heat::ResourceHeat`** :\ 
    The resource used by DHPipe, to be set equal to the resource in `to::Node`
- **`formulation::Formulation`** :\
    The used formulation of links. If not specified, a `Linear` link is assumed.


### [Mathematical description](@id nodes-DHPipe-math)

[`DHPipe`](@ref) utilizes standard variables from the [`Link`](@extref EnergyModelsBase.Link) type, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*. The variables include:

- [``\texttt{flow\_in}``](@extref man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref man-opt_var-flow)

#### [Constraints](@id nodes-DHPipe-math-con)

The constraint functions are called within the function [`create_link`](@ref), including the calculation of the heat losses, which is included as follows:

  ```math
  \texttt{flow\_out}[l, t, link\_res(l)] = \texttt{flow\_in}[l, t, link\_res(l)] - \texttt{pipelength}[l] * \texttt{heatlossfactor}[l] * (\texttt{t_{supply}}[l] - \texttt{t_{ground}}[l])
  ```



 As an example, for a pipe with a length of 1000 m, a heat loss factor of 0.25 W/(m*K) will result in a relative heat loss of 1.7 % for a 1000 m pipe, at a supply temperature of $70^oC$ and ground temperature of $10^oC$.

