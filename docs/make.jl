using Documenter, DocumenterCitations, DocumenterInterLinks, EnergyModelsHeat

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
    "Background" => "background/background.md",
    "API reference" => "reference/api.md",
]

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"))
# TODO: Enable modules
# TODO: Enable doctests
Documenter.makedocs(
    sitename = "EnergyModelsHeat",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        assets = String[],
    ),
    doctest = false,
    # modules = [EnergyModelsHeat],
    pages = pages,
    remotes = nothing,
    plugins=[bib],
)

# Documenter.deploydocs(; repo = "github.com/sintefore/PiecewiseAffineApprox.jl.git")
