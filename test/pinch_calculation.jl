@testitem "Pinch calculation" begin
    using TimeStruct
    const EMH = EnergyModelsHeat

    # Same T intervals in both circuits
    @test EMH.ψ(80, 60, 20, 80, 60) ≈ 0.0
    @test EMH.ψ(80, 60, 10, 80, 60) ≈ 0.0
    @test EMH.ψ(80, 60, 0, 80, 60) ≈ 1.0

    # Higher T in surplus heat source
    @test EMH.ψ(90, 60, 40, 80, 60) ≈ 0.0
    @test EMH.ψ(90, 60, 30, 80, 60) ≈ 0.0
    @test EMH.ψ(90, 60, 20, 80, 60) ≈ 0.0
    @test EMH.ψ(90, 60, 10, 80, 60) ≈ 0.0
    @test EMH.ψ(90, 60,  0, 80, 60) ≈ 2/3
    @test EMH.ψ(90, 70, 10, 80, 60) ≈ 1.0
    @test EMH.ψ(100, 70, 10, 80, 60) ≈ 2/3 # Equal mass flow -> loss
    @test EMH.ψ2(100, 70, 10, 80, 60) ≈ 1  # Adjusting mass flow to recover energy

    # Lower cold T in surplus heat source
    @test EMH.ψ(90, 50, 10, 80, 60) ≈ 0.0
    @test EMH.ψ2(90, 50, 10, 80, 60) ≈ 0.5
    
    # Lower cold T in district heating circuit
    @test EMH.ψ(90, 60, 10, 80, 50) ≈ 1
    @test EMH.ψ2(90, 60, 10, 80, 50) ≈ 1
    @test EMH.ψ(80, 60, 0, 80, 50) ≈ 0.0
    @test EMH.ψ2(80, 60, 0, 80, 50) ≈ 1.0 # TODO: Check this

    # Higher T in district heating supply temperature (needs upgrade)
    @test EMH.ψ(70, 50, 10, 80, 50) ≈ 0
    @test EMH.ψ(60, 40, 10, 80, 50) ≈ 0

    # Test with PinchData and TimeStruct
    pd = EMH.PinchData(
        FixedProfile(100),   
        FixedProfile(70),
        FixedProfile(10),    
        FixedProfile(80),    
        FixedProfile(60),    
    )
    T = SimpleTimes(1, 1)
    for t ∈ T
        @test EMH.ψ(pd, t) ≈ 2/3
    end
end

@testitem "Upgrade calculation" begin
    const EMH = EnergyModelsHeat

    # Circuits at same intervals:
    @test EMH.upgrade(70, 60, 0, 70, 60) ≈ 0.0
    @test EMH.upgrade2(70, 60, 0, 70, 60) ≈ 0.0
    @test EMH.upgrade(70, 60, 10, 70, 60) ≈ 0.0
    @test EMH.upgrade2(70, 60, 10, 70, 60) ≈ 1.0
    @test EMH.upgrade(70, 60, 20, 70, 60) ≈ 0.0 
    @test EMH.upgrade2(70, 60, 20, 70, 60) ≈ 2.0 # TODO: Check if this makes sense?

    @test EMH.upgrade(70, 40, 0, 70, 40) ≈ 0.0
    @test EMH.upgrade2(70, 40, 0, 70, 40) ≈ 0.0
    @test EMH.upgrade(70, 40, 10, 70, 40) ≈ 0.0
    @test EMH.upgrade2(70, 40, 10, 70, 40) ≈ 1 / 3

    # Lower cold T at surplus heat source (40 < 50)
    @test EMH.upgrade(70, 40, 10, 70, 50) ≈ 0.0
    @test EMH.upgrade2(70, 40, 10, 70, 50) ≈ 0.5
    # Lower cold T at district heating (40 < 50)
    @test EMH.upgrade(70, 50, 10, 70, 40) ≈ 0.0
    @test EMH.upgrade2(70, 50, 10, 70, 40) ≈ 0.0

    # No need for upgrade when heat source less ΔT ≥ DH supply T
    @test EMH.upgrade(90, 40, 5, 70, 60) ≈ 0
    @test EMH.upgrade2(90, 40, 5, 70, 60) ≈ -1.5 # TODO: Should be 0.0? (max(upgrade,0))?
    # T_COLD < (T_cold + ΔT_min) : 40 < 50 + 5
    @test EMH.upgrade(60, 40, 5, 70, 50) ≈ 0.0
    @test EMH.upgrade2(60, 40, 5, 70, 50) ≈ 0.75
    # T_COLD == (T_cold + ΔT_min) : 55 == 50 + 5
    @test EMH.upgrade(60, 55, 5, 70, 50) ≈ 0.0
    @test EMH.upgrade2(60, 55, 5, 70, 50) ≈ 0.0
    # T_COLD > (T_cold + ΔT_min) : 
    @test EMH.upgrade(60, 56, 5, 70, 50) ≈ 0.0
    @test EMH.upgrade2(60, 56, 5, 70, 50) ≈ 0.0
end
