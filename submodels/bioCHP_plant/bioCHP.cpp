#include <iostream>
#include <string.h>
#include "Parameters.h"
#include "Flows.h"
#include "Cost.h"
#include "Processes.h"

bool bioCHP_plant(vector<string> fuel_def, vector<double> Yj, double W_el, vector<double> Qk, vector<double> Tk_in, vector<double> Tk_out, vector<double> &Mj, double &C_inv, double &C_op){

	// INPUTS
	// feed_def: name of each biomass feedstock
	// Yj: mass fraction of each biomass feedstock
	// W_el: electric power output (MW_el)
	// Qk: heat demand (MW)
	// Tk_in: Return temperature for each heat demand (district heating)
	// Tk_in: Supply temperature for each heat demand (district heating)

	// OUTPUTS
	// Mj: Required mass flow of each biomass feedstock
	// C_inv: Investment cost
	// C_op_var: Variable operating cost
	// C_op_fix: Variable operating cost


	// Check that all feedstock exist in the database
	for(int nf = 0; nf < fuel_def.size(); nf++){ if( !find_flow(fuel_def[nf]) ){ 

		for(int nff = 0; nff < fuel_def.size(); nff++){ Mj.push_back(0.0); }
		C_inv = 0.0;
		C_op = 0.0;
		
		return false; 

	}}	

	// Check that there is sufficient heat available from Rankine cycle
	double sum_Qk = 0.0; for(int nk = 0; nk < Qk.size(); nk++){ sum_Qk = sum_Qk + Qk[nk]; }	
	if( sum_Qk > 0.5 * (W_el / 0.2) ){
		
		cout << "there is not sufficient heat available from Rankine cycle to supply the specifiy heat demand" << endl;
		cout << "Reducing proportionally the heat demands" << endl;
		for(int nk = 0; nk < Qk.size(); nk++){ Qk[nk] = Qk[nk] * (0.5 * (W_el / 0.2)) / sum_Qk; } 
	} 

	object bioCHP("plant", "bioCHP_PLANT", "bioCHP_function_inputs");
	bioCHP.vct_sp("fuel_def", fuel_def);
	bioCHP.vct_fp("Yj", Yj);
	bioCHP.fval_p("W_el", W_el);
	bioCHP.vct_fp("Qk", Qk);
	bioCHP.vct_fp("Tk_in", Tk_in);
	bioCHP.vct_fp("Tk_out", Tk_out);

	bioCHP_plant_model(bioCHP);

	Mj = bioCHP.vctp("Mj");
	C_inv = bioCHP.fp("C_inv") * 1e-6;
	C_op = bioCHP.fp("C_op") * 1e-6;

	export_output_parameters(bioCHP, "bioCHP_outputs");

	return true;
	
}


