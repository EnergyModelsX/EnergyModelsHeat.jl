using namespace std;
void unit_conversion(double &value, thermo_data model, string unit){
	if (unit == "DEFAULT" || model.unit == unit){
		return;
	}	
	else if (model.unit == "K" || model.unit == "KELVIN"){
		if (unit == "K" || model.unit == "KELVIN"){
			return;
		}
		else if (unit == "C" || unit == "CELSIUS" || "DEGC"){
			value -= 273.15;
			return;
		}
		else {
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "C" || model.unit == "CELSIUS" || model.unit == "DEGC"){
		if (unit == "C" || unit == "CELSIUS" || unit == "DEGC"){
			return;
		}
		else if (unit == "K" || unit == "KELVIN"){
			value += 273.15;
			return;
		}
		else {
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "PA" || model.unit == "PASCAL"){
		if (unit == "PA" || unit == "PASCAL"){
			return;
		}
		else if (unit == "KPA" || unit == "KILOPASCAL"){
			value = value*1e3;
			return;
		}
		else if (unit == "MPA" || unit == "MEGAPASCAL"){
			value = value*1e6;
			return;
		}
		else if (unit == "BAR"){
			value = value/1e5;
			return;
		}
		else if (unit == "MMHG"){
			value = value*0.00750062;
			return;	
		}
		else {
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "BAR"){
		if (unit == "PA" || unit == "PASCAL"){
			value = value*1e5;
			return;
		}
		else if (unit == "KPA" || unit == "KILOPASCAL"){
			value = value*100;
			return;
		}
		else if (unit == "MPA" || unit == "MEGAPASCAL"){
			value = value*0.1;
			return;
		}
		else if (unit == "MMHG"){
			value = value*750.062;
			return;
		}
		else {
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "MMHG"){
		if (unit == "PA" || unit == "PASCAL"){
			value = value/0.00750062;
			return;
		}
		else if (unit == "KPA" || unit == "KILOPASCAL"){
			value = value/7.50062;
			return;
		}
		else if (unit == "MPA" || unit == "MEGAPASCAL"){
			value = value/7500.62;
			return;
		}
		else if (unit=="BAR"){
			value = value/750.062;
			return;
		}
		else {
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "J/MOL" || model.unit == "J/MOLK" || model.unit == "J/MOLC"){
		if (unit == "J/KMOL" || unit == "J/KMOLK" || unit == "J/KMOLC"){
			value = value/1e3;
			return;
		}
		else if (unit == "J/KG" || unit == "J/KGK" || unit == "J/KGC"){
			value = value*1e3/model.MW;
			return;
		}
		else if (unit == "KJ/MOL" || unit == "KJ/MOLK" || unit == "KJ/MOLC" ){
			value = value/1e3;
			return;
		}
		else if (unit == "KJ/KMOL" || unit == "KJ/KMOLK" || unit == "KJ/KMOLC" ){
			return;
		}
		else if (unit == "KJ/KG" || unit == "KJ/KGK" || unit == "KJ/KGC" ){
			value = value/model.MW;
			return;
		}
		else{
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "J/KMOL" || model.unit == "J/KMOLK" || model.unit == "J/KMOLC"){
		if (unit == "J/MOL" || unit == "J/MOLK" || unit == "J/MOLC"){
			value = value/1e3;
			return;
		}
		else if (unit == "KJ/KMOL" || unit == "KJ/KMOLK" || unit == "KJ/KMOLC"){
			value = value/1e3;
			return;
		}
		else if (unit == "KJ/MOL" || unit == "KJ/MOLK" || unit == "KJ/MOLC"){
			value = value/1e6;
			return;
		}
		else if (unit == "J/KG" || unit == "J/KGK" || unit == "J/KGC"){
			value = value/model.MW;
			return;
		}
		else if (unit == "KJ/KG" || unit == "KJ/KGK" || unit == "KJ/KGC"){
			value = value/(1e3*model.MW);
			return;
		}
		else{
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "KJ/MOL" || model.unit == "KJ/MOLK" || model.unit == "KJ/MOLC"){
		if (unit == "J/MOL" || unit == "J/MOLK" || unit == "J/MOLC"){
			value = value*1e3;
			return;
		}
		else if (unit == "J/KMOL" || unit == "J/KMOLK" || unit == "J/KMOLC"){
			value = value*1e6;
			return;
		}
		else if (unit == "KJ/KMOL" || unit == "KJ/KMOLK" || unit == "KJ/KMOLC"){
			value = value*1e3;
			return;
		}
		else if (unit == "J/KG" || unit == "J/KGK" || unit == "J/KGC"){
			value = value*1e6/model.MW;
			return;
		}
		else if (unit == "KJ/KG" || unit == "KJ/KGK" || unit == "KJ/KGC"){
			value = value*1e3/model.MW;
			return;
		}
		else{
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "KJ/KMOL" || model.unit == "KJ/KMOLK" || model.unit == "KJ/KMOLC"){
		if (unit == "J/MOL" || unit == "J/MOLK" || unit == "J/MOLC"){
			return;
		}
		else if (unit == "KJ/MOL" || unit == "KJ/MOLK" || unit == "KJ/MOLC"){
			value = value/1e3;
			return;
		}
		else if (unit == "J/KMOL" || unit == "J/KMOLK" || unit == "J/KMOLC"){
			value = value*1e3;
			return;
		}
		else if (unit == "KJ/KG" || unit == "KJ/KGK" || unit == "KJ/KGC"){
			value = value/model.MW;
			return;
		}
		else if (unit == "J/KG" || unit == "J/KGK" || unit == "J/KGC"){
			value = value*1e3/model.MW;
			return;
		}
		else{
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "J/KG" || model.unit == "J/KGK" || model.unit == "J/KGC"){
		if (unit == "KJ/KG" || unit == "KJ/KGK" || unit == "KJ/KGC"){
			value = value/1e3;
			return;
		}
		else if (unit == "J/KMOL" || unit == "J/KMOLK" || unit == "J/KMOLC"){
			value = value*model.MW;
			return;
		}
		else if (unit == "J/MOL" || unit == "J/MOLK" || unit == "J/MOLC"){
			value = value*model.MW/1e3;
			return;
		}
		else if (unit == "KJ/MOL" || unit == "KJ/MOLK" || unit == "KJ/MOLC"){
			value = value*model.MW/1e6;
			return;
		}
		else if (unit == "KJ/KMOL" || unit == "KJ/KMOLK" || unit == "KJ/KMOLC"){
			value = value*model.MW/1e3;
			return;
		}
		else{
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}
	else if (model.unit == "KJ/KG" || model.unit == "KJ/KGK" || model.unit == "KJ/KGC"){
		if (unit == "J/MOL" || unit == "J/MOLK" || unit == "J/MOLC"){
			value = value*model.MW;
			return;
		}
		else if(unit == "KJ/MOL" || unit == "KJ/MOLK" || unit == "KJ/MOLC"){
			value = value*model.MW/1e3;
			return;
		}
		else if (unit == "KJ/KMOL" || unit == "KJ/KMOLK" || unit == "KJ/KMOLC"){
			value = value*model.MW;
			return;
		}
		else if (unit == "J/KMOL" || unit == "J/KMOLK" || unit == "J/KMOLC"){
			value = value*model.MW*1e3;
			return;
		}
		else if (unit == "J/KG" || unit == "J/KGK" || unit == "J/KGC"){
			value = value*1e3;
			return;
		}
		else{
			cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
			return;
		}
	}		
	else{
		cout<<"Caution: Unsupported output unit "<<unit<<" switching to default unit "<<model.unit <<endl;
		return;
	}			

}

