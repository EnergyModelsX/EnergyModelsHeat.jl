#include <iostream>
#include <string.h>
#include "Parameters.h"
#include "Flows.h"
#include "Cost.h"
#include "Processes.h"

void bioCHP_plant(vector<string> fuel_def, vector<double> Yj, double W_el, double Qk, double Tk_in, double Tk_out){

	// feed_def: name of each biomass feedstock
	// Yj: mass fraction of each biomass feedstock
	// W_el: electric power output (MW_el)
	// Qk: heat demand (MW)
	// Tk_in: Return temperature for each heat demand (district heating)
	// Tk_in: Supply temperature for each heat demand (district heating)

	object bioCHP("plant", "bioCHP_PLANT", "bioCHP_inputs");
	bioCHP.vct_sp("fuel_def", fuel_def);
	bioCHP.vct_fp("Yj", Yj);
	bioCHP.fval_p("W_el", W_el);
	bioCHP.fval_p("Qk", Qk);
	bioCHP.fval_p("Tk_in", Tk_in);
	bioCHP.fval_p("Tk_out", Tk_out);

	bioCHP_plant_model(bioCHP);
	export_output_parameters(bioCHP, "bioCHP_outputs");
	

}
