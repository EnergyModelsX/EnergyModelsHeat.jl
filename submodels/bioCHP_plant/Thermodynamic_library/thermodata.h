#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <boost/algorithm/string.hpp>
#include <string.h>
#include <vector> 
using namespace std;

//Function declarations:
void upper_case(string &str);
void upper_case(string &str1, string &str2);
void upper_case(string &str1, string &str2, string &str3);

//thermo data from input file
//properties tables are given at a constant pressure level, and provide the property as a function of temperature
//Exhaustive data tables should be used for high accuracy!

struct list_data{
	double cons;//Constant independent property (pressure or temperature) 
	vector<double> var;//variable independent property (pressure or temperature)
	vector<double> P;//Dependent property
};

struct model_data{
	string model_type;
	vector<string> constant_list;
	vector<double> constant_values;
};

struct thermo_data{
	string id, property_type, data_type, function_dependence, unit; 
	bool extrapolate = false;
	double MW;
	double min = -1e4; 
	double max = 1e4; //Validity (minimum and maximum limits)
	list_data lData; //if data list is used
	model_data mData; //if model list is used
};

/********************************************************************************************************/
/************************************FUNCTION EXTRACT THERMODATA*****************************************/
/********************************************************************************************************/
//Information: extracts all the property data from a given input file:

void extract_thermo_data(vector<thermo_data> &thermo, string input_file){
	ifstream td_file;
	td_file.open(input_file);
	if( !td_file.good() ) {cout << "input file not found " << endl; return;}
 
	thermo_data td; string line_txt, txt, str; double Temp, Prop; bool prop_set_found = false, compound_type_found = false;
  
	while (!td_file.eof()){
		if(!compound_type_found) {getline(td_file, line_txt);}
		stringstream sst(line_txt); getline(sst, txt, ' ');
		//convert to upper_case to avoid case sensitivity:
		upper_case(txt);
		if( txt == "COMPOUND:" || txt == "COMPOUND"){ 
			getline(sst, td.id, ' ');
			upper_case(td.id); 
			prop_set_found = false;
			while( prop_set_found == false ){
				getline(td_file, line_txt); 
				stringstream sst(line_txt); getline(sst, txt, ' '); 
				upper_case(txt);
				if (txt == "PROPERTY:" || txt == "PROPERTY"){
					getline(sst,td.property_type,' ');
					upper_case(td.property_type);
				}
				//Specifies whether the data are provided using either a list or a model.
				else if (txt == "DATA:" || txt == "DATA"){
					getline(sst,td.data_type,' ');
					upper_case(td.data_type);
				}
				else if (txt == "EXTRAPOLATION:" || txt == "EXTRAPOLATION"){
					getline(sst, str, ' ');
					upper_case(str);
					if (str == "YES"){
						td.extrapolate = true;
					}
					else{
						td.extrapolate = false;
					}
				}
				else if (txt == "UNIT:" || txt == "UNIT"){
					getline(sst,td.unit,' ');
					upper_case(td.unit);
				}
				else if (txt == "MW:"){
						getline(sst,str, ' ');
						td.MW = atof(str.c_str());
				}
				//Valid interval:
				else if (txt == "VALIDITY:" || txt == "VALIDITY"){
					vector<double> validity;
					double min, max;
					while(getline(sst, str,' ')){
						validity.push_back(atof(str.c_str()));
					}
					if (validity.size()>0){
						min = validity[0];
						max = validity[0];
						for(int i=0;i<validity.size();i++){
							double temp=validity[i];
							if (min > temp){
								min = temp;
							}
							else if (max < temp){
							max = temp;
							}
						}
						td.min = min; td.max = max;
					}
				}
				//Check whether the property is dependent on temperature or pressure:
				else if (txt == "DEPENDENCE:" || txt == "DEPENDENCE"){
					getline(sst,td.function_dependence,' ');
					upper_case(td.function_dependence);
				}
				//Deals with properties given in list form:
				else if (td.data_type == "LIST"){
					//Check at which isobar or isotherm the property remains valid
					if (txt == "CONSPROP:" || txt == "CONSTANT PROPERTY:" || txt == "ISOBAR:" ||txt == "ISOTERM"){ 
						getline(sst,str, ' ');
						td.lData.cons = atof(str.c_str());
					}
					//Independent property:
					else if (txt == "VAR:" || txt == "VARIABLE:" || txt == "VARIABLE") {
						while(getline(sst, str, ' ')){ td.lData.var.push_back(atof(str.c_str()));} 
					}
					//Dependendent property: 
					else if (txt == "PROP:" || txt == "PROPERTY:" || txt == "PROPERTY"){
						while(getline(sst, str, ' ')){ td.lData.P.push_back(atof(str.c_str()));}
					}
					//If non of the above are read, we have moved on to the next element
					else{
						prop_set_found = true;
						if( txt == "COMPOUND:" || txt == "COMPOUND") {compound_type_found = true;}
						if( txt != "COMPOUND:" || txt != "COMPOUND") {compound_type_found = false;}
						thermo.push_back(td); 
						//Delete vector for next entry:
						td.lData.var.clear(); td.lData.P.clear(); td.min = -1e4; td.max = 1e4; td.extrapolate = false; td.lData.cons = 0.0;
						td.data_type = "VOID"; td.property_type = "VOID"; td.id="VOID"; td.function_dependence = "VOID";
					}
				}
				//Deals with properties given in model form:
				else if (td.data_type == "MODEL"){
					if (txt == "MODEL:" || txt == "MODEL"){
						getline(sst, td.mData.model_type, ' ');
						upper_case(td.mData.model_type); 
					}
					else if (txt == "CONSTANTS:" || txt == "CONSTANTS" ){
						while(getline(sst, str, ' ')){ td.mData.constant_list.push_back(str);} 
					}
					else if (txt == "VALUES:" || txt == "VALUES"){
						while(getline(sst, str, ' '))
						{
							td.mData.constant_values.push_back(atof(str.c_str()));
						} 
					}
					else{
						prop_set_found = true;
						if( txt == "COMPOUND:" || txt == "COMPOUND") {compound_type_found = true;}
						if( txt != "COMPOUND:" || txt != "COMPOUND") {compound_type_found = false;}
						thermo.push_back(td);
						//Delete vector for next entry:
						td.mData.constant_list.clear(); td.mData.constant_values.clear(); td.min = -1e4; td.max = 1e4;
						td.data_type = "VOID"; td.property_type = "VOID"; td.id="VOID"; td.function_dependence = "VOID";
						td.mData.model_type ="VOID"; td.extrapolate = false;
					}
				}
				else{
					prop_set_found = true;
					if( txt == "COMPOUND:" || txt != "COMPOUND") {compound_type_found = true;}
					if( txt != "COMPOUND:" || txt != "COMPOUND") {compound_type_found = false;}
					thermo.push_back(td); td.min = -1e4; td.max = 1e4; td.extrapolate = false;
					td.data_type = "VOID"; td.property_type = "VOID"; td.id="VOID"; td.function_dependence = "VOID";
					//clear the vectors:
					if (td.data_type == "LIST"){
						td.lData.var.clear(); td.lData.P.clear();
					}
					else if (td.data_type == "MODEL"){
						td.mData.constant_list.clear(); td.mData.constant_values.clear();
					}
				}
			}
		}		
	}
	td_file.close();
} 


/********************************************************************************************************/
/*************************************FUNCTION EXTRACT PROPERTY******************************************/
/********************************************************************************************************/
//Information: extracts only the property data needed from a given input file:

bool extract_property(thermo_data &thermo, string property, double T, double P, string input_file){
	//Convert to upper case:
	upper_case(property);

	ifstream td_file;
	td_file.open(input_file);
	if( !td_file.good() ) {cout << "input file not found " << endl; return false;}
 
	thermo_data td; string line_txt, txt, str; double Temp, Prop; bool prop_set_found = false; bool property_found= false;

	while (!td_file.eof() && !property_found){
		getline(td_file, line_txt);
		stringstream sst(line_txt); getline(sst, txt, ' ');
		//convert to upper_case to avoid case sensitivity:
		upper_case(txt);
		if( txt == "PROPERTY:" || txt == "PROPERTY"){ 
			getline(sst, td.property_type, ' ');
			upper_case(td.property_type); 
			if(td.property_type == property){
				prop_set_found = false;
				while(prop_set_found == false){
					getline(td_file, line_txt); 
					stringstream sst(line_txt); getline(sst, txt, ' '); 
					upper_case(txt);
					//Specifies whether the data are provided using either a list or a model.
					if (txt == "DATA:" || txt == "DATA"){
						getline(sst,td.data_type,' ');
						upper_case(td.data_type);
					}
					else if (txt == "UNIT:" || txt == "UNIT"){
						getline(sst,td.unit,' ');
						upper_case(td.unit);
					}
					else if (txt == "EXTRAPOLATION:" || txt == "EXTRAPOLATION"){
						getline(sst, str, ' ');
						upper_case(str);

						if (str == "YES"){
							td.extrapolate = true;
						}
						else{
							td.extrapolate = false;
						}
				}
					else if (txt == "MW:" || txt == "MW"){
						getline(sst,str, ' ');
						td.MW = atof(str.c_str());
					}
					//Check whether the property is dependent on temperature or pressure:
					else if (txt == "DEPENDENCE:" || txt == "DEPENDENCE"){
						getline(sst,td.function_dependence,' ');
						upper_case(td.function_dependence);
					}
					//Valid interval:
					else if (txt == "VALIDITY:" || txt == "VALIDITY"){
						td.min = -1e4; td.max = 1e4;
						vector<double> validity;
						double min, max;
						while(getline(sst, str,' ')){
							validity.push_back(atof(str.c_str()));
						}
						if (validity.size()>0){
							min = validity[0];
							max = validity[0];
							for(int i=0;i<validity.size();i++){
								double temp=validity[i];
								if (min > temp){
									min = temp;
								}
								else if (max < temp){
								max = temp;
								}
							}
							td.min = min; td.max = max;
						}
					}
					//Deals with properties given in list form:
					else if (td.data_type == "LIST"){
						//Check at which isobar or isotherm the property remains valid
						if (txt == "CONSPROP:" || txt == "CONSTANT PROPERTY:" || txt == "ISOBAR:" ||txt == "ISOTERM"){ 
							getline(sst,str, ' ');
							td.lData.cons = atof(str.c_str());
						}
						//Independent property:
						else if (txt == "VAR:" || txt == "VARIABLE:" || txt == "VARIABLE") {
							while(getline(sst, str, ' ')){ td.lData.var.push_back(atof(str.c_str()));} 
						}
						//Dependendent property: 
						else if (txt == "PROP:" || txt == "PROPERTY:" || txt == "PROPERTY"){
							while(getline(sst, str, ' ')){ td.lData.P.push_back(atof(str.c_str()));}
						}
						//If non of the above are read, we have moved on to the next element
						else{
							prop_set_found = true;
							if (td.function_dependence == "TEMPERATURE"){
								if(T>=td.min && T<=td.max){
									thermo =td; 
									property_found = true;
								}
								else if (td.extrapolate){//list can be extrapolated
									thermo = td;
									property_found = true;
								}
							}
							else if (td.function_dependence == "PRESSURE"){
								if(P>=td.min && P<=td.max){
									thermo = td; 
									property_found = true;
								}
								else if (td.extrapolate){//list can be extrapolated
									thermo = td;
									property_found = true;
								}
							}							
						}
					}
					//Deals with properties given in model form:
					else if (td.data_type == "MODEL"){
						if (txt == "MODEL:" || txt == "MODEL"){
							getline(sst, td.mData.model_type, ' ');
							upper_case(td.mData.model_type); 
						}
						else if (txt == "CONSTANTS:" || txt == "CONSTANTS" ){
							while(getline(sst, str, ' ')){ td.mData.constant_list.push_back(str);} 
						}
						else if (txt == "VALUES:" || txt == "VALUES"){
							while(getline(sst, str, ' '))
							{
								td.mData.constant_values.push_back(atof(str.c_str()));
							} 
						}
						else{
							prop_set_found = true;
							if (td.function_dependence == "TEMPERATURE"){
								if(T>=td.min && T<=td.max){
									thermo =td; 
									property_found = true;
								}
								else if (td.extrapolate){//model can be extrapolated
									thermo = td;
									property_found = true;
								}
							}
							else if (td.function_dependence == "PRESSURE"){
								if(P>=td.min && P<=td.max){
									thermo =td; 
									property_found = true;
								}
								else if (td.extrapolate){//model can be extrapolated
									thermo = td;
									property_found = true;
								}
							}							
						}
					}
					else{
						prop_set_found = true;
					}
				}
			}
		}	
	}
	td_file.close();
	return property_found;
} 


/********************************************************************************************************/
/**********************************FUNCTION GET SPECIES THERMODATA***************************************/
/********************************************************************************************************/
//Information: Retrieves all the Thermodata for a given species


void get_species_thermo_data(vector<thermo_data> &thermo, string species_id, string database_file = "Thermodynamic_library/Thermodynamic_database/Species_thermofile_list"){
	ifstream data_file;
	data_file.open(database_file);
	if( !data_file.good() ) {cout << "input file not found " << endl; return;}
	string line_txt, txt, id, composition, path;
	bool path_found = false;
	bool species_found = false;
	//convert species_id to upper case:
	upper_case(species_id);

	while (!data_file.eof() && !path_found){
		getline(data_file, line_txt);
		stringstream sst(line_txt); getline(sst, txt, ' ');
		upper_case(txt);
		if (txt == "COMPOUND:" || txt == "COMPOUND"){
			getline(sst, id, ' ');
			//Convert to upper case only:
			upper_case(id);
		}
		else if (txt == "COMPOSITION:" || txt == "COMPOSITION"){
			getline(sst, composition, ' ');
			//Convert to upper case only:
			upper_case(composition);
		}
		else if (txt == "FILE:" || txt == "FILE"){
			//only extract the path if we have the correct species:
			if (id == species_id || composition == species_id){
				getline(sst, path, ' ');
				path_found = true;
			}
		}
	}
	//Close file:
	data_file.close();
	//Error if species cannot be found
	if (path_found == false){
		cout<<"Error: Species "<<species_id<<" is not in the property database"<<endl;
		cout<<"You need to add species to the database list and upload property parameters to use this package!"<<endl;
	}
	else{
		extract_thermo_data(thermo, path);
	}
}


/********************************************************************************************************/
/*************************************FUNCTION GET PROPERTY DATA*****************************************/
/********************************************************************************************************/
//Information: Retrieves specific property data for a given species
//Returns false if the property data cannot be retreived

bool get_property_data(thermo_data &thermo, string species_id, string property_id, double T, double P){

	string line_txt, txt, id, composition, path, molec_db;

	ifstream data_file;

	data_file.open("Flows_library/Flows_database/Molecules_db.txt");
	if( !data_file.good() ) {cout << "input file not found" << endl; return false;}

	bool path_found = false;
	bool species_found = false;
	//convert species_id to upper case:
	upper_case(species_id);

	while (!data_file.eof() && !path_found){
		getline(data_file, line_txt);
		stringstream sst(line_txt); getline(sst, txt, ' ');
		upper_case(txt);
		if (txt == "SPECIES_ID:" || txt == "SPECIES_ID"){
			getline(sst, id, ' ');
			//Convert to upper case only:
			upper_case(id);
		}
		else if (txt == "COMPOSITION:" || txt == "COMPOSITION"){
			getline(sst, composition, ' ');
			//Convert to upper case only:
			upper_case(composition);
		}
		else if (txt == "THERMO_DATA:" || txt == "THERMO_DATA"){
			//only extract the path if we have the correct species:
			if (id == species_id || composition == species_id){
				getline(sst, path, ' ');
				path_found = true;
			}
		}
	}
	//Close file:
	data_file.close();
	//Error if species cannot be found
	if (path_found == false){
		cout<<"Error: Species "<<species_id<<" is not in the property database"<<endl;
		cout<<"You need to add species to the database list and upload property parameters to use this package!"<<endl;
		return false;
	}
	else{
		thermo.id = id;
		bool found;
		found = extract_property(thermo, property_id, T, P, path);
		if(!found){
			cout<<"Error: A valid model for "<<property_id<<" for species "<<species_id<<" is not in the property database"<<endl;
			cout<<"You need to add property model to the file "<<path<<endl;
			return false;
		}
		return true;
	}
}

//function: search_thermo_data
//Returns the index of the thermo data in the vector of thermo data (-1 if does not exist)
int search_thermo_data(vector<thermo_data> &thermo, string id, string property_type){
	//Upper case used to make the search case insensitive:
	upper_case(id, property_type);
	for (int n = 0; n<thermo.size(); n++){
		if (thermo[n].id == id && thermo[n].property_type == property_type){
			return n;
		}
	}
	//cout << '\n'<< "Error: Property: " << property_type << " for species: " << id <<" does not exist in the list!"<< endl;

	return -1;   
}

//overloaded function:
//function: search_thermo_data
//Returns the index of the thermo data in the vector of thermo data provided it is within the valid interval (returns -1 if not)
//inputs:
//id: Type of compound
//property_type: type of property
//dependence: function dependence
//atVal: at value for which we need a correlation
int search_thermo_data(vector<thermo_data> &thermo, string id, string property_type, string function_dependence, double atVal){
	//Use upper case to make the search case insensitive:
	upper_case(id, property_type, function_dependence);
	for (int n = 0; n<thermo.size(); n++){
		if (thermo[n].id == id && thermo[n].property_type == property_type && thermo[n].function_dependence == function_dependence){
			if (atVal >= thermo[n].min && atVal<= thermo[n].max){
				return n;
			}
		}
	}
	cout << '\n'<< "Error: Property for species: "<< id<< '\n';
	cout <<" as a function of "<<function_dependence<< " at value: "<<atVal<< " has not been provided"<<endl;

	return -1;   
}


//overloaded function 2:
//function: search_thermo_data
//Returns the index of the thermo data in the vector provided the Temperature or Pressure inputs are valid:
//inputs:
//id: Type of compound
//property_type: type of property
//dependence: function dependence
//atVal: at value for which we need a correlation
int search_thermo_data(vector<thermo_data> &thermo, string id, string property_type, double T, double P){
	//Use upper case to make the search case insensitive:
	upper_case(id, property_type);
	for (int n = 0; n<thermo.size(); n++){
		if (thermo[n].id == id && thermo[n].property_type == property_type){
			if (thermo[n].function_dependence == "TEMPERATURE"){
				if (T >= thermo[n].min && T<= thermo[n].max){
					return n;
				}
			}
			else if (thermo[n].function_dependence == "PRESSURE"){
				if (P >= thermo[n].min && P<= thermo[n].max){
					return n;
				}				
			} 
		}
	}
	cout << '\n'<< "Error: Property for species: "<< id<< '\n';
	cout <<" for temperature: "<<T<< " and pressure: "<<P<<" has not been provided"<<endl;

	return -1;   
}

//String upper case functions:
void upper_case(string &str){
	transform(str.begin(), str.end(), str.begin(), ::toupper); 
}

void upper_case(string &str1, string &str2){
	transform(str1.begin(), str1.end(), str1.begin(), ::toupper); 
	transform(str2.begin(), str2.end(), str2.begin(), ::toupper); 
}

void upper_case(string &str1, string &str2, string &str3){
	transform(str1.begin(), str1.end(), str1.begin(), ::toupper); 
	transform(str2.begin(), str2.end(), str2.begin(), ::toupper); 
	transform(str3.begin(), str3.end(), str3.begin(), ::toupper); 
}

//Get property from list data:
//interpolates between closest values in the vector!
//inputs:
//list
//indVar - independent variable
double property_from_list_data(list_data &list, double indVar){
	double prev, cur, prev_prop, cur_prop;//previous and current value in list	
	prev = list.var[0];
	prev_prop = list.P[0];
	bool exit = false; //becomes true, once interpolation has been performed
	int i = 1;
	// if lower than the smallest value, extrapolation is necessary:
	if (indVar <= prev){
		cur = list.var[1];
		cur_prop = list.P[1];
		//Extrapolation:
		return prev_prop + ((cur_prop-prev_prop)/(cur-prev))*(indVar - prev);	
	}
	while (i<list.var.size() && !exit){
		cur = list.var[i];
		cur_prop = list.P[i];
		if (indVar >= prev && indVar < cur){
			exit = true;
		}else{ 
			prev = cur;
			prev_prop = cur_prop;
			i++;
		}
	}
	//update values for interpolation:
	prev = list.var[i-1]; cur = list.var[i]; prev_prop = list.P[i-1]; cur_prop = list.P[i];

	return prev_prop + ((cur_prop-prev_prop)/(cur-prev))*(indVar - prev);	
}

/********************************************************************************************************/
/************************************************PRINT***************************************************/
/********************************************************************************************************/
//Output functions:
void print_list_data(list_data &list){
	cout<<'\n'<< "Constant property: "<< list.cons<<endl;
	cout<<'\n'<<"Independent property:"<<endl;
	for( int k = 0; k < list.var.size(); k++ ) {  if (k == 0){cout<<'\n';} cout << " " << list.var[k];}
	cout<<'\n'<<"Dependent property:"<<endl;
	for( int k = 0; k < list.P.size(); k++ ) { if (k == 0){cout<<'\n';} cout << " " << list.P[k];}
	cout<<endl;
}

void print_model_data(model_data model){
	cout<<'\n'<<"Model type: "<< model.model_type<<endl;
	cout<<'\n'<<"List of constants: "<<endl;
	for( int k = 0; k < model.constant_list.size(); k++ ) {  if (k == 0){cout<<'\n';} cout << " " << model.constant_list[k];}
	cout<<'\n'<<"Constant values: "<<endl;
	for( int k = 0; k < model.constant_values.size(); k++ ) { if (k == 0){cout<<'\n';}cout << " " << model.constant_values[k];}
	cout<<endl;
}

void print_thermo_data(vector<thermo_data> &td){
	if (td.size() == 0){
		cout<<"No property data exist!"<<endl;
	}
	else{
		cout<< "no. listed property data: " << td.size() << endl;
		cout<< '\n' <<"***************************************************************************"<<endl;
		cout<<'\n'<<"                                 COMPOUND"<<endl;
		cout<<'\n'<<"                                 "<<td[0].id<<endl;
		cout<< '\n' <<"***************************************************************************"<<endl;
		for( int n = 0; n < td.size(); n++) 
		{
			cout<< '\n' <<"---------------------------------------------------------------------------"<<endl;
			cout << '\n'<<"Molecular weight" << " "<<td[n].MW << endl;
			cout << '\n'<<"Property type" << " "<<td[n].property_type << endl;
			cout << '\n'<<"Data type: " << td[n].data_type <<endl;
			if (td[n].extrapolate){
				cout << '\n'<<"Extrapolation: yes" << endl;
			}else{
				cout << '\n'<<"Extrapolation: no" << endl;
			}
			cout << '\n'<<"Unit: " << td[n].unit <<endl;
			if (td[n].data_type == "LIST"){			
				print_list_data(td[n].lData);
			}
			else if (td[n].data_type == "MODEL"){
				print_model_data(td[n].mData);
			}

			cout<<'\n'<<"Valid for inputs of type " << td[n].function_dependence<<" in the interval: "<<td[n].min<<" to ";
			cout<<td[n].max<<endl;
		}  
		cout<< '\n' <<"---------------------------------------------------------------------------"<<endl;
	}
	
} 

void print_thermo_data(thermo_data &td){
	cout<< '\n' <<"***************************************************************************"<<endl;
	cout<<'\n'<<"                                 COMPOUND"<<endl;
	cout<<'\n'<<"                                 "<<td.id<<endl;
	cout<< '\n' <<"***************************************************************************"<<endl;
	cout<< '\n' <<"---------------------------------------------------------------------------"<<endl;
	cout << '\n'<<"Molecular weight" << " "<<td.MW << endl;
	cout << '\n'<<"Property type" << " "<<td.property_type << endl;
	cout << '\n'<<"Data type: " << td.data_type <<endl;
	if (td.extrapolate){
		cout << '\n'<<"Extrapolation: yes" << endl;
	}else{
		cout << '\n'<<"Extrapolation: no" << endl;
	}
	cout << '\n'<<"Unit: " << td.unit <<endl;
	if (td.data_type == "LIST"){			
		print_list_data(td.lData);
	}
	else if (td.data_type == "MODEL"){
		print_model_data(td.mData);
	}

	cout<<'\n'<<"Valid for inputs of type " << td.function_dependence<<" in the interval: "<<td.min<<" to ";
	cout<<td.max<<endl;  
	cout<< '\n' <<"---------------------------------------------------------------------------"<<endl;
	
	
} 
