@testitem "ResourceHeat" begin
    using EnergyModelsBase
    using TimeStruct
    const EMB = EnergyModelsBase
    const EMH = EnergyModelsHeat

    # Create the resource and a time structure
    heat = ResourceHeat("DHheat", FixedProfile(70.0), FixedProfile(0))
    co2 = ResourceEmit("CO₂", 0.0)
    𝒯 = SimpleTimes(10, 1)

    @testset "ResourceHeat - Utility functions" begin
        # Test the identification functions
        @test EMH.is_heat(heat)
        @test !EMH.is_heat(co2)

        # Test the extraction functions
        @test EMB.co2_int(heat) == 0.0
        @test EMH.t_supply(heat) == FixedProfile(70.0)
        @test all(EMH.t_supply(heat, t) == 70.0 for t ∈ 𝒯)
        @test EMH.t_return(heat) == FixedProfile(0)
        @test all(EMH.t_return(heat, t) == 0 for t ∈ 𝒯)
    end

    @testset "ResourceHeat - Constructor" begin
        heat_prof_0 = ResourceHeat("DHheat", FixedProfile(70.0))
        heat_number = ResourceHeat("DHheat", 70.0, 0)
        heat_number_0 = ResourceHeat("DHheat", 70.0)
        for field ∈ fieldnames(ResourceHeat)
            @test getproperty(heat, field) == getproperty(heat_prof_0, field)
            @test getproperty(heat, field) == getproperty(heat_number, field)
            @test getproperty(heat, field) == getproperty(heat_number_0, field)
        end
    end
end
