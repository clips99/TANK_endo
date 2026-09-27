function plot_paper_figures()
% Batch dispatcher; each experiment owns its sole formal figure implementation.
code_dir=fileparts(mfilename('fullpath'));
addpath(fullfile(code_dir,'baseline'));
plot_baseline();
addpath(fullfile(code_dir,'debt_intensity'));
plot_debt_intensity();
addpath(fullfile(code_dir,'scale_development'));
plot_scale_development();
addpath(fullfile(code_dir,'demand_monetary'));
plot_demand_monetary();
addpath(fullfile(code_dir,'policy_counterfactual'));
plot_policy_counterfactual();
addpath(fullfile(code_dir,'stackelberg_B/robustness/sensitivity_sanity'));
plot_stackelberg_irf_compare();
addpath(fullfile(code_dir,'extension_scenarios'));
plot_extension_scenarios();
plot_demand_regional_balance();
end
