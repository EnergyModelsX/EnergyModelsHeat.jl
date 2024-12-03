using Documenter, DocumenterCitations, DocumenterInterLinks

using TimeStruct
using EnergyModelsBase
using EnergyModelsHeat

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
)

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"))
# TODO: Enable modules
# TODO: Enable doctests

Documenter.makedocs(
    sitename = "EnergyModelsHeat",
    repo="https://gitlab.sintef.no/zeesa-wp3/EnergyModelsHeat.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical="https://zeesa-wp3.pages.sintef.no/EnergyModelsHeat.jl",
        edit_link = "main",
        assets = String[],
    ),
    modules = [EnergyModelsHeat],
    pages = [
        "Introduction" => "index.md",
        "Resources" => [
            "ResourceHeat" => "resources/resourceheat.md",
        ],
        "Links" => [
            "DHPipe" => "links/dhpipe.md",
        ],
        "Nodes" => [
            "HeatPump" => "nodes/heatpump.md",
            "ThermalEnergyStorage" => "nodes/thermalenergystorage.md",
            "HeatExchanger" => "nodes/heatexchanger.md",
        ],
        "How to" => [
            "Use surplus heat for DH" => "howto/simple_conversion.md",
        ],
        "Library" => [
            "Public" => "library/public.md",
            "Internals" => [
                "library/internals/types-EMH.md",
                "library/internals/methods-fields.md",
                "library/internals/methods-EMH.md",
                "library/internals/methods-EMB.md",
            ],
        ],
        "Background" => "background/background.md",
    ],
    plugins = [links, bib],
)

# Documenter.deploydocs(; repo = "github.com/sintefore/PiecewiseAffineApprox.jl.git")
