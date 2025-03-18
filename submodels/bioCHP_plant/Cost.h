#include <stdio.h>
#include <fstream>
#include <string.h>
#include <vector>
#include <cmath>

using namespace std;

struct equipment
{
 public:
 string def;
 double Cpi, W_el, C_maint;	
};

struct material
{
 public:
 string type, def;
 double Q_annual, price, C_annual;	
};

double cecpi(int year_input){
 double CECPI; 
  if(year_input==1994){CECPI = 268.1;}
  if(year_input==1995){CECPI = 381.1;}
  if(year_input==1996){CECPI = 381.7;}
  if(year_input==1997){CECPI = 386.5;}
  if(year_input==1998){CECPI = 389.5;}
  if(year_input==1999){CECPI = 390.6;}
  if(year_input==2000){CECPI = 394.1;}
  if(year_input==2001){CECPI = 394.3;}
  if(year_input==2002){CECPI = 395.6;}
  if(year_input==2003){CECPI = 402.0;}
  if(year_input==2004){CECPI = 444.2;}
  if(year_input==2005){CECPI = 468.2;}
  if(year_input==2006){CECPI = 499.6;}
  if(year_input==2007){CECPI = 525.4;}
  if(year_input==2008){CECPI = 550.8;}
  if(year_input==2009){CECPI = 521.9;}
  if(year_input==2010){CECPI = 575.4;}
  if(year_input==2011){CECPI = 525.4;}
  if(year_input==2012){CECPI = 584.6;}
  if(year_input==2013){CECPI = 587.3;}
  if(year_input==2014){CECPI = 586.77;}
  if(year_input==2015){CECPI = 592.0;}
  if(year_input==2016){CECPI = 606.0;}
  if(year_input==2017){CECPI = 623.5;}
  if(year_input==2018){CECPI = 638.1;}
  if(year_input==2019){CECPI = 652.9;}
  if(year_input==2020){CECPI = 668.0;}
  return CECPI; 
}


double I_cecpi(int year_ref, int year){
 double CECPI, CECPI_ref;
 int year_input;

 for(int i=0; i<2; i++){

  if (i==0){year_input = year_ref;} 
  if (i==1){year_input = year;} 
	CECPI = cecpi(year_input);
  if (i==0){CECPI_ref = CECPI;} 
 }
return CECPI/CECPI_ref;	
}


void equipment_cost(object &par){

	par.fval_p("Cpi", par.fp("f_inst")*par.fp("Cpb")*pow(par.fp("S")/par.fp("Sb"),par.fp("n"))*I_cecpi(stoi(par.sp("base_year")), 2020) );

}

void material_cost(object &par){

	par.fval_p("C_annual", par.fp("Q_annual")*par.fp("price") );

}

void equipment_list(vector<equipment> &list, object &par){

	equipment eq;
	for(int n = 0; n < par.c.size(); n++){
		if(par.c[n].sys_type == "equipment"){ 
			eq.def = par.sys_def + "-" + par.c[n].sys_def;   
			eq.Cpi = par.c[n].fp("Cpi");   
			eq.W_el = par.c[n].fp("W_el");
			eq.C_maint = par.c[n].fp("Cpi")*par.c[n].fp("f_maint");   
			list.push_back(eq);
			par.fval_p("output-electric_load_"+par.c[n].sys_def, par.c[n].fp("W_el") );
		}
		if(par.c[n].c.size() > 0){ equipment_list(list, par.c[n]); } 
	}

}

void material_list(string type, vector<material> &list, object &par){

	material m;
	for(int n = 0; n < par.c.size(); n++){
		if(par.c[n].sys_type == type){ 
			m.def = par.sys_def + "-" + par.c[n].sys_def;   
			m.Q_annual = par.c[n].fp("Q_annual");   
			m.price = par.c[n].fp("price");   
			m.C_annual = par.c[n].fp("C_annual");   
			list.push_back(m);

		}
		if(par.c[n].c.size() > 0){ material_list(type, list, par.c[n]); } 
	}

}

void capex(object &par){

	vector<equipment> eq; equipment_list(eq,par);

	double C_eq = 0.0, W_el = 0.0, C_eq_maint = 0.0; for(int n = 0; n < eq.size(); n++){ 
		//cout << eq[n].def << " " << eq[n].Cpi << endl;  
		C_eq = C_eq + eq[n].Cpi; 
		W_el = W_el + eq[n].W_el; 
		C_eq_maint = C_eq_maint + eq[n].C_maint; 
	}

	par.fval_p("W_el(kW)", W_el );

	par.fval_p("output-electric_load", W_el );
	par.fval_p("output-C_eq", C_eq );
	par.fval_p("output-C_piping", C_eq * par.fp("f_piping") );
	par.fval_p("output-C_el", C_eq * par.fp("f_el") );
	par.fval_p("output-C_I&C", C_eq * par.fp("f_I&C") );
	par.fval_p("output-C_pi", par.fp("C_eq") + par.fp("C_piping") + par.fp("C_el") + par.fp("C_I&C") );
	par.fval_p("output-C_land", par.fp("C_pi") * par.fp("f_land") );
	par.fval_p("output-C_site", par.fp("C_pi") * par.fp("f_site") );
	par.fval_p("output-C_build", par.fp("C_pi") * par.fp("f_build") );
	par.fval_p("output-C_com", par.fp("C_pi") * par.fp("f_com") );
	par.fval_p("output-C_eng", (par.fp("C_pi") + par.fp("C_site") + par.fp("C_build") + par.fp("C_com")) * par.fp("f_eng") );
	par.fval_p("output-C_dev", (par.fp("C_pi") + par.fp("C_land") + par.fp("C_site") + par.fp("C_build") + par.fp("C_com") + par.fp("C_eng")) * par.fp("f_dev") );
	par.fval_p("output-C_cont", (par.fp("C_pi") + par.fp("C_land") + par.fp("C_site") + par.fp("C_build") + par.fp("C_com") + par.fp("C_eng") + par.fp("C_dev")) * par.fp("f_cont") );
	par.fval_p("output-C_inv", par.fp("C_pi") + par.fp("C_land") + par.fp("C_site") + par.fp("C_build") + par.fp("C_com") + par.fp("C_eng") + par.fp("C_dev") + par.fp("C_cont") );
	par.fval_p("output-C_eq_maint", par.fp("C_eq") * 0.02 );
	par.fval_p("output-C_piping_maint", par.fp("C_piping") * 0.02 );
	par.fval_p("output-C_el_maint", par.fp("C_el") * 0.02 );
	par.fval_p("output-C_I&C_maint", par.fp("C_I&C") * 0.02 );

	cout << "-------------------------" << endl;
	cout << " Capital costs (M$): " << endl;
	cout << "------------------" << endl;
	cout << "C_eq = " << C_eq << endl;	
	cout << "C_piping = " << par.fp("C_piping") << endl;	
	cout << "C_el = " << par.fp("C_el") << endl;	
	cout << "C_I&C = " << par.fp("C_I&C") << endl;	
	cout << "C_land = " << par.fp("C_land") << endl;	
	cout << "C_site = " << par.fp("C_site") << endl;	
	cout << "C_build = " << par.fp("C_build") << endl;	
	cout << "C_com = " << par.fp("C_com") << endl;	
	cout << "C_eng = " << par.fp("C_eng") << endl;	
	cout << "C_dev = " << par.fp("C_dev") << endl;	
	cout << "C_cont = " << par.fp("C_cont") << endl;	
	cout << "C_inv = " << par.fp("C_inv") << endl;	
	cout << "------------------" << endl;
}

void opex(object &par){

	vector<material> m;  
	material_list("consumable",m,par);
	material_list("solid_residue",m,par);

	cout << "------------------" << endl;
	cout << "Material list" << endl;
	cout << "------------------" << endl;
	double C_op_mat = 0.0; for(int n = 0; n < m.size(); n++){ 
		cout << m[n].type << m[n].def << " Q_annual: " << m[n].Q_annual << " price: " << m[n].price << " " << m[n].C_annual << endl;  
		C_op_mat = C_op_mat + m[n].C_annual; 
	}

	par.fval_p("output-C_op_mat", C_op_mat );

	par.fval_p("output-C_op_el", par.fp("W_el(kW)")*par.fp("price_electricity")*8000 );

	par.fval_p("output-C_op_maint", par.fp("C_eq_maint") + par.fp("C_piping_maint") + par.fp("C_el_maint") + par.fp("C_I&C_maint") );

	par.fval_p("output-C_op_ins", par.fp("C_pi") * par.fp("f_ins") );

	par.fval_p("output-C_op_adm", par.fp("C_pi") * par.fp("f_adm") );

	par.fval_p("output-C_op", par.fp("C_op_mat") + par.fp("C_op_el") + par.fp("C_op_maint") + par.fp("C_op_ins") + par.fp("C_op_adm") );

	cout << "-------------------------" << endl;
	cout << " Operational costs (M$): " << endl;
	cout << "-------------------------" << endl;
	cout << "Materials = " << par.fp("C_op_mat")* 1e-6 << endl;	
	cout << "Electricity = " << par.fp("C_op_el")* 1e-6 << endl;	
	cout << "Equipment maintenance = " << par.fp("C_eq_maint")* 1e-6 << endl;	
	cout << "Piping maintenance = " << par.fp("C_piping_maint")* 1e-6 << endl;	
	cout << "Electric system maintenance = " << par.fp("C_el_maint")* 1e-6 << endl;	
	cout << "I&C_maintenance = " << par.fp("C_I&C_maint") * 1e-6 << endl;	
	cout << "Total maintenance = " << par.fp("C_op_maint") * 1e-6 << endl;	
	cout << "Insurance and taxes = " << par.fp("C_op_ins") * 1e-6 << endl;	
	cout << "Administration = " << par.fp("C_op_adm") * 1e-6 << endl;	
	cout << "------------------" << endl;
}

void cost(object &par){

	capex(par);
	opex(par);

}

