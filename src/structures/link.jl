
using Pkg
# Activate the local environment including EnergyModelsInvestments, HiGHS, PrettyTables
Pkg.activate(@__DIR__)
# Install the dependencies.
Pkg.instantiate()

# Import the required packages
using EnergyModelsBase
using EnergyModelsInvestments
using HiGHS
using JuMP
using PrettyTables
using TimeStruct
using EnergyModelsGUI
using EnergyModelsRenewableProducers

const EMB = EnergyModelsBase
const EMI = EnergyModelsInvestments
const TS = TimeStruct

""" `Direct <: Link`

A direct link between two nodes.

# Fields
- **`id`** is the name/identifier of the link.
- **`from::Node`** is the node from which there is flow into the link.
- **`to::Node`** is the node to which there is flow out of the link.
- **`formulation::Formulation`** is the used formulation of links. If not specified, a
  `Linear` link is assumed.
"""
# Kan også ha en felt som ressurs
struct DHPipe <: EnergyModelsBase.Direct
    id::Any
    from::Node
    to::Node
    length::Float64
    heatlossfactor::Float64
    t_ground::Float64 # kan også bruke \theta (tab), kan også være tidsprofil
    resource_heat::ResourceHeat
    formulation::Formulation
end


DHPipe(id::Any, from::Node, to::Node, length::Float64, heatlossfactor::Float64, t_ground::Float64) = DHPipe(id, from, to, length, heatlossfactor, t_ground, Linear())

"""
    create_link(m, 𝒯, 𝒫, l, formulation::Formulation)

Set the constraints for a simple `Link` (input = output). Can serve as fallback option for
all unspecified subtypes of `Link`.
"""
pipelength(l::DHPipe) = l.length
heatlossfactor(l::DHPipe) = l.heatlossfactor
t_ground(l::DHPipe) = l.t_ground
res_heat(l::DHPipe) = l.resource_heat
t_supply(l::DHPipe) = t_supply(res_heat(l))

function EMB.create_link(m, 𝒯, 𝒫, l::DHPipe, formulation::Formulation)

    # Generic link in which each output corresponds to the input
    @constraint(m, [t ∈ 𝒯, p ∈ link_res(l)],
        m[:link_out][l, t, p] == m[:link_in][l, t, p]
        #m[:link_out][l, t, p] == m[:link_in][l, t, p]*HEATLOSSFACTOR
    )
end