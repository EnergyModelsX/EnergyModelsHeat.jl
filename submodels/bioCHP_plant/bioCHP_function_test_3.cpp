#include "bioCHP_function.cpp"

using namespace std;

int main(){

	vector<string> fuel_def = {"spruce_chips","spruce_T&B"};
	vector<double> Yj = {0.5,0.5};
	double W_el = 300.0;
	vector<double> Qk = {30.0, 40.0};
	vector<double> Tk_in = {70.0, 70.0};
	vector<double> Tk_out = {90.0, 90.0};

	vector<double> Mj; double C_inv; double C_op;	

	if( bioCHP_plant(fuel_def, Yj, W_el, Qk, Tk_in,Tk_out,Mj,C_inv,C_op) ){

		for(int nj = 0; nj < Mj.size(); nj++){ cout << "M_"+fuel_def[nj]+" = " << Mj[nj] << endl;}
		cout << "C_inv (M$) = " << C_inv << endl; 
		cout << "C_op (M$) = " << C_op << endl; 

	}
	else{ cout << "error" << endl; }
}
