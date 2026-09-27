function run_extension_scenarios()
% Run extension scenarios after the baseline mechanism is working.
%
% Scenarios:
%   1. baseline
%   2. reduced-form quoting-intermediary risk premium: mu_b > 0
%   3. central transfer buffer: z responds to net real debt-service burden
%   4. risk premium + transfer buffer
%   5. stronger interregional input linkages
%   6. weaker interregional input linkages
%
% Scenario .mod files are regenerated from RANK_two_region_baseline.mod on
% every run.
% The runner exports the single formal comparison figure used by the paper.


script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir,'../utils'));
caller_dir=pwd;
restore_directory=onCleanup(@()cd(caller_dir));
addpath(script_dir);
cd(script_dir);

dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

base_mod = fullfile(script_dir, '..', 'baseline', 'RANK_two_region_baseline.mod');
base_text = fileread(base_mod);

scenarios = make_scenario('scenario_01_baseline', ...
    '基准', {}, ...
    'mu_b=0, no transfer response, omega=0.85, eta=0.90');

scenarios(end + 1) = make_scenario('scenario_02_risk_premium', ...
    '缩约报价中介的地方债风险溢价', ...
    {'mu_b', 0.05}, ...
    'a reduced-form quoting intermediary raises local financing costs when debt ratios rise');

scenarios(end + 1) = make_scenario('scenario_03_transfer_buffer', ...
    '中央转移支付缓冲', ...
    {'rho_z', 0.50; 'phi_z_ds', 0.20}, ...
    'central transfers react to DS through the local-government budget');

scenarios(end + 1) = make_scenario('scenario_04_risk_and_transfer', ...
    '缩约报价中介风险溢价+转移支付缓冲', ...
    {'mu_b', 0.05; 'rho_z', 0.50; 'phi_z_ds', 0.20}, ...
    'reduced-form quoting-intermediary premium and central transfer buffer active together');

scenarios(end + 1) = make_scenario('scenario_05_strong_io', ...
    '强跨地区投入产出联系', ...
    {'omega1', 0.70; 'omega2', 0.70; 'eta', 0.75}, ...
    'lower home bias and lower substitution elasticity');

scenarios(end + 1) = make_scenario('scenario_06_weak_io', ...
    '弱跨地区投入产出联系', ...
    {'omega1', 0.95; 'omega2', 0.95; 'eta', 2.50}, ...
    'higher home bias and higher substitution elasticity');

periods = [1 4 8 12];
summary = table();
status = table();

% Generate every source before Dynare loads generated files on Windows.
for s = 1:numel(scenarios)
    scenario = scenarios(s);
    fprintf('\n=== Running %s: %s ===\n', scenario.name, scenario.label);

    scenario_text = base_text;
    for r = 1:size(scenario.replacements, 1)
        scenario_text = set_parameter_line( ...
            scenario_text, scenario.replacements{r, 1}, scenario.replacements{r, 2});
    end

    scenario_mod = [scenario.name '.mod'];
    fid = fopen(fullfile(script_dir,scenario_mod), 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;
end

for s = 1:numel(scenarios)
    scenario = scenarios(s);
    scenario_mod = [scenario.name '.mod'];
    try
        evalc(sprintf('dynare %s noclearall nolog', scenario_mod));
        result_file = fullfile(script_dir,scenario.name, 'Output', [scenario.name '_results.mat']);
        load(result_file, 'oo_');

        scenario_summary = collect_summary(oo_, scenario, periods);
        summary = [summary; scenario_summary]; %#ok<AGROW>

        status = [status; table(string(scenario.name), string(scenario.label), ...
            "ok", string(scenario.notes), ...
            'VariableNames', {'scenario','label','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Scenario %s failed: %s', scenario.name, err.message);
        status = [status; table(string(scenario.name), string(scenario.label), ...
            "failed", string(err.message), ...
            'VariableNames', {'scenario','label','status','notes'})]; %#ok<AGROW>
    end
end

writetable(status, fullfile(script_dir,'extension_scenario_status.csv'));
writetable(summary, fullfile(script_dir,'extension_scenario_summary.csv'));

key_metrics = ["Local bond rate", "Net real debt-service burden", "Pre-financing fiscal resources", ...
    "Public investment", "Public capital", "Production GDP", ...
    "Private investment", "Labor demand", "Inflation"];
key_t1 = summary(ismember(summary.metric, key_metrics), ...
    {'scenario','label','metric','diff_t1','diff_t4','diff_t8','diff_t12'});
writetable(key_t1, fullfile(script_dir,'extension_key_diffs.csv'));

fprintf('\nScenario status\n');
fprintf('--------------------------------\n');
disp(status);

if any(status.status == "failed")
    error('One or more extension scenarios failed; see extension_scenario_status.csv.');
end

plot_extension_scenarios();
end

function scenario = make_scenario(name, label, replacements, notes)
    scenario = struct();
    scenario.name = name;
    scenario.label = label;
    scenario.replacements = replacements;
    scenario.notes = notes;
end

function text = set_parameter_line(text, name, value)
    pattern = ['(?m)^' regexptranslate('escape', name) '\s*=\s*[^;]+;'];
    replacement = sprintf('%-11s= %.8g;', name, value);
    count = numel(regexp(text, pattern, 'match'));
    text = regexprep(text, pattern, replacement, 'once');
    if count ~= 1
        error('Expected to replace parameter %s exactly once; replaced %d.', name, count);
    end
end

function scenario_summary = collect_summary(oo_, scenario, periods)
    shock_suffix = '_emp';
    pairs = {
        'Local bond rate',        'rb1',  'rb2';
        'Central transfer',       'z1',   'z2';
        'Net real debt-service burden','ds1','ds2';
        'Pre-financing fiscal resources','fs1','fs2';
        'Public investment',      'ig1',  'ig2';
        'Public capital',         'kg1',  'kg2';
        'Production GDP',         'xloc1','xloc2';
        'Final absorption',       'y1',   'y2';
        'Private investment',     'inv1', 'inv2';
        'Labor demand',           'n1',   'n2';
        'Real wage',              'w1',   'w2';
        'Consumption',            'c1',   'c2';
        'Inflation',              'pinf1','pinf2'
    };

    scenario_summary = table();
    for i = 1:size(pairs, 1)
        low_irf = get_irf(oo_, pairs{i, 2}, shock_suffix);
        high_irf = get_irf(oo_, pairs{i, 3}, shock_suffix);
        diff_irf = high_irf - low_irf;

        row = table(string(scenario.name), string(scenario.label), string(pairs{i, 1}), ...
            string(pairs{i, 2}), string(pairs{i, 3}), ...
            low_irf(periods(1)), high_irf(periods(1)), diff_irf(periods(1)), ...
            low_irf(periods(2)), high_irf(periods(2)), diff_irf(periods(2)), ...
            low_irf(periods(3)), high_irf(periods(3)), diff_irf(periods(3)), ...
            low_irf(periods(4)), high_irf(periods(4)), diff_irf(periods(4)), ...
            'VariableNames', {'scenario','label','metric','low_var','high_var', ...
            'low_t1','high_t1','diff_t1', ...
            'low_t4','high_t4','diff_t4', ...
            'low_t8','high_t8','diff_t8', ...
            'low_t12','high_t12','diff_t12'});
        scenario_summary = [scenario_summary; row]; %#ok<AGROW>
    end
end

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('IRF field not found: %s', field);
    end
    irf = oo_.irfs.(field);
end
