#include "bioCHP.cpp"

using namespace std;

int main(){

	vector<string> fuel_def = {"spruce_chips"};
	vector<double> Yj = {1.0};
	double W_el = 300.0;
	vector<double> Qk = {};
	vector<double> Tk_in = {};
	vector<double> Tk_out = {};

	vector<double> Mj; double C_inv; double C_op;	

	if( bioCHP_plant(fuel_def, Yj, W_el, Qk, Tk_in,Tk_out,Mj,C_inv,C_op) ){

		for(int nj = 0; nj < Mj.size(); nj++){ cout << "M_"+fuel_def[nj]+" = " << Mj[nj] << endl;}
		cout << "C_inv (M$) = " << C_inv << endl; 
		cout << "C_op (M$) = " << C_op << endl; 

	}
	else{ cout << "error" << endl; }
}
