# EnergyModelsHeat

[![DOI](https://joss.theoj.org/papers/10.21105/joss.06619/status.svg)](https://doi.org/10.21105/joss.06619)
[![Build Status](https://github.com/EnergyModelsX/EnergyModelsHeat.jl/workflows/CI/badge.svg)](https://github.com/EnergyModelsX/EnergyModelsHeat.jl/actions?query=workflow%3ACI)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://energymodelsx.github.io/EnergyModelsHeat.jl/stable/)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://energymodelsx.github.io/EnergyModelsHeat.jl/dev/)

`EnergyModelsHeat` extends `EnergyModelsBase` with functionality to model heat flows, heat pumps, thermal energy storage, and district heating networks with higher accuracy.
This includes as well an approach for the calculation of the potential for utilizing surplus heat from processes in the district heating network.

## Usage

The usage of the package is best illustrated through the commented [`examples`](examples).
The examples are minimum working examples highlighting how to build simple energy system models.

## Cite

If you find `EnergyModelsHeat` useful in your work, we kindly request that you cite the following [publication](https://doi.org/10.21105/joss.06619):

```bibtex
@article{hellemo2024energymodelsx,
  title = {EnergyModelsX: Flexible Energy Systems Modelling with Multiple Dispatch},
  author = {Hellemo, Lars and B{\o}dal, Espen Flo and Holm, Sigmund Eggen and Pinel, Dimitri and Straus, Julian},
  journal = {Journal of Open Source Software},
  volume = {9},
  number = {97},
  pages = {6619},
  year = {2024},
  doi = {https://doi.org/10.21105/joss.06619},
}
```

## Project Funding

The development of `EnergyModelsHeat` was funded by the Norwegian Research Council in the project [ZEESA](https://www.sintef.no/en/projects/2023/zeesa-zero-emission-energy-systems-for-the-arctic/), project number [336342](https://prosjektbanken.forskningsradet.no/project/FORISS/336342), as well as the European Union’s Horizon Europe research and innovation programme in the project [iDesignRES](https://idesignres.eu/) under grant agreement [101095849](https://doi.org/10.3030/101095849).
