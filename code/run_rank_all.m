function run_rank_all(start_step)
% Complete reproduction from model solving through the exact manuscript figures.
root=fileparts(fileparts(mfilename('fullpath')));
if nargin<1,start_step=1;end
validateattributes(start_step,{'numeric'},{'scalar','integer','>=',1,'<=',9});
old=pwd; cleanup=onCleanup(@()cd(old));
started=now;
addpath(fullfile(root,'code'),fullfile(root,'code/utils'));
scripts={'baseline/run_baseline.m','debt_intensity/run_debt_intensity_experiment.m', ...
    'scale_development/run_scale_development_experiment.m', ...
    'stackelberg_B/baseline/run_stackelberg_baseline.m', ...
    'stackelberg_B/robustness/scheme_A/run_scheme_A.m', ...
    'demand_monetary/run_monetary_hawkishness_experiment.m', ...
    'policy_counterfactual/run_policy_counterfactual_experiment.m', ...
    'extension_scenarios/run_extension_scenarios.m', ...
    'extension_scenarios/run_demand_regional_balance.m'};
for i=start_step:numel(scripts)
    fprintf('Reproduction step %d/%d: %s\n',i,numel(scripts),scripts{i});
    isolated_script(fullfile(root,'code',scripts{i}));
end
addpath(fullfile(root,'code/stackelberg_B/robustness/scheme_A'));
compare_scheme_A_B();
addpath(fullfile(root,'code/stackelberg_B/robustness/sensitivity_sanity'));
run_ba_sensitivity_sanity();
isolated_script(fullfile(root,'code/validate_all_models.m'));
validation=readtable(fullfile(root,'code/model_validation_status.csv'),'TextType','string');
assert(height(validation)==54 && all(validation.status=="ok"),'Expected 54 passing models.');
audit_occbin_rank();
summarize_rank_results();
% Runners already rendered their unique figures. Confirm the manuscript uses
% those files, without running a second plotting pipeline.
paper=fileread(fullfile(root,'RANK_DSGE_endo.tex'));
figures=regexp(paper,'\\includegraphics(?:\[[^\]]*\])?\{([^}]+\.pdf)\}','tokens');
assert(numel(figures)==14,'Expected 14 PDF files across Figures 1-13.');
for i=1:numel(figures)
    pdf=fullfile(root,figures{i}{1});
    assert(isfile(pdf) && isfile(strrep(pdf,'.pdf','.png')), 'Missing formal figure: %s',pdf);
    if start_step==1
        a=dir(pdf); b=dir(strrep(pdf,'.pdf','.png'));
        assert(min(a.datenum,b.datenum)>=started-1/86400,'Runner did not refresh figure: %s',pdf);
    end
end
fprintf('All model checks and 14 manuscript PDF/PNG pairs complete.\n');
fprintf('Compile the self-contained RANK_DSGE_endo.tex twice with XeLaTeX.\n');
end

function isolated_script(filename)
% Dynare publishes M_/oo_/options_ in the base workspace. Legacy scripts
% contain clear, so keep orchestration state in this separate function scope.
[folder,entry]=fileparts(filename);
addpath(folder);
evalin('base',entry);
end
