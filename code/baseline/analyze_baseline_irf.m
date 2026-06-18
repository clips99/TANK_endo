% Baseline monetary tightening IRF analysis.
% Run after:
%   dynare TANK_two_region_baseline.mod noclearall

clear;
clc;

results_file = fullfile(pwd, 'TANK_two_region_baseline', 'Output', ...
    'TANK_two_region_baseline_results.mat');
if ~isfile(results_file)
    error('Results file not found: %s. Run Dynare first.', results_file);
end

load(results_file, 'oo_');

shock_suffix = '_emp';
periods = [1 4 8 12];

pairs = {
    'Local bond rate',       'rb1', 'rb2', 'higher is costlier';
    'Debt service pressure', 'ds1', 'ds2', 'higher is more pressure';
    'Fiscal space',          'fs1', 'fs2', 'lower is tighter';
    'Public investment',     'ig1', 'ig2', 'lower is weaker';
    'Public capital',        'kg1', 'kg2', 'lower is weaker';
    'Intermediate output',   'ym1', 'ym2', 'lower is weaker';
    'Final output',          'y1',  'y2',  'lower is weaker';
    'Private investment',    'inv1','inv2','lower is weaker';
    'Labor demand',          'n1',  'n2',  'lower is weaker';
    'Real wage',             'w1',  'w2',  'lower is weaker';
    'Consumption',           'c1',  'c2',  'lower is weaker';
    'Inflation',             'pinf1','pinf2','lower is weaker'
};

summary = table();
for i = 1:size(pairs, 1)
    label = pairs{i, 1};
    low_name = pairs{i, 2};
    high_name = pairs{i, 3};
    direction = pairs{i, 4};

    low_irf = get_irf(oo_, low_name, shock_suffix);
    high_irf = get_irf(oo_, high_name, shock_suffix);
    diff_irf = high_irf - low_irf;

    row = table( ...
        string(label), string(low_name), string(high_name), string(direction), ...
        low_irf(periods(1)), high_irf(periods(1)), diff_irf(periods(1)), ...
        low_irf(periods(2)), high_irf(periods(2)), diff_irf(periods(2)), ...
        low_irf(periods(3)), high_irf(periods(3)), diff_irf(periods(3)), ...
        low_irf(periods(4)), high_irf(periods(4)), diff_irf(periods(4)), ...
        'VariableNames', {'metric','low_var','high_var','interpretation', ...
        'low_t1','high_t1','diff_t1', ...
        'low_t4','high_t4','diff_t4', ...
        'low_t8','high_t8','diff_t8', ...
        'low_t12','high_t12','diff_t12'});
    summary = [summary; row]; %#ok<AGROW>
end

policy = table();
for name = ["mp", "r"]
    irf = get_irf(oo_, char(name), shock_suffix);
    row = table(name, irf(periods(1)), irf(periods(2)), irf(periods(3)), irf(periods(4)), ...
        'VariableNames', {'variable','t1','t4','t8','t12'});
    policy = [policy; row]; %#ok<AGROW>
end

writetable(summary, 'baseline_irf_summary.csv');
writetable(policy, 'baseline_policy_irf.csv');

fprintf('\nPolicy shock IRF\n');
fprintf('--------------------------------\n');
disp(policy);

fprintf('\nRegional IRF comparison: high-debt minus low-debt\n');
fprintf('--------------------------------\n');
disp(summary(:, {'metric','diff_t1','diff_t4','diff_t8','diff_t12'}));

make_irf_figure(oo_, shock_suffix);

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('IRF field not found: %s', field);
    end
    irf = oo_.irfs.(field);
end

function make_irf_figure(oo_, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 800]);
    tiledlayout(2, 4, 'Padding', 'compact', 'TileSpacing', 'compact');

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

    exportgraphics(fig, 'baseline_irf_comparison.png', 'Resolution', 180);
    close(fig);
end
