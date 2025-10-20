"""
    Legacy constructors for TES without discharge parameters.
"""
function ThermalEnergyStorage{T}(
    id,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:EMB.StorageBehavior}
    return ThermalEnergyStorage{T}(
        id,
        charge,
        level,
        StorOpexVar(FixedProfile(0)),
        stor_res,
        heat_loss_factor,
        input,
        output,
        ExtensionData[],
    )
end

function ThermalEnergyStorage{T}(
    id,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData},
) where {T<:EMB.StorageBehavior}
    return ThermalEnergyStorage{T}(
        id,
        charge,
        level,
        StorOpexVar(FixedProfile(0)),
        stor_res,
        heat_loss_factor,
        input,
        output,
        data,
    )
end

function ThermalEnergyStorage(
    id::Any,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData},
)
    return ThermalEnergyStorage{CyclicRepresentative}(
        id,
        charge,
        level,
        StorOpexVar(FixedProfile(0)),
        stor_res,
        heat_loss_factor,
        input,
        output,
        data,
    )
end
