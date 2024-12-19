#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <boost/algorithm/string.hpp>
#include <string.h>
#include <vector> 
#include <math.h>

//#include "thermodata.h"
//#include "conversion.h"

using namespace std;

//declarations:
double Antoine(thermo_data model, double T, double P, string unit);
double Majer1985(thermo_data model, double T, double P, string unit);
double PPDS12(thermo_data model, double T, double P, string unit);
double DIPPR107(thermo_data model, double T, double P, string unit);
double TDEliquid(thermo_data model, double T, double P, string unit);
double Shomate(thermo_data model, double T, double P, string unit);
double Constant(thermo_data model, double T, double P, string unit);
double Wagner25(thermo_data model, double T, double P, string unit);
double TDEWatson(thermo_data model, double T, double P, string unit);
double ThermoML(thermo_data model, double T, double P, string unit);


double thermodynamic_property(string species_id, string property_id, double T, double P, string unit = "DEFAULT"){
	//Initializations:
	thermo_data data; 
	bool property_found;
	double propVal = 0.0; //return value

	//Convert the unit string to upper case:
	upper_case(unit);
	property_found = get_property_data(data, species_id, property_id, T, P);

	//DEBUG:
	//print_thermo_data(data);
	//END DEBUG

	//If property data doesn't exist in the list:
	if (!property_found){
		//cout<< '\n'<<"Error: Property list/model cannot be found in list!"<<endl;
		//cout<<"Check thermodynamic_data for more info!"<<endl;
		return -1.0;
	}

	//Check whether the data is provided as a list or by model parameters:
	if (data.data_type == "LIST"){
		//check whether we should interpolate based on temperature or pressure:
		if (data.function_dependence == "TEMPERATURE"){
			property_from_list_data(data.lData, T);
		}
		else if (data.function_dependence == "PRESSURE"){
			property_from_list_data(data.lData, T);
		}
		else {
			cout<<'\n'<<"Error: No independent variable provided for "<<species_id<<": "<<property_id;
			cout<<"! Cannot interpolate!"<<endl;
			return -1.0;
		}
	}
	else if (data.data_type == "MODEL"){
		if (data.mData.model_type == "ANTOINE"){
			return Antoine(data, T, P, unit);
		}
		else if (data.mData.model_type == "MAJER1985"){
			return Majer1985(data, T, P, unit);
		}
		else if (data.mData.model_type == "PPDS12"){
			return PPDS12(data, T, P, unit);
		}
		else if (data.mData.model_type == "ALYLEE" || data.mData.model_type == "CPIDEAL"|| data.mData.model_type == "DIPPR107"){
			return DIPPR107(data, T, P, unit);
		}
		else if (data.mData.model_type == "TDEWATSON"){
			return TDEWatson(data, T, P, unit);
		}
		else if (data.mData.model_type == "THERMOML"){
			return ThermoML(data, T, P, unit);
		}
		else if (data.mData.model_type == "WAGNER25"){
			return Wagner25(data, T, P, unit);
		}
		else if (data.mData.model_type == "CPLIQ" || data.mData.model_type == "TDELIQ" || data.mData.model_type == "TDELIQUID"){
			return TDEliquid(data, T, P, unit);
		}
		else if (data.mData.model_type == "SHOMATE" ){
			return Shomate(data, T, P, unit);
		}
		else if (data.mData.model_type == "CONSTANT" ){
			return Constant(data, T, P, unit);
		}
		else{
			cout<<'\n'<<"Error[THERMOPKG]: Model " << data.mData.model_type<<" not yet implemented!"<<endl;
			cout<< "Source: go thermo_property_models.h to make changes!"<<endl; 
		}
	}
	else {
		cout << '\n' << "Error: Invalid property data data_type provided for "<<species_id<<": "<<property_id;
		cout <<"! Cannot continue!"<< endl;
		return -1.0;
	}
}


//Calculates Tsat or Psat depending on which property one wants to solve for
//Inputs:
//property type: Tsat or Psat
//id: the species id
//model: model data
//T: Temperature
//P: pressure
double Antoine(thermo_data model, double T, double P, string unit){
	double A, B, C;
	//get the model parameters:
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "A"){
			A = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "B"){
			B = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C"){
			C = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for Antoine! Check your constants in the input file!"<<endl;
			return -1.0;
			
		}
	}
	if (model.property_type == "TSAT" || model.property_type =="T"){
		double Tsat = B/(A-log10(P))-C;
		//output of results or conversion to desired unit:
		unit_conversion(Tsat, model, unit);
		return Tsat;
	}
	else if(model.property_type == "PSAT" || model.property_type == "P"){
		double Psat = pow(10.0,(A-(B/(T+C))));
		//convert unit:
		unit_conversion(Psat, model, unit);
		return Psat;
	}
	else{
		cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
		cout<< "Error: Invalid property for the Antoine equation! Use either Tsat or Psat!"<<endl;
	} 		
}

//Liquid vapor pressure:
double Wagner25(thermo_data model, double T, double P, string unit){
	double Tmin = model.min; double Tmax = model.max;
	double C1, C2, C3, C4, lPc, Tc;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "C1"){
			C1 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C2"){
			C2 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C3"){
			C3 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C4"){
			C4 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "lPc"||model.mData.constant_list[i] == "Pc"){
			lPc = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "Tc"){
			Tc = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for Antoine! Check your constants in the input file!"<<endl;
			return -1.0;
			
		}
	}

	double Psat;	

	//check if extrapolation is necessary:
	if(T<Tmin){//extrapolation at the lower bound: (lnp)
		double T1, T2; //extrapolation variables:
		T1 = Tmin; T2 = T1 + 1.0;//sample at two points for extrapolation
		
		double Tr1 = T1/Tc; double Tr2 = T2/Tc;
		double lPsat1 = lPc + (C1*(1-Tr1) + C2*pow(1-Tr1,1.5) + C3*pow(1-Tr1,2.5) + C4*pow(1-Tr1,5))/Tr1; 
		double lPsat2 = lPc + (C1*(1-Tr2) + C2*pow(1-Tr2,1.5) + C3*pow(1-Tr2,2.5) + C4*pow(1-Tr2,5))/Tr2; 

		double lPsat = lPsat1 + ((lPsat1-lPsat2)*(T-T1)/(T1-T2));
		Psat = exp(lPsat);
	}
	else if(T>Tmax){//extrapolation at the upper bound (lnp)
		double T1, T2; //extrapolation variables:
		T1 = Tmax; T2 = T1 - 1.0;//sample at two points for extrapolation
		
		double Tr1 = T1/Tc; double Tr2 = T2/Tc;
		double lPsat1 = lPc + (C1*(1-Tr1) + C2*pow(1-Tr1,1.5) + C3*pow(1-Tr1,2.5) + C4*pow(1-Tr1,5))/Tr1; 
		double lPsat2 = lPc + (C1*(1-Tr2) + C2*pow(1-Tr2,1.5) + C3*pow(1-Tr2,2.5) + C4*pow(1-Tr2,5))/Tr2; 

		double lPsat = lPsat1 + ((lPsat1-lPsat2)*(T-T1)/(T1-T2));
		Psat = exp(lPsat);
	}
	else{
		double Tr = T/Tc;
		double lPsat = lPc + (C1*(1-Tr) + C2*pow(1-Tr,1.5) + C3*pow(1-Tr,2.5) + C4*pow(1-Tr,5))/Tr; 
		Psat = exp(lPsat);
	}
	//unit conversion:
	unit_conversion(Psat, model, unit);

	return Psat;	

}

//Heat of evaporation using the publication by Majer and Svoboda, 1985
double Majer1985(thermo_data model, double T, double P, string unit){
	//Declare constants for the process:
	double A, alpha, beta, Tc;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "A"){
			A = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "alpha"){
			alpha = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "beta"){
			beta = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "Tc"){
			Tc = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for Majer1985! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	//reduced temperature:	
	double Tr = T/Tc;
		
	double HVap= A*exp(-alpha*Tr)*pow((1-Tr),beta);	
	unit_conversion(HVap, model, unit);

	return HVap;
}

//TDEWatson equation for heat of evaporation:
double TDEWatson(thermo_data model, double T, double P, string unit){
	double Tmin = model.min; double Tmax = model.max;
	//Declare parameters:
	double C1, C2, C3, C4, Tc;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "C1"){
			C1 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C2"){
			C2 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C3"){
			C3 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C4"){
			C4 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "Tc"){
			Tc = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for TDEWatson! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	double HVap;
	if (T>Tc){//Set Hvap to 0 above critical temperature
		HVap = 0.0;
	}
	else if (T<Tmin){//Extrapolate HVAP at Tmin 
		double T1 = Tmin; double T2 = Tmin + 1.0;
		double Tr1 = T1/Tc; double Tr2 = T2/Tc;
		double lgHVap1 = C1 + C2*log(1-Tr1) + C3*Tr1*log(1-Tr1) + C4*pow(Tr1,2)*log(1-Tr1);
		double lgHVap2 = C1 + C2*log(1-Tr2) + C3*Tr2*log(1-Tr2) + C4*pow(Tr2,2)*log(1-Tr2);

		double HVap1 = exp(lgHVap1); double HVap2 = exp(lgHVap2);
		//Extrapolation:
		HVap = HVap1 + ((HVap1-HVap2)*(T-T1)/(T1-T2));
	}
	else if(T>Tmax){
		double T1 = Tmax; double T2 = Tmax - 1.0;
		double Tr1 = T1/Tc; double Tr2 = T2/Tc;
		double lgHVap1 = C1 + C2*log(1-Tr1) + C3*Tr1*log(1-Tr1) + C4*pow(Tr1,2)*log(1-Tr1);
		double lgHVap2 = C1 + C2*log(1-Tr2) + C3*Tr2*log(1-Tr2) + C4*pow(Tr2,2)*log(1-Tr2);

		double HVap1 = exp(lgHVap1); double HVap2 = exp(lgHVap2);
		//Extrapolation:
		HVap = HVap1 + ((HVap1-HVap2)*(T-T1)/(T1-T2));		
	}
	else{
		double Tr = T/Tc;
		double lgHVap = 0.0;
		lgHVap = C1 + C2*log(1-Tr) + C3*Tr*log(1-Tr) + C4*pow(Tr,2)*log(1-Tr);

		HVap = exp(lgHVap);
	}
	//unit conversion:
	unit_conversion(HVap, model, unit);
	return HVap;
}

//PPDS12 function:
//From DDB
double PPDS12(thermo_data model, double T, double P, string unit){
	double Tmin = model.min; double Tmax = model.max;
	//Declare constants for the process:
	double A, B, C, D, E, Tc, R;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "A"){
			A = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "B"){
			B = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C"){
			C = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "D"){
			D = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "E"){
			E = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "Tc"){
			Tc = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "R"){
			R = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for PPDS12! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	double Hvap;
	//Extrapolation outside bounds:
	if (T<Tmin){//extrapolation at the lower bound
		double T1 = Tmin; double T2 =T1+1.0;
		double Tr1, Tr2, Hvap1, Hvap2;
		Tr1 = 1-T1/Tc; Tr2 = 1-T2/Tc;
		Hvap1 = R*Tc*(A*pow(Tr1,1.0/3.0)+B*pow(Tr1,2.0/3.0)+C*Tr1+D*pow(Tr1,2)+E*pow(Tr1,6));
		Hvap2 = R*Tc*(A*pow(Tr2,1.0/3.0)+B*pow(Tr2,2.0/3.0)+C*Tr2+D*pow(Tr2,2)+E*pow(Tr2,6));

		Hvap = Hvap1 + ((Hvap1-Hvap2)*(T-T1)/(T1-T2));
	}
	else if(T>Tc){//Hvap = 0.0 above critical temperature
		Hvap = 0.0;
	}
	else if(T>Tmax){//Extrapolation at the upper bound
		double T1 = Tmax; double T2 =T1-1.0;
		double Tr1, Tr2, Hvap1, Hvap2;
		Tr1 = 1-T1/Tc; Tr2 = 1-T2/Tc;
		Hvap1 = R*Tc*(A*pow(Tr1,1.0/3.0)+B*pow(Tr1,2.0/3.0)+C*Tr1+D*pow(Tr1,2)+E*pow(Tr1,6));
		Hvap2 = R*Tc*(A*pow(Tr2,1.0/3.0)+B*pow(Tr2,2.0/3.0)+C*Tr2+D*pow(Tr2,2)+E*pow(Tr2,6));
		Hvap = Hvap1 + ((Hvap1-Hvap2)*(T-T1)/(T1-T2));
	}
	else{	
		//reduced temperature:	
		double Tr = 1-T/Tc;
		Hvap = R*Tc*(A*pow(Tr,1.0/3.0)+B*pow(Tr,2.0/3.0)+C*Tr+D*pow(Tr,2)+E*pow(Tr,6));
	}
	//unit conversion:	
	unit_conversion(Hvap, model, unit);
	
	return Hvap;
}

//Ideal gas constant heat capacity:
//Formula from Aly and Lee 1981 (DIPPR107)
double DIPPR107(thermo_data model, double T, double P, string unit){
	//Declare constants for the process:
	double A, B, C, D, E;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "A"){
			A = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "B"){
			B = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C"){
			C = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "D"){
			D = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "E"){
			E = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for PPDS12! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	//reduced temperature:	
	double cp = 0.0;
	cp = A+B*pow((C/T)/sinh(C/T),2)+D*pow((E/T)/cosh(E/T),2);

	//unit conversion:
	unit_conversion(cp, model, unit);
		
	return cp;
}

//Saturated liquid heat capacity at constant pressure:
double TDEliquid(thermo_data model, double T, double P, string unit){
	double Tmin = model.min; double Tmax = model.max;
	//Declare constants for the process:
	double C1, C2, C3, C4, B, Tc;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "C1"){
			C1 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C2"){
			C2 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C3"){
			C3 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C4"){
			C4 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "B"){
			B = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "Tc"){
			Tc = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for NISTcpliq! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	double cpliq;
	if (T<Tmin){//extrapolation at Tmin
		double T1 = Tmin; double T2 = Tmin + 1.0;
		double t1 = 1-T1/Tc; double t2 = 1-T2/Tc;
		double cpliq1 = B/t1 + C1 + C2*T1 + C3*pow(T1,2) + C4*pow(T1,3);
		double cpliq2 = B/t2 + C1 + C2*T2 + C3*pow(T2,2) + C4*pow(T2,3);

		cpliq = cpliq1 + ((cpliq1-cpliq2)*(T-T1)/(T1-T2));
	}
	else if (T>Tmax){
		double T1 = Tmin; double T2 = Tmin + 1.0;
		double t1 = 1-T1/Tc; double t2 = 1-T2/Tc;
		double cpliq1 = B/t1 + C1 + C2*T1 + C3*pow(T1,2) + C4*pow(T1,3);
		double cpliq2 = B/t2 + C1 + C2*T2 + C3*pow(T2,2) + C4*pow(T2,3);

		cpliq = cpliq1 + ((cpliq1-cpliq2)*(T-T1)/(T1-T2));
	}
	else {
		double t = 1-T/Tc;
		cpliq = B/t + C1 + C2*T + C3*pow(T,2) + C4*pow(T,3);
	}
	//unit converter:
	unit_conversion(cpliq, model, unit);

	return cpliq;
}

//Saturated liquid heat capacity at constant pressure:
double ThermoML(thermo_data model, double T, double P, string unit){
	double Tmin = model.min; double Tmax = model.max;
	//Declare constants for the process:
	double C1, C2, C3, C4, C5, Tc;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "C1"){
			C1 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C2"){
			C2 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C3"){
			C3 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C4"){
			C4 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C5"){
			C5 = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "Tc"){
			Tc = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for NISTcpliq! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	double cpliq;
	if (T<Tmin){
		double T1 = Tmin; double T2 = Tmin+1.0;
		double cpliq1 = C1 + C2*T1 + C3*pow(T1,2) + C4*pow(T1,3) + C5*pow(T1,4);
		double cpliq2 = C1 + C2*T2 + C3*pow(T2,2) + C4*pow(T2,3) + C5*pow(T2,4);
		cpliq = cpliq1 + ((cpliq1-cpliq2)*(T-T1)/(T1-T2));
	}
	else if(T>Tmax){
		double T1 = Tmax; double T2 = Tmax-1.0;
		double cpliq1 = C1 + C2*T1 + C3*pow(T1,2) + C4*pow(T1,3) + C5*pow(T1,4);
		double cpliq2 = C1 + C2*T2 + C3*pow(T2,2) + C4*pow(T2,3) + C5*pow(T2,4);
		cpliq = cpliq1 + ((cpliq1-cpliq2)*(T-T1)/(T1-T2));		
	}
	else{
		cpliq = C1 + C2*T + C3*pow(T,2) + C4*pow(T,3) + C5*pow(T,4);
	}
	//unit conversion:
	unit_conversion(cpliq, model, unit);
	return cpliq;
}

double Shomate(thermo_data model, double T, double P, string unit){
	//Declare constants for the process:
	double A, B, C, D, E, F, G, H;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "A"){
			A = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "B"){
			B = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "C"){
			C = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "D"){
			D = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "E"){
			E = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "F"){
			F = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "G"){
			G = model.mData.constant_values[i];
		}
		else if (model.mData.constant_list[i] == "H"){
			H = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for Shomate! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	//reduced temperature:	
        
        //cout << "model.property_type: " << model.property_type << endl; 
	double val = 0.0;
	if(model.property_type == "CP"){
		val = A+B*pow((T/1000.0),1)+C*pow((T/1000.0),2)+D*pow((T/1000.0),3)+E*pow((T/1000.0),4);
		//unit conversion:
		unit_conversion(val, model, unit);
		return val;
        }

	if(model.property_type == "H"){
		val = A*pow((T/1000.0),1)+B*pow((T/1000.0),2)/2.0+C*pow((T/1000.0),3)/3.0+D*pow((T/1000.0),4)/4.0-E/(T/1000.0)+F-H;
		//unit conversion:
		unit_conversion(val, model, unit);
		return val;
        }

	if(model.property_type == "S"){
		val = A*log(T/1000.0)+B*pow((T/1000.0),1)+C*pow((T/1000.0),2)/2.0+D*pow((T/1000.0),3)/3.0-E/(2.0*pow((T/1000.0),2.0))+G;
		//unit conversion:
		unit_conversion(val, model, unit);
		return val;
        }

}

double Constant(thermo_data model, double T, double P, string unit){
	//Declare constants for the process:
	double A;
	for(int i = 0; i<model.mData.constant_list.size(); i++){
		if (model.mData.constant_list[i] == "A"){
			A = model.mData.constant_values[i];
		}
		else{
			cout << "Error concerning: "<<model.id<<" in the input list"<<endl;
			cout << "Error: Unknown constant listed for Shomate! Check your constants in the input file!"<<endl;
			return -1;
		}
	}
	//reduced temperature:	
        
        //cout << "model.property_type: " << model.property_type << endl; 
	return A;

}








