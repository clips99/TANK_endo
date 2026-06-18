% Economic scale and development heterogeneity experiment.
%
% Region 1 is the developed region and region 2 is the less-developed,
% high-debt region. The experiment varies aggregate economic size
% Y1/Y2 = 1, 1.5, and 2 through regional GDP weights in the national Taylor
% rule. Region-level steady output remains normalized to preserve the
% current analytical steady state; debt-to-GDP ratios are held fixed.

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

output_ratios = [1.00 1.50 2.00];
developed_debt_ratio = 0.40;
less_developed_debt_ratio = 1.00;
periods = [1 4 8 12];
shock_suffix = '_emp';

status = table();
region2_summary = table();
gap_summary = table();
irf_series = table();
results = struct('name', {}, 'label', {}, 'output_ratio', {}, ...
    's1', {}, 's2', {}, 'oo', {});

for i = 1:numel(output_ratios)
    output_ratio = output_ratios(i);
    ybar1 = 1.00;
    ybar2 = 1.00;
    s1 = output_ratio / (output_ratio + 1);
    s2 = 1 / (output_ratio + 1);

    scenario_name = sprintf('scale_development_y%03d', round(100 * output_ratio));
    scenario_label = sprintf('Y1/Y2 = %.1f', output_ratio);
    fprintf('\n=== Running %s: %s, s1 = %.3f ===\n', ...
        scenario_name, scenario_label, s1);

    scenario_text = base_text;
    scenario_text = set_parameter_line(scenario_text, 'ybar1', ybar1);
    scenario_text = set_parameter_line(scenario_text, 'ybar2', ybar2);
    scenario_text = set_parameter_line(scenario_text, 's1', s1);
    scenario_text = set_parameter_line(scenario_text, 's2', s2);
    scenario_text = set_parameter_line(scenario_text, 'b_y1', developed_debt_ratio);
    scenario_text = set_parameter_line(scenario_text, 'b_y2', less_developed_debt_ratio);

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
        loaded = load(result_file, 'oo_', 'M_');

        scenario = struct('name', scenario_name, ...
            'label', scenario_label, ...
            'output_ratio', output_ratio, ...
            's1', s1, 's2', s2);

        region2_summary = [region2_summary; ...
            collect_region2_summary(loaded.oo_, scenario, periods, shock_suffix)]; %#ok<AGROW>
        gap_summary = [gap_summary; ...
            collect_gap_summary(loaded.oo_, scenario, periods, shock_suffix)]; %#ok<AGROW>
        irf_series = [irf_series; ...
            collect_irf_series(loaded.oo_, scenario, shock_suffix)]; %#ok<AGROW>

        results(end + 1).name = scenario_name; %#ok<SAGROW>
        results(end).label = scenario_label;
        results(end).output_ratio = output_ratio;
        results(end).s1 = s1;
        results(end).s2 = s2;
        results(end).oo = loaded.oo_;

        status = [status; table(string(scenario_name), string(scenario_label), ...
            output_ratio, s1, s2, developed_debt_ratio, less_developed_debt_ratio, ...
            "ok", "", ...
            'VariableNames', {'scenario','label','output_ratio','s1','s2', ...
            'b_y1','b_y2','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Scale-development scenario %s failed: %s', scenario_name, err.message);
        status = [status; table(string(scenario_name), string(scenario_label), ...
            output_ratio, s1, s2, developed_debt_ratio, less_developed_debt_ratio, ...
            "failed", string(err.message), ...
            'VariableNames', {'scenario','label','output_ratio','s1','s2', ...
            'b_y1','b_y2','status','notes'})]; %#ok<AGROW>
    end
end

writetable(status, 'scale_development_status.csv');
writetable(region2_summary, 'scale_development_region2_summary.csv');
writetable(gap_summary, 'scale_development_gap_summary.csv');
writetable(irf_series, 'scale_development_irf_series.csv');

fprintf('\nScale and development heterogeneity scenario status\n');
fprintf('--------------------------------\n');
disp(status);

if ~isempty(results)
    make_region2_figure(results, shock_suffix);
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

function summary = collect_region2_summary(oo_, scenario, periods, shock_suffix)
    metrics = {
        'Policy rate',           'r';
        'Debt service pressure', 'ds2';
        'Fiscal space',          'fs2';
        'Public investment',     'ig2';
        'Public capital',        'kg2';
        'Final output',          'y2';
        'Consumption',           'c2';
        'Inflation',             'pinf2'
    };

    summary = table();
    for i = 1:size(metrics, 1)
        irf = get_irf(oo_, metrics{i, 2}, shock_suffix);
        row = table(string(scenario.name), string(scenario.label), ...
            scenario.output_ratio, scenario.s1, scenario.s2, ...
            string(metrics{i, 1}), string(metrics{i, 2}), ...
            irf(periods(1)), irf(periods(2)), irf(periods(3)), irf(periods(4)), ...
            'VariableNames', {'scenario','label','output_ratio','s1','s2', ...
            'metric','variable','t1','t4','t8','t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function summary = collect_gap_summary(oo_, scenario, periods, shock_suffix)
    pairs = {
        'Debt service pressure', 'ds1',   'ds2';
        'Fiscal space',          'fs1',   'fs2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Private investment',    'inv1',  'inv2';
        'Final output',          'y1',    'y2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    summary = table();
    for i = 1:size(pairs, 1)
        low_irf = get_irf(oo_, pairs{i, 2}, shock_suffix);
        high_irf = get_irf(oo_, pairs{i, 3}, shock_suffix);
        diff_irf = high_irf - low_irf;

        row = table(string(scenario.name), string(scenario.label), ...
            scenario.output_ratio, scenario.s1, scenario.s2, ...
            string(pairs{i, 1}), string(pairs{i, 2}), string(pairs{i, 3}), ...
            diff_irf(periods(1)), diff_irf(periods(2)), ...
            diff_irf(periods(3)), diff_irf(periods(4)), ...
            'VariableNames', {'scenario','label','output_ratio','s1','s2', ...
            'metric','developed_var','less_developed_var', ...
            'diff_t1','diff_t4','diff_t8','diff_t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function series = collect_irf_series(oo_, scenario, shock_suffix)
    pairs = {
        'Debt service pressure', 'ds1',   'ds2';
        'Fiscal space',          'fs1',   'fs2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Private investment',    'inv1',  'inv2';
        'Final output',          'y1',    'y2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    series = table();
    for i = 1:size(pairs, 1)
        developed_irf = get_irf(oo_, pairs{i, 2}, shock_suffix);
        less_developed_irf = get_irf(oo_, pairs{i, 3}, shock_suffix);
        diff_irf = less_developed_irf - developed_irf;
        horizon = (1:numel(less_developed_irf))';

        rows = table(repmat(string(scenario.name), numel(horizon), 1), ...
            repmat(string(scenario.label), numel(horizon), 1), ...
            repmat(scenario.output_ratio, numel(horizon), 1), ...
            repmat(scenario.s1, numel(horizon), 1), ...
            repmat(scenario.s2, numel(horizon), 1), ...
            repmat(string(pairs{i, 1}), numel(horizon), 1), ...
            horizon, developed_irf(:), less_developed_irf(:), diff_irf(:), ...
            'VariableNames', {'scenario','label','output_ratio','s1','s2', ...
            'metric','horizon','developed_irf','less_developed_irf','diff_irf'});
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

function make_region2_figure(results, shock_suffix)
    panels = {
        'Policy rate',           'r';
        'Debt service pressure', 'ds2';
        'Fiscal space',          'fs2';
        'Public investment',     'ig2';
        'Public capital',        'kg2';
        'Final output',          'y2';
        'Consumption',           'c2';
        'Inflation',             'pinf2'
    };
    make_scale_figure(results, shock_suffix, panels, 'region2', ...
        'Figure 3. Less-developed high-debt region IRFs by Y1/Y2', ...
        'figure3_scale_development_region2_irfs.png');
end

function make_gap_figure(results, shock_suffix)
    panels = {
        'Debt service pressure', 'ds1',   'ds2';
        'Fiscal space',          'fs1',   'fs2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Private investment',    'inv1',  'inv2';
        'Final output',          'y1',    'y2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };
    make_scale_figure(results, shock_suffix, panels, 'gap', ...
        'Less-developed high-debt minus developed low-debt IRFs by Y1/Y2', ...
        'figure3_scale_development_gap_irfs.png');
end

function make_scale_figure(results, shock_suffix, panels, mode, title_text, file_name)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 760]);
    tiledlayout(2, 4, 'Padding', 'compact', 'TileSpacing', 'compact');
    colors = lines(numel(results));
    labels = strings(numel(results), 1);
    for s = 1:numel(results)
        labels(s) = sprintf('%s, s1=%.2f', results(s).label, results(s).s1);
    end

    for p = 1:size(panels, 1)
        nexttile;
        for s = 1:numel(results)
            if strcmp(mode, 'region2')
                irf = get_irf(results(s).oo, panels{p, 2}, shock_suffix);
            else
                developed_irf = get_irf(results(s).oo, panels{p, 2}, shock_suffix);
                less_developed_irf = get_irf(results(s).oo, panels{p, 3}, shock_suffix);
                irf = less_developed_irf - developed_irf;
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
