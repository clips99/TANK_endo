% Run extension scenarios after the baseline mechanism is working.
%
% Scenarios:
%   1. baseline
%   2. local risk premium: mu_b > 0
%   3. central transfer buffer: z responds to debt-service pressure and
%      enters the public-investment rule
%   4. risk premium + transfer buffer
%   5. stronger interregional input linkages
%   6. weaker interregional input linkages
%
% Scenario .mod files are regenerated from TANK_two_region_baseline.mod on
% every run. TANK_two_region_baseline_old.mod is only a historical backup.
% Full-horizon IRF figures are exported for each scenario, using the same
% low-debt/high-debt panel layout as baseline_irf_comparison.png.

clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
if ~isempty(script_dir)
    cd(script_dir);
end

dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

base_mod = fullfile(script_dir, '..', 'baseline', 'TANK_two_region_baseline.mod');
base_text = fileread(base_mod);

scenarios = make_scenario('scenario_01_baseline', ...
    'Baseline', {}, ...
    'mu_b=0, no transfer response, omega=0.85, eta=0.90');

scenarios(end + 1) = make_scenario('scenario_02_risk_premium', ...
    'Local debt risk premium', ...
    {'mu_b', 0.05}, ...
    'mu_b>0 raises local financing costs when debt ratios rise');

scenarios(end + 1) = make_scenario('scenario_03_transfer_buffer', ...
    'Central transfer buffer', ...
    {'rho_z', 0.50; 'phi_z_ds', 0.20; 'psi_z', 0.20}, ...
    'central transfers react to DS and support public investment');

scenarios(end + 1) = make_scenario('scenario_04_risk_and_transfer', ...
    'Risk premium plus transfer buffer', ...
    {'mu_b', 0.05; 'rho_z', 0.50; 'phi_z_ds', 0.20; 'psi_z', 0.20}, ...
    'risk premium and central transfer buffer active together');

scenarios(end + 1) = make_scenario('scenario_05_strong_io', ...
    'Stronger input-output linkages', ...
    {'omega1', 0.70; 'omega2', 0.70; 'eta', 0.75}, ...
    'lower home bias and lower substitution elasticity');

scenarios(end + 1) = make_scenario('scenario_06_weak_io', ...
    'Weaker input-output linkages', ...
    {'omega1', 0.95; 'omega2', 0.95; 'eta', 2.50}, ...
    'higher home bias and higher substitution elasticity');

periods = [1 4 8 12];
summary = table();
status = table();

for s = 1:numel(scenarios)
    scenario = scenarios(s);
    fprintf('\n=== Running %s: %s ===\n', scenario.name, scenario.label);

    scenario_text = base_text;
    for r = 1:size(scenario.replacements, 1)
        scenario_text = set_parameter_line( ...
            scenario_text, scenario.replacements{r, 1}, scenario.replacements{r, 2});
    end

    scenario_mod = [scenario.name '.mod'];
    fid = fopen(scenario_mod, 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        eval(sprintf('dynare %s noclearall', scenario_mod));
        result_file = fullfile(scenario.name, 'Output', [scenario.name '_results.mat']);
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

writetable(status, 'extension_scenario_status.csv');
writetable(summary, 'extension_scenario_summary.csv');

key_metrics = ["Local bond rate", "Debt service pressure", "Fiscal space", ...
    "Public investment", "Public capital", "Final output", ...
    "Private investment", "Labor demand", "Inflation"];
key_t1 = summary(ismember(summary.metric, key_metrics), ...
    {'scenario','label','metric','diff_t1','diff_t4','diff_t8','diff_t12'});
writetable(key_t1, 'extension_key_diffs.csv');

fprintf('\nScenario status\n');
fprintf('--------------------------------\n');
disp(status);

if any(status.status == "ok")
    figure_files = make_extension_irf_figures(scenarios, status);
    fprintf('\nFull-horizon IRF figures\n');
    fprintf('--------------------------------\n');
    disp(table(figure_files, 'VariableNames', {'file'}));
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
        'Debt service pressure',  'ds1',  'ds2';
        'Fiscal space',           'fs1',  'fs2';
        'Public investment',      'ig1',  'ig2';
        'Public capital',         'kg1',  'kg2';
        'Intermediate output',    'ym1',  'ym2';
        'Final output',           'y1',   'y2';
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

function figure_files = make_extension_irf_figures(scenarios, status)
    shock_suffix = '_emp';
    panels = {
        'Debt service pressure', 'ds1', 'ds2';
        'Fiscal space',          'fs1', 'fs2';
        'Public investment',     'ig1', 'ig2';
        'Public capital',        'kg1', 'kg2';
        'Private investment',    'inv1','inv2';
        'Final output',          'y1',  'y2';
        'Consumption',           'c1',  'c2';
        'Inflation',             'pinf1','pinf2'
    };

    figure_files = strings(0, 1);
    for s = 1:numel(scenarios)
        scenario = scenarios(s);
        row = status(status.scenario == string(scenario.name), :);
        if height(row) == 0 || row.status(1) ~= "ok"
            continue;
        end

        result_file = fullfile(scenario.name, 'Output', [scenario.name '_results.mat']);
        loaded = load(result_file, 'oo_');
        file_name = ['extension_irf_' scenario.name '.png'];
        make_irf_figure(loaded.oo_, shock_suffix, panels, scenario.label, file_name);
        figure_files(end + 1, 1) = string(file_name); %#ok<AGROW>
    end
end

function make_irf_figure(oo_, shock_suffix, panels, label, file_name)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 800]);
    tiledlayout(2, 4, 'Padding', 'compact', 'TileSpacing', 'compact');
    for i = 1:size(panels, 1)
        nexttile;
        low_irf = get_irf(oo_, panels{i, 2}, shock_suffix);
        high_irf = get_irf(oo_, panels{i, 3}, shock_suffix);
        horizon = 1:numel(low_irf);
        plot(horizon, low_irf, 'LineWidth', 1.4);
        hold on;
        plot(horizon, high_irf, '--', 'LineWidth', 1.4);
        yline(0, ':');
        title(panels{i, 1}, 'Interpreter', 'none');
        xlabel('period');
        grid on;
        if i == 1
            legend({'low debt', 'high debt'}, 'Location', 'best');
        end
    end

    sgtitle(label, 'Interpreter', 'none');
    exportgraphics(fig, file_name, 'Resolution', 180);
    close(fig);
end
