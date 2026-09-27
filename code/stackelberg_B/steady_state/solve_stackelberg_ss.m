% Recompute the RANK Stackelberg multipliers and fiscal steady state.
script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir),'robustness','sensitivity_sanity'));
result = solve_stackelberg_ss_for_parameters(2.5,0.10,20,0.45);
assert(result.status == "PASS", 'RANK multiplier solver failed.');
region = repelem(["region_1";"region_2"],6);
variable = repmat(result.variable_names,2,1);
value = repmat(result.solution,2,1);
writetable(table(region,variable,value),fullfile(script_dir,'stackelberg_ss_solution.csv'));
equation = repmat(["FOC_IG";"FOC_KG";"FOC_K";"FOC_N";"FOC_QK";"FOC_I"],2,1);
residual = repmat(result.raw_residual,2,1);
writetable(table(region,equation,residual),fullfile(script_dir,'stackelberg_ss_residuals.csv'));
B = 4*[0.40;1.00];
ss = result.private_steady;
p = result.parameters;
Z = ss.G+ss.IG+(ss.RB-1)*B-p.tauL*ss.X;
budget_residual = B-ss.RB*B-ss.G-ss.IG+p.tauL*ss.X+Z;
metric = ["max_foc_residual";"max_budget_residual";"multiplier_jacobian_rank"; ...
    "multiplier_jacobian_dimension";"B1";"B2";"Z1";"Z2";"C";"N";"chiN"];
value = [result.max_raw_residual;max(abs(budget_residual));2*result.jacobian_rank; ...
    2*result.jacobian_dimension;B;Z;ss.C;ss.N;p.chiN];
writetable(table(metric,value),fullfile(script_dir,'stackelberg_ss_diagnostics.csv'));
% Calibrate the canonical model from this freshly solved system, at full precision.
model_path = fullfile(fileparts(script_dir),'baseline','RANK_two_region_stackelberg.mod');
content = fileread(model_path);
names = {'lamgbar1','murbar1','mukbar1','muqbar1'};
indices = [1,3,4,5];
for k=1:numel(names)
    content=regexprep(content,['(?m)^' names{k} '\s*=[^;]+;'], ...
        sprintf('%-12s = %.17g;',names{k},result.solution(indices(k))));
end
fid=fopen(model_path,'w');fprintf(fid,'%s',content);fclose(fid);
disp(table(metric,value));
