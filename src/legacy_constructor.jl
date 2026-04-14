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
    @warn(
        "The used implementation of a `ThermalEnergyStorage` will be discontinued in the near future. " *
        "See the documentation for the new implementation including a discharge capacity.\n" *
        "In practice, one has have to be incorporated:\n" *
        "You must add an `AbstractStorageParameters` after the `level` parameters.\n" *
        "It is recommended to update the existing implementation to the new version.",
        maxlog = 1
    )
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
    @warn(
        "The used implementation of a `ThermalEnergyStorage` will be discontinued in the near future. " *
        "See the documentation for the new implementation including a discharge capacity.\n" *
        "In practice, one has have to be incorporated:\n" *
        "You must add an `AbstractStorageParameters` after the `level` parameters.\n" *
        "It is recommended to update the existing implementation to the new version.",
        maxlog = 1
    )
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
    @warn(
        "The used implementation of a `ThermalEnergyStorage` will be discontinued in the near future. " *
        "See the documentation for the new implementation including a discharge capacity.\n" *
        "In practice, one has have to be incorporated:\n" *
        "You must add an `AbstractStorageParameters` after the `level` parameters.\n" *
        "It is recommended to update the existing implementation to the new version.",
        maxlog = 1
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
