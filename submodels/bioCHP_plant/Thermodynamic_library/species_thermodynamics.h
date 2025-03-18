#include <tgmath.h>
#include <math.h>
#include <string.h>
#include <vector>

using namespace std;

double shomate(string property, double tK, double A, double B, double C, double D, double E, double F, double G, double Hf298){

	// properties
	// cp = heat capacity (J/mol*K) = A + B * t + C * t2 + D * t3 + E / t2
	// h - H°298.15 = standard enthalpy (kJ/mol) = A*t + B*t2/2 + C*t3/3 + D*t4/4 - E/t + F - Hf298
	// s = standard entropy (J/mol*K) = A * Ln(t) + B * t + C * t2 / 2 + D * t3 / 3 - E / (2 * t2) + G

        if(property == "cp"){ return A+B*pow(tK,1)+C*pow(tK,2)+D*pow(tK,3)+E/pow(tK,2);}
        if(property == "h"){ return A*pow(tK,1)+B*pow(tK,2)/2.0+C*pow(tK,3)/3.0+D*pow(tK,4)/4.0-E/tK+F-Hf298;}
        if(property == "hf"){ return Hf298;}
        if(property == "s"){ return A*log(tK)+B*pow(tK,1)+C*pow(tK,2)/2.0+D*pow(tK,3)/3.0-E/(2.0*pow(tK,2.0))+G;}



}
 
double thermodynamic_property(string species, string property, double TK, double P, string unit){

	double tK = TK/1000.0;

	if (species == "CO2"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.2){
			A = 24.99735; B = 55.18696; C = -33.69137; D = 7.948387; E = -0.136638; F = -403.6075; G = 228.2431; Hf298 = -393.5224;
		}
		if (tK > 1.2){
			A = 58.16639; B = 2.720074; C = -0.492289; D = 0.038844; E = -6.447293; F = -425.9186; G = 263.6125; Hf298 = -393.5224;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "CO"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.3){
			A = 25.56759; B = 6.09613; C = 4.054656; D = -2.671301; E = 0.131021; F = -118.0089; G = 227.3665; Hf298 = -110.5271;
		}
		if (tK > 1.3){
			A = 35.1507; B = 1.300095; C = -0.205921; D = 0.01355; E = -3.28278; F = -127.8375; G = 231.712; Hf298 = -110.5271;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "H2O"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.7){
			A = 30.092; B = 6.832514; C = 6.793435; D = -2.53448; E = 0.082139; F = -250.881; G = 223.3967; Hf298 = -241.8264;
		}
		if (tK > 1.7){
			A = 41.96426; B = 8.622053; C = -1.499781; D = 0.098119; E = -11.15764; F = -272.1797; G = 219.7809; Hf298 = -241.8264;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "H2"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.5){
			A = 33.1078; B = -11.508; C = 11.6093; D = -2.8444; E = -0.159665; F = -9.991971; G = 172.788; Hf298 = 0.0;
		}
		if (tK > 1.5){
			A = 34.1434; B = 0.503927; C = 0.372036; D = -0.038599; E = -8.074761; F = -21.2188; G = 162.093; Hf298 = 0.0;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "CH4"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.3){
			A = -0.703029; B = 108.4773; C = -42.52157; D = 5.862788; E = 0.678565; F = -76.84376; G = 158.7163; Hf298 = -74.8731;
		}
		if (tK > 1.3){
			A = 85.81217; B = 11.26467; C = -2.114146; D = 0.13819; E = -26.42221; F = -153.5327; G = 224.4143; Hf298 = -74.8731;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "N2"){
		double A, B, C, D, E, F, G, Hf298;
		A = 26.092; B = 8.218801; C = -1.976141; D = 0.159274; E = 0.044434; F = -7.98923; G = 221.02; Hf298 = 0.0;
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "O2"){
		double A, B, C, D, E, F, G, Hf298;
		A = 29.659; B = 6.137261; C = -1.186521; D = 0.09578; E = -0.219663; F = -9.861391; G = 237.948; Hf298 = 0.0;
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "SO2"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.2){
			A = 21.43049; B = 74.35094; C = -57.75217; D = 16.35534; E = 0.086731; F = -305.7688; G = 254.8872; Hf298 = -296.8422;
		}
		if (tK > 1.2){
			A = 57.48188; B = 1.009328; C = -0.07629; D = 0.005174; E = -4.045401; F = -324.414; G = 302.7798; Hf298 = -296.8422;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "SO3"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.2){
			A = 24.02503; B = 119.4607; C = -94.38686; D = 26.96237; E = -0.117517; F = -407.8526; G = 253.5186; Hf298 = -395.7654;
		}
		if (tK > 1.2){
			A = 81.99008; B = 0.622236; C = -0.12244; D = 0.008294; E = -6.703688; F = -437.659; G = 330.9264; Hf298 = -395.7654;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "HCl"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.2){
			A = 32.12392; B = -13.45805; C = 19.86852; D = -6.853936; E = -0.049672; F = -101.6206; G = 228.6866; Hf298 = -92.31201;
		}
		if (tK > 1.2){
			A = 31.91923; B = 3.203184; C = -0.541539; D = 0.035925; E = -3.438525; F = -108.015; G = 218.2768; Hf298 = -92.31201;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "Cl2"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.0){
			A = 33.0506; B = 12.2294; C = -12.0651; D = 4.38533; E = -0.159494; F = -10.8348; G = 259.029; Hf298 = 0.0;
		}
		if (tK > 1.0 && tK <= 3.0){
			A = 42.6773; B = -5.00957; C = 1.904621; D = -0.165641; E = -2.098481; F = -17.2898; G = 269.84; Hf298 = 0.0;
		}
		if (tK > 3.0){
			A = -42.5535; B = 41.6857; C = -7.12683; D = 0.387839; E = 101.144; F = 132.764; G = 264.786; Hf298 = 0.0;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "NH3"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.4){
			A = 19.99563; B = 49.77119; C = -15.37599; D = 1.921168; E = 0.189174; F = -53.30667; G = 203.8591; Hf298 = -45.89806;
		}
		if (tK > 1.4){
			A = 52.02427; B = 18.48801; C = -3.765128; D = 0.248541; E = -12.45799; F = -85.53895; G = 223.8022; Hf298 = -45.89806;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "NO2"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.2){
			A = 16.10857; B = 75.89525; C = -54.3874; D = 14.30777; E = 0.239423; F = 26.17464; G = 240.5386; Hf298 = 33.09502;
		}
		if (tK > 1.2){
			A = 56.82541; B = 0.738053; C = -0.144721; D = 0.009777; E = -5.459911; F = 2.846456; G = 290.5056; Hf298 = 33.09502;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}
	else if (species == "N2O4"){
		double A, B, C, D, E, F, G, Hf298;
		if (tK <= 1.0){
			A = 34.05274; B = 191.9845; C = -151.0575; D = 44.3935; E = -0.158949; F = -8.893428; G = 293.7724; Hf298 = 9.078988;
		}
		if (tK > 1.0){
			A = 128.622; B = 2.524345; C = -0.520883; D = 0.03663; E = -11.55704; F = -59.22619; G = 417.0444; Hf298 = 9.078988;
		}
		return shomate(property, tK, A, B, C, D, E, F, G, Hf298);
	}


}
