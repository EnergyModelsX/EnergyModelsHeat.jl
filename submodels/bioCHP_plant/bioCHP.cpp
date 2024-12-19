#include <iostream>
#include <string.h>
#include "Parameters.h"
#include "Flows.h"
#include "Cost.h"
#include "Processes.h"


using namespace std;

int main(){

	object bioCHP("plant", "bioCHP_PLANT", "bioCHP_inputs");
	bioCHP_plant_model(bioCHP);
	export_output_parameters(bioCHP, "bioCHP_outputs");

}
