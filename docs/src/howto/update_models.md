# [Update your model to the latest versions](@id how_to-update)

`EnergyModelsHeat` is still in a pre-release version.
Hence, there are frequently breaking changes occuring, although we plan to keep backwards compatibility.
This document is designed to provide users with information regarding how they have to adjust their nodal descriptions to keep compatibility to the latest changes.

## [Adjustments from 0.1.2](@id how_to-update-01)

### [Thermal energy storage](@id how_to-update-01-TES)

!!! warning
    The legacy constructors for calls of the type of version 0.1 will be removed in version 0.3.
    In addition, the adjustments will not be updated in release 0.3 as potential models will be at that time most likely more than 1 year old.

Starting from version 0.1.2, we introduced a discharge capacity for [`ThermalEnergyStorage`](@ref).
As a consequence, older versions without the discharge capacity will require an adjustment to include the [`AbstractStorageParameters`](@extref EnergyModelsBase nodes-storage-phil-capacities).
The adjustment will **not** change the behavior of the node.

```julia
# Old structure:
ThermalEnergyStorage{CyclicRepresentative}(
    "TES",
    StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
    StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
    heat_use,
    0.05,
    Dict(heat_use => 1),
    Dict(heat_use => 1),
    ExtensionData[], # Conditional
)

# New structure:
ThermalEnergyStorage{CyclicRepresentative}(
    "TES",
    StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
    StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
    StorOpexVar(FixedProfile(0)),
    heat_use,
    0.05,
    Dict(heat_use => 1),
    Dict(heat_use => 1),
    ExtensionData[], # Conditional
)
```
