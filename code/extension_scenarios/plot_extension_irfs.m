% Plot full-horizon IRFs for extension scenarios from existing Dynare results.
%
% This script does not rerun Dynare. It only reads scenario_*_results.mat
% files and refreshes extension_irf_scenario_*.png figures.

clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
if ~isempty(script_dir)
    cd(script_dir);
end

scenarios = {
    'scenario_01_baseline',          'Baseline';
    'scenario_02_risk_premium',      'Local debt risk premium';
    'scenario_03_transfer_buffer',   'Central transfer buffer';
    'scenario_04_risk_and_transfer', 'Risk premium plus transfer buffer';
    'scenario_05_strong_io',         'Stronger input-output linkages';
    'scenario_06_weak_io',           'Weaker input-output linkages'
};

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

figure_files = strings(size(scenarios, 1), 1);
for s = 1:size(scenarios, 1)
    name = scenarios{s, 1};
    label = scenarios{s, 2};
    result_file = fullfile(name, 'Output', [name '_results.mat']);
    if ~isfile(result_file)
        error('Results file not found: %s', result_file);
    end

    loaded = load(result_file, 'oo_');
    file_name = ['extension_irf_' name '.png'];
    make_irf_figure(loaded.oo_, shock_suffix, panels, label, file_name);
    figure_files(s) = string(file_name);
end

fprintf('\nFull-horizon extension IRF figures refreshed\n');
fprintf('--------------------------------\n');
disp(table(figure_files, 'VariableNames', {'file'}));

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('IRF field not found: %s', field);
    end
    irf = oo_.irfs.(field);
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
