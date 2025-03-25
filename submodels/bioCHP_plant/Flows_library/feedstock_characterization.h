#include <string>
//#include <boost/array.hpp>

void Heating_Value(flow &feed);

void raw_feedstock_characterization(flow &feed, string feed_def){
 
	// GdAS 03.03.2020
	double cp=0.0, rho=0.0, cp_DM=0.0, rho_DM=0.0, cp_H2O=0.0, rho_H2O=0.0, VDM_VH2O=0.0;
 
	double kH2O = -2.5;

	
	//WOOD:
	if (feed_def=="spruce_stem"){
		//atomic composition:
		feed.i.push_back(species("C",0.4738, 12.01)); feed.i.push_back(species("H", 0.064, 1.01));
		feed.i.push_back(species("O", 0.461, 16.00)); feed.i.push_back(species("N", 0.0009, 14.01));
		feed.i.push_back(species("S", 0.0001, 32.06));
		//proximates:
		feed.k.push_back(species("VOL",0.7243)); feed.k.push_back(species("FC", 0.2727)); feed.k.push_back(species("ash", 0.003));
		//properties:
		feed.P.LHV_dry = 19.9;
	}
	else if (feed_def=="spruce_bark"){
			//atomic composition:
			feed.i.push_back(species("C",0.4909,12.01)); feed.i.push_back(species("H",0.0606, 1.01)); 
			feed.i.push_back(species("O",0.4438,16.00)); feed.i.push_back(species("N",0.0045,14.01));
			feed.i.push_back(species("S",0.0002,32.06));

			//proximates:	
  			feed.k.push_back(species("VOL", 0.7062)); feed.k.push_back(species("FC", 0.2685)); 
			feed.k.push_back(species("ash", 0.0253));

			//properties:
			feed.P.LHV_dry = 20.25;
	}
	else if (feed_def=="spruce_T&B"){
			//atomic composition:
			feed.i.push_back(species("C", 0.5153, 12.01)); feed.i.push_back(species("H", 0.0651,1.01)); 
			feed.i.push_back(species("O", 0.415,16.00)); feed.i.push_back(species("N",0.0044,14.01)); 
			feed.i.push_back(species("S", 0.0002,32.06));
			
			//proximates:
  			feed.k.push_back(species("VOL",0.6982)); feed.k.push_back(species("FC", 0.2449)); 
			feed.k.push_back(species("ash", 0.0569));
			
			//properties:
  			feed.P.LHV_dry = 19.94;
	}
	else if (feed_def=="birch_stem"){
			//atomic composition:
			feed.i.push_back(species("C",0.4862,12.01)); feed.i.push_back(species("H",0.0634,1.01)); 
			feed.i.push_back(species("O",0.449,16.00)); 
			feed.i.push_back(species("N",0.0009,14.01)); feed.i.push_back(species("S",0.0005,32.06));
			//proximates: 
  			feed.k.push_back(species("VOL",0.8943)); feed.k.push_back(species("FC",0.1035)); 
			feed.k.push_back(species("ash",0.0022));
			//properties:
  			feed.P.LHV_dry = 18.42;
	}
		//SEWAGE SLUDGE:
	else if (feed_def=="sewage_sludge_non-digested_reference"){
			//atomic composition:
			feed.i.push_back(species("C",0.3705,12.01)); feed.i.push_back(species("H",0.0585,1.01)); 
			feed.i.push_back(species("O",0.3325,16.00));feed.i.push_back(species("N",0.0425,14.01)); 
			feed.i.push_back(species("S",0.012,32.06)); feed.i.push_back(species("P",0.027,30.97));
			//proximates:
  			feed.k.push_back(species("DM", 0.25)); feed.k.push_back(species("H2O", 0.75)); 
			feed.k.push_back(species("ash",0.228));
			//constituents:
			feed.l.push_back(species("cellulose", 0.015));
			feed.l.push_back(species("hemicellulose", 0.031));
			feed.l.push_back(species("arabinose", 0.001));
			feed.l.push_back(species("lignin", 0.134));
 			feed.l.push_back(species("protein", 0.421));  
			feed.l.push_back(species("lipids", 0.043));
			feed.l.push_back(species("fatty_acids", 0.017));
			//properties:
			feed.P.LHV_dry = 15.8;
	}
	else if (feed_def=="sewage_sludge_digested_reference"){
			//atomic composition:
			feed.i.push_back(species("C",0.332,12.01)); feed.i.push_back(species("H",0.058,1.01)); 
			feed.i.push_back(species("O",0.322,16.00)); feed.i.push_back(species("N",0.038,14.01));
			feed.i.push_back(species("S",0.012,32.06)); feed.i.push_back(species("P",0.02145,30.97));
			feed.i.push_back(species("K",0.0051,39.10)); feed.i.push_back(species("Cl",0.0,35.45));
			feed.i.push_back(species("Ca",0.0065,40.08)); feed.i.push_back(species("Al",0.02935,26.98)); 
			feed.i.push_back(species("Fe",0.0256,55.84)); feed.i.push_back(species("Mg",0.00365,24.31));
			feed.i.push_back(species("Mn",0.00000025,54.94)); feed.i.push_back(species("Na",0.0031,22.99)); 
			feed.i.push_back(species("Si",0.00145,28.08)); feed.i.push_back(species("Ti",0.00004,47.87)); 
			feed.i.push_back(species("Zn",0.0038,65.38)); feed.i.push_back(species("Hg",0.0,200.06));
			feed.i.push_back(species("Pb",0.0,207.2)); feed.i.push_back(species("Cd",0.0,112.4)); 
			feed.i.push_back(species("Cr",0.00000001,52.00)); feed.i.push_back(species("Cu",0.00145,63.55));
			feed.i.push_back(species("Ni",0.00095,58.93)); feed.i.push_back(species("As",0.0,74.92));
			//proximates
			feed.k.push_back(species("DM",0.178)); 
			feed.k.push_back(species("H2O", 1.0 - feed.k[0].Y)); 
			feed.k.push_back(species("ash",0.228));
			feed.k.push_back(species("INORG"));
			feed.k.push_back(species("ORG"));
			feed.k.push_back(species("INORG-O"));
			feed.k.push_back(species("ORG-O"));
			feed.k.push_back(species("INORG-S"));
			feed.k.push_back(species("ORG-S"));
			feed.k.push_back(species("INORG-N"));
			feed.k.push_back(species("ORG-N"));
			//constituents:
			feed.l.push_back(species("cellulose", 0.0395));
			feed.l.push_back(species("hemicellulose", 0.018));
			feed.l.push_back(species("arabinose", 0.001));
			feed.l.push_back(species("lignin", 0.119));
 			feed.l.push_back(species("protein", 0.3015));  
			feed.l.push_back(species("lipids", 0.074));
			feed.l.push_back(species("fatty_acids", 0.015));
			//properties
 			feed.P.LHV_dry = 16.4;
	}
	else if (feed_def=="sewage_sludge_Karlsruhe"){
			//atomic composition:
			feed.i.push_back(species("C",0.391,12.01)); feed.i.push_back(species("H",0.056,1.01)); 
			feed.i.push_back(species("O",0.3325,16.00)); feed.i.push_back(species("N",0.053,14.01));
			feed.i.push_back(species("S",0.00062,32.06)); feed.i.push_back(species("P",0.0023,30.97));
			feed.i.push_back(species("K",0.00082,39.10)); feed.i.push_back(species("Cl",0.0,35.45));
			feed.i.push_back(species("Ca",0.00246,40.08)); feed.i.push_back(species("Al",0.00071,26.98)); 
			feed.i.push_back(species("Fe",0.00399,55.84)); feed.i.push_back(species("Mg",0.00024,24.31));
			feed.i.push_back(species("Mn",0.00000004,54.94)); feed.i.push_back(species("Na",0.00041,22.99)); 
			feed.i.push_back(species("Si",0.0023,28.08)); feed.i.push_back(species("Ti",0.0,47.87)); 
			feed.i.push_back(species("Zn",0.00008,65.38)); feed.i.push_back(species("Hg",0.00000005,200.06));
			feed.i.push_back(species("Pb",0.0,207.2)); feed.i.push_back(species("Cd",0.0,112.4)); 
			feed.i.push_back(species("Cr",0.0,52.00)); feed.i.push_back(species("Cu",0.00001,63.55));
			feed.i.push_back(species("Ni",0.0,58.93)); feed.i.push_back(species("As",0.0,74.92));
			//proximates:
			feed.k.push_back(species("DM",0.032)); feed.k.push_back(species("H2O",0.968)); 
			feed.k.push_back(species("ash", 0.238));
			//properties:
			feed.P.LHV_dry = 16.9; feed.P.HHV_dry = 17.0;
	}
 
	//update heating values:
	Heating_Value(feed);
 
	// cp J/kg K
	cp_H2O = 4200.0; cp_DM = 1200.0;
	//cp = specific_heat_mix(yDM, yH2O, 0, cp_DM, cp_H2O, 0)
 
	// rho kg / m3
	rho_DM = 500.0; rho_H2O = 1000.0;
	//rho = density_mix("Solid-Liquid", yDM, yH2O, 0, rho_DM, rho_H2O, 0)
 
}

void Heating_Value(flow &feed){
 
	double sum_y = 0.0;
	double kC, kH, kO, kS, kN, kH2O, kA;
	double yC=0.0, yH=0.0, yS=0.0, yN=0.0, yO=0.0; //atomic components
	double yA=0.0, yH2O=0.0; //proximates	

	kC = 34.1; kH = 102; kO = -9.85; kS = 19.1; kN = 0; kH2O = -2.5; kA = 0.0; 
	//kC = 34.1; kH = 110.4; kO = -12; kS = 6.86; kN = -12; kH2O = -2.442; kA = -1.53;  // Milne's formulae (from Phyllis)
	//kC = 34.8; kH = 93.9; kO = -10.8; kS = 10.5; kN = 6.3; kH2O = -2.45; kA = 0.0; // Ref. Christensen, T. (1998)


	//fetching the weight fractions:
	for (int n=0; n<feed.i.size(); n++){
		if (feed.i[n].id == "C"){
			yC = feed.i[n].Y;
		}
		else if (feed.i[n].id == "H"){
			yH = feed.i[n].Y;
		}
  		else if (feed.i[n].id == "O"){
			yO = feed.i[n].Y;
		}
		else if (feed.i[n].id == "N"){
			yN = feed.i[n].Y;
		}
		else if (feed.i[n].id == "S"){
			yS = feed.i[n].Y;
		}
	}


	//fetching the proximates:
	for (int n=0;n<feed.k.size(); n++){
		if (feed.k[n].id == "ash"){
			yA = feed.k[n].Y;
		}
		else if (feed.k[n].id == "H2O"){
			yH2O = feed.k[n].Y;
		}
	}

	if (yH2O > 1) yH2O = yH2O / 100;
 
	//sum_y = yC + yH + yO + yS + yN
	//if (sum_y > 1.0001) {
	//    yC = yC / sum_y; yH = yH / sum_y; yO = yO / sum_y; yS = yS / sum_y; yN = yN / sum_y;
	//}
 
	if(feed.P.LHV_dry == 0){
	feed.P.LHV_dry = kC * yC + kH * yH + kS * yS + kN * yN + kO * yO + kA * yA;}

	feed.P.LHV = feed.P.LHV_dry * (1 - yH2O) + kH2O * yH2O;
	feed.P.HHV_dry = feed.P.LHV_dry - kH2O * yH * (18 / 2);
	feed.P.HHV = feed.P.LHV - kH2O * (1 - yH2O) * yH * (18 / 2);

}

flow get_characterization_vector(string feed_def) {
 
	flow feed; feed = flow(); feed.def = feed_def;
 	
	raw_feedstock_characterization(feed,feed_def);

	return feed;
 
}


void flow::calculate_solid_fuel(){

        //cout << "calculating solid fuel properties" << endl;

	double sum_y = 0.0;
	double kC, kH, kO, kS, kN, kH2O, kA;
	double yC=0.0, yH=0.0, yS=0.0, yN=0.0, yO=0.0; //atomic components
	double yA=0.0, yH2O=0.0, yDM = 0.0; //proximates	

        if( index_species(k, "H2O") == -1 and index_species(k, "DM") != -1 ){
		yH2O = 1.0-k[index_species(k, "DM")].Y;
		k.push_back(species("H2O", yH2O));
	}

        if( index_species(k, "H2O") != -1 and index_species(k, "DM") == -1 ){
		yDM = 1.0-k[index_species(k, "H2O")].Y;
		k.push_back(species("DM", yDM));
	}

	if ( index_species(i, "O") == -1 ){
	double sum_Yi = 0.0; for(int ni = 0; ni < i.size(); ni++){sum_Yi += i[ni].Y;}
	double YO = 1.0 - sum_Yi;
	i.push_back(species("O",YO));
	}

 
	kC = 34.1; kH = 102; kO = -9.85; kS = 19.1; kN = 0; kH2O = -2.5; kA = 0.0; 
	//kC = 34.1; kH = 110.4; kO = -12; kS = 6.86; kN = -12; kH2O = -2.442; kA = -1.53;  // Milne's formulae (from Phyllis)
	//kC = 34.8; kH = 93.9; kO = -10.8; kS = 10.5; kN = 6.3; kH2O = -2.45; kA = 0.0; // Ref. Christensen, T. (1998)


	//fetching the weight fractions:
	for (int n=0; n<i.size(); n++){
		if (i[n].id == "C"){
			yC = i[n].Y;
		}
		else if (i[n].id == "H"){
			yH = i[n].Y;
		}
  		else if (i[n].id == "O"){
			yO = i[n].Y;
		}
		else if (i[n].id == "N"){
			yN = i[n].Y;
		}
		else if (i[n].id == "S"){
			yS = i[n].Y;
		}
	}


	//fetching the proximates:
	for (int n=0;n<k.size(); n++){
		if (k[n].id == "ash"){
			yA = k[n].Y;
		}
		else if (k[n].id == "H2O"){
			yH2O = k[n].Y;
		}
	}

	if (yH2O > 1) {yH2O = yH2O / 100;}
 
	//sum_y = yC + yH + yO + yS + yN
	//if (sum_y > 1.0001) {
	//    yC = yC / sum_y; yH = yH / sum_y; yO = yO / sum_y; yS = yS / sum_y; yN = yN / sum_y;
	//}
 
	if(P.LHV_dry == 0){
	P.LHV_dry = kC * yC + kH * yH + kS * yS + kN * yN + kO * yO + kA * yA;}

	P.LHV = P.LHV_dry * (1.0 - yH2O) + kH2O * yH2O;
	P.HHV_dry = P.LHV_dry - kH2O * yH * (18 / 2);
	P.HHV = P.LHV - kH2O * (1 - yH2O) * yH * (18 / 2);

	if(yH2O > 0) {
		P.cp = 1.2e3 * (1.0-yH2O) + 4.18e3 * yH2O;
		P.rho = 1.0 / ((1.0-yH2O)/(0.5e3) + yH2O/1e3);
	}

	F.V = F.M / P.rho;
	P.ht = P.cp * (F.T - 25.0); F.Ht = F.M * P.ht;
	P.hf = P.LHV * 1e6; F.Hf = F.M * P.hf;
	F.H = F.Ht + F.Hf;

}

void flow::calculate_gas_fuel(){

 
	if(P.LHV == 0){
		for (int nj = 0; nj < j.size(); nj++){
		P.LHV += j[nj].P.LHV;
		}
	}

	P.LHV = 0; P.MW = 0.0;
	for (int nj = 0; nj < j.size(); nj++){
		P.LHV += j[nj].P.LHV * j[nj].Y;
		P.MW += j[nj].P.MW * j[nj].X;
		P.cp += j[nj].P.cp * j[nj].Y;
	}

	 double sum_Y_rho = 0.0; 
	 for(int n = 0; n < j.size(); n++){sum_Y_rho += j[n].Y/j[n].P.rho;}
         P.rho = 1.0 / sum_Y_rho;

	P.LHV_dry = P.LHV;

	P.ht = P.cp * (F.T - 25.0); 
	P.hf = P.LHV * 1e6;
	P.h = P.ht + P.hf;

	//F.Ht = P.ht * F.M; 
	//F.Hf = F.M * P.hf;
	//F.H = F.Ht + F.Hf;
		
	

}
