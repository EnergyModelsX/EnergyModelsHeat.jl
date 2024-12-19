//#include <cmath.h>
#include <tgmath.h>
#include <math.h>
#include <string.h>
#include <vector>

using namespace std;

//Function headers:
double wCwO(string CellerO, double H, double wH, double wS, double wCl, double wN, double wAske, double wH2O);
double NedreBrennverdi(double wC, double wH, double wO, double wS, double wN, double wH2O);
double SGas(string Comp, double TC);
double HGas(string Comp, double TC);
double CpGas(string Comp, double TC, double TC1 = 0.0);
void GasData(string Comp, double &T, double &A, double &B, double &C, double &D, double &E, double &f, double &G, double &H, double &Hf298);
double AcidVaporDewPoint(string Comp, double xHCl, double xsO2, double xH2O, double P);
double THGasMix(double H, double xCO2, double xH2O, double xO2, double xN2, double xCO = 0.0, double xH2 = 0.0);
double HGasMix(double T, double xCO2, double xH2O, double xO2, double xN2, double xCO = 0.0, double xH2 = 0.0);
double HfGas_Mix(double xO2, double xN2, double xCO2, double xH2O, double xH2, double xCO, double xCH4, double xC2H4, double xC2H2, double xC2H6, double xC3, double xC4, double xC5, double xC6, double xC7, double xC8, double xC9, double xC10);
double hPWater(double P);
double hTWater(double T);
double TSatWater(double P);
double PSatWater(double T);
double sPhSupSteam(double P, double H);
double TPhSupSteam(double P, double H);
double hPsSupSteam(double P, double S);
double hPTSupSteam(double P, double Temp);
double sPTSupSteam(double P, double T_in);
double dT_sPTSupSteam(double P, double T);
double sPSatSteam(double P);
double sPWater(double P);
double sTWater(double T);
double hPSatSteam(double P);
double HTSteam(double T);
double vTWater(double T);
double vTSteam(double T);
double HVapH2O(double T);
double CpVann(double T);
double cp(string Comp, double T, double T2 = 9999.0);
double cpRGASS(string Comp, double T, double T1 = 9999.0, int kg = 0);
double cpMix(double xCO2, double xO2, double xH2O, double xN2, double T, double T1 = 9999.0);
double PvH2O(double T);
double TSatH2O(double P);
double gas_visc_lucas(double T, string Comp);
double gas_visc(double T, string Comp);
double G_Mix_visc(double T, double xO2, double xCO, double xH2, double xCO2, double xH2O, double xN2);
double gas_lambda(double T, string Comp);

// Bibliotek med korrelasjoner for fysikalske data
// HGasMix   Beregner entalpi [kJ/Nm3] av røykgass sfa. temperatur [C]
// HVapH2O   Fordampningsvarme for vann [kJ/kg] sfa. temperatur [C]
// gas_lambda Termisk konduktivitet i gass [W/(m K)] sfa temperatur [C]
// G_Mix_visc Viskositet [Pa s] for en gassblanding sfa. temperaturen T [C]
// gas_visc  Viskositet for komponenter [Pa s] sfa. temperatur [C]

double wESt(string CHO, double Qar, double wS, double wCl, double wN, double wAske, double wH2O){
	// Empirisk korrelasjon for wC, wH og wO som funksjon av input parametrene over.
	// Basert på
	double k;
	double kC, kH, kO, kS, kN, kH2O, kA;
	kC = 34.1; kH = 102; kO = -9.85; kS = 19.1; kN = 0.0; kH2O = -2.5; kA = 0.0;   
	//kC = 34.8; kH = 93.9; kO = -10.8; kS = 10.5; kN = 6.3; kH2O = -2.45; kA=0.0;    // Ref. Christensen, T. (1998)
	//kC = 34.1; kH = 110.4; kO = -12.0; kS = 6.86; kN = -12.0; kA = -1.53; //Milne's formulae (from Phyllis)
	//kC = 34.91; kH = 97.67; kO = -10.34; kS = 10.05; kN = 0.0; kA = -2.11; // Review artikkel
 
	double Qdaf, wC, wH, wO;
	
	//Qdaf = Qar / ((1 - wH2O) * (1 - wAske))
	//Qar = (kC*wC+kH*wH+kS*wS+kN*wN+kO*wO)*(1-wH2O) + kH2O*wH2O = Qdaf*(1-wH2O)+kH2O*wH2O

	Qdaf = (Qar - kH2O * wH2O) / (1 - wH2O); //korrigert  27.03.03
	wC = (0.01727 * Qdaf + 0.1583);
	k = (Qar - kH2O * wH2O) / (1 - wH2O);
	wH = (k - (kC * wC + kS * wS + kN * wN + kA * wAske) - kO * (1 - wC - wN - wS - wCl - wAske)) / (kH - kO);
	wO = 1 - (wC + wH + wS + wN + wCl + wAske);

	if (CHO == "C"){
		return wC;
	}
	else if (CHO == "H"){
		return wH;
	}
	else{
		return wO;
	}
}


double wCwO(string CellerO, double H, double wH, double wS, double wCl, double wN, double wAske, double wH2O){
	double k, x, y, wA;
	double kC, kH, kO, kS, kN, kH2O, kA;
	kC = 34.1; kH = 102.0; kO = -9.85; kS = 19.1; kN = 0.0; kH2O = -2.5;
	//kC = 34.8; kH = 93.9; kO = -10.8; kS = 10.5; kN = 6.3; kH2O = -2.45; //Ref. Christensen, T. (1998)
	//kC = 34.1; kH = 110.4; kO = -12.0; kS = 6.86; kN = -12.0; kA = -1.53; //Milne's formulae (from Phyllis)
 
	wA = wAske + wS + wCl + wN;
	k = (H - kH2O * wH2O) / (1 - wH2O) - kH * wH - kS * wS - kN * wN;
	y = (12 / 16) * (kC * (1 - wA) - k * (1 + wH / (1 - wA - wH))) / (-kO * (1 - wA) + k * (1 + wH / (1 - wA - wH)));
	x = (12 + 16 * y) * wH / (1 - wA - wH);
 
	if (CellerO == "C"){
		return 12 / (12 + x + 16 * y) * (1 - wA);
	}
	else{
		return 16 * y / (12 + x + 16 * y) * (1 - wA);
	}
}


double NedreBrennverdi(double wC, double wH, double wO, double wS, double wN, double wH2O){
	//Beregning av nedre brennverdi [MJ/kg]
	//Forutsetning: Brensel: 20C, Forbrenningsluft inn: 20C, røykgass ut ved 100oC (ikke kondensert).
 
	//ToP - 4.8.2000
 
	double kC, kH, kO, kS, kN, kH2O, kA;
	kC = 34.1; kH = 102; kO = -9.85; kS = 19.1; kN = 0; kH2O = -2.5; kA = 0.0;
	//kC = 34.8; kH = 93.9; kO = -10.8; kS = 10.5; kN = 6.3; kH2O = -2.45; kA = 0.0; // Ref. Christensen, T. (1998)
	//kC = 34.1; kH = 110.4; kO = -12; kS = 6.86; kN = -12; kH2O = -2.442; kA = -1.53; // Milne's formulae (from Phyllis)
	if (wH2O > 1)  wH2O = wH2O / 100;    //forutsetter vektfraksjon i input
	if (wC + wH + wO + wS + wN > 1.0001) {
		wC = wC / 100; wH = wH / 100; wO = wO / 100; wS = wS / 100; wN = wN / 100;
	}

	return (kC * wC + kH * wH + kS * wS + kN * wN + kO * wO) * (1 - wH2O) + kH2O * wH2O; // Ref. Christensen (1998)
}


double SGas(string Comp, double TC){
	//Standard entropy S^o [J/(mol K)]
	//Comp {se rutinen GasData for definerte komponenter}
	//TC - temperatur [C]
 
	//ToP - 16.3.00
	double T = (TC + 273.15) / 1000;
 
	double A, B, C, D, E, f, G, H, Hf298;

	//COME BACK TO THIS: (must be a void function with addresses!)
	GasData(Comp, T, A, B, C, D, E, f, G, H, Hf298);
 
	return A * log(T) + B * T + C * (pow(T,2)) / 2 + D * (pow(T,3)) / 3 - E / (2 * pow(T,2)) + G;
}


double HGas(string Comp, double TC){
	//Standard entalpi [kJ/mol]
	//Comp {se rutinen GasData for definerte komponenter}
	//TC - temperatur [C]
 
	//ToP - 16.3.00
	double T = (TC + 273.15) / 1000;
        //double T = (TC + 273.15);
	double A, B, C, D, E, f, G, H, Hf298; 
	GasData(Comp, T, A, B, C, D, E, f, G, H, Hf298);
        double R = 8.314;
 
	return R*(A * T + B * pow(T,2) / 2 + C * pow(T,3) / 3 + D * pow(T,4) / 4 - E / T + f);
}

void GasNASAData(string Species, double &Tn, double &a1, double &a2, double &a3, double &a4, double &a5, double &a6, double &a7)
{
// Cp° = A + B * t + C * t2 + D * t3 + E / t2
// H° - H°298.15= A*t + B*t2/2 + C*t3/3 + D*t4/4 - E/t + F - fH°f,298
// S° = A * Ln(t) + B * t + C * t2 / 2 + D * t3 / 3 - E / (2 * t2) + G
// Cp = heat capacity (J/mol*K)
// H° = standard enthalpy (kJ/mol)
// S° = standard entropy (J/mol*K)

if( Species == "O2") {
if( Tn > 1000 ){ a1 = 3.28253784; a2 = 0.00148308754; a3 = -0.000000757966669; a4 = 2.09470555E-10; a5 = -2.16717794E-14; a6 = -1088.45772; a7 = 5.45323129;}
if( Tn <= 1000 ){ a1 = 3.78245636; a2 = -0.00299673416; a3 = 0.00000984730201; a4 = -9.68129509E-09; a5 = 3.24372837E-12; a6 = -1063.94356; a7 = 3.65767573;}
}
if( Species == "N2") {
if( Tn > 1000 ){ a1 = 3.28253784; a2 = 0.00148308754; a3 = -0.000000757966669; a4 = 2.09470555E-10; a5 = -2.16717794E-14; a6 = -1088.45772; a7 = 5.45323129;}
if( Tn <= 1000 ){ a1 = 3.298677; a2 = 0.0014082404; a3 = -0.000003963222; a4 = 0.000000005641515; a5 = -2.444854E-12; a6 = -1020.8999; a7 = 3.950372;}
}
if( Species == "H2O") {
if( Tn > 1000 ){ a1 = 3.03399249; a2 = 0.00217691804; a3 = -0.000000164072518; a4 = -9.7041987E-11; a5 = 1.68200992E-14; a6 = -30004.2971; a7 = 4.9667701;}
if( Tn <= 1000 ){ a1 = 4.19864056; a2 = -0.0020364341; a3 = 0.00000652040211; a4 = -5.48797062E-09; a5 = 1.77197817E-12; a6 = -30293.7267; a7 = -0.849032208;}
}
if( Species == "CO2") {
if( Tn > 1000 ){ a1 = 3.85746029; a2 = 0.00441437026; a3 = -0.00000221481404; a4 = 5.23490188E-10; a5 = -4.72084164E-14; a6 = -48759.166; a7 = 2.27163806;}
if( Tn <= 1000 ){ a1 = 2.35677352; a2 = 0.00898459677; a3 = -0.00000712356269; a4 = 2.45919022E-09; a5 = -1.43699548E-13; a6 = -48371.9697; a7 = 9.90105222;}
}
if( Species == "CO") {
if( Tn > 1000 ){ a1 = 2.71518561; a2 = 0.00206252743; a3 = -0.000000998825771; a4 = 2.30053008E-10; a5 = -2.03647716E-14; a6 = -14151.8724; a7 = 7.81868772;}
if( Tn <= 1000 ){ a1 = 3.57953347; a2 = -0.00061035368; a3 = 0.00000101681433; a4 = 9.07005884E-10; a5 = -9.04424499E-13; a6 = -14344.086; a7 = 3.50840928;}
}
if( Species == "H2") {
if( Tn > 1000 ){ a1 = 3.3372792; a2 = -0.0000494024731; a3 = 0.000000499456778; a4 = -1.79566394E-10; a5 = 2.00255376E-14; a6 = -950.158922; a7 = -3.20502331;}
if( Tn <= 1000 ){ a1 = 2.34433112; a2 = 0.00798052075; a3 = -0.000019478151; a4 = 2.01572094E-08; a5 = -7.37611761E-12; a6 = -917.935173; a7 = 0.683010238;}
}
}

double HGas_j(string Comp, double TC){

	double T = (TC + 273.15);
        double a1, a2, a3, a4, a5, a6, a7;
        double R = 8.314;
        GasNASAData(Comp, T, a1, a2, a3, a4, a5, a6, a7);

        return R * T * (a1 + a2 * T / 2 + a3 * pow(T,2) / 3 + a4 * pow(T,3) / 4 + a5 * pow(T,4) / 5 + a6 / T);
}


double CpGas(string Comp, double TC, double TC1){
	//Spesifikk varmekapasitet [J/(mol K)]
	//Comp {se rutinen GasData for definerte komponenter}
	//TC - temperatur [C]
	//TC1 - valgfri temperatur [C]. Dersom gitt beregnes midlere varmekap. mellom TC og TC1.
 
	//ToP - 16.3.00
	double T = (TC + 273.15) / 1000;
	double T1 = (TC1 + 273.15) / 1000;
 
	double A, B, C, D, E, f, G, H, Hf298;
	GasData(Comp, T, A, B, C, D, E, f, G, H, Hf298);
        double R = 8.314;
 
	if (TC1 == 0){
		return A + B * T + C * pow(T,2) + D * pow(T,3) + E / pow(T,2);
	}
	else{
		return (A * (T1 - T) + B / 2 * (pow(T1,2) - pow(T,2)) + C / 3 * (pow(T1,3) - pow(T,3)) + D / 4 * (pow(T1,4) - pow(T,4)) - E * (1 / T1 - 1 / T)) / (T1 - T);
	}
}


void GasData(string Comp, double &T, double &A, double &B, double &C, double &D, double &E, double &f, double &G, double &H, double &Hf298){
	//Korrelasjoner for termokjemiske data for enkeltkomponenter
	//hentet fra NIST Chemistry WebBook : http://webbook.nist.gov/chemistry/
	//Cp° = A + B * t + C * t2 + D * t3 + E / t2
	//H° - H°298.15= A*t + B*t2/2 + C*t3/3 + D*t4/4 - E/t + F - fH°f,298
	//S° = A * Ln(t) + B * t + C * t2 / 2 + D * t3 / 3 - E / (2 * t2) + G
	//Cp = heat capacity (J/mol*K)
	//H° = standard enthalpy (kJ/mol)
	//Print fH°298.15 = enthalpy; of; formation; at; 298.15K (kJ / mol)
	//S° = standard entropy (J/mol*K)
	//t = temperature(K) / 1000#
 
	//Gyldig temperaturområde er fra 298 til 6000K
 
	//ToP 19.3.00
	if (Comp == "CO2"){
		if (T <= 1.2){
			A = 24.99735; B = 55.18696; C = -33.69137; D = 7.948387; E = -0.136638; f = -403.6075; G = 228.2431; Hf298 = -393.5224;
		}
		if (T > 1.2){
			A = 58.16639; B = 2.720074; C = -0.492289; D = 0.038844; E = -6.447293; f = -425.9186; G = 263.6125; Hf298 = -393.5224;
		}
	}
	else if (Comp == "CO"){
		if (T <= 1.3){
			A = 25.56759; B = 6.09613; C = 4.054656; D = -2.671301; E = 0.131021; f = -118.0089; G = 227.3665; Hf298 = -110.5271;
		}
		if (T > 1.3){
			A = 35.1507; B = 1.300095; C = -0.205921; D = 0.01355; E = -3.28278; f = -127.8375; G = 231.712; Hf298 = -110.5271;
		}
	}
	else if (Comp == "H2O"){
		if (T <= 1.7){
			A = 30.092; B = 6.832514; C = 6.793435; D = -2.53448; E = 0.082139; f = -250.881; G = 223.3967; Hf298 = -241.8264;
		}
		if (T > 1.7){
			A = 41.96426; B = 8.622053; C = -1.499781; D = 0.098119; E = -11.15764; f = -272.1797; G = 219.7809; Hf298 = -241.8264;
		}
	}
	else if (Comp == "H2"){
		if (T <= 1.5){
			A = 33.1078; B = -11.508; C = 11.6093; D = -2.8444; E = -0.159665; f = -9.991971; G = 172.788; Hf298 = 0.0;
		}
		if (T > 1.5){
			A = 34.1434; B = 0.503927; C = 0.372036; D = -0.038599; E = -8.074761; f = -21.2188; G = 162.093; Hf298 = 0.0;
		}
	}
	else if (Comp == "CH4"){
		if (T <= 1.3){
			A = -0.703029; B = 108.4773; C = -42.52157; D = 5.862788; E = 0.678565; f = -76.84376; G = 158.7163; Hf298 = -74.8731;
		}
		if (T > 1.3){
			A = 85.81217; B = 11.26467; C = -2.114146; D = 0.13819; E = -26.42221; f = -153.5327; G = 224.4143; Hf298 = -74.8731;
		}
	}
	else if (Comp == "N2"){
		A = 26.092; B = 8.218801; C = -1.976141; D = 0.159274; E = 0.044434; f = -7.98923; G = 221.02; Hf298 = 0.0;
	}
	else if (Comp == "O2"){
		A = 29.659; B = 6.137261; C = -1.186521; D = 0.09578; E = -0.219663; f = -9.861391; G = 237.948; Hf298 = 0.0;
	}
	else if (Comp == "SO2"){
		if (T <= 1.2){
			A = 21.43049; B = 74.35094; C = -57.75217; D = 16.35534; E = 0.086731; f = -305.7688; G = 254.8872; Hf298 = -296.8422;
		}
		if (T > 1.2){
			A = 57.48188; B = 1.009328; C = -0.07629; D = 0.005174; E = -4.045401; f = -324.414; G = 302.7798; Hf298 = -296.8422;
		}
	}
	else if (Comp == "SO3"){
		if (T <= 1.2){
			A = 24.02503; B = 119.4607; C = -94.38686; D = 26.96237; E = -0.117517; f = -407.8526; G = 253.5186; Hf298 = -395.7654;
		}
		if (T > 1.2){
			A = 81.99008; B = 0.622236; C = -0.12244; D = 0.008294; E = -6.703688; f = -437.659; G = 330.9264; Hf298 = -395.7654;
		}
	}
	else if (Comp == "HCl"){
		if (T <= 1.2){
			A = 32.12392; B = -13.45805; C = 19.86852; D = -6.853936; E = -0.049672; f = -101.6206; G = 228.6866; Hf298 = -92.31201;
		}
		if (T > 1.2){
			A = 31.91923; B = 3.203184; C = -0.541539; D = 0.035925; E = -3.438525; f = -108.015; G = 218.2768; Hf298 = -92.31201;
		}
	}
	else if (Comp == "Cl2"){
		if (T <= 1.0){
			A = 33.0506; B = 12.2294; C = -12.0651; D = 4.38533; E = -0.159494; f = -10.8348; G = 259.029; Hf298 = 0.0;
		}
		if (T > 1.0 && T <= 3.0){
			A = 42.6773; B = -5.00957; C = 1.904621; D = -0.165641; E = -2.098481; f = -17.2898; G = 269.84; Hf298 = 0.0;
		}
		if (T > 3.0){
			A = -42.5535; B = 41.6857; C = -7.12683; D = 0.387839; E = 101.144; f = 132.764; G = 264.786; Hf298 = 0.0;
		}
	}
	else if (Comp == "NH3"){
		if (T <= 1.4){
			A = 19.99563; B = 49.77119; C = -15.37599; D = 1.921168; E = 0.189174; f = -53.30667; G = 203.8591; Hf298 = -45.89806;
		}
		if (T > 1.4){
			A = 52.02427; B = 18.48801; C = -3.765128; D = 0.248541; E = -12.45799; f = -85.53895; G = 223.8022; Hf298 = -45.89806;
		}
	}
	else if (Comp == "NO2"){
		if (T <= 1.2){
			A = 16.10857; B = 75.89525; C = -54.3874; D = 14.30777; E = 0.239423; f = 26.17464; G = 240.5386; Hf298 = 33.09502;
		}
		if (T > 1.2){
			A = 56.82541; B = 0.738053; C = -0.144721; D = 0.009777; E = -5.459911; f = 2.846456; G = 290.5056; Hf298 = 33.09502;
		}
	}
	else if (Comp == "N2O4"){
		if (T <= 1.0){
			A = 34.05274; B = 191.9845; C = -151.0575; D = 44.3935; E = -0.158949; f = -8.893428; G = 293.7724; Hf298 = 9.078988;
		}
		if (T > 1.0){
			A = 128.622; B = 2.524345; C = -0.520883; D = 0.03663; E = -11.55704; f = -59.22619; G = 417.0444; Hf298 = 9.078988;
		}
	}
}


double AcidVaporDewPoint(string Comp, double xHCl, double xsO2, double xH2O, double P){
	//Beregner syreduggpunkt [C] for HCl (Comp="HCl") eller H2SO4
	//xHCl, xSO2, xH2O - molfraksjon av hendholdsvis HCl, SO2 og H2O i røykgassen
	//P - trykk [atma]
 
	//Basert på korrelasjon fra  http://pages.hotbot.com/books/vganapathy/corros.html
	//Torbjørn Pettersen 11.5.99
	P = P * 760;     // atm -> mmHg
	double pHCl, pH2SO4, pH2O, THCl, TH2SO4;
	pHCl = xHCl * P;
	pH2O = xH2O * P;
	pH2SO4 = xsO2 * 0.02 * (64 / 80) * P;
	THCl = 1000 / (3.7368 - 0.1591 * log(pH2O) - 0.326 * log(pHCl) + 0.00269 * log(pH2O) * log(pHCl));
	TH2SO4 = 1000 / (2.276 - 0.0294 * log(pH2O) - 0.0858 * log(pH2SO4) + 0.0062 * log(pH2O) * log(pH2SO4));

	if (Comp == "HCl"){
		return THCl;
	}
	else{
		return TH2SO4;
	}

}


double THGasMix(double H, double xCO2, double xH2O, double xO2, double xN2, double xCO, double xH2){
	//Beregner temperatur [C] for en gassblanding med CO2, H2O,O2 og N2
	//med entalpi H [kJ/Nm3], hvor H beregnes fra HGasMix(T,...)
	//Torbjørn Pettersen, 13.5.99
	//ToP, 23.4.00 (mulighet for å regne på primærkammergass med CO og H2)
	double T, f, dfdx, dT;
	static double Tn;
	dT = 1.0;
	(Tn == 0.0) ? Tn = 1000.0:Tn=Tn; //start estimat

	int nIt = 0;

	while (abs(Tn - T) > 0.05 && nIt < 5000){
		T = Tn;
    	f = H - HGasMix(T, xCO2, xH2O, xO2, xN2, xCO, xH2);
    	dfdx = ((H - HGasMix(T + dT, xCO2, xH2O, xO2, xN2, xCO, xH2)) - f) / dT;
    	Tn = 0.5 * Tn + 0.5 * (T - f / dfdx);
		nIt++;
	}
	if (nIt>=5000){
		cout <<"Error number of it exceeded in THGasMix";
	}
	return Tn;
}

double HGasMix(double T, double xCO2, double xH2O, double xO2, double xN2, double xCO, double xH2){
	//Entalpi for gass blanding med CO2, H2O, O2 og N2 [kJ/Nm3]
	//T - temperatur [C]
	//xCO2, xH2O, xO2, xN2 - molfraksjoner eller mol/tid eller Nm3/tid
 
	//Torbjørn Pettersen, 16.12.98
	//ToP, 23.4.00 (Nye Cp data og mulighet for å regne på primærkammergass)
	double HCO2, HO2, HH2O, HN2, HCO, HH2, sumX;
	if (T < -273 || T > 6000){
		cout << "Ugyldig temperatur";
    }
 
	//HN2 = -2.1282 + 1.2779 * T + 0.00010401 * pow(T,2); //Verdier benyttet i beregninger før 29.1.00
	//HO2 = -8.43 + 1.3597 * T + 0.00010443 * pow(T,2);	//Gir ca 3% lavere Cp verdier enn CpRGASS
	//HCO2 = -30.225 + 1.9576 * T + 0.00025049 * pow(T,2); //og er basert på at Cp er en linær funksjon av T.
	//HH2O = -0.90662 + 1.4463 * T + 0.00024529 * pow(T,2); //(ToP, 29.1.00)
 
	//HN2 = cpRGASS("N2", 0, T) * T / 22.41; //Basert på cpRGASS
	//HO2 = cpRGASS("O2", 0, T) * T / 22.41; //Korrigert 29.1.00 (ToP)
	//HCO2 = cpRGASS("CO2", 0, T) * T / 22.41;
	//HH2O = cpRGASS("H2O", 0, T) * T / 22.41;
 
	//HN2 = CpGas("N2", 0, T) * T / 22.41;  //J/mol / Nm3/kmol = kJ/Nm3
	//HO2 = CpGas("O2", 0, T) * T / 22.41;  //J/mol / Nm3/kmol = kJ/Nm3
	//HCO2 = CpGas("CO2", 0, T) * T / 22.41; //J/mol / Nm3/kmol = kJ/Nm3
	//HH2O = CpGas("H2O", 0, T) * T / 22.41;  //J/mol / Nm3/kmol = kJ/Nm3
	//HH2 = CpGas("H2", 0, T) * T / 22.41; //J/mol / Nm3/kmol = kJ/Nm3
	//HCO = CpGas("CO", 0, T) * T / 22.41; //J/mol / Nm3/kmol = kJ/Nm3
 
	double T0 = 25.0; //La til entalpiberegning basert på HGas og T0 som referansetemperatur.
	HN2 = (HGas("N2", T) - HGas("N2", T0)) / 0.02241;   // kJ/mol / Nm3/mol = kJ/Nm3
	HO2 = (HGas("O2", T) - HGas("O2", T0)) / 0.02241;  // kJ/mol / Nm3/mol = kJ/Nm3
	HCO2 = (HGas("CO2", T) - HGas("CO2", T0)) / 0.02241; // kJ/mol / Nm3/mol = kJ/Nm3
	HCO = (HGas("CO", T) - HGas("CO", T0)) / 0.02241;  // kJ/mol / Nm3/mol = kJ/Nm3
	HH2 = (HGas("H2", T) - HGas("H2", T0)) / 0.02241;  // kJ/mol / Nm3/mol = kJ/Nm3
	HH2O = (HGas("H2O", T) - HGas("H2O", T0)) / 0.02241;  // kJ/mol / Nm3/mol = kJ/Nm3

	HN2 = (HGas_j("N2", T) - HGas_j("N2", T0)) / 0.02241;   // J/mol / Nm3/mol = J/Nm3
	HO2 = (HGas_j("O2", T) - HGas_j("O2", T0)) / 0.02241;  // J/mol / Nm3/mol = J/Nm3
	HCO2 = (HGas_j("CO2", T) - HGas_j("CO2", T0)) / 0.02241; // J/mol / Nm3/mol = J/Nm3
	HCO = (HGas_j("CO", T) - HGas_j("CO", T0)) / 0.02241;  // J/mol / Nm3/mol = J/Nm3
	HH2 = (HGas_j("H2", T) - HGas_j("H2", T0)) / 0.02241;  // J/mol / Nm3/mol = J/Nm3
	HH2O = (HGas_j("H2O", T) - HGas_j("H2O", T0)) / 0.02241;  // J/mol / Nm3/mol = J/Nm3
 
	sumX = (xCO2 + xO2 + xH2O + xN2 + xCO + xH2);
	return (xCO2 * HCO2 + xH2O * HH2O + xO2 * HO2 + xN2 * HN2 + xCO * HCO + xH2 * HH2) / sumX;
}

 
double HfGas_Mix(double xO2, double xN2, double xCO2, double xH2O, double xH2, double xCO, double xCH4, double xC2H4, double xC2H2, double xC2H6, double xC3, double xC4, double xC5, double xC6, double xC7, double xC8, double xC9, double xC10){
 
	double Hf_O2, Hf_N2, hf_CO2, hf_H2O, hf_H2, hf_CO, HF_CH4, Hf_C2H4, Hf_C2H2, Hf_C2H6;
	double Hf_C3, Hf_C4, Hf_C5, Hf_C6, Hf_C7, Hf_C8, Hf_C9, Hf_C10;
 
	// Hf in kJ / mol
 
	hf_CO = -26.42 * 4.18; hf_CO2 = -94.05 * 4.18; hf_H2O = -57.8 * 4.18; hf_H2 = 0; Hf_O2 = 0; Hf_N2 = 0; HF_CH4 = -17.83;
	Hf_C2H4 = 52.459; Hf_C2H2 = 227.98; Hf_C2H6 = -83.77; HF_CH4 = -74.53;
	Hf_C3 = -104.04; Hf_C4 = -211.53; Hf_C5 = -314.3; Hf_C6 = -361.06; Hf_C7 = -354.7; Hf_C8 = -359.6; Hf_C9 = -371.23; Hf_C10 = -395.39;
 
	double Hfgas=0.0;
	Hfgas = -(xO2 * Hf_O2 + xN2 * Hf_N2 + xCO2 * hf_CO2 + xH2O * hf_H2O + xH2 * hf_H2 + xCO * hf_CO + xC2H4 * Hf_C2H4 + xC2H2 * Hf_C2H2 + xC2H6 * Hf_C2H6);
	Hfgas = Hfgas - (xC3 * Hf_C3 + xC4 * Hf_C4 + xC5 * Hf_C5 + xC6 * Hf_C6 + xC7 * Hf_C7 + xC8 * Hf_C8 + xC9 * Hf_C9 + xC10 * Hf_C10);

	return Hfgas;
}
 

double gas_visc_lucas(double T, string Comp){
	// Beregn viskositet av komponenter i gass fase
	// eta(T,C) - [Pa s]
	// T - [C]
	// C - {O2, N2, CO, CO2, H2O}
	// Basert på korrelasjon fra "Properties of gases and liquids",
	// Reid et al.
	// Lucas metode: Slik metoden er implementert her er den ikke
	// gyldig for komponentene hydrogen og helium.
	// Parametre som inngår for hver komponent:
	//   Mw - molvekt [g/mol]
	//   Tc - kritisk temperatur [K]
	//   Pc - kritisk trykk [bar]
	//   Zc - kritisk kompressibilitet [-]
	//   dipm - dipolmoment [debey]
	double Mw, TC, Pc, Zc, dipm;
	double Tr, eps, ur, Fp0, Fq0;

	if (Comp == "H2O"){
		Mw = 18.015; //g/mol
		TC = 647.3;  //K
		Pc = 221.2;  //bar
    	Zc = 0.235;  
		dipm = 1.8;
	}   
	else if (Comp == "O2"){
		Mw = 32.0; //g/mol
		TC = 154.6; //K
		Pc = 50.4; //bar
		Zc = 0.288;
		dipm = 0.0; 
	}
	else if (Comp == "N2"){
		Mw = 28.0; //g/mol
		TC = 126.2; //K
		Pc = 33.9; //bar
		Zc = 0.29;
		dipm = 0.0; 
	}
	else if (Comp == "CO"){
		dipm = 0.1; 
		Mw = 28.01; //g/mol
		TC = 132.9; //K
		Pc = 35.0; //bar
		Zc = 0.295;
		dipm = 0.1;
	}
	else if (Comp == "CO2"){
		Mw = 44.01; //g/mol
		TC = 304.1; //K
		Pc = 73.8; //bar
		Zc = 0.274; 
		dipm = 0.0; 
	}
	Tr = (273 + T) / TC;
 
	eps = 0.176 * pow((TC / (pow(Mw,3) * pow(Pc,4))),(1 / 6)); // [m2/(N s)]
 
	ur = 52.46 * pow(dipm,2) * Pc / pow(TC,2);
	Fp0 = 1.0;
	Fq0 = 1.0;
	if (ur >= 0.022 && ur < 0.075){
		Fp0 = 1 + 30.55 * pow((0.292 - Zc),1.72);
	}
	else if (ur >= 0.075){
		Fp0 = 1 + 30.55 * pow((0.292 - Zc),1.72) * abs(0.96 + 0.1 * (Tr - 0.7));
	}

	return 0.0000001 * (0.807 * pow(Tr, 0.618) - 0.357 * exp(-0.449 * Tr) + 0.34 * exp(-4.058 * Tr) + 0.018) * Fp0 * Fq0 / eps; // [Pa*s]
}

//THIS FUNCTION SEEMS INCOMPLETE!!
double gas_visc(double T, string Comp){
	// Beregner gass-viskositet av enkeltkomponenter [Pa s] som funksjon av
	// T - temperatur [C]
	// Comp - {O2, N2, CO, CO2, H2, H2O}
	//Viskositet, kg/(m.s)   (K & B, Tabell 45)
	// Gunnar Nåvik
	// Torbjørn Pettersen 1.5.99 (Re-implementert og sammenliknet md gas_visc_lucas).
	vector<double> A(6,0.0);
	double my, Tk;
	double dmydT=0.0, T0=0.0, dT=0.0;
	Tk = T + 273;
	if (Comp == "O2"){
		if(Tk <= 1273){ //TC<1000 oC
			A[0] = 18.11; A[1] = 0.6632; A[2] = -0.0001879;
			dmydT = 0.0;
		}
		else{ //lineær ekstrapolasjon over 1000 oC:
			T0 = 1273; dT = Tk - T0; Tk = T0;
			dmydT = A[1] + 2 * A[2] * T0;
		}
		my = (A[0] + A[1] * Tk + A[2] * pow(Tk,2) + dmydT * dT) * 0.0000001;
	}
	else if (Comp == "CO2"){
		A[0] = 25.45; A[1] = 0.4549; A[2] = -0.00008649;
		my = (A[0] + A[1] * Tk + A[2] * pow(Tk,2)) * 0.0000001; //TC<1400 oC
	}
	else if (Comp == "CO"){
		A[0] = 32.28; A[1] = 0.4747; A[2] = -0.00009648;
		my = (A[0] + A[1] * Tk + A[2] * pow(Tk,2)) * 0.0000001;  //TC<1400 oC
	}
	else if (Comp == "H2O"){
		if(Tk <= 1273){ //TC<1000 oC
			A[0] = -31.89;  A[1] = 0.4145; A[2] = -0.000008272;
			dmydT = 0.0;
		}
		else{  //lineær ekstrapolasjon over 1000 oC:
			T0 = 1273; dT = Tk - T0; Tk = T0;
			dmydT = A[1] + 2 * A[2] * T0;
		}
		my = (A[0] + A[1] * Tk + A[2] * pow(Tk,2) + dmydT * dT) * 0.0000001;
	}
	else if (Comp == "H2"){
		A[0] = 21.87; A[1] = 0.222; A[2] = -0.00003751;
		my = (A[0] + A[1] * Tk + A[2] * pow(Tk,2)) * 0.0000001; //TC<1200 oC
	}
	else if (Comp == "N2"){
		A[0] = 30.43; A[1] = 0.4989; A[2] = -0.0001033;
		my = (A[0] + A[1] * Tk + A[2] * pow(Tk, 2)) * 0.0000001; //TC<1200 oC
	}

	return my;
}


double G_Mix_visc(double T, double xO2, double xCO, double xH2, double xCO2, double xH2O, double xN2){
	// Beregner viskositet for en gassblanding som funksjon av temperaturen T [C]
	// og sammensetningen.
	// Blanderegler fra Reid et al.
	// Gunnar Nåvik
	// Torbjørn Pettersen 1.5.99 (reimplementering)
	vector<double> x(6), U(6), Mw(6);
	x[0] = xO2; U[0] = gas_visc_lucas(T, "O2"); Mw[0] = 32.0;
	x[1] = xCO; U[1] = gas_visc_lucas(T, "CO"); Mw[1] = 28.0;
	x[2] = xH2; U[2] = gas_visc(T, "H2"); Mw[2] = 2.0;
	x[3] = xCO2; U[3] = gas_visc_lucas(T, "CO2"); Mw[3] = 44.0;
	x[4] = xH2O; U[4] = gas_visc_lucas(T, "H2O"); Mw[4] = 18.0;
	x[5] = xN2; U[5] = gas_visc_lucas(T, "N2"); Mw[5] = 28.0;
	double fiij, fiji;
	double sumi, sumj;
	sumi = 0.0;
	for (int i=0;i<6;i++){
		sumi += x[i]; //normaliser som molfraksjoner
	}

	for (int i=0;i<6;i++){
		x[i]=x[i]/sumi;
	}

	sumi = 0.0;
	for (int i=0;i<6;i++){
		sumj = 0.0;
		for (int j=0;j<6;j++){
			fiij = pow((1.0 + sqrt(U[i]/U[j]) * pow((Mw[j]/Mw[i]),0.25)),2) / sqrt(8*(1 + Mw[i] / Mw[j]));
			sumj += x[j] * fiij;
		}
		sumi += x[i] * U[i] / sumj;
	}
	return sumi; //viskositet for blanding
}


double gas_lambda(double T, string Comp){
	// Termisk konduktivitet i gass fase [W/(m K)] sfa Temperatur [C]
	// Comp - {O2, H2O, N2, CO, CO2}
	// Basert på korrelasjoner fra Reid et al.
	// Torbjørn Pettersen 2.5.99
	double A, B, C, D, Tmin, Tmax, T_;

	
	if (Comp == "H2O"){
		A = 0.007341; B = -0.00001013; C = 0.0000001801; D = -0.000000000091;
		Tmin = 273.0; // T>=Tmin [C]
		Tmax = 1070.0; // T<=Tmax [C]
	}
	else if (Comp == "O2"){
		A = -0.0003273; B = 0.00009966; C = -0.00000003743; D = 0.000000000009732;
		Tmin = 115.0;
		Tmax = 1470.0;
	}
	else if (Comp == "N2"){
		A = 0.0003919; B = 0.00009816; C = -0.00000005067; D = 0.00000000001504;
		Tmin = 115.0;
		Tmax = 1470.0;
	}
	else if (Comp == "CO"){
		A = 0.0005067; B = 0.00009125; C = -0.00000003524; D = 0.000000000008199;
		Tmin = 115.0;
		Tmax = 1670.0;
	}
	else if (Comp == "CO2"){
		A = -0.007215; B = 0.00008015; C = 0.000000005477; D = -0.00000000001053;
		Tmin = 185.0;
		Tmax = 1670.0;
	}
	T_ = T + 273; // C -> K
	if (T_ >= Tmin && T_ <= Tmax){
		return A + B * T_ + C * pow(T_, 2) + D * pow(T_, 3);
	}
	else{
		return 0;
	}
}
