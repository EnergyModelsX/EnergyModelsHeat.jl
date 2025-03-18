
#include <stdio.h>
#include <fstream>
#include <string.h>
#include <vector>
#include <cmath>

using namespace std;

struct physical_parameter 
{
 public:
 string symb, def, unit;
 double val;
 physical_parameter(string input_symb, double input_val, string input_unit);
 physical_parameter(string input_symb, string input_def, double input_val, string input_unit);
};

 physical_parameter::physical_parameter(string input_symb, double input_val, string input_unit){
 symb = input_symb; val = input_val; unit = input_unit;
 }

 physical_parameter::physical_parameter(string input_symb, string input_def, double input_val, string input_unit){
 symb = input_symb; def = input_def; val = input_val; unit = input_unit;
 }

struct physical_parameters_set 
{
 public:
 vector<physical_parameter> p;
 double f(string symb);
};

 double physical_parameters_set::f(string symb){
	bool found = false;
 	for(int np = 0; np < p.size(); np++){if (p[np].symb == symb){ found = true; return p[np].val;}}
	return -1; 
 }

struct properties 
{
 public:
	double LHV,LHV_dry,HHV,HHV_dry;
	double cp, rho, MW ;
	double hf, ht, h; //J/mol (REFPROP)
	double s, g, gf, e; // (REFPROP)
	double DP, BP, hVap, Tsat, q; //dew point, bubble point, heat of evaporation
        double k, visc;
	double em_psr; // energy particle size reducton 
        vector<double> val; // valences
};

struct flow_parameters 
{
	public:
        double P, T;
	double M,N,VN,V; //M: mass, N: molar, VN: volumetric normal, V: volumetric
	double H,Ht,Hf;
};

struct species
{
	public:
	string id, def, formula; 
	string prop_data;//properties data: refprop, NASA or thermoPkg
        bool refprop, NASA, thermoPkg, input;
	string molec_db, refprop_file = "NONE", NASA_file, thermoPkg_file;
	double TC, Y, X; //TC: transfer coeff, Y: wt%, X: mol%
	vector<double> val;
	properties P;
	flow_parameters F;
	species(){};
	species(string sid);
	species(string sid, double sY);
	species(string sid, double val, string def);
	species(string sid, double sY, double sMW);
	species(string sid, double sTC, double sY, double sX, double sMW);
	void calculate_refprop(string);
	//void get_species_data();
	void get_species_data_(string);
	void calculate_thermodynamic_properties();
};


species::species(string sid){
	id = sid;
	TC = 1.0; Y = 0.0; X = 0.0; 
        
}

species::species(string sid, double sY){
	id = sid;
	TC = 1.0; Y=sY; X = 0.0;	
}


species::species(string sid, double val, string def){
	id = sid;
	TC = 1.0; X=0.0; 
        if(def == "Y"){Y=val;}
        if(def == "X"){X=val;}
}

species::species(string sid, double sY, double sMW){
	id = sid;
	TC = 1.0; Y=sY; X = 0.0; P.MW = sMW; 
}

species::species(string sid, double sTC, double sY, double sX, double sMW){
	id = sid;

	TC = sTC; Y=sY; X=sX; P.MW = sMW;
}

int index_species(vector<species> &spc, string spc_id)
{
	for(int i = 0; i < spc.size(); i++){ if(spc[i].id == spc_id){return i;}}
	return -1; //returns a negative number if species does not exist in the vector
}

struct phase
{
 public:
  string id;
  double C,Y,X, phi;
  properties P;
  flow_parameters F;
  vector<species> i, j, k;
};


struct flow
{
	public:
	string id, def, cls, prop_data;
        string flow_db, thermo_file, trans_file, chem_file;
	vector<species> i,j,k,l; int n_i, n_j, n_k, n_l; string atom_def, molec_def, prox_def; //i=atoms,j=molec,k=prox,l=const
        //particles_distribution fp;
	properties P;
	flow_parameters F;
	phase ph[3]; 
  	//vector<chemical_reaction> rct; int n_rct;
	flow(string flw_def);
	flow(string flw_def, string flw_id);
	flow(){};
	void get_flow_data(string);
        void initialize_species(vector<species>&);
	void get_flow_species(vector<species>&, string);
	void get_flow_composition(vector<species>&, string);
	void get_flow_properties();
	void get_flow_chemistry();
	void interpret_molecules();
	void mix_flows(flow&, flow&);
	void flows_database(string);
	void get_species_data();
	void get_species_MW();
	void define_flow_prop_data();
	void calculate_flow(string);
	void calculate_flow_composition();
	void calculate_flow_properties(string);
	void calculate_species_properties(string);
	void calculate_flow_parameters();
	void calculate_solid_fuel();
	void calculate_gas_fuel();

	void calculate_properties();
	void calculate_gas_thermodynamics();
	void calculate_thermodynamic_properties();
	void calculate_MW();
	void print_flow();
};


 
flow::flow(string flw_def)
{
	def = flw_def; 
	F = flow_parameters(); P = properties();
	F.T = 25.0; F.P = 1.01325;	
	//flows_database(flw_def);
	get_flow_data(flw_def);
	if(cls == "woody_biomass" or cls == "sludge"){calculate_solid_fuel();}
}

flow::flow(string flw_id, string flw_def)
{
	id = flw_id; def = flw_def;
	F = flow_parameters(); P = properties();
	F.T = 25.0; F.P = 1.01325;	
	//flows_database(flw_def);
	get_flow_data(flw_def);
	if(cls == "woody_biomass" or cls == "sludge"){calculate_solid_fuel();}
	
}

void flow::get_species_data()
{
	//for( int n=0; n<j.size(); n++){j[n].get_species_data();} 
	//for( int n=0; n<i.size(); n++){i[n].get_species_data();} 
}


int index_flow(vector<flow> &f, string f_id)
{
	for(int i = 0; i < f.size(); i++){ if(f[i].id == f_id){return i;}}
	return -1; //returns a negative number if species does not exist in the vector
}

 void flow::calculate_MW()
 {
  get_species_data();
  P.MW = 0;
  for( int n=0; n<j.size(); n++){P.MW = P.MW + j[n].X*j[n].P.MW;} 
 }

void flow::calculate_properties()
{
	get_species_data();
	P.MW = 0; P.cp = 0; P.rho = 0;
	if(j.size() == 1) 
        {
         P.MW = j[0].P.MW*1e-3;
         P.cp = j[0].P.cp;
         P.rho = j[0].P.rho;

        } 
	if(j.size() > 1) 
        {
	 double sum_Y = 0.0; for(int n = 0; n < j.size(); n++){sum_Y += j[n].Y;}
	 double sum_X = 0.0; for(int n = 0; n < j.size(); n++){sum_X += j[n].X;}
         if (sum_Y > 0 and sum_X == 0)
         {
  	  for(int n = 0; n < j.size(); n++){j[n].Y = j[n].Y/sum_Y;}
          double sum_Y_MW = 0.0; for(int n = 0; n < j.size(); n++) {if(j[n].Y > 0 and j[n].P.MW > 0){sum_Y_MW += j[n].Y/j[n].P.MW;}}
          for(int n = 0; n < j.size(); n++)
          {
	   if(j[n].Y > 0 and j[n].P.MW > 0 and sum_Y_MW > 0){j[n].X = (j[n].Y / j[n].P.MW) / sum_Y_MW;}
	   if(j[n].Y == 0){j[n].X = 0;}
          }
         }
         else if (sum_Y == 0 and sum_X > 0)
         {
  	  for(int n = 0; n < j.size(); n++){j[n].X = j[n].X/sum_X;}
          double sum_X_MW = 0.0; for(int n = 0; n < j.size(); n++) {if(j[n].Y > 0 and j[n].P.MW > 0){sum_X_MW += j[n].X*j[n].P.MW;}}
          for(int n = 0; n < j.size(); n++)
          {
	   j[n].Y = (j[n].X * j[n].P.MW) / sum_X_MW;
	   if(j[n].X == 0){j[n].Y = 0;}
          }
         }
      
         for(int n = 0; n < j.size(); n++) 
         {
          P.MW += j[n].X * j[n].P.MW * 1e-3;
          P.cp += j[n].X * j[n].P.cp;
         }
	 double sum_Y_rho = 0.0; for(int n = 0; n < j.size(); n++){sum_Y_rho += j[n].Y/j[n].P.rho;}
         P.rho = 1.0 / sum_Y_rho;
        }

}

 void flow::interpret_molecules()
 {
  char * molec_ID; char * atom_ID; vector<string> atoms_ID; vector<int> atoms_N; 
  string txt; double val; int ctr_atom, ctr_atom1, ctr_atom2, ctr_molec, pos; 

  //cout << "Molecule interpreter. No. molecules: " << j.size() << endl;
  
  if( j.size() > 0)
  {
  for(int n = 0; n <  j.size(); n++)
  {
   //cout << "molecule formula: " << j[n].formula << endl;
   ctr_atom = 0; ctr_atom1 = 0; ctr_atom2 = 0; ctr_molec = 0;
   molec_ID = new char[j[n].formula.length()];
   strcpy(molec_ID,j[n].formula.c_str());
   j[n].P.MW = 0.0;
   int l = 0; pos = 0;
   while(l<j[n].formula.length())
   {

    if(molec_ID[l]=='T' && (molec_ID[l+1]=='X' || molec_ID[l+1]=='-' )){l = l+2;}
    if(molec_ID[l]=='S' && (molec_ID[l+1]=='X' || molec_ID[l+1]=='-')){l = l+2;}
    if((molec_ID[l]=='+' || molec_ID[l]=='-') && (molec_ID[l+1] >='1' && molec_ID[l+1] <= '9')){break;}
    if((molec_ID[l]=='+' || molec_ID[l]=='-') && l == j[n].formula.length()-1){break;}

    // finding a match in the atoms list  
    for(int m = 0; m < i.size(); m++)
    {
     atom_ID = new char[i[m].id.length()];
     strcpy(atom_ID,i[m].id.c_str()); 

     if(i[m].id.length() == 1 and ctr_atom2 == 0)
     {
      if(molec_ID[l]==atom_ID[0])
      {
       ctr_atom1 = 1; atoms_ID.push_back(i[m].id);
      } 
     }
   
     if(i[m].id.length() == 2)
     {
      if(l+1<=j[n].formula.length()-1 && molec_ID[l+1]==atom_ID[1] && molec_ID[l]==atom_ID[0])
      {
       ctr_atom2 = 1; l = l+1;
       if(ctr_atom1 == 0){atoms_ID.push_back(i[m].id);}
       if(ctr_atom1 == 1){atoms_ID[atoms_ID.size()-1]= i[m].id; ctr_atom1 = 0;}
      } 
     }
    }

    if(ctr_atom1 == 1 or ctr_atom2 == 1)
    {
     ctr_atom1 = 0; ctr_atom2 = 0;
     if(l == j[n].formula.length()-1)
     {
      atoms_N.push_back(1); 
      ctr_molec = 1;
     }

     if((l < j[n].formula.length()-1) && !(molec_ID[l+1]>='0' && molec_ID[l+1]<='9'))
     {
      atoms_N.push_back(1); pos = l+1;
     }

     if((l<j[n].formula.length()-1) && (molec_ID[l+1]>='0' && molec_ID[l+1]<='9'))
     {
      if( (l+1) ==  (j[n].formula.length()-1)){ctr_molec = 1; atoms_N.push_back(molec_ID[l+1]-'0');}
      if( (l+1) < (j[n].formula.length()-1))
      {
       int v = 0; 
       while(molec_ID[l+1]>='0' && molec_ID[l+1]<='9')
       {
        v = 10 * v + molec_ID[l+1]-'0'; 
        if((l+1) == j[n].formula.length()-1){ctr_molec = 1; break;}
        l = l+1;
       }	
       atoms_N.push_back(v);  
       pos = l+1;
      }
     }
     l = pos;
    }
  
    if(ctr_molec == 1){ctr_molec = 0; break;}        

   }

   int index;

   double sum_N = 0; double sum_M = 0; 
   for(int ni = 0; ni < atoms_ID.size(); ni++)
   {
     	
    index = index_species(i, atoms_ID[ni]);
    sum_N = sum_N + atoms_N[ni];
    sum_M = sum_M + atoms_N[ni]*i[index].P.MW; 
    i[index].X = 0; i[index].Y = 0; //initialize	
   } 

   for(int ni = 0; ni < atoms_ID.size(); ni++)
   {
    index = index_species(i, atoms_ID[ni]);
    if(molec_def == "X"){i[index].X = i[index].X + j[n].X * atoms_N[ni]/sum_N;}
    if(molec_def == "Y"){i[index].Y = i[index].Y + j[n].Y * atoms_N[ni]*i[index].P.MW/sum_M;}
   } 

   for(int ni = 0; ni < atoms_ID.size(); ni++)
   {
    index = index_species(i, atoms_ID[ni]);
    j[n].P.MW = j[n].P.MW + atoms_N[ni]*i[index].P.MW ;
   } 

   double sum_Y_MW = 0.0; for(int ni = 0; ni < i.size(); ni++){sum_Y_MW += i[ni].Y/i[ni].P.MW;   }
   if(molec_def == "Y"){
   for(int ni = 0; ni < i.size(); ni++){i[ni].X = (i[ni].Y/i[ni].P.MW)/sum_Y_MW;}
   }

  atoms_ID.erase(atoms_ID.begin(),atoms_ID.begin()+atoms_ID.size());
  atoms_N.erase(atoms_N.begin(),atoms_N.begin()+atoms_N.size());

  }
  }
 }

 void flow::initialize_species(vector<species> &spc)
 {
  int n_spc = spc.size();
  if(n_spc > 0)for(int ns = 0; ns < n_spc; ns++){{
  spc[ns].Y = 0; spc[ns].X = 0; 
  spc[ns].P = properties(); 
  spc[ns].F = flow_parameters();
  }}  
 }

 void species::get_species_data_(string spc_type)
 {
  P = properties(); F = flow_parameters();
  string txt, line_txt, symb; int n; double num;

  //cout << "getting data for species: " << id << endl;
  ifstream db;

  if(spc_type == "molecule") {

	 db.open("Flows_library/Flows_database/Molecules_db.txt"); 
	 if(!db.good()){cout << "molecule file not found" << endl; db.close(); return;}

         bool molecule_found = false;
	 while (molecule_found == false) {
		getline(db, line_txt); stringstream sst(line_txt); 
		getline(sst, txt, ' '); 
		if(txt == "Species_id"){ 
			while(getline(sst, txt, ' ')){if(txt == id){molecule_found = true; break;}}
		} 
		if(db.eof()){break;}
	 }
	 if(molecule_found == false) {cout << "molecule " << id << " not found" << endl; db.close(); return;}

	 db >> txt; if(txt == "Composition:"){db >> formula;}
	 db >> txt; if(txt == "NASA"){ db >> txt; if(txt == "yes"){NASA = true;} else {NASA = false; } }
	 db >> txt; if(txt == "thermo_data"){ db >> txt; thermoPkg_file = txt; if(txt == "none"){thermoPkg = false;} else {thermoPkg = true;}} 
	 db >> txt; if(txt == "inputs"){
 	 db >> n;
	 if (n > 0){
		input = true;	
		for (int i=0; i < n; i++){
	    	db >> symb; db >>  num;
     		if (symb == "MW") {P.MW =  num; }
     		if (symb == "hf") {P.hf =  num; }
     		if (symb == "rho_m") {P.rho =  num; }
     		if (symb == "cp_m") {P.cp =  num; }
     		if (symb == "k") {P.k =  num; }
     		if (symb == "visc") {P.visc =  num; }
     		if (symb == "HHV") {P.HHV =  num;} 
     		if (symb == "LHV") {P.LHV =  num;}
     		if (symb == "Tsat") {P.Tsat =  num;}
     		if (symb == "hv") {P.hVap =  num;}
    	   	}
   	}
	else {input = false;}
	}

	db.close();  

  }

  if(spc_type == "atom") {

	db.open("Flows_library/Flows_database/atoms_db.txt");
	if(!db.good()){cout << "atom_file not found" << endl; db.close(); return;}

         bool atom_found = false;
	 while (atom_found == false) {
		getline(db, line_txt); stringstream sst(line_txt); 
		getline(sst, txt, ' '); 
		if(txt == id){ 
			getline(sst, txt, ' '); P.MW = atof(txt.c_str());
			if( getline(sst, txt, ' ') and txt == "valences:"){ while(getline(sst, txt, ' ')){val.push_back(atof(txt.c_str()));}}
			atom_found = true; 
			break; 
		}
		if(db.eof()){break;}
	 }
	 if(atom_found == false) {cout << "atom id not found in the databse" << endl; db.close(); return;}

	db.close();  
  }


}


void flow::get_flow_composition(vector<species> &spc, string input)
{
 string txt, symb, val, line_txt; int n_spc; bool found = false;
 species sp;

 ifstream flow_file; 
 flow_file.open(flow_db); 

 if(!flow_file.good()){cout << "flow_file problem" << endl;}
 if(flow_file.good()){
         bool flow_found = false;
	 while (flow_found == false) {
		getline(flow_file, line_txt); stringstream sst(line_txt); 
		getline(sst, txt, ' '); 
		if(txt == "Flow_def" or txt == "Flow_def:" or txt == "flow_def" or txt == "flow_def:" ){ 
			while(getline(sst, txt, ' ')){if(txt == def){flow_found = true; break;}}
		} 
		if(flow_file.eof()){break;}
	 }
	 if(flow_found == false) {cout << "flow def not found" << endl; flow_file.close(); return;}


	 while (!flow_file.eof()){ 
	 getline(flow_file, line_txt); stringstream sst(line_txt); getline(sst, txt, ' ');
	  if(txt == input) { break;}
	  if(txt == "END") { flow_file.close(); n_spc = 0; return;}
	 }

	 getline(flow_file, line_txt); stringstream sst(line_txt); 
	 getline(sst, txt, ' '); 
	 getline(sst, txt, ' '); 
	 n_spc = atoi(txt.c_str());
	   if (n_spc > 0){
	     for (int n = 0; n < n_spc; n++){
	      getline(flow_file, line_txt); stringstream sst(line_txt);
	      getline(sst, txt, ' '); 
		      if( getline(sst, symb, ' ') ) { 
			getline(sst, val, ' '); 
			spc.push_back(species(txt,atof(val.c_str()),symb));
			if( symb == "Y" and input == "MOLECULES"){molec_def = "Y";}
			if( symb == "X" and input == "MOLECULES"){molec_def = "X";}
			if( symb == "Y" and input == "ATOMS"){atom_def = "Y";}
			if( symb == "X" and input == "ATOMS"){atom_def = "X";}
			if( symb == "Y" and input == "PROXIMATE"){prox_def = "Y";}
			if( symb == "X" and input == "PROXIMATE"){prox_def = "X";}

		      }
		      else if( !getline(sst, symb, ' ') ) { 
			spc.push_back(species(txt)); 
		      }

		      if(input == "MOLECULES") {spc[spc.size()-1].get_species_data_("molecule");}
		      if(input == "ATOMS") {spc[spc.size()-1].get_species_data_("atom");}
		      for(int m = 0; m < 3; m++)
		      {
		       if(input == "ATOMS") { ph[m].i.push_back(spc[spc.size()-1]); }
		       if(input == "MOLECULES") { ph[m].j.push_back(spc[spc.size()-1]); }
		       if(input == "PROXIMATE") { ph[m].k.push_back(spc[spc.size()-1]); }
		      }      
	     }
	   }

 	flow_file.close();
	}
}

void flow::get_flow_properties()
{
 string txt, line_txt, symb; double val; int n;

 ifstream flow_file; flow_file.open(flow_db); 

 if(!flow_file.good()){cout << "flow_file problem" << endl; flow_file.close(); return;}
 if(flow_file.good()){

         bool flow_found = false;
	 while (flow_found == false) {
		getline(flow_file, line_txt); stringstream sst(line_txt); 
		getline(sst, txt, ' '); 
		if(txt == "Flow_def" or txt == "Flow_def:" or txt == "flow_def" or txt == "flow_def:" ){ 
			while(getline(sst, txt, ' ')){if(txt == def){flow_found = true; break;}}
		} 
		if(flow_file.eof()){break;}
	 }
	 if(flow_found == false) {cout << "flow def not found" << endl; flow_file.close(); return;}

	 while (!flow_file.eof()) 
	 {
	  flow_file >> txt; 
	  if(txt == "PROPERTIES"){break;}
	  if(txt == "END"){flow_file.close(); return;}
	 }

	flow_file >> txt; flow_file >> n;
	if (n > 0){
		for (int np = 0; np < n; np++){
			flow_file >> symb; flow_file >> val;
			if (symb == "MW") {P.MW = val; }
			if (symb == "rho_m") {P.rho = val; }
			if (symb == "cp_m") {P.cp = val; }
			if (symb == "k") {P.k = val; }
			if (symb == "visc") {P.visc = val; }
			if (symb == "HHV") {P.HHV = val;} 
			if (symb == "LHV") {P.LHV = val;}
			if (symb == "HHV_dry") {P.HHV_dry = val;} 
			if (symb == "LHV_dry") {P.LHV_dry = val;}
			if (symb == "Tsat") {P.Tsat = val;}
			if (symb == "hv") {P.hVap = val;}
	 	}
	}

	flow_file.close();
 }
}

void flow::get_flow_data(string input_def){

 string line_txt, txt, symb; double val; int n; 
 species spc;

 def = input_def;

 //cout << "getting data for flow: " << def << endl;

 ifstream db_file;
 
 db_file.open("Flows_library/Flows_database/Flow_list.txt");
 if(!db_file.good()){cout << "flow_list file not found" << endl; db_file.close(); return;}
 if(db_file.good()){
         bool flow_found = false;
	 while (flow_found == false) {
		getline(db_file, line_txt); stringstream sst(line_txt); 
		getline(sst, txt, ' '); 
		if(txt == input_def){ 
			flow_found = true;
			getline(sst, cls, ' ');
			getline(sst, flow_db, ' ');
			break;
		} 
		if(db_file.eof()){break;}
	 }

 	if(flow_found == false){cout << "flow is not in the list" << endl; db_file.close(); return;}
 	db_file.close(); 
 }

 ifstream db; 
 db.open(flow_db); 
 if(!db.good()){cout << "flow_db file problem" << endl; db.close(); return;}
 if(db.good()){
         bool flow_found = false;
	 while (flow_found == false) {
		getline(db, line_txt); stringstream sst(line_txt); 
		getline(sst, txt, ' '); 
		if(txt == "Flow_def" or txt == "Flow_def:" or txt == "flow_def" or txt == "flow_def:" ){ 
			while(getline(sst, txt, ' ')){if(txt == def){flow_found = true; break;}}
		} 
		if(db.eof()){break;}
	 }
	 if(flow_found == false) {cout << "flow def not found" << endl; db.close(); return;}

	 bool flow_cls_defined = false;
 
	 while(flow_cls_defined == false){
	 getline(db, line_txt); stringstream sst(line_txt); 
	 getline(sst, txt, ' '); 
	 if(txt == "Flow_cls" or txt == "Flow_cls:" or txt == "flow_cls" or txt == "flow_cls:" ){ 
	 	getline(sst, cls, ' '); flow_cls_defined = true;
	 }
	 }

	 bool prop_data_defined = false;
 
	 while(prop_data_defined == false){
	 getline(db, line_txt); stringstream sst(line_txt); 
	 getline(sst, txt, ' '); 
	 if(txt == "Prop_data" or txt == "Prop_data:" or txt == "prop_data" or txt == "prop_data:" ){ 
	 	getline(sst, prop_data, ' ');
	 	if(prop_data == "refprop"){if(getline(sst, txt, ' ')){thermo_file = txt;}}
		prop_data_defined = true;	
	 }
	 }


 	 db.close();
 }


 if (prop_data != "IDEAL_GAS")
 {
  get_flow_composition(j, "MOLECULES");
  get_flow_composition(i, "ATOMS");
  interpret_molecules();
  //cout << "interpreting molecules" << endl;
  //if(molec_def == "Y") { if(atom_def != "X" or atom_def != "Y") {interpret_molecules();}}
  get_flow_composition(k, "PROXIMATE");
  get_flow_properties();
  //get_flow_chemistry();
 }

 calculate_flow_composition();

}

void flow::mix_flows(flow &f1, flow &f2)
{
 
 F.M = f1.F.M + f2.F.M;
 F.N = f1.F.N + f2.F.N;

 P.LHV = (f1.F.M * f1.P.LHV 
+ f2.F.M * f2.P.LHV)/F.M;

 P.HHV = (f1.F.M * f1.P.HHV + f2.F.M * f2.P.HHV)/F.M;

 F.Ht = f1.F.Ht + f2.F.Ht;

 P.cp = (f1.F.M * f1.P.cp / f1.P.MW + f2.F.N * f2.P.cp / f2.P.MW)/F.M;

 P.rho = F.M / ((f1.F.M / f1.P.rho) + (f2.F.M / f2.P.rho));

 F.T = 25.0 + F.Ht/(F.N * P.cp);

 bool equal_species;

 // Dilute both flows

 if(F.M > 0)for(int n = 0; n < f2.j.size(); n++){f2.j[n].Y = f2.j[n].Y * f2.F.M / F.M;} 
 if(F.M > 0)for(int m = 0; m < f1.j.size(); m++){f1.j[m].Y = f1.j[m].Y * f1.F.M / F.M;} 
 if(F.N > 0)for(int n = 0; n < f2.j.size(); n++){f2.j[n].X = f2.j[n].X * f2.F.N / F.N;} 
 if(F.N > 0)for(int m = 0; m < f1.j.size(); m++){f1.j[m].X = f1.j[m].X * f1.F.N / F.N;} 

 if(F.M > 0)for(int n = 0; n < f2.i.size(); n++){f2.i[n].Y = f2.i[n].Y * f2.F.M / F.M;} 
 if(F.M > 0)for(int m = 0; m < f1.i.size(); m++){f1.i[m].Y = f1.i[m].Y * f1.F.M / F.M;} 
 if(F.N > 0)for(int n = 0; n < f2.i.size(); n++){f2.i[n].X = f2.i[n].X * f2.F.N / F.N;} 
 if(F.N > 0)for(int m = 0; m < f1.i.size(); m++){f1.i[m].X = f1.i[m].X * f1.F.N / F.N;} 

 if(F.M > 0)for(int n = 0; n < f2.k.size(); n++){f2.k[n].Y = f2.k[n].Y * f2.F.M / F.M;} 
 if(F.M > 0)for(int m = 0; m < f1.k.size(); m++){f1.k[m].Y = f1.k[m].Y * f1.F.M / F.M;} 

 for(int n = 0; n < f2.j.size(); n++)
  {
   equal_species = false;
   for(int m = 0; m < f1.j.size(); m++)
   {
    if(f2.j[n].id == f1.j[m].id)
    {
     equal_species = true;
     if(F.M > 0) { j[m].Y = f2.j[n].Y + f1.j[m].Y; }
     if(F.N > 0) { j[m].X = f2.j[n].X + f1.j[m].X; }
    }
   }
   if(equal_species == false)
   {
    j.push_back(f2.j[n]);
    //j[j.size()-1].Y = f2.F.M * f2.j[n].Y / F.M;
   } 
  }

 for(int n = 0; n < f2.i.size(); n++)
  {
   equal_species = false;
   for(int m = 0; m < f1.i.size(); m++)
   {
    if(f2.i[n].id == f1.i[m].id)
    {
     equal_species = true;
     if(F.M > 0) { i[m].Y = f2.i[n].Y + f1.i[n].Y; }
     else if(F.N > 0) { i[m].X = f2.i[n].X + f1.i[m].X; }
    }
   }
   if(equal_species == false)
   {
    i.push_back(f2.i[n]);
   } 
  }

 for(int n = 0; n < f2.k.size(); n++)
  {
   equal_species = false;
   for(int m = 0; m < f1.k.size(); m++)
   {
    if(f2.k[n].id == f1.k[m].id)
    {
     equal_species = true;
     if(F.M > 0) { k[m].Y = f2.k[n].Y + f1.k[m].Y; }
    }
   }
   if(equal_species == false)
   {
    k.push_back(f2.k[n]);
   } 
  }

  //calculate_properties();
}

void flow::print_flow(){

  cout << "-------------------- " << endl;
  cout << "id: " << id << endl;
  cout << "def: " << def << endl;
  cout << "cls: " << cls << endl;
  cout << "prop_data: " << prop_data << endl;
  cout << "M: " << F.M << endl;
  cout << "T: " << F.T << endl;
  cout << "P: " << F.P << endl;
  cout << "LHV dry: " << P.LHV_dry << endl;
  cout << "LHV: " << P.LHV << endl;
  cout << "MW: " << P.MW << endl;
  cout << "cp: " << P.cp << endl;
  cout << "rho: " << P.rho << endl;
  cout << "h: " << P.h << endl;
  cout << "ht: " << P.ht << endl;
  cout << "s: " << P.s << endl;
  cout << "H : " << F.H << endl;
  cout << "Ht : " << F.Ht << endl;
  cout << "Hf : " << F.Hf << endl;
  cout << "-------------------- " << endl;
  if(i.size() == 0){cout << " atomic composition is not defined" << endl;}	
  if(i.size() > 0){
  	cout << "Atomic composition: " << endl;
  	cout << "------------------- " << endl;	
  	for(int n = 0; n < i.size(); n++){cout << i[n].id << " X: " << i[n].X << " Y: " << i[n].Y << endl;}
  } 
  cout << "-------------------- " << endl;
  if(j.size() == 0){cout << " molecular composition is not defined" << endl;}	
  if(j.size() > 0){
  	cout << "Molecular composition: " << endl;
  	cout << "------------------- " << endl;	
  	for(int n = 0; n < j.size(); n++){cout << j[n].id << " MW: " << j[n].P.MW << " X: " << j[n].X << " Y: " << j[n].Y << endl;} 
  }
  cout << "-------------------- " << endl;
  if(k.size() == 0){cout << " proximate composition is not defined" << endl;}	
  if(k.size() > 0){
  	cout << "Proximate composition: " << endl;
  	cout << "------------------- " << endl;	
  	for(int n = 0; n < k.size(); n++){cout << k[n].id << " X: " << k[n].X << " Y: " << k[n].Y << endl;} 
  }

}

bool find_flow(string input_def){

 	ifstream db_file;

	string line_txt, txt, flow_cls, flow_db, error = input_def + " not found in the database";
 
 	db_file.open("Flows_library/Flows_database/Flow_list.txt");

 	if(!db_file.good()){ cout << error << endl; db_file.close(); return false;}
 	if(db_file.good()){
         	bool flow_found = false;
	 	while (flow_found == false) {
			getline(db_file, line_txt); stringstream sst(line_txt); 
			getline(sst, txt, ' '); 
			if(txt == input_def){ 
				flow_found = true;
				getline(sst, flow_cls, ' ');
				getline(sst, flow_db, ' ');
				break;
			} 
			if(db_file.eof()){break;}
	 	}

 		if(flow_found == false){cout << error << endl; db_file.close(); return false;}
	}

	db_file.close(); 

 	ifstream db; 
 	db.open(flow_db); 
 	if(!db.good()){cout << error << endl; db.close(); return false;}
 	if(db.good()){
         	bool flow_found = false;
	 	while (flow_found == false) {
			getline(db, line_txt); stringstream sst(line_txt); 
			getline(sst, txt, ' '); 
			if(txt == "Flow_def" or txt == "Flow_def:" or txt == "flow_def" or txt == "flow_def:" ){ 
				while(getline(sst, txt, ' ')){if(txt == input_def){flow_found = true; return true;}}
			} 
			if(db.eof()){break;}
		 }
		//if(flow_found == false) {cout << error << endl; db.close(); return false;}
		return false;
	}


 }


