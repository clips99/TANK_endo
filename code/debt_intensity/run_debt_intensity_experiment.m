% Debt intensity experiment.
%
% Keep the low-debt region's steady-state debt-to-GDP ratio fixed at 40%,
% set the high-debt region's ratio to 40%, 80%, 120%, and 160%, and compare
% monetary-tightening IRFs across debt intensities.

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

debt_ratios = [0.40 0.80 1.20 1.60];
periods = [1 4 8 12];
shock_suffix = '_emp';

status = table();
high_region_summary = table();
gap_summary = table();
irf_series = table();
results = struct('name', {}, 'label', {}, 'debt_ratio', {}, 'oo', {});

for i = 1:numel(debt_ratios)
    debt_ratio = debt_ratios(i);
    scenario_name = sprintf('debt_intensity_b%03d', round(100 * debt_ratio));
    scenario_label = sprintf('B2/Y2 = %.0f%%', 100 * debt_ratio);
    fprintf('\n=== Running %s: %s ===\n', scenario_name, scenario_label);

    scenario_text = base_text;
    scenario_text = set_parameter_line(scenario_text, 'b_y1', 0.40);
    scenario_text = set_parameter_line(scenario_text, 'b_y2', debt_ratio);

    scenario_mod = [scenario_name '.mod'];
    fid = fopen(scenario_mod, 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        result_file = fullfile(scenario_name, 'Output', [scenario_name '_results.mat']);
        loaded = load(result_file, 'oo_');

        scenario = struct('name', scenario_name, ...
            'label', scenario_label, 'debt_ratio', debt_ratio);
        high_region_summary = [high_region_summary; ...
            collect_high_region_summary(loaded.oo_, scenario, periods, shock_suffix)]; %#ok<AGROW>
        gap_summary = [gap_summary; ...
            collect_gap_summary(loaded.oo_, scenario, periods, shock_suffix)]; %#ok<AGROW>
        irf_series = [irf_series; ...
            collect_irf_series(loaded.oo_, scenario, shock_suffix)]; %#ok<AGROW>

        results(end + 1).name = scenario_name; %#ok<SAGROW>
        results(end).label = scenario_label;
        results(end).debt_ratio = debt_ratio;
        results(end).oo = loaded.oo_;

        status = [status; table(string(scenario_name), string(scenario_label), ...
            debt_ratio, "ok", "", ...
            'VariableNames', {'scenario','label','debt_ratio','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Debt intensity scenario %s failed: %s', scenario_name, err.message);
        status = [status; table(string(scenario_name), string(scenario_label), ...
            debt_ratio, "failed", string(err.message), ...
            'VariableNames', {'scenario','label','debt_ratio','status','notes'})]; %#ok<AGROW>
    end
end

writetable(status, 'debt_intensity_status.csv');
writetable(high_region_summary, 'debt_intensity_high_region_summary.csv');
writetable(gap_summary, 'debt_intensity_gap_summary.csv');
writetable(irf_series, 'debt_intensity_irf_series.csv');

fprintf('\nDebt intensity scenario status\n');
fprintf('--------------------------------\n');
disp(status);

if ~isempty(results)
    make_high_region_figure(results, shock_suffix);
    make_gap_figure(results, shock_suffix);
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

function summary = collect_high_region_summary(oo_, scenario, periods, shock_suffix)
    metrics = {
        'Debt service pressure', 'ds2';
        'Public investment',     'ig2';
        'Public capital',        'kg2';
        'Final output',          'y2';
        'Consumption',           'c2';
        'Inflation',             'pinf2'
    };

    summary = table();
    for i = 1:size(metrics, 1)
        irf = get_irf(oo_, metrics{i, 2}, shock_suffix);
        row = table(string(scenario.name), string(scenario.label), scenario.debt_ratio, ...
            string(metrics{i, 1}), string(metrics{i, 2}), ...
            irf(periods(1)), irf(periods(2)), irf(periods(3)), irf(periods(4)), ...
            'VariableNames', {'scenario','label','debt_ratio','metric','variable', ...
            't1','t4','t8','t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function summary = collect_gap_summary(oo_, scenario, periods, shock_suffix)
    pairs = {
        'Debt service pressure', 'ds1',   'ds2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Final output',          'y1',    'y2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    summary = table();
    for i = 1:size(pairs, 1)
        low_irf = get_irf(oo_, pairs{i, 2}, shock_suffix);
        high_irf = get_irf(oo_, pairs{i, 3}, shock_suffix);
        diff_irf = high_irf - low_irf;

        row = table(string(scenario.name), string(scenario.label), scenario.debt_ratio, ...
            string(pairs{i, 1}), string(pairs{i, 2}), string(pairs{i, 3}), ...
            diff_irf(periods(1)), diff_irf(periods(2)), ...
            diff_irf(periods(3)), diff_irf(periods(4)), ...
            'VariableNames', {'scenario','label','debt_ratio','metric','low_var','high_var', ...
            'diff_t1','diff_t4','diff_t8','diff_t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function series = collect_irf_series(oo_, scenario, shock_suffix)
    pairs = {
        'Debt service pressure', 'ds1',   'ds2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Final output',          'y1',    'y2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    series = table();
    for i = 1:size(pairs, 1)
        low_irf = get_irf(oo_, pairs{i, 2}, shock_suffix);
        high_irf = get_irf(oo_, pairs{i, 3}, shock_suffix);
        diff_irf = high_irf - low_irf;
        horizon = (1:numel(high_irf))';

        rows = table(repmat(string(scenario.name), numel(horizon), 1), ...
            repmat(string(scenario.label), numel(horizon), 1), ...
            repmat(scenario.debt_ratio, numel(horizon), 1), ...
            repmat(string(pairs{i, 1}), numel(horizon), 1), ...
            horizon, low_irf(:), high_irf(:), diff_irf(:), ...
            'VariableNames', {'scenario','label','debt_ratio','metric', ...
            'horizon','low_irf','high_irf','diff_irf'});
        series = [series; rows]; %#ok<AGROW>
    end
end

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('IRF field not found: %s', field);
    end
    irf = oo_.irfs.(field);
end

function make_high_region_figure(results, shock_suffix)
    panels = {
        'Debt service pressure', 'ds2';
        'Public investment',     'ig2';
        'Public capital',        'kg2';
        'Final output',          'y2';
        'Consumption',           'c2';
        'Inflation',             'pinf2'
    };
    make_debt_figure(results, shock_suffix, panels, 'high', ...
        'Figure 2. High-debt region IRFs under alternative steady-state debt ratios', ...
        'figure2_debt_intensity_high_region_irfs.png');
end

function make_gap_figure(results, shock_suffix)
    panels = {
        'Debt service pressure', 'ds1',   'ds2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Final output',          'y1',    'y2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };
    make_debt_figure(results, shock_suffix, panels, 'gap', ...
        'High-debt minus low-debt IRFs under alternative steady-state debt ratios', ...
        'figure2_debt_intensity_gap_irfs.png');
end

function make_debt_figure(results, shock_suffix, panels, mode, title_text, file_name)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 760]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    colors = lines(numel(results));
    labels = strings(numel(results), 1);
    for s = 1:numel(results)
        labels(s) = string(results(s).label);
    end

    for p = 1:size(panels, 1)
        nexttile;
        for s = 1:numel(results)
            if strcmp(mode, 'high')
                irf = get_irf(results(s).oo, panels{p, 2}, shock_suffix);
            else
                low_irf = get_irf(results(s).oo, panels{p, 2}, shock_suffix);
                high_irf = get_irf(results(s).oo, panels{p, 3}, shock_suffix);
                irf = high_irf - low_irf;
            end
            horizon = 1:numel(irf);
            plot(horizon, irf, 'LineWidth', 1.4, 'Color', colors(s, :));
            hold on;
        end
        yline(0, ':');
        title(panels{p, 1}, 'Interpreter', 'none');
        xlabel('period');
        grid on;
        if p == 1
            legend(labels, 'Location', 'best', 'Interpreter', 'none');
        end
    end

    sgtitle(title_text, 'Interpreter', 'none');
    exportgraphics(fig, file_name, 'Resolution', 180);
    close(fig);
end
