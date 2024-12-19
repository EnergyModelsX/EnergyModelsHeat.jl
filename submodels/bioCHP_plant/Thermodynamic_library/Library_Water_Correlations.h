#include <stdio.h>
#include <fstream>
#include <string.h>
#include <math.h>

using namespace std;

double hPWater(double P)
{
// Entalpi [kJ/kg] i vann som funksjon av trykk P [bara]
double A, B, C, D, E, f, G, H, i, j;

  A = 417.5841933;
  B = -0.07054123;
  C = 88.52544085;
  D = -0.07123712;
  E = -27.5061584;
  f = 0.011864798;
  G = -3.14730479;
  H = -0.00047385;
  i = 0.490013015;

return (A + C * log(P) + E * pow(log(P),2.0) + G * pow(log(P), 3.0) + 
           i * pow(log(P), 4)) / (1 + B * log(P) + D * pow(log(P), 2.0) + 
           f * pow(log(P), 3.0) + H * pow(log(P), 4.0));
}

double hTWater(double T)
{
double A, B, C, D, E, f, G, H, i, j;

  A = 0.0632975;
  B = -0.01339766;
  C = 4.19852677;
  D = 0.000046507;
  E = -0.05673632;
  f = -0.000000036518;
  G = 0.000205288;
  H = -0.000000000044775;
  i = -0.00000022361;
  j = 3.98021E-14;

 return (A + C * T + E * pow(T, 2) + G * pow(T, 3) + i * pow(T, 4)) / 
    (1 + B * T + D * pow(T, 2) + f * pow(T, 3) + H * pow(T, 4) + j * pow(T, 5));
}

double TSatWater(double P)
{
// Mettningstemperatur [C] for vann som funksjon av trykk P [bara]
 double A, B, C, D, E, f, G, H, i, j, k;

  A = 99.63289447;
  B = -0.05130517;
  C = 22.83849468;
  D = -0.07760334;
  E = -6.76745509;
  f = 0.014921577;
  G = -0.59401138;
  H = -0.00098977;
  i = 0.139188034;
  j = 0.0000208266;
  k = -0.0057961;

 return (A + C * log(P) + E * pow(log(P), 2) + G * pow(log(P), 3) + 
             i * pow(log(P), 4) + k * pow(log(P), 5)) /  
            (1 + B * log(P) + D * pow(log(P), 2) + f * pow(log(P), 3) + 
            H * pow(log(P), 4) + j * pow(log(P), 5));
}

double PSatWater(double T)
{
 // Damptrykk [bara] for vann som funksjon av temperatur T [C]
 double A, B, C, D, E, f, G, H, i, j, k;

  A = 0.005990987;
  B = -0.00804865;
  C = 0.00038093;
  D = 0.0000327926;
  E = 0.0000134856;
  f = -0.000000078284;
  G = 0.0000000622167;
  H = 9.75712e-11;
  i = 0.00000000298018;
  j = -4.9808e-14;
  k = -7.9081e-12;

 return (A + C * T + E * pow(T, 2) + G * pow(T, 3) + i * pow(T, 4) + k * pow(T, 5)) / 
            (1 + B * T + D * pow(T, 2) + f * pow(T, 3) + H * pow(T, 4) + j * pow(T, 5));
}

double sPhSupSteam(double P, double H)
{
// Entropi s [kJ/(kg K)] for overhetet damp som funksjon av trykk P [bara] og entalpi h [kJ/kg]
 double A, B, C, D, E, f, G, U, i, j, k;

 if(P < 10){
  A = 15.90422271;
  B = -0.32133416;
  C = -43407.1173;
  D = -0.00875556;
  E = 99643900;
  f = -943.3511;
  G = 0.000241371;
  U = -119490000000;
  i = 1583110;
  j = 30.39968182;

 return A + B * log(P) + C / H + D * pow(log(P), 2) + E / pow(H,2) + 
             f * (log(P)) / H + G * pow(log(P), 3) + U / pow(H,3) + 
             i * (log(P)) / pow(H,2) + j * pow(log(P), 2) / H;
 }

 if (P >= 10 && P < 24){
  A = 12.17787168;
  B = -0.05047554;
  C = -11638.1867;
  D = 0.002274248;
  E = -2655900;
  f = -214.407354;
  G = -0.000029586;
  U = -9912400000;
  i = 363315.174;
  j = 0.344766694;

 return A + B * P + C / H + D * pow(P,2) + E / pow(H,2) + f * P / H + G * pow(P,3) + 
              U / pow(H,3) + i * P / pow(H,2) + j * pow(P,2) / H;

 }

 if (P >= 24 && P < 42) {
  A = 12.13000484;
  B = -0.02596893;
  C = -13150.5398;
  D = 0.000637558;
  E = -1576600;
  f = -119.539592;
  G = -0.0000041047;
  U = -6764600000;
  i = 225677.9999;
  j = -0.035514;

 return A + B * P + C / H + D * pow(P,2) + E / pow(H,2) + f * P / H + 
               G * pow(P,3) + U / pow(H,3) + i *  P / pow(H,2) + j * pow(P,2) / H;
 }

if (P >= 42 && P < 60) {
  A = 10.64359824;
  B = -0.32048327;
  C = 12007.48665;
  D = 0.165713691;
  E = -58179000;
  f = -6064.1728;
  G = -0.01666699;
  U = 25957700000;
  i = 9512250;
  j = 133.8484047;

 return A + B * log(P) + C / H + D * pow(log(P), 2) + E / pow(H,2) + 
              f * (log(P)) / H + G * pow(log(P), 3) + U / pow(H,3) + 
              i * (log(P)) / pow(H,2) + j * pow(log(P), 2) / H;
 }


if (P >= 60 && P < 100) {
  A = 10.1644606;
  B = 78.48986572;
  C = -11188.9497;
  D = -5024.39478;
  E = -23899000;
  f = 306473.6403;
  G = 59081.83839;
  U = 45771900000;
  i = -846390000;
  j = 5052500;
 
 return A + B / P + C / H + D / pow(P,2) + E / pow(H,2) + f / (P * H) + 
              G / pow(P,3) + U / pow(H,3) + i / (P * pow(H,2)) + j / (pow(P,2) * H);
 }

}

double TPhSupSteam(double P, double H)
{
// Temperatur [C] for overhetet damp som funksjon av trykk P [bara] og entalpi h [kJ/kg]
 double A, B, C, D, E, f, G, U, i, j, k;

 if (P < 10) {
  A = 3383.21301;
  B = 46.53089341;
  C = -12602000;
  D = 0.155249729;
  E = 12495500000;
  f = -323525.168;
  G = 0.001128569;
  U = -989420000000;
  i = 568766000;
  j = -601.941773;

 return A + B * P + C / H + D * pow(P,2) + E / pow(H,2) + f * P / H + 
              G * pow(P,3) + U / pow(H,3) + i * P / pow(H,2) + j * pow(P,2) / H - 273.17;
 }

 if(P >= 10 && P < 24) {
  A = 2537.3289;
  B = 16.07484702;
  C = -3557100;
  D = 0.066498641;
  E = -19253000000;
  f = -125839.259;
  G = -0.00045922;
  U = 35725400000000;
  i = 244038000;
  j = -150.038485;

 return A + B * P + C / H + D * pow(P,2) + E / pow(H,2) + f * P / H + 
             G * pow(P,3) + U / pow(H,3) + i * P / pow(H,2) + j * pow(P,2) / H - 273.17;
 }

 if(P >= 24 && P < 40) {
  A = 1400.998669;
  B = 464.5647437;
  C = 4987640;
  D = -26.5159894;
  E = -37810000000;
  f = -2996500;
  G = -0.16822354;
  U = 47329400000000;
  i = 4251290000;
  j = 125603.7895;

 return A + B * log(P) + C / H + D * pow(log(P), 2) + E / pow(H,2) + 
              f * (log(P)) / H + G * pow(log(P), 3) + U / pow(H,3) + 
              i * (log(P)) / pow(H,2) + j * pow(log(P), 2) / H - 273.17;
 }

 if(P >= 40 && P < 60) {
  A = 1400.749789;
  B = 578.0416208;
  C = 3673840;
  D = -65.9610443;
  E = -34664000000;
  f = -2812200;
  G = 3.293513522;
  U = 45442200000000;
  i = 3874260000;
  j = 132398.2899;

 return A + B * log(P) + C / H + D * pow(log(P), 2) + E / pow(H,2) + 
              f * (log(P)) / H + G * pow(log(P), 3) + U / pow(H,3) +  
              i * (log(P)) / pow(H,2) + j * pow(log(P), 2) / H - 273.17;
 }

if(P >= 60 && P < 100) {
  A = 1486950;
  B = 18029.10934;
  C = -550948.579;
  D = 154.5242383;
  E = 67848.35116;
  f = -4407.74853;
  G = 1.57895513;
  U = -2775.67759;
  i = 269.4471355;
  j = -19.7817003;

 return A + B * log(P) + C * log(H) + D * pow(log(P), 2) + E * pow(log(H),2) + 
              f * log(P) * log(H) + G * pow(log(P), 3) + U * pow(log(H),3) + 
              i * log(P) * pow(log(H),2) + j * pow(log(P), 2) * log(H) - 273.17;
 }
}

double hPTSupSteam(double P, double Temp)
{
// Entalpi [kJ/kg] for overhetet damp som funksjon av temperatur T [C] og trykk P [bara]
double A, B, C, D, E, f, G, H, i, j, k, T;

T = Temp + 273.15;

if (P < 6) {
  A = -56835.8274;
  B = -978.268268;
  C = 30403.15382;
  D = 0.956874395;
  E = -5297.41232;
  f = 295.8283303;
  G = -0.00390838;
  H = 314.2187143;
  i = -22.3871465;
  j = -0.14473537;

 return A + B * P + C * log(T) + D * pow(P,2) + E * pow(log(T), 2) + 
              f * P * log(T) + G * pow(P,3) + H * pow(log(T), 3) +  
              i * P * pow(log(T), 2) + j * pow(P,2) * log(T);
 }

if (P >= 6 && P < 10) {
  A = -131757.625;
  B = -6996.63699;
  C = 66816.71538;
  D = -163.058843;
  E = -11191.0492;
  f = 2220.573263;
  G = -37.9649307;
  H = 632.9474087;
  i = -186.603652;
  j = 59.50843382;

 return A + B * log(P) + C * log(T) + D * pow(log(P), 2) + E * pow(log(T), 2) + 
              f * log(P) * log(T) + G * pow(log(P), 3) + H * pow(log(T), 3) + 
              i * log(P) * pow(log(T), 2) + j * pow(log(P), 2) * log(T);
 }

 if (P >= 10 && P < 24) {
  A = -186456.557;
  B = -755.251695;
  C = 90831.0755;
  D = -0.29235124;
  E = -14680.9497;
  f = 226.0904167;
  G = 0.001304593;
  H = 799.5590956;
  i = -16.9130087;
  j = 0.033445377;

 return A + B * P + C * log(T) + D * pow(P,2) + E * pow(log(T), 2) + f * P * log(T) + 
              G * pow(P,3) + H * pow(log(T), 3) + i * P * pow(log(T), 2) + j * pow(P,2) * log(T);
 }

 if (P >= 24 && P < 42) {
  A = 8775.254532;
  B = -12.7851943;
  C = -8032300;
  D = 0.001672424;
  E = 3924150000;
  f = 20283.06325;
  G = 0.000228998;
  H = -683190000000;
  i = -8055900;
  j = -21.1829918;

 return A + B * P + C / T + D * pow(P,2) + E / pow(T, 2) + f * P / T + G * pow(P,3) + 
              H / pow(T, 3) + i * P / pow(T, 2) + j * pow(P,2) / T;
 }

// if (P >= 42 && P < 100) {
 if (P >= 42 && P < 300) {
  A = 10440.24509;
  B = -20.9445233;
  C = -11277000;
  D = 0.030110858;
  E = 5988250000;
  f = 30697.15714;
  G = -0.0000027895;
  H = -1109400000000;
  i = -11659000;
  j = -24.5631185;

 return A + B * P + C / T + D * pow(P,2) + E / pow(T, 2) + f * P / T + G * pow(P,3) + 
              H / pow(T, 3) + i * P / pow(T, 2) + j * pow(P,2) / T;
 }
 
}


double hPSatSteam(double P)
{
// Entalpi [kJ/kg] i mettet damp som funksjon av trykk P [bara]
double A, B, C, D, E, f, G, H, i, j, k;

  A = 2675.345891;
  B = -0.15399836;
  C = -367.76698;
  D = -0.05206658;
  E = -144.467875;
  f = 0.012174232;
  G = 29.7200077;
  H = -0.00065473;
  i = -1.34590982;
  j = -0.0000010367;

 return (A + C * log(P) + E * pow(log(P), 2) + G * pow(log(P), 3) + 
              i * pow(log(P), 4)) / (1 + B * log(P) + D * pow(log(P), 2) + 
              f * pow(log(P), 3) + H * pow(log(P), 4) + j * pow(log(P), 5));
}

double sPTSupSteam(double P, double T_in)
{
double A, B, C, D, E, f, G, H, i, j, k;
double T;

T = T_in + 273.15;

if (P < 10) {
  A = -64.7641083;
  B = -3.92551262;
  C = 30.94072835;
  D = -0.10016359;
  E = -4.62861565;
  f = 1.055357192;
  G = -0.00103702;
  H = 0.246609789;
  i = -0.08032672;
  j = 0.015149543;

 return A + B * log(P) + C * log(T) + D * pow(log(P), 2) + E * pow(log(T), 2) + 
             f * log(P) * log(T) + G * pow(log(P), 3) + H * pow(log(T), 3) + 
             i * log(P) * pow(log(T), 2) + j * pow(log(P), 2) * log(T);
 }

 if (P >= 10 && P < 24) {
  A = 12.92832091;
  B = -0.10043202;
  C = -6049.57011;
  D = 0.002231524;
  E = 2466170;
  f = 32.05749209;
  G = -0.000027218;
  H = -397150000;
  i = -13142.3681;
  j = 0.011191165;

 return A + B * P + C / T + D * pow(P,2) + E / pow(T, 2) + f * P / T + G * pow(P,3) + 
              H / pow(T, 3) + i * P / pow(T, 2) + j * pow(P,2) / T;
 }

 if (P >= 24 && P < 42) {
  A = 13.62876031;
  B = -0.0658488;
  C = -8058.25636;
  D = 0.000640942;
  E = 3755420;
  f = 37.56535927;
  G = -0.0000038759;
  H = -665520000;
  i = -14683.8767;
  j = -0.03100245;

 return A + B * P + C / T + D * pow(P,2) + E / pow(T,2) + f * P / T + G * pow(P,3) + 
              H / pow(T, 3) + i * P / pow(T, 2) + j * pow(P,2) / T;
 }

 //if (P >= 42 && P < 100) {
 if (P >= 42 && P < 300) {
  A = 15.8812763;
  B = -0.05656025;
  C = -13082.1017;
  D = 0.000200402;
  E = 6965160;
  f = 52.74533859;
  G = -0.00000050255;
  H = -1332300000;
  i = -19906.5907;
  j = -0.03586857;

 return A + B * P + C / T + D * pow(P,2) + E / pow(T, 2) + f * P / T + G * pow(P,3) + 
              H / pow(T, 3) + i * P / pow(T, 2) + j * pow(P,2) / T;
 }
}

double sPWater(double P)
{
// Entropi [kJ/(kg K)] i vann som funksjon av trykk P [bara]
 double A, B, C, D, E, f, G, H, i, j, k;

  A = 1.302760006;
  B = -0.14590949;
  C = 0.125910175;
  D = -0.06165915;
  E = -0.10991702;
  f = 0.013583385;
  G = -0.00288777;
  H = -0.00065883;
  i = 0.002340523;
  j = 0.00000173044;
  k = -0.000067444;

 return (A + C * log(P) + E * pow(log(P), 2) + G * pow(log(P), 3) + i * pow(log(P), 4) + 
          k * pow(log(P), 5)) / (1 + B * log(P) + D * pow(log(P), 2) + f * pow(log(P), 3) + 
          H * pow(log(P), 4) + j * pow(log(P), 5));
}

double sPSatSteam(double P)
{
// Entropi [kJ/(kg K)] som funksjon av trykk P [bara]
 double A, B, C, D, E, f, G, H, i, j, k;

  A = 7.359240216;
  B = 0.13119276;
  C = 0.630242728;
  D = -0.10155537;
  E = -0.78903897;
  f = 0.004329778;
  G = 0.065565806;
  H = 0.000569646;
  i = 0.002292981;
  j = 0.0000202713;

 return (A + C * log(P) + E * pow(log(P),2) + G * pow(log(P),3) + i * pow(log(P), 4)) / 
        (1 + B * log(P) + D * pow(log(P), 2) + f * pow(log(P), 3) + H * pow(log(P), 4) + 
        j * pow(log(P), 5));
}

double sTWater(double T)
{
// Entropi [kJ/(kg K)] i vann som funksjon av temperatur T [C]
double A, B, C, D, E, f, G, H, i, j, k;

  A = 1.40623e-50;
  B = 0.000151552;
  C = 0.000217867;
  D = -0.00000000054663;
  E = 0.0000000225065;
  f = -1.7725e-14;
  G = -2.5516e-13;
  H = 1.14005e-19;
  i = 7.68145e-20;
  j = -1.2373e-25;
  k = 3.70402e-24;

 return pow(((A + C * pow(T, 2) + E * pow(T, 4) + G * pow(T, 6) + i * pow(T, 8) + k * pow(T, 10)) / 
          (1 + B * pow(T, 2) + D * pow(T, 4) + f * pow(T, 6) + H * pow(T, 8) + j * pow(T, 10))),0.5);

}

double HTSteam(double T)
{
// Entalpi [kJ/kg] i damp som funksjon av temperatur T [C]
double A, B, C, D, E, f, G, H, i;

  A = 6419730;
  B = 0.0000674237;
  C = 559.7205236;
  D = -0.0000000008934;
  E = -0.00649911;
  f = 3.6399e-15;
  G = 0.0000000141076;
  H = -7.1983e-21;
  i = 1.18814E-14;

 return pow(((A + C * pow(T, 2) + E * pow(T, 4) + G * pow(T, 6) + i * pow(T, 8)) / 
           (1 + B * pow(T, 2) + D * pow(T, 4) + f * pow(T, 6) + H * pow(T, 8))),0.5);
}

double vTWater(double T)
{
// Spesifikk volum [m3/kg] for vann som funksjon av temperatur T [C]
double A, B, C, D, E;
  A = -0.0014778;
  B = 0.003805233;
  C = 372.8596342;
  D = 10271.62001;
  E = 0.048420526;

 return A + B / pow((1 + 4 * pow(((T - C) / D),2) * (pow(2,(1 / E)) - 1)),E);
}

double vTSteam(double T)
{
// Spesifikk volum [m3/kg] av damp som funksjon av temperatur T [C]
double A, B, C, D, E, f;

  A = 5.329275975;
  B = 0.002538932;
  C = -0.05548114;
  D = -0.0000065631;
  E = 0.0000826718;
  f = -0.0000000061263;

 return exp((A + C * T + E * pow(T, 2)) / 
                (1 + B * T + D * pow(T, 2) + f * pow(T, 3)));
}

double HVapH2O(double T)
{
// Fordampningsvarme for vann [kJ/kg] som funksjon av temperatur [C]
// Korrelasjonen bør kontrolleres en gang til før den brukes som standard (Torbjørn).
//if T >= 0 And T < 374.15 {
    //HVapH2O = -0.0000004589 * pow(T, 4 + 0.0002687 * pow(T, 3 - 0.05516 * pow(T, 2 + 1.363 * T + 2449
//Else
    //MsgBox ("Gyldighetsområde for HVapH2O: 0 <= T [C] <= 374.15")
    //HVapH2O = 0#
//End if
 return HTSteam(T) - hTWater(T);
}

double CpWater(double T)
{
// CpVann = 4.2
 return hTWater(T + 1) - hTWater(T);    //29.05.2003
}


