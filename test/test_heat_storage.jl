@testmodule TESTestData begin
    using HiGHS
    using JuMP

    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct

    # Define the different resources and their emission intensity in tCO2/MWh
    power    = ResourceCarrier("Power", 0.0)
    heat_use = ResourceCarrier("Heat_usable", 0.0)
    co2      = ResourceEmit("CO₂", 1.0)

    function tes_test_case(;
        type = ThermalEnergyStorage,
        level_cap = FixedProfile(20),
        level_opex = FixedProfile(0.8),
        charge_cap = FixedProfile(10),
        charge_opex = FixedProfile(0.5),
        discharge_cap = FixedProfile(5),
        discharge_opex = FixedProfile(0.2),
        stor_res = heat_use,
        heat_loss_factor = 0.05,
        input = Dict(heat_use => 1),
        output = Dict(heat_use => 1),
        level_charge = 0.125,
        level_discharge = 0.25,
        c_rate_points_charge = [[2.0, 10.0], [10.0, 7.0], [18.0, 4.0]],
        c_rate_points_discharge = [[18.0, 5.0], [10.0, 3.0], [2.0, 1.0]],
        supply_cap = FixedProfile(0.7),
        oper = SimpleTimes(4, 2),
    )
        # Creation of the products vector
        𝒫 = [power, heat_use, co2]

        # Creation of the time structure and global data
        𝒯 = TwoLevel(2, 1, oper; op_per_strat = 8)
        modeltype = OperationalModel(
            Dict(co2 => FixedProfile(10)),
            Dict(co2 => FixedProfile(0)),
            co2,
        )

        if type <: ThermalEnergyStorage
            tes = type(
                "TES",
                StorCapOpexFixed(charge_cap, charge_opex),
                StorCapOpexFixed(level_cap, level_opex),
                StorCapOpexFixed(discharge_cap, discharge_opex),
                stor_res,
                heat_loss_factor,
                input,
                output,
            )
        elseif type <: BoundRateTES
            tes = type(
                "TES",
                StorCapOpexFixed(level_cap, level_opex),
                stor_res,
                heat_loss_factor,
                level_charge,
                level_discharge,
                input,
                output,
            )
        elseif type <: LevelDependentRateTES
            tes = type(
                "TES",
                StorCap(charge_cap),
                StorCap(level_cap),
                StorCap(discharge_cap),
                stor_res,
                heat_loss_factor,
                c_rate_points_charge,
                c_rate_points_discharge,
                input,
                output,
            )
        end

        # Create the test nodes
        𝒩 = [
            RefSource(
                "surplus heat source",
                supply_cap,
                FixedProfile(0),
                FixedProfile(0),
                Dict(heat_use => 1),
            ),
            tes,
            RefSink(
                "heat demand",
                OperationalProfile([0.2, 0.2, 0.4, 1.6]),
                Dict(:surplus => FixedProfile(0), :deficit => FixedProfile(1e6)),
                Dict(heat_use => 1),
            ),
        ]

        # Connect all nodes with the availability node for the overall energy/mass balance
        ℒ = [
            Direct("source-TES", 𝒩[1], 𝒩[2]),
            Direct("source-demand", 𝒩[1], 𝒩[3]),
            Direct("TES-demand", 𝒩[2], 𝒩[3]),
        ]

        # Input data structure and modeltype creation
        case = Case(𝒯, 𝒫, [𝒩, ℒ])
        optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
        m = create_model(case, modeltype)
        set_optimizer(m, optimizer)
        return m, case, modeltype
    end
end

@testitem "ThermalEnergyStorage" setup = [TESTestData] begin
    using JuMP
    using EnergyModelsBase
    using TimeStruct
    const EMH = EnergyModelsHeat

    # Create the case and modeltype
    m, case, modeltype = TESTestData.tes_test_case()
    optimize!(m)

    # Extract the individual elements and resources
    tes = get_nodes(case)[2]
    heat_use = get_products(case)[2]
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    lvl = value.(m[:stor_level][tes, :])

    @testset "ThermalEnergyStorage - Utility functions" begin
        # Test the EMB extraction functions
        @test charge(tes) == StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5))
        @test level(tes) == StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8))
        @test discharge(tes) == StorCapOpexFixed(FixedProfile(5), FixedProfile(0.2))
        @test storage_resource(tes) == heat_use
        @test inputs(tes) == [heat_use]
        @test outputs(tes) == [heat_use]
        @test node_data(tes) == ExtensionData[]

        # Test the EMHEat extraction functions
        @test EMH.heat_loss_factor(tes) == 0.05
    end

    @testset "ThermalEnergyStorage - Constructor" begin
        tes_1 = ThermalEnergyStorage{CyclicRepresentative}(
            "TES",
            StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            StorOpexVar(FixedProfile(0)),
            heat_use,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        tes_2 = ThermalEnergyStorage{CyclicRepresentative}(
            "TES",
            StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            StorOpexVar(FixedProfile(0)),
            heat_use,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
        )
        tes_3 = ThermalEnergyStorage(
            "TES",
            StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            StorOpexVar(FixedProfile(0)),
            heat_use,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        tes_4 = ThermalEnergyStorage{CyclicRepresentative}(
            "TES",
            StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            heat_use,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        tes_5 = ThermalEnergyStorage{CyclicRepresentative}(
            "TES",
            StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            heat_use,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
        )
        tes_6 = ThermalEnergyStorage(
            "TES",
            StorCapOpexFixed(FixedProfile(10), FixedProfile(0.5)),
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            heat_use,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        for field ∈ fieldnames(ThermalEnergyStorage)
            @test getproperty(tes_1, field) == getproperty(tes_2, field)
            @test getproperty(tes_1, field) == getproperty(tes_3, field)
            @test getproperty(tes_1, field) == getproperty(tes_4, field)
            @test getproperty(tes_1, field) == getproperty(tes_5, field)
            @test getproperty(tes_1, field) == getproperty(tes_6, field)
        end
    end

    @testset "ThermalEnergyStorage - Constraints-level" begin
        # Test that the loss is correctly included
        # - EMB.constraints_level_iterate(m, n::AbstractThermalEnergyStor, ...)
        # Test that the level balance is correct in the first periods
        @test all(
            isapprox(
                lvl[t],
                lvl[t_prev] +
                value.(m[:stor_level_Δ_op][tes, t]) * duration(t) -
                lvl[t_prev] * EMH.heat_loss_factor(tes) * duration(t);
                atol = 1e-6) for
            t_inv ∈ 𝒯ᴵⁿᵛ for (t_prev, t) ∈ withprev(t_inv) if !isnothing(t_prev)
        )

        # Test that the level balance is correct in the subsequent periods
        @test all(
            isapprox(
                lvl[t],
                lvl[last(t_inv)] +
                value.(m[:stor_level_Δ_op][tes, t]) * duration(t) -
                lvl[last(t_inv)] * EMH.heat_loss_factor(tes) * duration(t);
                atol = 1e-6) for
            t_inv ∈ 𝒯ᴵⁿᵛ for (t_prev, t) ∈ withprev(t_inv) if isnothing(t_prev)
        )

        # Test that the total loss is correct
        heat_stored = sum(lvl[t] * duration(t) for t ∈ 𝒯)
        heat_in = sum(value.(m[:flow_in][tes, t, heat_use]) * duration(t) for t ∈ 𝒯)
        heat_out = sum(value.(m[:flow_out][tes, t, heat_use]) * duration(t) for t ∈ 𝒯)
        @test heat_stored * EMH.heat_loss_factor(tes) ≈ heat_in - heat_out
        @test heat_in - heat_out ≈ 0.83456 atol = 1e-3
    end
end

@testitem "ThermalEnergyStorage" setup = [TESTestData] begin
    using JuMP
    using EnergyModelsBase
    using TimeStruct
    const EMH = EnergyModelsHeat

    # Create the case and modeltype
    type = BoundRateTES
    level_cap = FixedProfile(2)
    supply_cap = OperationalProfile([0.4, 0.7, 1.0, 0.7])
    m, case, modeltype = TESTestData.tes_test_case(; type, level_cap)
    optimize!(m)

    # Extract the individual elements and resources
    tes = get_nodes(case)[2]
    heat_use = get_products(case)[2]
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    lvl = value.(m[:stor_level][tes, :])

    @testset "BoundRateTES - Utility functions" begin
        # Test the EMB extraction functions
        @test level(tes) == StorCapOpexFixed(FixedProfile(2), FixedProfile(0.8))
        @test storage_resource(tes) == heat_use
        @test inputs(tes) == [heat_use]
        @test outputs(tes) == [heat_use]
        @test node_data(tes) == ExtensionData[]

        # Test the EMHEat extraction functions
        @test EMH.heat_loss_factor(tes) == 0.05
        @test EMH.level_charge(tes) == 0.125
        @test EMH.level_discharge(tes) == 0.25
    end

    @testset "BoundRateTES - Constructor" begin
        tes_1 = BoundRateTES{CyclicRepresentative}(
            "TES",
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            heat_use,
            0.2,
            0.25,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        tes_2 = BoundRateTES{CyclicRepresentative}(
            "TES",
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            heat_use,
            0.2,
            0.25,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
        )
        tes_3 = BoundRateTES(
            "TES",
            StorCapOpexFixed(FixedProfile(20), FixedProfile(0.8)),
            heat_use,
            0.2,
            0.25,
            0.05,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        for field ∈ fieldnames(BoundRateTES)
            @test getproperty(tes_1, field) == getproperty(tes_2, field)
            @test getproperty(tes_1, field) == getproperty(tes_3, field)
        end
    end

    @testset "BoundRateTES - Constraints-level" begin
        # Test that the loss is correctly included
        # - EMB.constraints_level_iterate(m, n::AbstractThermalEnergyStor, ...)
        # Test that the level balance is correct in the first periods
        @test all(
            isapprox(
                lvl[t],
                lvl[t_prev] +
                value.(m[:stor_level_Δ_op][tes, t]) * duration(t) -
                lvl[t_prev] * EMH.heat_loss_factor(tes) * duration(t);
                atol = 1e-6) for
            t_inv ∈ 𝒯ᴵⁿᵛ for (t_prev, t) ∈ withprev(t_inv) if !isnothing(t_prev)
        )

        # Test that the level balance is correct in the subsequent periods
        @test all(
            isapprox(
                lvl[t],
                lvl[last(t_inv)] +
                value.(m[:stor_level_Δ_op][tes, t]) * duration(t) -
                lvl[last(t_inv)] * EMH.heat_loss_factor(tes) * duration(t);
                atol = 1e-6) for
            t_inv ∈ 𝒯ᴵⁿᵛ for (t_prev, t) ∈ withprev(t_inv) if isnothing(t_prev)
        )

        # Test that the total loss is correct
        heat_stored = sum(lvl[t] * duration(t) for t ∈ 𝒯)
        heat_in = sum(value.(m[:flow_in][tes, t, heat_use]) * duration(t) for t ∈ 𝒯)
        heat_out = sum(value.(m[:flow_out][tes, t, heat_use]) * duration(t) for t ∈ 𝒯)
        @test heat_stored * EMH.heat_loss_factor(tes) ≈ heat_in - heat_out
        @test heat_in - heat_out ≈ 0.39780 atol = 1e-3

        # Test that the capacity limits are enforced
        # - EMB.constraints_capacity(m, n::BoundRateTES, 𝒯::TimeStructure, modeltype::EnergyModel)
        @test all(lvl[t] ≤ capacity(level(tes), t) - 0.5 for t ∈ 𝒯)
        @test all(value.(m[:stor_level_inst][tes, t]) ≈ capacity(level(tes), t) for t ∈ 𝒯)

        @test all(
            value.(m[:stor_charge_use][tes, t]) ≤ capacity(level(tes), t) * 0.125 + 1e-6
            for
            t ∈ 𝒯
        )
        @test sum(value.(m[:stor_charge_use][tes, t]) ≈ 0.25 for t ∈ 𝒯) == 4

        @test all(
            value.(m[:stor_discharge_use][tes, t]) ≤ capacity(level(tes), t) * 0.25 + 1e-6
            for t ∈ 𝒯
        )
        @test sum(value.(m[:stor_discharge_use][tes, t]) ≈ 0.5 for t ∈ 𝒯) == 2
    end
end

@testitem "LevelDependentRateTES" setup = [TESTestData] begin
    using JuMP
    using EnergyModelsBase
    using TimeStruct
    const EMH = EnergyModelsHeat

    # Create the case and modeltype
    type = LevelDependentRateTES
    m, case, modeltype = TESTestData.tes_test_case(; type)
    optimize!(m)

    # Extract the individual elements and resources
    tes = get_nodes(case)[2]
    heat_use = get_products(case)[2]
    𝒯 = get_time_struct(case)
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)
    lvl = value.(m[:stor_level][tes, :])

    @testset "LevelDependentRateTES - Utility functions" begin
        # Test the EMB extraction functions
        @test charge(tes) == StorCap(FixedProfile(10))
        @test level(tes) == StorCap(FixedProfile(20))
        @test discharge(tes) == StorCap(FixedProfile(5))
        @test storage_resource(tes) == heat_use
        @test inputs(tes) == [heat_use]
        @test outputs(tes) == [heat_use]
        @test node_data(tes) == ExtensionData[]

        # Test the EMHEat extraction functions
        @test EMH.heat_loss_factor(tes) == 0.05
        @test EMH.c_rate_points_charge(tes) == [[2.0, 10.0], [10.0, 7.0], [18.0, 4.0]]
        @test EMH.c_rate_points_discharge(tes) == [[18.0, 5.0], [10.0, 3.0], [2.0, 1.0]]
    end

    @testset "LevelDependentRateTES - Constructor" begin
        c_charge = [[2.0, 10.0], [10.0, 7.0], [18.0, 4.0]]
        c_discharge = [[18.0, 5.0], [10.0, 3.0], [2.0, 1.0]]
        tes_1 = LevelDependentRateTES{CyclicRepresentative}(
            "TES",
            StorCap(FixedProfile(10)),
            StorCap(FixedProfile(20)),
            StorCap(FixedProfile(5)),
            heat_use,
            0.05,
            c_charge,
            c_discharge,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        tes_2 = LevelDependentRateTES{CyclicRepresentative}(
            "TES",
            StorCap(FixedProfile(10)),
            StorCap(FixedProfile(20)),
            StorCap(FixedProfile(5)),
            heat_use,
            0.05,
            c_charge,
            c_discharge,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
        )
        tes_3 = LevelDependentRateTES(
            "TES",
            StorCap(FixedProfile(10)),
            StorCap(FixedProfile(20)),
            StorCap(FixedProfile(5)),
            heat_use,
            0.05,
            c_charge,
            c_discharge,
            Dict(heat_use => 1),
            Dict(heat_use => 1),
            ExtensionData[],
        )
        for field ∈ fieldnames(LevelDependentRateTES)
            @test getproperty(tes_1, field) == getproperty(tes_2, field)
            @test getproperty(tes_1, field) == getproperty(tes_3, field)
        end
    end

    @testset "LevelDependentRateTES - Constraints-level" begin
        # Test that the loss is correctly included in the first periods
        @test all(
            isapprox(
                lvl[t],
                lvl[t_prev] +
                value.(m[:stor_level_Δ_op][tes, t]) * duration(t) -
                lvl[t_prev] * EMH.heat_loss_factor(tes) * duration(t);
                atol = 1e-6) for
            t_inv ∈ 𝒯ᴵⁿᵛ for (t_prev, t) ∈ withprev(t_inv) if !isnothing(t_prev)
        )

        # Test that the total loss is correct
        heat_stored = sum(lvl[t] * duration(t) for t ∈ 𝒯)
        heat_in = sum(value.(m[:flow_in][tes, t, heat_use]) * duration(t) for t ∈ 𝒯)
        heat_out = sum(value.(m[:flow_out][tes, t, heat_use]) * duration(t) for t ∈ 𝒯)
        @test heat_stored * EMH.heat_loss_factor(tes) ≈ heat_in - heat_out
    end

    @testset "LevelDependentRateTES - Constraints-capacity" begin
        # The auxiliary region-selection binaries are declared
        @test haskey(object_dictionary(m), :bin_region_charge)
        @test haskey(object_dictionary(m), :bin_region_discharge)

        # The installed capacities are respected
        @test all(value.(m[:stor_level][tes, t]) ≤ capacity(level(tes), t) + 1e-6 for t ∈ 𝒯)
        @test all(
            value.(m[:stor_charge_use][tes, t]) ≤ capacity(charge(tes), t) + 1e-6 for
            t ∈ 𝒯
        )
        @test all(
            value.(m[:stor_discharge_use][tes, t]) ≤ capacity(discharge(tes), t) + 1e-6 for
            t ∈ 𝒯
        )

        # The used charge and discharge rates never exceed the theoretical c-rate curve
        # evaluated at the storage level of the previous operational period. The curves are
        # recomputed here independently from the anchor points, so this checks that the
        # constraints reproduce the intended state-of-charge dependent limits.
        pts_c = EMH.c_rate_points_charge(tes)
        pts_d = EMH.c_rate_points_discharge(tes)

        # Maximum charge rate at level `x`: piecewise line from (0, cap) through the ascending
        # anchor points.
        function charge_curve(x, cap)
            x1, y1 = pts_c[1]
            seg1 = (y1 - cap) / x1 * x + cap
            length(pts_c) == 1 && return seg1
            x2, y2 = pts_c[2]
            seg2 = (y2 - y1) / (x2 - x1) * (x - x2) + y2
            length(pts_c) == 2 && return x ≤ x1 ? seg1 : seg2
            x3, y3 = pts_c[3]
            seg3 = (y3 - y2) / (x3 - x2) * (x - x3) + y3
            return x ≤ x1 ? seg1 : (x ≤ x2 ? seg2 : seg3)
        end

        # Maximum discharge rate at level `x`: piecewise line from (cap_level, cap) through the
        # descending anchor points.
        function discharge_curve(x, cap, cap_level)
            x1, y1 = pts_d[1]
            seg1 = (cap - y1) / (cap_level - x1) * (x - cap_level) + cap
            length(pts_d) == 1 && return seg1
            x2, y2 = pts_d[2]
            seg2 = (y1 - y2) / (x1 - x2) * (x - x2) + y2
            length(pts_d) == 2 && return x ≥ x1 ? seg1 : seg2
            x3, y3 = pts_d[3]
            seg3 = (y2 - y3) / (x2 - x3) * (x - x3) + y3
            return x ≥ x1 ? seg1 : (x ≥ x2 ? seg2 : seg3)
        end

        @test all(
            value(m[:stor_charge_use][tes, t]) ≤
            charge_curve(lvl[t_prev], capacity(charge(tes), t)) + 1e-6 for
            (t_prev, t) ∈ withprev(𝒯) if !isnothing(t_prev)
        )
        @test all(
            value(m[:stor_discharge_use][tes, t]) ≤
            discharge_curve(
                lvl[t_prev],
                capacity(discharge(tes), t),
                capacity(level(tes), t_prev),
            ) + 1e-6 for (t_prev, t) ∈ withprev(𝒯) if !isnothing(t_prev)
        )
    end
end
