#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string.h>
#include <vector>

using namespace std;

vector<string> divide_string(string str, char c){

	//cout << "divide " << str << endl;
	vector<string> list;
	vector<char> cstr(str.begin(), str.end());
	string element = "";
	bool element_found = false;
	int l = 0; while( l < str.length() ){		
		if( cstr[l] != c ){ element = element + cstr[l]; }
	 	if( cstr[l] == c ){ list.push_back(element); element = ""; } 	
		if( l == str.length()-1){ list.push_back(element); break; }	
		//cout << l << " " << cstr[l] << " " << element << endl;	
		l = l+1;
	}
	cstr.clear(); 
	//cout << "list size " << list.size() << endl; if(list.size() > 0){ for(int n = 0; n < list.size(); n++){ cout << list[n] << endl; }} 
	return list;
}

struct parameter
{
 public:
 string sys_type, sys_def; 
 string data_def, data_id, data_type, data_info;
 int pos;
 vector<string> str; 
 vector<double> num;
 parameter(string line);
 parameter(){};
};

parameter::parameter(string line){

	stringstream sst(line); 
	sst >> data_def; sst >> sys_type; sst >> sys_def; sst >> data_id;  
  	string txt; while(sst >> txt) { str.push_back(txt); }
	pos = 0;
}

struct object
{
 public:
 string sys_type, sys_def, sys_file; 
 vector<object> c; 
 vector<parameter> p; 
 object(string type, string def, string file); 
 object(string type, string def); 
 object(){};
 int ic(string type, string def);
 int ip(string symb);
 bool bp(string symb);
 double fp(string symb);
 vector<double> vctp(string symb);
 string sp(string symb);
 vector<string> svct(string symb);
 void fval_p(string symb, double val);
 void sval_p(string symb, string val);
 void vct_fp(string symb, vector<double> vct);
 void vct_sp(string symb, vector<string> vct);

};


string get_parameter_value(vector<parameter> &par, string sys_type, string sys_def, string data_id){
	//cout << "getting value for " << data_id << " in " << sys_type << " " << sys_def << endl;
 	bool found = false;
 	for( int np = 0; np < par.size(); np++){
  		if(par[np].sys_type == sys_type and par[np].sys_def == sys_def and par[np].data_id == data_id ){
   			string val = par[np].str[par[np].pos];
			//cout << "value : " << val << endl; 
   			if (par[np].pos < par[np].str.size()-1)  { par[np].pos = par[np].pos +1; }
   			found = true; return val;
  		} 
 	}
 	if( found == false ) { return "null"; }
	return "null";
} 



void print_parameter_value(vector<parameter> &p, string sys_type, string sys_def, string data_id)
{
 bool found = false;
 for( int np = 0; np < p.size(); np++)
 {
  if(p[np].sys_type == sys_type and p[np].sys_def == sys_def and p[np].data_id == data_id )
  {
   found = true;
   cout << p[np].sys_type << " " 
        << p[np].sys_def  << " "
        << p[np].data_def << " " 
        << p[np].data_id  << " "
        << p[np].str[p[np].pos] << endl;
  } 
 }
 if( found == false ) { cout << "none found" << endl; }
} 

void export_parameter(vector<parameter> &par, string data_def, string sys_type, string sys_def, string data_id, string val)
{
 //cout << "exporting parameter" << endl;
 bool found = false;
 for( int np = 0; np < par.size(); np++)
 {
  if(par[np].sys_type == sys_type and par[np].sys_def == sys_def and par[np].data_id == data_id )
  {
   par[np].str.push_back(val); par[np].pos = par[np].str.size()-1;
   found = true; 
  } 
 }
 if( found == false ) 
 {
  //cout << "not found in the list... creating" << endl;
  parameter p; 
  p.data_def = data_def; p.sys_type = sys_type; p.sys_def = sys_def; p.data_id = data_id; p.str.push_back(val); p.pos = 0;
  par.push_back(p);
  //print_parameter_value(par,par[par.size()-1].sys_type, par[par.size()-1].sys_def, par[par.size()-1].data_id); 
 }
} 

void get_parameters( vector<parameter> &par, string sys_type, string sys_def, string input_file)
{
	//cout << "getting parameter for " << sys_type << " " << sys_def << endl;
 	ifstream p_file;
 	p_file.open(input_file);
 	if( !p_file.good() ) {cout << "input file not found " << endl; p_file.close(); return;}

 	parameter p; string line_txt, type, def, txt, str; double num; 
	bool par_set_found = false, sys_found = false;
  
  	while(!sys_found) { 
		getline(p_file, line_txt); 
		stringstream sst(line_txt); sst >> type; sst >> def;
 		if( type == sys_type and def == sys_def  ) { 
			//cout << sys_type << " " << sys_def << endl;
			sys_found = true;

			while(!par_set_found){
				getline(p_file, line_txt); //cout << "line_txt: " << line_txt << endl;
				stringstream sst(line_txt); sst >> txt; 

				if (txt == "input" or txt == "prop" or txt == "output" ){
					p.sys_type = sys_type; p.sys_def = sys_def;
      					p.data_def = txt;
      					sst >> p.data_id;   
					//cout << "data_def: " << txt << " data_id: " << p.data_id << endl;
					bool str_complete = false; 
					p.data_info = "";
      					while(sst >> str) { 
						vector<char> cstr(str.begin(), str.end());
						if(!str_complete and cstr[0] != '#'){ p.str.push_back(str);}
						if(cstr[0] == '#'){ str_complete = true; }
						if(str_complete and cstr[0] != '#'){ p.data_info = str + " ";}
		
					} 
      					p.pos = 0; par.push_back(p); p = parameter(); p.str.clear(); p.num.clear();
     				}

				if (txt != "input" and txt != "output" and txt != "prop"){
					par_set_found = true;
					p_file.close(); return;
				}  

			}
		}	
		if(p_file.eof()) { p_file.close(); return; }

    	} 
} 

void export_output_parameters( object &obj, string file)
{
        
 ofstream output_parameters(file);

 for( int np = 0; np < obj.p.size(); np++) 
 {
   if(obj.p[np].data_def == "output")
   {
    output_parameters << obj.p[np].sys_type << " " << obj.p[np].sys_def << " " << obj.p[np].data_id;

    for( int ns = 0; ns < obj.p[np].str.size(); ns++ ) { output_parameters << " " << obj.p[np].str[ns];} 
    output_parameters << endl;
   }
 }

 output_parameters.close();   
  
} 


void print_parameters( vector<parameter> &p)
{
 cout << "no. parameters: " << p.size() << endl;
 for( int np = 0; np < p.size(); np++) 
 {
   cout << p[np].sys_type << " " << p[np].sys_def << " "
        << p[np].data_def << " " << p[np].data_type;

   for( int ns = 0; ns < p[np].str.size(); ns++ ) { cout << " " << p[np].str[ns];} 
   cout << endl;

 }  
} 

double fp(vector<parameter> &par, string sys_type, string sys_def, string data_id)
{

	if(get_parameter_value(par, sys_type, sys_def, data_id) == "null"){ return -1;  }
	return atof(get_parameter_value(par, sys_type, sys_def, data_id).c_str());
} 

string sp(vector<parameter> &par, string sys_type, string sys_def, string data_id)
{
	return get_parameter_value(par, sys_type, sys_def, data_id);
} 

vector<double> fp_vct(vector<parameter> &par, string sys_type, string sys_def, string data_id){
 	bool found = false;
 	vector<double> vct;
 	for( int np = 0; np < par.size(); np++){
  		if(par[np].sys_type == sys_type and par[np].sys_def == sys_def and par[np].data_id == data_id ){
   			for(int n = 0; n < par[np].str.size(); n++){ vct.push_back(atof(par[np].str[n].c_str()));} 
   			found = true; return vct;
  		} 
 	}
 	//if( found == false ) { return vct; }
	return vct;
} 

vector<string> sp_vct(vector<parameter> &par, string sys_type, string sys_def, string data_id){
 	bool found = false;
 	vector<string> vct;
 	for( int np = 0; np < par.size(); np++){
  		if(par[np].sys_type == sys_type and par[np].sys_def == sys_def and par[np].data_id == data_id ){
   			for(int n = 0; n < par[np].str.size(); n++){ vct.push_back(par[np].str[n]);} 
   			found = true; return vct;
  		} 
 	}
 	if( found == false ) { return vct; }
	return vct;
} 

void fval_p(vector<parameter> &par, string data_def, string sys_type, string sys_def, string data_id, double val){
	export_parameter(par, data_def, sys_type, sys_def, data_id, to_string(val));
} 

void sval_p(vector<parameter> &par, string data_def, string sys_type, string sys_def, string data_id, string val){
	export_parameter(par, data_def, sys_type, sys_def, data_id, val);
} 

void fvct_p(vector<parameter> &par, string data_def, string sys_type, string sys_def, string data_id, vector<double> val){
 	//cout << "exporting parameter" << endl;
 	bool found = false;
 	for( int np = 0; np < par.size(); np++){
  		if(par[np].sys_type == sys_type and par[np].sys_def == sys_def and par[np].data_id == data_id ){
  			par[np].str.clear(); 
  			for(int n = 0; n < val.size(); n++){par[np].str.push_back(to_string(val[n]));} par[np].pos = 0;
   			found = true; 
  		} 
 	}
 	if( found == false ) {
  		//cout << "not found in the list... creating" << endl;
  		parameter p; 
  		p.data_def = data_def; p.sys_type = sys_type; p.sys_def = sys_def; p.data_id = data_id; p.pos = 0;
		for(int n = 0; n < val.size(); n++){p.str.push_back( to_string(val[n]) );} 
  		par.push_back(p);
  		//print_parameter_value(par,par[par.size()-1].sys_type, par[par.size()-1].sys_def, par[par.size()-1].data_id); 
 	}
} 

void svct_p(vector<parameter> &par, string data_def, string sys_type, string sys_def, string data_id, vector<string> val){
 	//cout << "exporting parameter" << endl;
 	bool found = false;
 	for( int np = 0; np < par.size(); np++){
  		if(par[np].sys_type == sys_type and par[np].sys_def == sys_def and par[np].data_id == data_id ){
  			par[np].str.clear(); 
  			for(int n = 0; n < val.size(); n++){par[np].str.push_back(val[n]);} par[np].pos = 0;
   			found = true; 
  		} 
 	}
 	if( found == false ) {
  		//cout << "not found in the list... creating" << endl;
  		parameter p; 
  		p.data_def = data_def; p.sys_type = sys_type; p.sys_def = sys_def; p.data_id = data_id; p.pos = 0;
		for(int n = 0; n < val.size(); n++){p.str.push_back( val[n] );} 
  		par.push_back(p);
  		//print_parameter_value(par,par[par.size()-1].sys_type, par[par.size()-1].sys_def, par[par.size()-1].data_id); 
 	}
}

object::object(string type, string def, string file){
	sys_type = type; sys_def = def; sys_file = file;
	get_parameters(p, type, def, file);
}

object::object(string type, string def){
	sys_type = type; sys_def = def;
	if(type == "equipment"){get_parameters(p, type, def, "Database/Equipment_database");} 
	if(type == "consumable"){get_parameters(p, type, def, "Database/Consumables_database");} 
	if(type == "solid_residue"){get_parameters(p, type, def, "Database/Consumables_database");} 
}

int object::ic(string type, string def){ 

	for(int n = 0; n < c.size(); n++){ if(c[n].sys_type == type and c[n].sys_def == def){ return n; }} 
	return -1; 

}

int object::ip(string symb){ 

 	bool found = false;
 	for( int np = 0; np < p.size(); np++){
  		if(p[np].data_id == symb ){ return np; }
  	} 
 	//if( found == false ) { return -1; }
	return -1;


}

bool object::bp(string symb){ 

 	bool found = false;
 	for( int np = 0; np < p.size(); np++){
  		if(p[np].data_id == symb ){ return true; }
  	} 
 	//if( found == false ) { return false; }
	return false;

}

double object::fp(string symb){ 

	string val = get_parameter_value(p, sys_type, sys_def, symb);
	if(val == "null"){ return -1;  }
	return atof(val.c_str());

}
string object::sp(string symb){ 

	return get_parameter_value(p, sys_type, sys_def, symb);

}

vector<double> object::vctp(string symb){ return fp_vct(p, sys_type, sys_def, symb);}

vector<string> object::svct(string symb){ return sp_vct(p, sys_type, sys_def, symb);}

void object::fval_p(string symb, double val){

	if(divide_string(symb,'-').size() == 1){ export_parameter(p, "prop", sys_type, sys_def, symb, to_string(val)); }
	if(divide_string(symb,'-').size() == 2){ 
		export_parameter(p, divide_string(symb,'-')[0], sys_type, sys_def, divide_string(symb,'-')[1], to_string(val)); 
	}


}

void object::sval_p(string symb, string val){

	if(divide_string(symb,'-').size() == 1){ export_parameter(p, "prop", sys_type, sys_def, symb, val); }
	if(divide_string(symb,'-').size() == 2){ 
		export_parameter(p, divide_string(symb,'-')[0], sys_type, sys_def, divide_string(symb,'-')[1], val); 
	}

}

void object::vct_fp(string symb, vector<double> vct){

	if(divide_string(symb,'-').size() == 1){ fvct_p(p, "prop", sys_type, sys_def, symb, vct); }
	if(divide_string(symb,'-').size() == 2){ 
		fvct_p(p, divide_string(symb,'-')[0], sys_type, sys_def, divide_string(symb,'-')[1], vct); 
	}
}

void object::vct_sp(string symb, vector<string> vct){

	if(divide_string(symb,'-').size() == 1){ svct_p(p, "prop", sys_type, sys_def, symb, vct); }
	if(divide_string(symb,'-').size() == 2){ 
		svct_p(p, divide_string(symb,'-')[0], sys_type, sys_def, divide_string(symb,'-')[1], vct); 
	}

}

void transfer_parameter(string symb, object from, object &to){

	to.p.push_back(from.p[from.ip(symb)]);

}
