using Documenter, DocumenterCitations, DocumenterInterLinks, DocumenterMermaid

using TimeStruct
using EnergyModelsBase
using EnergyModelsHeat

DocMeta.setdocmeta!(
    EnergyModelsHeat,
    :DocTestSetup,
    :(using EnergyModelsHeat);
    recursive = true,
)

# Copy the NEWS.md file
news = "docs/src/manual/NEWS.md"
cp("NEWS.md", news; force=true)

links = InterLinks(
    "TimeStruct" => "https://sintefore.github.io/TimeStruct.jl/stable/",
    "EnergyModelsBase" => "https://energymodelsx.github.io/EnergyModelsBase.jl/stable/",
)

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"))

Documenter.makedocs(
    sitename = "EnergyModelsHeat",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        assets = String[],
    ),
    modules = [EnergyModelsHeat],
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Quick Start" => "manual/quick-start.md",
            "Examples" => "manual/simple-example.md",
            "Release notes" => "manual/NEWS.md",
        ],
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
            "Contribute to EnergyModelsHeat" => "howto/contribute.md",
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
        "Background" => [
            "Heat exchanger" => "background/background.md",
            "Bio CHP" => "background/bio_chp.md",
        ],
    ],
    plugins = [links, bib],
)

deploydocs(;
    repo = "github.com/EnergyModelsX/EnergyModelsHeat.jl.git",
)
