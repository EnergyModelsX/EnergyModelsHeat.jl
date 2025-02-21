
struct steam_turbine_parameters
{
 public:
 string id;
 double Mi, Pi, Ti, Po, mu_isent, W;
 vector<double> Pext, Mext;  
 void assign_parameter_values(string, string, vector<parameter>&);
};

void steam_turbine_parameters::assign_parameter_values(string sys_type, string sys_def, vector<parameter> &par){

 	Po = atof(get_parameter_value(par, sys_type, sys_def, "Po").c_str());
 	mu_isent = atof(get_parameter_value(par, sys_type, sys_def, "mu_isent").c_str());
}


void steam_turbine(flow &in, flow &out, steam_turbine_parameters &ST){

	cout << "---------------------- " << endl;
	cout << "steam turbine stage: " << endl;
	cout << "---------------------- " << endl;

  	ST.Mi = in.F.M; ST.Ti = in.F.T; ST.Pi = in.F.P; 
 	//in.calculate_refprop("PT");
 	in.calculate_flow_properties("PT");

	double eff_el = 0.9;

 	double s_out, s_in = sPTSupSteam(ST.Pi, ST.Ti);
 	double hs_out, h_out, h_calc, h_in = hPTSupSteam(ST.Pi, ST.Ti);

 	double T_out, Ts_out = TSatWater(ST.Po); // initial guess
 	double ys_moisture = 0.0, y_moisture;  // Initial Guess
 	double s_out_initial = sPTSupSteam(ST.Po, Ts_out);

 	if (s_out_initial < s_in) {
   		s_out = s_out_initial;
   		while (s_out < s_in) {
   			Ts_out += 0.01;
   			s_out = sPTSupSteam(ST.Po, Ts_out);
   		}
  		hs_out = hPTSupSteam(ST.Po, Ts_out);
  		h_out = h_in + ST.mu_isent * (hPTSupSteam(ST.Po, Ts_out) - h_in);
 	}

 	if (s_out_initial > s_in) {
  		s_out = s_out_initial;
  		while (s_out > s_in) {
   			ys_moisture += 0.001;
   			s_out = ys_moisture * sPWater(ST.Po) + (1.0 - ys_moisture) * sPSatSteam(ST.Po);
  		}
 		hs_out = ys_moisture * hPWater(ST.Po) + (1.0 - ys_moisture) * hPSatSteam(ST.Po);
 		h_out = h_in + ST.mu_isent * (hs_out - h_in);
 	}


 	if ( h_out > hPSatSteam(ST.Po) ) {
  		y_moisture = 0;
  		T_out = Ts_out;
  		h_calc = hPSatSteam(ST.Po);
  		while (h_calc < h_out) {
  			T_out += 0.001;
  			h_calc = hPTSupSteam(ST.Po, T_out);
  		}
 	}

 	if ( h_out < hPSatSteam(ST.Po) ) {
  		y_moisture = ys_moisture;
  		T_out = Ts_out;
  		h_calc = hs_out;
  		while (h_calc < h_out) {
   	 		y_moisture = y_moisture - 0.001;
    			h_calc = y_moisture * hPWater(ST.Po) + (1.0 - y_moisture) * hPSatSteam(ST.Po);
  		}
 	}

 	in.F.Ht = in.F.M * 1e3 * h_in;

 	out.F.M = in.F.M;
 	out.F.T = T_out;
 	out.F.P = ST.Po;
 	out.P.h = h_calc;
 	out.P.ht = out.P.h;
 	out.F.Ht = out.F.M * 1e3 * h_calc;

 	ST.W = eff_el * in.F.M * 1e3 * (h_in-h_calc);  

 	cout << "Parameter:" << '\t' << "in" << '\t' << "out" << endl;
 	cout << "P (bar-a)"  << '\t' << ST.Pi << '\t' << ST.Po << endl;
 	cout << "T (deg-C)"  << '\t' << ST.Ti << '\t' << Ts_out << endl;
 	cout << "hs (kJ/kg)"  << '\t' << h_in << '\t' << hs_out << endl;
 	cout << "h (kJ/kg)"  << '\t' << h_in << '\t' << h_out << endl;
 	cout << "s (kJ/kg K)"  << '\t' << s_in << '\t' << s_out << endl;
 	cout << "q (kg/kg)"  << '\t' << "0.0" << '\t' << ys_moisture << endl;
 	cout << "W_el (MW): " << 1e-6 * ST.W << endl;
	cout << "---------------------- " << endl;

}


void steam_turbine_model(flow &in, flow &out, object &par){

	cout << "-------------------------- " << endl;
	cout << "steam turbine with bleeds: " << endl;
	cout << "-------------------------- " << endl;

	steam_turbine_parameters ST; ST.assign_parameter_values("process", "Rankine_cycle", par.p);

 	flow out_n("water"); 

	int N_bleed = par.vctp("P_bleed").size();
	
 	cout << "No. bleeds: " << par.vctp("P_bleed").size() << endl;
 
 	double W = 0;

 	if (N_bleed == 0){ steam_turbine(in, out, ST);}

 	if (N_bleed > 0){
		steam_turbine_parameters ST_n;	
		for (int n = 0; n < N_bleed+1; n++){
			if(n == 0){
				ST_n.Ti = in.F.T; ST_n.Pi = in.F.P; ST_n.Po = par.vctp("P_bleed")[n]; ST_n.mu_isent = ST.mu_isent;
				steam_turbine(in, out_n, ST_n);
				out_n.F.M = out_n.F.M - par.vctp("M_bleed")[n]; 
			}

			if(N_bleed > 1 and n > 0 and n < N_bleed){
				ST_n.Ti = out_n.F.T; ST_n.Pi = out_n.F.P; ST_n.Po = par.vctp("P_bleed")[n]; ST_n.mu_isent = ST.mu_isent;
				steam_turbine(out_n, out_n, ST_n);
				out_n.F.M = out_n.F.M - par.vctp("M_bleed")[n]; 
			}

			if(n == N_bleed){
				ST_n.Ti = out_n.F.T; ST_n.Pi = out_n.F.P; ST_n.Po = ST.Po; ST_n.mu_isent = ST.mu_isent;
				steam_turbine(out_n, out, ST_n);
			}
			W = W + ST_n.W;
		}

		par.fval_p("W_el",1e-6 * W);

		cout << "-------------------------- " << endl;
 		cout << "Steam turbine power output: (MW): " << 1e-6 * W << endl;
 	}
}

void steam_condenser(flow &steam, flow &cond, object &par){

	cout << "---------------------- " << endl;
	cout << "Steam condenser: " << endl;
	cout << "---------------------- " << endl;

	cond = flow("cond", "water");	
	cond.F.T = par.fp("T_cond");
	cond.F.P = par.fp("P_cond");
	cond.F.M = steam.F.M;

	//steam.calculate_flow("PT");
	steam.P.h = hPTSupSteam(steam.F.P, steam.F.T);
	//cond.calculate_flow("PT");
	cond.P.h = hTWater(cond.F.T);
	double Q_cond = steam.F.M * (steam.P.h - cond.P.h);

 	cout << "Parameter:" << '\t' << "in" << '\t' << "out" << endl;
 	cout << "P (bar-a)"  << '\t' << steam.F.P << '\t' << cond.F.P << endl;
 	cout << "T (deg-C)"  << '\t' << steam.F.T << '\t' << cond.F.T << endl;
 	cout << "h (J/kg)"  << '\t' << steam.P.h << '\t' << cond.P.h << endl;

	cout << "Steam condenser duty (MW): " << Q_cond * 1e-6 << endl;
	
	par.fval_p("Q_cond", Q_cond * 1e-6);


 }
 
 void district_heating(flow &dh_in, flow &dh_out, object &par){

	cout << "---------------------- " << endl;
	cout << "District heating: " << endl;
	cout << "---------------------- " << endl;


	vector<double> P_bleed, M_bleed; 

	dh_in = flow("dh_in", "water"); dh_out = flow("dh_out", "water"); 

	for(int nk = 0; nk < par.vctp("Qk").size(); nk++){

		dh_in.F.T = par.vctp("Tk_in")[nk]; dh_in.F.P = 1.01325; dh_in.P.h = hTWater(dh_in.F.T); //h_in.calculate_flow_properties("PT");
		dh_out.F.T = par.vctp("Tk_out")[nk]; dh_out.F.P = 1.01325; dh_out.P.h = hTWater(dh_out.F.T); //dh_out.calculate_flow_properties("PT");

		dh_in.F.M = par.vctp("Qk")[nk] / (dh_out.P.h - dh_in.P.h);
		dh_out.F.M = dh_in.F.M;

		flow hf_in, hf_out; // In / out heating fluid to for exporting heat to district heating
		hf_in = flow("hf_in", "water"); hf_out = flow("hf_out", "water");
		hf_in.F.T = dh_out.F.T + 25.0; hf_in.F.P = PSatWater(hf_in.F.T); double Tsat_hf_in = TSatWater(hf_in.F.P); hf_in.P.h = hPSatSteam(hf_in.F.P);
		hf_out.F.T = Tsat_hf_in - 5.0; hf_out.F.P = hf_in.F.P; hf_out.P.h = hTWater(hf_out.F.T); 

		hf_in.F.M = 1e3*par.vctp("Qk")[nk] / (hf_in.P.h - hf_out.P.h);
		hf_out.F.M = hf_in.F.M;
	
 		cout << "Heating fluid:" << '\t' << "in" << '\t' << "out" << endl;
 		cout << "M (kg/s)"  << '\t' << hf_in.F.M << '\t' << hf_out.F.M << endl;
 		cout << "P (bar-a)"  << '\t' << hf_in.F.P << '\t' << hf_out.F.P << endl;
 		cout << "T (deg-C)"  << '\t' << hf_in.F.T << '\t' << hf_out.F.T << endl;
 		cout << "h (kJ/kg)"  << '\t' << hf_in.P.h << '\t' << hf_out.P.h << endl;

		cout << "Qk (MW): " << par.vctp("Qk")[nk] << endl;
		cout << "DH HX duty (MW): " << hf_in.F.M * (hf_in.P.h - hf_out.P.h) * 1e-3 << endl;
	
		P_bleed.push_back(hf_in.F.P); M_bleed.push_back(hf_in.F.M);
	}
	par.vct_fp("P_bleed", P_bleed);
	par.vct_fp("M_bleed", M_bleed);

 }

void rankine_cycle(object &par){

	cout << "---------------------------------------------------- " << endl;
	cout << " Rankine cycle with heat output to district heating: " << endl;
	cout << "---------------------------------------------------- " << endl;

	flow bfw, sat_cond, sat_stm, steam, steam_out, cond, dh_in, dh_out;
	bfw = flow("bfw", "water"); bfw.F.T = 105.0; bfw.F.P = par.fp("P_stm"); bfw.P.h = hTWater(bfw.F.T); bfw.P.Tsat = TSatWater(bfw.F.P); double Tsat = bfw.P.Tsat;
	sat_cond = flow("sat_cond", "water"); sat_cond.F.T = Tsat-5.0; sat_cond.F.P = par.fp("P_stm"); sat_cond.calculate_flow_properties("PT");
	sat_stm = flow("sat_stm", "water"); sat_stm.F.P = par.fp("P_stm"); sat_stm.F.T = Tsat+5.0; sat_stm.calculate_flow_properties("PT");

	steam = flow("steam", "water"); steam.F.P = par.fp("P_stm"); steam.F.T = par.fp("T_stm"); steam.P.h = hPTSupSteam(steam.F.P,steam.F.T); 
	steam.F.M = 1e-3*par.fp("Q_stm")/(steam.P.h-bfw.P.h);
	steam_out = flow("cond", "water");
	cond = flow("cond", "water");
	
	district_heating(dh_in, dh_out, par);
	steam_turbine_model(steam, steam_out, par);
	steam_condenser(steam_out, cond, par);

	object rankine_eq("equipment","rankine_cycle");
	rankine_eq.fval_p("S", par.fp("Q_stm")*1e-6);
	equipment_cost(rankine_eq);
	par.c.push_back(rankine_eq);

	cout << "rankine_eq cost (M$): " << rankine_eq.fp("Cpi") * 1e-6 << endl;

	

}




