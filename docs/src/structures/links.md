## Links
EnergyModelsHeat introduces a new link for DH pipes, called DHPipe, exending on the abstract type link from EnergyModelsBase. 

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
    The heat loss factor per meter pipe in [W/(m*K)], [kW/(m*K)] or [MW/(m*K)], depending on the applied unit for energy. Typical values for heat loss factors in DH pipes can be found at the website of the DH pipe manufacturer [LOGSTOR](@cite). 
- **`t_ground::Float64`** :\
    The ground temperature in Celsius
- **`resource_heat::ResourceHeat`**:\ 
    The resource used by DHPipe, to be set equal to the resource in `to::Node`
- **`formulation::Formulation`** :\
    The used formulation of links. If not specified, a `Linear` link is assumed.

The heat losses for pipe $l$  are included through the following constraint:
  ```math
  \texttt{flow\_out}[l, t, link\_res(l)] = \texttt{flow\_in}[l, t, link\_res(l)] - pipelength[l] * heatlossfactor[l] * (t_supply[l] - t_ground[l])
  ```
 As an example, for a pipe with a length of 1000 m, a heat loss factor of 0.25 W/(m*K) will result in a relative heat loss of 1.7 % for a 1000 m pipe, at a supply temperature of $70^oC$ and ground temperature of $10^oC$.

## References
```@bibliography
```