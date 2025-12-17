# Release Notes

## Version 0.1.4 (2025-12-17)

* Updated the format of `descriptive_names.yaml` to [`EnergyModelsGUI` v0.6.0](https://github.com/EnergyModelsX/EnergyModelsGUI.jl/releases/tag/v0.6.0).

## Version 0.1.3 (2025-10-20)

### New subtype for thermal energy storage

* Added Abstract type `AbstractTES`.
* Introduced a new `AbstractTES` type `BoundRateTES` including documentation, checks, and tests which sets a maximum bound for charge and discharge capacities in relation to the installed storage level.
* Added discharge capacity to `ThermalEnergyStorage` node with legacy constructors to prevent breaking changes.

### Miscellaneous

* Switched from `Data` to `ExtensionData` as described within [`EnergyModelsBase` v0.9.1](https://github.com/EnergyModelsX/EnergyModelsBase.jl/releases/tag/v0.9.1).
* Removed the folder `submodels` as the CHP model was moved to *[a new repository](https://github.com/iDesignRES/CHP_modelling)*.
* Unified and extended the test structure.
* Included the descriptive names for `EnergyModelsGUI`.

### Fixes

* Minor fixes to the documentation and example comments.
* Fixed one of the constructors for `ThermalEnergyStorage` which was not working.
  This includes as well now a warning if the wrong `StorageBehavior` is utilized.

## Version 0.1.2 (2025-06-10)

### Bugfix

* The function `t_source(n::HeatPump)` did result in an error.
  This was not tested previously and not used in the model.
  New tests are hence included for it.

## Version 0.1.1 (2025-02-10)

* Adjusted to [`EnergyModelsBase` v0.9.0](https://github.com/EnergyModelsX/EnergyModelsBase.jl/releases/tag/v0.9.0):
  * Increased version nubmer for EMB.
  * Model worked without adjustments.
  * Adjustments only required for simple understanding of changes.
* Included updated `DHPipe`:
  * `DHPIpe` now follow a check.
  * The arguments for `create_link` were updated.
* Renaming of test files to be consistent with other packages.

## Version 0.1.0 (2024-12-18)

Initial version of the heat package within the [EnergyModelsX](https://github.com/EnergyModelsX) framework.

### Heat Pump

* Developed a new `HeatPump` node based on `RefNetworkNode`.
* Incorporates constraints on the input flow of a heat source and a driving force (electricity).
* The underlying COP calculation is based on given profiles for sink and source temperature as well as a Carnot efficiency.

### Thermal Energy Storage

* Developed a `ThermalEnergyStorage` node.
* Includes heat losses calculated by a given heat loss factor and the storage level of the previous time period.

### District Heating Pipe

* Developed a new type of link called `DHPipe`.
* Incorporates a constant absolute heat loss between the input and the output of the link based on district heating temperature, ground temperature, pipe lenght and heat loss factor.
* Requires a capacity and allows for investments.

### HeatExchanger nodes

* Developed a `HeatExchanger` node as parametric type.
* The node can be used in combination with `ResourceHeat` for automatic calculation of the achievable energy recovery.
