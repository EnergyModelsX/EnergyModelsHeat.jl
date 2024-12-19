
void feedstock_characterization(vector<flow> &feedstock, object &plant){

	feedstock.push_back( flow("feed", plant.sp("fuel_def") ) );

	feedstock[0].F.Hf = plant.fp("boiler_power_in_MW");
	feedstock[0].F.T = 25.0; 
	feedstock[0].F.P = 1.01325; 
	feedstock[0].F.M = feedstock[0].F.Hf / feedstock[0].P.LHV;

	plant.fval_p("M_fuel", feedstock[0].F.M);
	plant.fval_p("Hf_fuel", feedstock[0].F.Hf);

	plant.c.push_back(object("consumable",feedstock[0].def,"Database/Consumables_database"));
 	int feed = plant.ic("consumable",feedstock[0].def);
 	plant.c[feed].fval_p("Q_annual", plant.fp("M_fuel") * 3.6 * 8000);
	material_cost(plant.c[feed]);

}

void bioCHP_plant_model(object &bioCHP){		

	cout << "************************* " << endl;
	cout << "bioCHP PLANT: " << endl;
	cout << "************************* " << endl;

	object boiler("system", "solid_fuel_boiler", "bioCHP_inputs"); 
	object rankine("process", "Rankine_cycle", "bioCHP_inputs"); 
	object scrubber("process", "flue_gas_cleaning", "bioCHP_inputs"); 

	vector<flow> feed; feedstock_characterization(feed, bioCHP);

	flow flue_gas, bottom_ash, fly_ash, dh_in, dh_out;
	boiler.fval_p("M_fuel", bioCHP.fp("M_fuel"));

	solid_fuel_boiler(feed, flue_gas, bottom_ash, fly_ash, boiler);

	rankine.fval_p("P_stm", bioCHP.fp("P_stm"));
	rankine.fval_p("T_stm", bioCHP.fp("T_stm"));
	rankine.fval_p("Q_stm", boiler.fp("Q_out"));
	rankine.fval_p("Q_dh", bioCHP.fp("heat_demand_MW"));
	//rankine.fval_p("Q_dh", boiler.fp("Q_out")*bioCHP.fp("heat_power_ratio"));

	rankine_cycle(rankine);
	//NOx_reduction_model(comb_fg, denox_fg, cons, par);
	scrubber.fval_p("M_fuel", bioCHP.fp("M_fuel"));
	dry_scrubber_model(flue_gas, flue_gas, scrubber);

	bioCHP.c.push_back(boiler);
	bioCHP.c.push_back(rankine);
	bioCHP.c.push_back(scrubber);

	bioCHP.fval_p("output-Biomass_mass_input_(t/h)", bioCHP.fp("M_fuel")*3.6);
	bioCHP.fval_p("output-Biomass_energy_input_(MW)", bioCHP.fp("Hf_fuel"));
	bioCHP.fval_p("output-Heat_production_(MW)", bioCHP.fp("heat_demand_MW"));
	bioCHP.fval_p("output-Electricity_production_(MW)", rankine.fp("W_el"));

	cost(bioCHP);

}


