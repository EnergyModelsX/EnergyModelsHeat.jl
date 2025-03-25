void get_feedstock(vector<flow> &f, object &plant){

	double LHV = 0.0;for(int nf = 0; nf < plant.svct("fuel_def").size(); nf++){
		f.push_back( flow("feed", plant.svct("fuel_def")[nf] ) );
		f[nf].F.T = 25.0; 
		f[nf].F.P = 1.01325;
		LHV += f[nf].P.LHV * plant.vctp("Yj")[nf];
	}

	plant.fval_p("LHV_f", LHV);

}

void bioCHP_plant_model(object &bioCHP){		

	cout << "************************* " << endl;
	cout << "bioCHP PLANT: " << endl;
	cout << "************************* " << endl;

	object boiler("system", "solid_fuel_boiler", "bioCHP_inputs"); 
	object rankine("process", "Rankine_cycle", "bioCHP_inputs"); 
	object scrubber("process", "flue_gas_cleaning", "bioCHP_inputs"); 

	vector<flow> feed; get_feedstock(feed, bioCHP);

	flow flue_gas, bottom_ash, fly_ash, dh_in, dh_out; vector<flow> comb_air;


	rankine.fval_p("P_stm", bioCHP.fp("P_stm"));
	rankine.fval_p("T_stm", bioCHP.fp("T_stm"));
	rankine.vct_fp("Qk", bioCHP.vctp("Qk"));
	rankine.vct_fp("Tk_in", bioCHP.vctp("Tk_in"));
	rankine.vct_fp("Tk_out", bioCHP.vctp("Tk_out"));

	if( bioCHP.bp("W_el") ){

		cout << "bioCHP PLANT calculation using W_el: " << endl;

		double Hf = bioCHP.fp("W_el")/0.2; for(int nk = 0; nk < bioCHP.vctp("Qk").size(); nk++){ Hf += bioCHP.vctp("Qk")[nk];  } Hf = Hf/0.9;

		double ratio = 0.0;

		double Mf = Hf/bioCHP.fp("LHV_f");

		cout << "initial Hf: " << Hf << endl;
		cout << "initial Mf: " << Mf << endl;

		for(int nf = 0; nf < feed.size(); nf++){
			feed[nf].F.M = bioCHP.vctp("Yj")[nf] * Mf;		
			feed[nf].F.Hf = feed[nf].F.M * feed[nf].P.LHV;		
		}
		
		object r = rankine;
		object b = boiler; 

		solid_fuel_boiler(feed, comb_air, flue_gas, bottom_ash, fly_ash, b);
		r.fval_p("Q_stm", b.fp("Q_out"));
		rankine_cycle(r);
		Hf = Hf * bioCHP.fp("W_el")/r.fp("W_el"); 

		cout << "Final Hf: " << Hf << endl;

		bioCHP.fval_p("Hf", Hf);

	}


	bioCHP.fval_p("M_fuel", bioCHP.fp("Hf")/bioCHP.fp("LHV_f"));

	for(int nf = 0; nf < feed.size(); nf++){
		feed[nf].F.M = bioCHP.vctp("Yj")[nf] * bioCHP.fp("M_fuel");		
		feed[nf].F.Hf = feed[nf].F.M * feed[nf].P.LHV;		
	}

	boiler.fval_p("M_fuel", bioCHP.fp("M_fuel"));

	solid_fuel_boiler(feed, comb_air, flue_gas, bottom_ash, fly_ash, boiler);

	rankine.fval_p("Q_stm", boiler.fp("Q_out"));

	rankine_cycle(rankine);

	scrubber.fval_p("M_fuel", bioCHP.fp("M_fuel"));

	dry_scrubber_model(flue_gas, flue_gas, scrubber);

	bioCHP.c.push_back(boiler);
	bioCHP.c.push_back(rankine);
	bioCHP.c.push_back(scrubber);

	for(int nf = 0; nf < feed.size(); nf++){
		bioCHP.fval_p("output-Mj", feed[nf].F.M);
		bioCHP.fval_p("output-Hfj", feed[nf].F.Hf);
		bioCHP.c.push_back(object("consumable",feed[nf].def,"Database/Consumables_database"));
 		int f = bioCHP.ic("consumable",feed[nf].def);
 		bioCHP.c[f].fval_p("Q_annual", feed[nf].F.M * 3.6 * 8000);
		material_cost(bioCHP.c[f]);

	}

	bioCHP.fval_p("output-Biomass_mass_input_(t/h)", bioCHP.fp("M_fuel")*3.6);
	bioCHP.fval_p("output-Biomass_energy_input_(MW)", bioCHP.fp("Hf"));
	bioCHP.fval_p("output-Heat_production_(MW)", bioCHP.fp("heat_demand_MW"));
	bioCHP.fval_p("output-Electricity_production_(MW)", rankine.fp("W_el"));

	cost(bioCHP);

}
