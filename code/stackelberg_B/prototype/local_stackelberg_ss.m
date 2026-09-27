% One-region RANK prototype; the same six-equation solver feeds the full model.
script_dir=fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir),'robustness','sensitivity_sanity'));
result=solve_stackelberg_ss_for_parameters(2.5,0.1,20,0.45);
assert(result.status=="PASS");
variable=result.variable_names;value=result.solution;
writetable(table(variable,value),fullfile(script_dir,'local_stackelberg_ss_solution.csv'));
equation=["FOC_IG";"FOC_KG";"FOC_K";"FOC_N";"FOC_QK";"FOC_I"];
residual=result.raw_residual;
writetable(table(equation,residual),fullfile(script_dir,'local_stackelberg_ss_residuals.csv'));
metric=["jacobian_rank";"dimension";"max_residual";"exitflag"];
value=[result.jacobian_rank;result.jacobian_dimension;result.max_raw_residual;result.exitflag];
writetable(table(metric,value),fullfile(script_dir,'local_stackelberg_ss_diagnostics.csv'));
