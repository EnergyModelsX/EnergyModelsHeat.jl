

struct combustion_parameters
{
 public:
string oxidant_def; double x_O2;
double T_g, T_ox, T_ext;
double P_bar;
double tR_s;
double lambda;
double steam_P, steam_T, steam_M, Q_steam;
double fash_bottom, yC_ash, T_ash;
double Hf, Q_out, q_loss, Q_loss;
};

void calculate_fuel_combustion_properties(flow fuel, object &prop)
{

 int C = index_species(fuel.i, "C");
 int H = index_species(fuel.i, "H");
 int O = index_species(fuel.i, "O");

 int H2O = index_species(fuel.k, "H2O");
 int ash = index_species(fuel.k, "ash");

 if(fuel.prop_data == "solid_fuel"){

	 	prop.fval_p("n_H",(fuel.i[H].Y/1)/(fuel.i[C].Y/12));
	 	prop.fval_p("n_O",(fuel.i[O].Y/16)/(fuel.i[C].Y/12));
	 	prop.fval_p("W_CHxOy",0.012 + prop.fp("n_H") * 0.001 + prop.fp("n_O") * 0.016);
		prop.fval_p("nu_O2", 1 + prop.fp("n_H") / 4 - prop.fp("n_O") / 2);
		prop.fval_p("nu_CO2", 1.0);
		prop.fval_p("nu_H2O", prop.fp("n_H") / 2);
		prop.fval_p("V_stoich", fuel.F.M * (1 - fuel.k[H2O].Y) * (1 - fuel.k[ash].Y) * (prop.fp("nu_O2") / 0.21) * (0.02241 / prop.fp("W_CHxOy")));
		prop.fval_p("vn_CO2_m", (1 - fuel.k[H2O].Y) * prop.fp("nu_CO2") * (0.02241 / prop.fp("W_CHxOy")));
		prop.fval_p("vn_H2O_m", (1 - fuel.k[H2O].Y) * prop.fp("nu_H2O") * (0.02241 / prop.fp("W_CHxOy")) + fuel.k[H2O].Y * (0.02241 / 0.018));

 }


 if(fuel.prop_data == "gas_fuel"){

	int CO2 = index_species(fuel.j, "CO2"); 

	if(CO2 > 0 and fuel.j[CO2].Y > 0){ 
		// gas fuel contains CO2
		double Y_CO2 = fuel.j[CO2].Y; 
		for(int nj = 0; nj < fuel.j.size(); nj++){if(fuel.j[nj].id != "CO2"){fuel.j[nj].Y = fuel.j[nj].Y / (1.0 - fuel.j[CO2].Y); }}
		fuel.j[CO2].Y = 0.0;
		fuel.molec_def = "Y"; fuel.calculate_flow_composition(); fuel.interpret_molecules();

 		prop.fval_p("n_H", (fuel.i[H].Y/1)/((fuel.i[C].Y-(Y_CO2 * 12 / 44))/12));
 		prop.fval_p("n_O", ((fuel.i[O].Y-(2*Y_CO2 * 16 / 44))/16)/((fuel.i[C].Y-(Y_CO2 * 12 / 44))/12));
		prop.fval_p("W_CHxOy", 0.012 + prop.fp("n_H") * 0.001 + prop.fp("n_O") * 0.016);
		prop.fval_p("nu_O2", 1 + prop.fp("n_H") / 4 - prop.fp("n_O") / 2);
		prop.fval_p("nu_CO2", 1.0);
		prop.fval_p("nu_H2O", prop.fp("n_H") / 2);
		prop.fval_p("V_stoich", fuel.F.M * (1.0 - Y_CO2) * (1 - fuel.k[H2O].Y) * (1 - fuel.k[ash].Y) * (prop.fp("nu_O2") / 0.21) * (0.02241 / prop.fp("W_CHxOy")));
		prop.fval_p("vn_CO2_m", (1 - fuel.k[H2O].Y) * ( (1.0 - Y_CO2) * prop.fp("nu_CO2") * (0.02241 / prop.fp("W_CHxOy")) + Y_CO2 * (0.02241 / 0.044)));
		prop.fval_p("vn_H2O_m", (1 - fuel.k[H2O].Y) * (1.0 - Y_CO2) * prop.fp("nu_H2O") * (0.02241 / prop.fp("W_CHxOy")) + Y_CO2 * (0.02241 / 0.018));

	}

	else{
		// otherwise
	
	 	prop.fval_p("n_H", (fuel.i[H].Y/1)/(fuel.i[C].Y/12));
	 	prop.fval_p("n_O", (fuel.i[O].Y/16)/(fuel.i[C].Y/12));
		prop.fval_p("W_CHxOy", 0.012 + prop.fp("n_H") * 0.001 + prop.fp("n_O") * 0.016);
		prop.fval_p("nu_O2", 1 + prop.fp("n_H") / 4 - prop.fp("n_O") / 2);
		prop.fval_p("nu_CO2", 1.0);
		prop.fval_p("nu_H2O", prop.fp("n_H") / 2);
		prop.fval_p("V_stoich", fuel.F.M * (1 - fuel.k[H2O].Y) * (1 - fuel.k[ash].Y) * (prop.fp("nu_O2") / 0.21) * (0.02241 / prop.fp("W_CHxOy")));
		prop.fval_p("vn_CO2_m", (1 - fuel.k[H2O].Y) * prop.fp("nu_CO2") * (0.02241 / prop.fp("W_CHxOy")));
		prop.fval_p("vn_H2O_m", (1 - fuel.k[H2O].Y) * prop.fp("nu_H2O") * (0.02241 / prop.fp("W_CHxOy")) + fuel.k[H2O].Y * (0.02241 / 0.018));

	}


 }



//double kf_C, kf_H, kf_O, kf_H2O;
//double h_CHxOy; // MJ/kg enthalpy combustion CHxOy

 //kf_C = 34.1; kf_H = 102.0; kf_O = -9.85; kf_H2O = -2.5;
 //h_CHxOy = (kf_C + kf_H * x_f * (1 / 12) + kf_O * y_f * (16 / 12)) / (1 + x_f * (1 / 12) + y_f * (16 / 12));

}


void solid_fuel_boiler(vector<flow> &fuel, vector<flow> &comb_air, flow &flue_gas, flow &bottom_ash, flow &fly_ash, object &comb){

  cout << "************************* " << endl;
  cout << " Solid fuel boiler " << endl; 
  cout << "************************* " << endl;

 vector<flow> air; vector<flow> fg; vector<flow> ba; vector<flow> fa;

	if(air.size() == 0){ 

    		for( int n = 0; n < fuel.size(); n++){

			air.push_back(flow(comb.sp("oxidant_def"))); 	
			fg.push_back(flow("flue_gas", "flue_gas")); 
			ba.push_back(flow("bottom_ash", "ash")); 	
			fa.push_back(flow("fly_ash", "ash")); 

		}

	}

	for( int n = 0; n < fuel.size(); n++){

        int C = index_species(fuel[n].i, "C");
        int H = index_species(fuel[n].i, "H");
        int O = index_species(fuel[n].i, "O");
        int N = index_species(fuel[n].i, "N");
        int H2O = index_species(fuel[n].k, "H2O");
        int ash = index_species(fuel[n].k, "ASH");

        int O2g = index_species(fg[n].j, "O2");
        int N2g = index_species(fg[n].j, "N2");
        int CO2g = index_species(fg[n].j, "CO2");
        int H2Og = index_species(fg[n].j, "H2O");

        // calculating fuel combustion properties

	object comb_f("fuel",fuel[n].def); calculate_fuel_combustion_properties(fuel[n], comb_f);

	double T_0 = 25.0;
        // calculating combustion air" 
 	air[n].F.VN = comb.fp("lambda") * comb_f.fp("V_stoich"); 
        air[n].F.T = comb.fp("T_ox"); 
        air[n].F.P = comb.fp("P_bar"); 
        air[n].calculate_flow("PT");

        // calculating flue gas 
	fg[n].F.T = comb.fp("T_g"); 
	fg[n].F.P = comb.fp("P_bar"); 
	fg[n].j[O2g].F.VN = (comb.fp("lambda") - 1) * comb_f.fp("V_stoich") * 0.21;
	fg[n].j[N2g].F.VN = comb.fp("lambda") * comb_f.fp("V_stoich") * 0.79;
	fg[n].j[CO2g].F.VN = fuel[n].F.M * comb_f.fp("vn_CO2_m");
	fg[n].j[H2Og].F.VN = fuel[n].F.M * comb_f.fp("vn_H2O_m");
	fg[n].F.VN = 0; for(int nj = 0; nj < fg[n].j.size(); nj++){fg[n].F.VN = fg[n].F.VN + fg[n].j[nj].F.VN;}
        for(int nj = 0; nj < fg[n].j.size(); nj++){fg[n].j[nj].X = fg[n].j[nj].F.VN / fg[n].F.VN;}
	fg[n].molec_def = "X"; 
	fg[n].calculate_flow("PT");

        // calculating ash 
 	ba[n].P.cp = 1.25; // kJ/kg*k
	comb.fval_p("fash_bottom", 0.1); comb.fval_p("yC_ash", 0.03); comb.fval_p("T_ash",1000.0);
        ba[n].F.M = fuel[n].F.M * (1.0 - fuel[n].k[H2O].Y) * (fuel[n].k[ash].Y * comb.fp("fash_bottom")); 
	ba[n].F.Ht = ba[n].F.M * (ba[n].P.cp* (comb.fp("T_ash") - 25) * 1e3 + comb.fp("yC_ash") * 34.1*1e6);
        fa[n].F.M = fuel[n].F.M * (1.0 - fuel[n].k[H2O].Y) * fuel[n].k[ash].Y * (1.0-comb.fp("fash_bottom")) ; 
	fa[n].F.Ht = fa[n].F.M * fa[n].P.cp* (comb.fp("T_ash") - 25);
 
      }

	double comb_Hf = 0; 
        for( int n = 0; n < fuel.size(); n++){
	        if ( n == 0 ) {
			if(comb_air.size() == 0){ comb_air.push_back(air[n]);} 
			flue_gas = fg[n]; bottom_ash = ba[n]; fly_ash = fa[n]; }
        	if ( n > 0 ) { 
        		comb_air[0].mix_flows(comb_air[0], air[n]); 
        		bottom_ash.mix_flows(bottom_ash, ba[n]); 
        		flue_gas.mix_flows(flue_gas, fg[n]); 
        		fly_ash.mix_flows(fly_ash, fa[n]); }

        	comb_Hf = comb_Hf + fuel[n].F.Hf;
	}

	comb.fval_p("Hf", comb_Hf);
	comb.fval_p("Q_loss", flue_gas.F.Ht * comb.fp("q_loss"));
	comb.fval_p("Q_out", comb.fp("Hf")*1e6 + comb_air[0].F.Ht - flue_gas.F.Ht - bottom_ash.F.Ht - comb.fp("Q_loss"));

	object boiler("equipment","biomass_stoker_boiler_power");
	boiler.fval_p("S", comb.fp("M_fuel")*3.6);
	equipment_cost(boiler);
	boiler.fval_p("W_el", comb.fp("M_fuel")*3.6*boiler.fp("w_el"));
	comb.c.push_back(boiler);

	object prep("equipment","biomass_storage&feeding");
	prep.fval_p("S", comb.fp("M_fuel")*3.6);
	equipment_cost(prep);
	comb.c.push_back(prep);

        cout << "-------------" << endl; 
        cout << "Mass balance" << endl; 
        cout << "------------" << endl; 
        cout << "fuel M (kg/s): " << comb.fp("M_fuel") <<  endl;
		for(int nf = 0; nf < fuel.size(); nf++){
			cout << '\t' << fuel[nf].def << " (kg/s): " << fuel[nf].F.M << endl;
		}
        cout << "flue gas M: " << flue_gas.F.M <<  endl; 
	cout << "comb air M: " << comb_air[0].F.M << endl;
	cout << "bottom ash M: " << bottom_ash.F.M << endl; 
	cout << "fly ash M: " << fly_ash.F.M << endl; 

        cout << "-------------" << endl; 
        cout << "energy balance" << endl; 
        cout << "-------------" << endl; 
        cout << "Fuel Hf (MW): " << comb.fp("Hf") <<  endl;
		for(int nf = 0; nf < fuel.size(); nf++){
			cout << '\t'<< fuel[nf].def << " (MW): " << fuel[nf].F.Hf << endl;
		}

        cout << "Q_out: (W) " << comb.fp("Q_out") << endl; 
        cout << "Q_loss: (W) " << comb.fp("Q_loss") << endl; 
        cout << "H_air: (W) " << comb_air[0].F.Ht  << endl; 
        cout << "H_fg: (W) " << flue_gas.F.Ht << endl; 
        cout << "H_ba: (W) " << bottom_ash.F.Ht << endl; 
        cout << "H_fa: (W) " << fly_ash.F.Ht << endl; 

}

