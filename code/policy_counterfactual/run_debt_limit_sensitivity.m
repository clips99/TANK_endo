% Debt-limit sensitivity checks for the high-debt region.
%
% This diagnostic script reuses the generated strict debt-limit model and
% changes only psi_L or ubar_L2. It does not overwrite the main paper figures
% or the main counterfactual CSV files.

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

shock_suffix = '_emp';
b_y2 = 1.00;

base_limit = struct('ucrit', 0.995, 'nu', 250.00, ...
    'ubar1', 0.975, 'ubar2', 0.985);

results = struct('name', {}, 'label', {}, 'psi_L', {}, ...
    'line_style', {}, 'limit_settings', {}, 'series', {});
summary = table();
all_series = table();

existing = struct( ...
    'name', {'policy_cf_baseline', 'policy_cf_fiscal_discipline'}, ...
    'label', {'Baseline', 'Strict rule: psi=20, ubar2=0.985'}, ...
    'psi_L', {0.00, 20.00}, ...
    'ubar2', {0.985, 0.985}, ...
    'line_style', {'-', '--'});

variants = struct( ...
    'name', {'policy_cf_sens_low_psi', 'policy_cf_sens_ubar098'}, ...
    'label', {'Lower psi: psi=8, ubar2=0.985', 'Lower ubar2: psi=20, ubar2=0.980'}, ...
    'psi_L', {8.00, 20.00}, ...
    'ubar2', {0.985, 0.980}, ...
    'line_style', {'-.', ':'});

for i = 1:numel(existing)
    scenario = existing(i);
    result_file = fullfile(scenario.name, 'Output', [scenario.name '_results.mat']);
    loaded = load(result_file, 'oo_', 'M_');
    limit = base_limit;
    limit.ubar2 = scenario.ubar2;
    [results, summary, all_series] = append_result(results, summary, all_series, ...
        loaded.oo_, loaded.M_, scenario, limit, shock_suffix, b_y2);
end

template = fileread('policy_cf_fiscal_discipline.mod');
for i = 1:numel(variants)
    scenario = variants(i);
    fprintf('\n=== Running %s: %s ===\n', scenario.name, scenario.label);

    scenario_text = set_parameter_value(template, 'psi_L', scenario.psi_L);
    scenario_text = set_parameter_value(scenario_text, 'ubar_L2', scenario.ubar2);

    scenario_mod = [scenario.name '.mod'];
    fid = fopen(scenario_mod, 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
    result_file = fullfile(scenario.name, 'Output', [scenario.name '_results.mat']);
    delete_stale_result_file(result_file);
    evalc(sprintf('dynare %s noclearall', scenario_mod));
    loaded = load(result_file, 'oo_', 'M_');

    limit = base_limit;
    limit.ubar2 = scenario.ubar2;
    [results, summary, all_series] = append_result(results, summary, all_series, ...
        loaded.oo_, loaded.M_, scenario, limit, shock_suffix, b_y2);
end

writetable(summary, 'debt_limit_sensitivity_summary.csv');
writetable(all_series, 'debt_limit_sensitivity_irf_series.csv');
make_sensitivity_figure(results, base_limit.ucrit);

fprintf('\nDebt-limit sensitivity summary\n');
fprintf('--------------------------------\n');
disp(summary(:, {'label','psi_L','ubar2','max_u2','min_u2', ...
    'max_debt_ratio2','min_debt_ratio2','min_ig2','max_ig2','min_y2','max_y2'}));

function [results, summary, all_series] = append_result(results, summary, all_series, ...
        oo_, M_, scenario, limit, shock_suffix, b_y2)
    series = collect_sensitivity_series(oo_, M_, scenario, limit, shock_suffix, b_y2);
    summary = [summary; collect_sensitivity_summary(series, scenario, limit)]; %#ok<AGROW>
    all_series = [all_series; series]; %#ok<AGROW>

    results(end + 1).name = scenario.name; %#ok<AGROW>
    results(end).label = scenario.label;
    results(end).psi_L = scenario.psi_L;
    results(end).line_style = scenario.line_style;
    results(end).limit_settings = limit;
    results(end).series = series;
end

function series = collect_sensitivity_series(oo_, M_, scenario, limit, shock_suffix, b_y2)
    b2 = get_irf(oo_, 'b2', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    y2 = get_irf(oo_, 'y2', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    horizon = (1:numel(y2))';
    [u2, pressure2] = debt_limit_series(oo_, M_, limit, shock_suffix, 2);
    debt_ratio2 = b2(:) - b_y2 * y2(:);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.psi_L, numel(horizon), 1), ...
        repmat(limit.ucrit, numel(horizon), 1), ...
        repmat(limit.nu, numel(horizon), 1), ...
        repmat(limit.ubar2, numel(horizon), 1), ...
        horizon, u2(:), pressure2(:), debt_ratio2(:), ...
        ds2(:), fs2(:), ig2(:), kg2(:), y2(:), c2(:), pinf2(:), ...
        'VariableNames', {'scenario','label','psi_L','ucrit','nu','ubar2', ...
        'horizon','u2','pressure2','debt_ratio2','ds2','fs2','ig2','kg2', ...
        'y2','c2','pinf2'});
end

function summary = collect_sensitivity_summary(series, scenario, limit)
    z = series.u2 - limit.ucrit;
    crosses_ucrit = any(z(1:end - 1) .* z(2:end) < 0);

    summary = table(string(scenario.name), string(scenario.label), ...
        scenario.psi_L, limit.ucrit, limit.nu, limit.ubar2, ...
        max(series.u2), min(series.u2), crosses_ucrit, ...
        max(series.pressure2), min(series.pressure2), ...
        max(series.debt_ratio2), min(series.debt_ratio2), ...
        min(series.ig2), max(series.ig2), min(series.kg2), ...
        min(series.y2), max(series.y2), ...
        'VariableNames', {'scenario','label','psi_L','ucrit','nu','ubar2', ...
        'max_u2','min_u2','crosses_ucrit','max_pressure2','min_pressure2', ...
        'max_debt_ratio2','min_debt_ratio2','min_ig2','max_ig2','min_kg2', ...
        'min_y2','max_y2'});
end

function make_sensitivity_figure(results, ucrit)
    fig = figure('Color', 'w', 'Position', [100 100 1450 850]);
    tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

    plot_panel(results, 'u2', 'High debt: limit utilization', ucrit);
    plot_panel(results, 'debt_ratio2', 'High debt: debt/GDP response', 0);
    plot_panel(results, 'ds2', 'High debt: real debt-service pressure', 0);
    plot_panel(results, 'ig2', 'High debt: public investment', 0);
    plot_panel(results, 'kg2', 'High debt: public capital', 0);
    plot_panel(results, 'y2', 'High debt: output', 0);

    sgtitle('Debt-limit sensitivity: high-debt region');
    exportgraphics(fig, 'debt_limit_sensitivity_high_debt_irfs.png', 'Resolution', 220);
    close(fig);
end

function plot_panel(results, field_name, title_text, ref_line)
    nexttile;
    colors = [
        0.05 0.20 0.35
        0.70 0.12 0.12
        0.10 0.45 0.20
        0.45 0.20 0.65
    ];

    labels = cell(1, numel(results));
    for i = 1:numel(results)
        y = results(i).series.(field_name);
        plot(1:numel(y), y, 'LineWidth', 1.7, ...
            'Color', colors(i, :), 'LineStyle', results(i).line_style);
        hold on;
        labels{i} = results(i).label;
    end

    yline(ref_line, ':', 'Color', [0.30 0.30 0.30]);
    title(title_text, 'Interpreter', 'none');
    xlabel('Periods');
    grid on;

    if strcmp(field_name, 'y2')
        legend(labels, 'Location', 'best', 'Interpreter', 'none');
    end
end

function [u, pressure_value] = debt_limit_series(oo_, M_, settings, shock_suffix, region)
    suffix = string(region);
    ubar = settings.(['ubar' char(suffix)]);

    b = level_series(oo_, M_, ['b' char(suffix)], shock_suffix);
    rb = level_series(oo_, M_, ['rb' char(suffix)], shock_suffix);
    pinf = level_series(oo_, M_, ['pinf' char(suffix)], shock_suffix);
    g = level_series(oo_, M_, ['g' char(suffix)], shock_suffix);
    tr = level_series(oo_, M_, ['tr' char(suffix)], shock_suffix);
    y = level_series(oo_, M_, ['y' char(suffix)], shock_suffix);
    z = level_series(oo_, M_, ['z' char(suffix)], shock_suffix);

    b_lag = lag_level_series(b, steady_value(oo_, M_, ['b' char(suffix)]));
    rb_lag = lag_level_series(rb, steady_value(oo_, M_, ['rb' char(suffix)]));
    lambda = param_value(M_, ['lambda' char(suffix)]);
    theta_T = param_value(M_, 'theta_T');
    tau_y = param_value(M_, 'tau_y');

    fg = (rb_lag ./ pinf - 1) .* b_lag + g + lambda * tr ...
        - (1 - theta_T) * tau_y * y - z;

    bbar = steady_value(oo_, M_, ['b' char(suffix)]);
    rbbar = steady_value(oo_, M_, ['rb' char(suffix)]);
    pinfbar = steady_value(oo_, M_, ['pinf' char(suffix)]);
    gbar = steady_value(oo_, M_, ['g' char(suffix)]);
    trbar = steady_value(oo_, M_, ['tr' char(suffix)]);
    ybar = steady_value(oo_, M_, ['y' char(suffix)]);
    zbar = steady_value(oo_, M_, ['z' char(suffix)]);
    fgbar = (rbbar / pinfbar - 1) * bbar + gbar + lambda * trbar ...
        - (1 - theta_T) * tau_y * ybar - zbar;
    bmax = (bbar + fgbar) / ubar;

    u = (b_lag + fg) / bmax;
    pressure_value = pressure(u, settings.ucrit, settings.nu) ...
        - pressure(ubar, settings.ucrit, settings.nu);
end

function x = level_series(oo_, M_, var_name, shock_suffix)
    irf = get_irf(oo_, var_name, shock_suffix);
    x = steady_value(oo_, M_, var_name) + irf(:);
end

function x_lag = lag_level_series(x, steady)
    x_lag = [steady; x(1:end - 1)];
end

function value = steady_value(oo_, M_, var_name)
    names = cellstr(M_.endo_names);
    idx = find(strcmp(names, var_name), 1);
    if isempty(idx)
        error('Endogenous variable not found: %s', var_name);
    end
    value = oo_.steady_state(idx);
end

function value = param_value(M_, param_name)
    names = cellstr(M_.param_names);
    idx = find(strcmp(names, param_name), 1);
    if isempty(idx)
        error('Parameter not found: %s', param_name);
    end
    value = M_.params(idx);
end

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if isfield(oo_.irfs, field)
        irf = oo_.irfs.(field)(:);
    else
        irf = zeros(40, 1);
    end
end

function p = pressure(u, ucrit, nu)
    p = log(1 + exp(nu * (u - ucrit))) / nu;
end

function text = set_parameter_value(text, name, value)
    pattern = ['(?m)^\s*' name '\s*=\s*[-+0-9.eE]+;\s*$'];
    replacement = sprintf('%-11s= %.8g;', name, value);
    text = regex_replace_once(text, pattern, replacement);
end

function text = regex_replace_once(text, pattern, replacement)
    count_matches = numel(regexp(text, pattern, 'match'));
    text = regexprep(text, pattern, replacement, 'once');
    if count_matches ~= 1
        error('Expected regex replacement exactly once; found %d matches: %s', ...
            count_matches, pattern);
    end
end

function delete_stale_result_file(result_file)
    if isfile(result_file)
        delete(result_file);
    end
end
