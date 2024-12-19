

struct NOX_reduction_parameters
{
 public:
 string tech;
 physical_parameters_set par; 
};


void NOx_reduction_model(flow &in, flow &out, vector<flow> &cons, vector<parameter> &par){

 in.print_flow();

 //physical_parameters_set par; 

 double X_NOx_clean = atof(get_parameter_value(par, "process", "AIR_EMISSIONS", "NOx").c_str());
 //par.p.push_back(physical_parameters("X_NOx_clean", X_NOx_clean, "mg/Nm3"));

 double T_SCR = atof(get_parameter_value(par, "process", "NOx_REDUCTION", "T").c_str());
 in.F.T = T_SCR; in.calculate_flow("PT");

 cons.push_back(flow("ammonia", "NH3_pure")); int ammonia = index_flow(cons, "ammonia");
 cons[ammonia].F.T =  atof(get_parameter_value(par, "process", "NOx_REDUCTION", "T_NH3").c_str());
 cons[ammonia].F.P =  atof(get_parameter_value(par, "process", "NOx_REDUCTION", "P_NH3").c_str());
 cons[ammonia].calculate_flow("PT");
 cons[ammonia].F.M = cons[ammonia].P.rho * in.F.M * 1e-3 * 1.270 / (2166.8 / 3600.0);

 out = in;
 out.mix_flows(in, cons[ammonia]); 
 int NO2 = index_species(out.j, "NO2"); out.j[NO2].X = X_NOx_clean;
 int NH3 = index_species(out.j, "NH3"); out.j[NH3].X -= in.j[NO2].X - X_NOx_clean;     
 out.calculate_flow("PT");
 out.print_flow();

 cout << "fg in M: " << in.F.M <<  endl;
 cout << "cons M: " << cons[ammonia].F.M <<  endl;
 cout << "cons rho: " << cons[ammonia].P.rho <<  endl;
 cout << "fg out M: " << out.F.M <<  endl;

 export_parameter(par, "output", "process", "NOx_REDUCTION", "M_NH3", to_string(cons[ammonia].F.M));

}

void dry_scrubber_model(flow &in, flow &out, object &par){

 cout << "=====================" << endl;
 cout << " WET SCRUBBER" << endl;
 cout << "=====================" << endl;

 
 in.F.T = par.fp("T_op"); in.F.P = par.fp("P_op"); in.calculate_flow("PT");

 par.c.push_back(object("consumable","lime","Database/Consumables_database"));
 int lime = par.ic("consumable","lime");
 par.c[lime].fval_p("Q_annual", par.fp("M_fuel") * 14.44 * 3.6 * 8000); //14.44 kg / ton solid fuel
 material_cost(par.c[lime]);

 par.c.push_back(object("solid_residue","scrubber_cake","Database/Consumables_database"));
 int cake = par.ic("solid_residue","scrubber_cake");
 par.c[cake].fval_p("Q_annual", par.c[lime].fp("Q_annual") );
 material_cost(par.c[cake]);
 
 out = in;

 par.c.push_back(object("equipment","dry_scrubber"));
 int scrubber = par.ic("equipment","dry_scrubber");  
 par.c[scrubber].fval_p("S", in.F.M*3.6);
 par.c[scrubber].fval_p("W_el", par.fp("M_fuel")*3.6*par.c[scrubber].fp("w_el"));
 
 equipment_cost(par.c[scrubber]);

 cout << "scrubber inlet M (kg/s): " << in.F.M << endl;
 cout << "scrubber cost (M$): " << par.c[scrubber].fp("Cpi") * 1e-6 << endl;
 cout << "lime cost (M$ annual): " << par.c[lime].fp("C_annual") * 1e-6 << endl;
 cout << "cake cost (M$ annual): " << par.c[cake].fp("C_annual") * 1e-6 << endl;


}

 
