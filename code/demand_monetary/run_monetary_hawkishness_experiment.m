% Monetary policy stabilization experiment under a persistent demand slump.
%
% Introduce a common persistent negative demand shock into the risk-free Euler
% equation and vary the Taylor-rule inflation response coefficient. The main
% statistics summarize each rule by welfare, aggregate volatility, and regional
% synchronization.

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

policy_rules = struct( ...
    'name', {'phi_110', 'baseline_policy', 'phi_200', 'phi_250', 'strong_inflation_policy'}, ...
    'label', {'phi_pi = 1.1', 'Baseline rule: phi_pi = 1.5', ...
    'phi_pi = 2.0', 'phi_pi = 2.5', 'Stronger rule: phi_pi = 3.0'}, ...
    'phi_pi', {1.10, 1.50, 2.00, 2.50, 3.00}, ...
    'line_style', {':', '-', '-.', ':', '--'});

rho_demand = 0.80;
demand_shock_stderr = 0.0025;
shock_suffix = '_ed';
periods = [1 4 8 12];
irf_comparison_phi_pi = [1.50 3.00];
baseline_phi_pi = 1.50;

status = table();
summary = table();
irf_series = table();
results = struct('name', {}, 'label', {}, 'phi_pi', {}, ...
    'line_style', {}, 'oo', {}, 'M', {});

for i = 1:numel(policy_rules)
    rule = policy_rules(i);
    scenario_name = ['negative_demand_' rule.name];
    scenario_label = rule.label;
    fprintf('\n=== Running %s: %s ===\n', scenario_name, scenario_label);

    scenario_text = make_negative_demand_model(base_text, rho_demand, demand_shock_stderr);
    scenario_text = set_parameter_line(scenario_text, 'phi_pi', rule.phi_pi);

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

        scenario = struct('name', scenario_name, 'label', scenario_label, ...
            'phi_pi', rule.phi_pi, 'line_style', rule.line_style, ...
            'rho_demand', rho_demand, 'shock_stderr', demand_shock_stderr);
        summary = [summary; collect_summary(loaded.oo_, scenario, shock_suffix, periods)]; %#ok<AGROW>
        irf_series = [irf_series; collect_irf_series(loaded.oo_, scenario, shock_suffix)]; %#ok<AGROW>

        results(end + 1).name = scenario_name; %#ok<SAGROW>
        results(end).label = scenario_label;
        results(end).phi_pi = rule.phi_pi;
        results(end).line_style = rule.line_style;
        results(end).oo = loaded.oo_;
        results(end).M = loaded.M_;

        status = [status; table(string(scenario_name), string(scenario_label), ...
            rule.phi_pi, rho_demand, demand_shock_stderr, "ok", "", ...
            'VariableNames', {'scenario','label','phi_pi','rho_demand', ...
            'shock_stderr','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Negative-demand policy scenario %s failed: %s', scenario_name, err.message);
        status = [status; table(string(scenario_name), string(scenario_label), ...
            rule.phi_pi, rho_demand, demand_shock_stderr, "failed", string(err.message), ...
            'VariableNames', {'scenario','label','phi_pi','rho_demand', ...
            'shock_stderr','status','notes'})]; %#ok<AGROW>
    end
end

tradeoff_metrics = collect_stability_sync_metrics(results, shock_suffix);
welfare_metrics = collect_welfare_metrics(results, shock_suffix, baseline_phi_pi);
evaluation_table = build_policy_evaluation_table(tradeoff_metrics, welfare_metrics);

writetable(status, 'negative_demand_policy_status.csv');
writetable(summary, 'negative_demand_policy_summary.csv');
writetable(irf_series, 'negative_demand_policy_irf_series.csv');
writetable(tradeoff_metrics, 'negative_demand_policy_tradeoff_metrics.csv');
writetable(welfare_metrics, 'negative_demand_policy_welfare_metrics.csv');
writetable(evaluation_table, 'negative_demand_policy_evaluation_table.csv');

fprintf('\nNegative demand policy experiment status\n');
fprintf('--------------------------------\n');
disp(status);

fprintf('\nAggregate stabilization and regional synchronization summary\n');
fprintf('--------------------------------\n');
disp(summary(:, {'label','min_r','min_yagg','min_pinfagg', ...
    'max_ds2','min_ig2','max_abs_y_gap','max_abs_pinf_gap'}));

if ~isempty(tradeoff_metrics)
    fprintf('\nInflation stability and regional synchronization metrics\n');
    fprintf('--------------------------------\n');
    disp(tradeoff_metrics(:, {'label','inflation_volatility', ...
        'output_volatility','output_desynchronization', ...
        'inflation_desynchronization','debt_service_desynchronization'}));
end

if ~isempty(welfare_metrics)
    fprintf('\nConsumption-equivalent welfare changes relative to phi_pi = %.1f\n', ...
        baseline_phi_pi);
    fprintf('--------------------------------\n');
    disp(welfare_metrics(:, {'label','cev_national_pct','cev_low_debt_pct', ...
        'cev_high_debt_pct','cev_ricardian_pct','cev_htm_pct'}));
end

if ~isempty(results)
    make_stability_sync_map(tradeoff_metrics);
    make_welfare_cev_figure(welfare_metrics);

    comparison_results = select_phi_results(results, irf_comparison_phi_pi);
    if numel(comparison_results) == numel(irf_comparison_phi_pi)
        make_national_figure(comparison_results, shock_suffix);
        make_high_debt_figure(comparison_results, shock_suffix);
        make_gap_figure(comparison_results, shock_suffix);
        make_appendix_four_line_figure(comparison_results, shock_suffix);
    end
end

function text = make_negative_demand_model(text, rho_demand, demand_shock_stderr)
    text = replace_exactly_once(text, 'yagg pinfagg r mp;', ...
        'yagg pinfagg r mp demand;');
    text = replace_exactly_once(text, 'varexo emp;', 'varexo emp ed;');
    text = replace_exactly_once(text, ...
        'rho_a rho_g rho_tr rho_z rho_fp rho_ig rho_mp rho_r', ...
        'rho_a rho_g rho_tr rho_z rho_fp rho_ig rho_mp rho_r rho_demand');

    text = regex_replace_once(text, '(?m)^(rho_r\s*=\s*[^;]+;)', ...
        sprintf('$1\nrho_demand = %.8g;', rho_demand));

    old_euler = 'lam1 = beta * lam1(+1) * r / pinf1(+1);';
    new_euler = ['lam1 = beta * lam1(+1) * r / pinf1(+1) * exp(-demand); ' ...
        '// positive ed creates a persistent negative demand wedge'];
    text = replace_exactly_once(text, old_euler, new_euler);

    demand_process_block = sprintf(['mp = rho_mp * mp(-1) + emp;\n' ...
        '    demand = rho_demand * demand(-1) - ed;']);
    text = replace_exactly_once(text, 'mp = rho_mp * mp(-1) + emp;', ...
        demand_process_block);

    text = regex_replace_once(text, '(?m)^(\s*mp\s*=\s*0;)', ...
        sprintf('$1\n    demand = 0;'));

    shock_block = sprintf(['shocks;\n' ...
        '    var emp; stderr 0;\n' ...
        '    var ed; stderr %.8g;\n' ...
        'end;'], demand_shock_stderr);
    text = regex_replace_once(text, 'shocks;[\s\S]*?end;', shock_block);

    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp demand r rb1 rb2 yagg pinfagg\n' ...
        '    ds1 ds2 fs1 fs2\n' ...
        '    ig1 ig2 kg1 kg2\n' ...
        '    cr1 ch1 nr1 nh1 cr2 ch2 nr2 nh2\n' ...
        '    ym1 ym2 y1 y2 inv1 inv2 n1 n2 w1 w2 c1 c2\n' ...
        '    pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function text = set_parameter_line(text, name, value)
    pattern = ['(?m)^' regexptranslate('escape', name) '\s*=\s*[^;]+;'];
    replacement = sprintf('%-11s= %.8g;', name, value);
    count_matches = numel(regexp(text, pattern, 'match'));
    text = regexprep(text, pattern, replacement, 'once');
    if count_matches ~= 1
        error('Expected to replace parameter %s exactly once; replaced %d.', name, count_matches);
    end
end

function summary = collect_summary(oo_, scenario, shock_suffix, periods)
    demand = get_irf(oo_, 'demand', shock_suffix);
    r = get_irf(oo_, 'r', shock_suffix);
    yagg = get_irf(oo_, 'yagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);

    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    y1 = get_irf(oo_, 'y1', shock_suffix);
    y2 = get_irf(oo_, 'y2', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    ds_gap = ds2 - ds1;
    ig_gap = ig2 - ig1;
    y_gap = y2 - y1;
    pinf_gap = pinf2 - pinf1;

    summary = table(string(scenario.name), string(scenario.label), scenario.phi_pi, ...
        scenario.rho_demand, scenario.shock_stderr, ...
        min(demand), min(r), min(yagg), min(pinfagg), ...
        max(ds2), min(fs2), min(ig2), min(kg2), min(y2), min(c2), min(pinf2), ...
        max(abs(ds_gap)), max(abs(ig_gap)), max(abs(y_gap)), max(abs(pinf_gap)), ...
        yagg(periods(1)), yagg(periods(2)), yagg(periods(3)), yagg(periods(4)), ...
        pinfagg(periods(1)), pinfagg(periods(2)), pinfagg(periods(3)), pinfagg(periods(4)), ...
        ds2(periods(1)), ds2(periods(2)), ds2(periods(3)), ds2(periods(4)), ...
        ig2(periods(1)), ig2(periods(2)), ig2(periods(3)), ig2(periods(4)), ...
        y_gap(periods(1)), y_gap(periods(2)), y_gap(periods(3)), y_gap(periods(4)), ...
        pinf_gap(periods(1)), pinf_gap(periods(2)), pinf_gap(periods(3)), pinf_gap(periods(4)), ...
        'VariableNames', {'scenario','label','phi_pi','rho_demand','shock_stderr', ...
        'min_demand','min_r','min_yagg','min_pinfagg', ...
        'max_ds2','min_fs2','min_ig2','min_kg2','min_y2','min_c2','min_pinf2', ...
        'max_abs_ds_gap','max_abs_ig_gap','max_abs_y_gap','max_abs_pinf_gap', ...
        'yagg_t1','yagg_t4','yagg_t8','yagg_t12', ...
        'pinfagg_t1','pinfagg_t4','pinfagg_t8','pinfagg_t12', ...
        'ds2_t1','ds2_t4','ds2_t8','ds2_t12', ...
        'ig2_t1','ig2_t4','ig2_t8','ig2_t12', ...
        'y_gap_t1','y_gap_t4','y_gap_t8','y_gap_t12', ...
        'pinf_gap_t1','pinf_gap_t4','pinf_gap_t8','pinf_gap_t12'});
end

function series = collect_irf_series(oo_, scenario, shock_suffix)
    demand = get_irf(oo_, 'demand', shock_suffix);
    r = get_irf(oo_, 'r', shock_suffix);
    yagg = get_irf(oo_, 'yagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);
    cr1 = get_irf(oo_, 'cr1', shock_suffix);
    ch1 = get_irf(oo_, 'ch1', shock_suffix);
    nr1 = get_irf(oo_, 'nr1', shock_suffix);
    nh1 = get_irf(oo_, 'nh1', shock_suffix);
    cr2 = get_irf(oo_, 'cr2', shock_suffix);
    ch2 = get_irf(oo_, 'ch2', shock_suffix);
    nr2 = get_irf(oo_, 'nr2', shock_suffix);
    nh2 = get_irf(oo_, 'nh2', shock_suffix);
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs1 = get_irf(oo_, 'fs1', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg1 = get_irf(oo_, 'kg1', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    y1 = get_irf(oo_, 'y1', shock_suffix);
    y2 = get_irf(oo_, 'y2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);
    horizon = (1:numel(yagg))';

    ds_gap = ds2(:) - ds1(:);
    fs_gap = fs2(:) - fs1(:);
    ig_gap = ig2(:) - ig1(:);
    kg_gap = kg2(:) - kg1(:);
    y_gap = y2(:) - y1(:);
    c_gap = c2(:) - c1(:);
    pinf_gap = pinf2(:) - pinf1(:);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.phi_pi, numel(horizon), 1), ...
        repmat(scenario.rho_demand, numel(horizon), 1), ...
        repmat(scenario.shock_stderr, numel(horizon), 1), ...
        horizon, demand(:), r(:), yagg(:), pinfagg(:), ...
        cr1(:), ch1(:), nr1(:), nh1(:), cr2(:), ch2(:), nr2(:), nh2(:), ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        y1(:), y2(:), c1(:), c2(:), pinf1(:), pinf2(:), ...
        ds_gap, fs_gap, ig_gap, kg_gap, y_gap, c_gap, pinf_gap, ...
        abs(ds_gap), abs(ig_gap), abs(y_gap), abs(pinf_gap), ...
        'VariableNames', {'scenario','label','phi_pi','rho_demand','shock_stderr', ...
        'horizon','demand','r','yagg','pinfagg', ...
        'cr1','ch1','nr1','nh1','cr2','ch2','nr2','nh2', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'y1','y2','c1','c2','pinf1','pinf2', ...
        'ds_gap','fs_gap','ig_gap','kg_gap','y_gap','c_gap','pinf_gap', ...
        'abs_ds_gap','abs_ig_gap','abs_y_gap','abs_pinf_gap'});
end

function metrics = collect_stability_sync_metrics(results, shock_suffix)
    metrics = table();
    for i = 1:numel(results)
        pinfagg_pct = 100 * get_irf(results(i).oo, 'pinfagg', shock_suffix);
        yagg_pct = 100 * get_irf(results(i).oo, 'yagg', shock_suffix);
        y1_pct = 100 * get_irf(results(i).oo, 'y1', shock_suffix);
        y2_pct = 100 * get_irf(results(i).oo, 'y2', shock_suffix);
        pinf1_pct = 100 * get_irf(results(i).oo, 'pinf1', shock_suffix);
        pinf2_pct = 100 * get_irf(results(i).oo, 'pinf2', shock_suffix);
        ds1_pct = 100 * get_irf(results(i).oo, 'ds1', shock_suffix);
        ds2_pct = 100 * get_irf(results(i).oo, 'ds2', shock_suffix);
        s1 = get_model_parameter(results(i).M, 's1');
        s2 = get_model_parameter(results(i).M, 's2');

        inflation_volatility = sqrt(sum(pinfagg_pct(:).^2));
        output_volatility = sqrt(sum(yagg_pct(:).^2));
        output_desynchronization = sqrt(sum((y2_pct(:) - y1_pct(:)).^2));
        inflation_desynchronization = sqrt(sum((pinf2_pct(:) - pinf1_pct(:)).^2));
        debt_service_desynchronization = sqrt(sum((ds2_pct(:) - ds1_pct(:)).^2));
        weighted_output_desynchronization = sqrt(sum( ...
            s1 * (y1_pct(:) - yagg_pct(:)).^2 ...
            + s2 * (y2_pct(:) - yagg_pct(:)).^2));

        row = table(string(results(i).name), string(results(i).label), ...
            results(i).phi_pi, numel(pinfagg_pct), ...
            inflation_volatility, output_volatility, ...
            output_desynchronization, inflation_desynchronization, ...
            debt_service_desynchronization, weighted_output_desynchronization, ...
            'VariableNames', {'scenario','label','phi_pi','irf_periods', ...
            'inflation_volatility','output_volatility', ...
            'output_desynchronization','inflation_desynchronization', ...
            'debt_service_desynchronization', ...
            'weighted_output_desynchronization'});
        metrics = [metrics; row]; %#ok<AGROW>
    end

    if ~isempty(metrics)
        metrics = sortrows(metrics, 'phi_pi');
    end
end

function welfare_metrics = collect_welfare_metrics(results, shock_suffix, baseline_phi_pi)
    welfare_metrics = table();
    if isempty(results)
        return;
    end

    welfare_results = repmat(struct(), numel(results), 1);
    for i = 1:numel(results)
        welfare_results(i).scenario = results(i).name;
        welfare_results(i).label = results(i).label;
        welfare_results(i).phi_pi = results(i).phi_pi;
        welfare_results(i).welfare = compute_conditional_welfare(results(i), shock_suffix);
    end

    baseline_idx = find(abs([welfare_results.phi_pi] - baseline_phi_pi) < 1e-10, 1);
    if isempty(baseline_idx)
        error('Baseline phi_pi %.4g not found for welfare comparison.', baseline_phi_pi);
    end
    baseline = welfare_results(baseline_idx).welfare;

    for i = 1:numel(welfare_results)
        current = welfare_results(i).welfare;
        cev_national = solve_consumption_equivalent( ...
            baseline.paths.national, current.W_national, baseline.params);
        cev_low = solve_consumption_equivalent( ...
            baseline.paths.low_debt, current.W_low_debt, baseline.params);
        cev_high = solve_consumption_equivalent( ...
            baseline.paths.high_debt, current.W_high_debt, baseline.params);
        cev_ricardian = solve_consumption_equivalent( ...
            baseline.paths.ricardian, current.W_ricardian, baseline.params);
        cev_htm = solve_consumption_equivalent( ...
            baseline.paths.htm, current.W_htm, baseline.params);

        row = table(string(welfare_results(i).scenario), string(welfare_results(i).label), ...
            welfare_results(i).phi_pi, current.irf_periods, baseline_phi_pi, ...
            current.W_national, current.W_low_debt, current.W_high_debt, ...
            current.W_ricardian, current.W_htm, ...
            100 * cev_national, 100 * cev_low, 100 * cev_high, ...
            100 * cev_ricardian, 100 * cev_htm, ...
            'VariableNames', {'scenario','label','phi_pi','irf_periods','baseline_phi_pi', ...
            'welfare_national','welfare_low_debt','welfare_high_debt', ...
            'welfare_ricardian','welfare_htm', ...
            'cev_national_pct','cev_low_debt_pct','cev_high_debt_pct', ...
            'cev_ricardian_pct','cev_htm_pct'});
        welfare_metrics = [welfare_metrics; row]; %#ok<AGROW>
    end

    welfare_metrics = sortrows(welfare_metrics, 'phi_pi');
end

function welfare = compute_conditional_welfare(result, shock_suffix)
    params = get_welfare_parameters(result.M);

    cr1 = get_level_path(result, 'cr1', shock_suffix);
    ch1 = get_level_path(result, 'ch1', shock_suffix);
    nr1 = get_level_path(result, 'nr1', shock_suffix);
    nh1 = get_level_path(result, 'nh1', shock_suffix);
    cr2 = get_level_path(result, 'cr2', shock_suffix);
    ch2 = get_level_path(result, 'ch2', shock_suffix);
    nr2 = get_level_path(result, 'nr2', shock_suffix);
    nh2 = get_level_path(result, 'nh2', shock_suffix);

    periods = numel(cr1);
    discount = params.beta .^ (0:periods - 1)';

    WR1 = sum(discount .* period_utility(cr1, nr1, params));
    WH1 = sum(discount .* period_utility(ch1, nh1, params));
    WR2 = sum(discount .* period_utility(cr2, nr2, params));
    WH2 = sum(discount .* period_utility(ch2, nh2, params));

    W_low_debt = (1 - params.lambda1) * WR1 + params.lambda1 * WH1;
    W_high_debt = (1 - params.lambda2) * WR2 + params.lambda2 * WH2;
    W_national = params.s1 * W_low_debt + params.s2 * W_high_debt;
    W_ricardian = params.s1 * (1 - params.lambda1) * WR1 ...
        + params.s2 * (1 - params.lambda2) * WR2;
    W_htm = params.s1 * params.lambda1 * WH1 ...
        + params.s2 * params.lambda2 * WH2;

    welfare = struct();
    welfare.params = params;
    welfare.irf_periods = periods;
    welfare.W_national = W_national;
    welfare.W_low_debt = W_low_debt;
    welfare.W_high_debt = W_high_debt;
    welfare.W_ricardian = W_ricardian;
    welfare.W_htm = W_htm;

    welfare.paths.national = make_welfare_paths( ...
        {cr1, ch1, cr2, ch2}, {nr1, nh1, nr2, nh2}, ...
        [params.s1 * (1 - params.lambda1), params.s1 * params.lambda1, ...
         params.s2 * (1 - params.lambda2), params.s2 * params.lambda2]);
    welfare.paths.low_debt = make_welfare_paths( ...
        {cr1, ch1}, {nr1, nh1}, [1 - params.lambda1, params.lambda1]);
    welfare.paths.high_debt = make_welfare_paths( ...
        {cr2, ch2}, {nr2, nh2}, [1 - params.lambda2, params.lambda2]);
    welfare.paths.ricardian = make_welfare_paths( ...
        {cr1, cr2}, {nr1, nr2}, ...
        [params.s1 * (1 - params.lambda1), params.s2 * (1 - params.lambda2)]);
    welfare.paths.htm = make_welfare_paths( ...
        {ch1, ch2}, {nh1, nh2}, ...
        [params.s1 * params.lambda1, params.s2 * params.lambda2]);
end

function params = get_welfare_parameters(M_)
    params = struct();
    params.beta = get_model_parameter(M_, 'beta');
    params.sigma = get_model_parameter(M_, 'sigma');
    params.varphi = get_model_parameter(M_, 'varphi');
    params.chi_n = get_model_parameter(M_, 'chi_n');
    params.lambda1 = get_model_parameter(M_, 'lambda1');
    params.lambda2 = get_model_parameter(M_, 'lambda2');
    params.s1 = get_model_parameter(M_, 's1');
    params.s2 = get_model_parameter(M_, 's2');
end

function paths = make_welfare_paths(consumption_paths, labor_paths, weights)
    paths = struct('C', {}, 'N', {}, 'weight', {});
    for i = 1:numel(consumption_paths)
        paths(end + 1).C = consumption_paths{i}(:); %#ok<AGROW>
        paths(end).N = labor_paths{i}(:);
        paths(end).weight = weights(i);
    end
end

function xi = solve_consumption_equivalent(base_paths, target_welfare, params)
    base_welfare = welfare_with_consumption_shift(base_paths, 0, params);
    if abs(target_welfare - base_welfare) < 1e-12
        xi = 0;
        return;
    end

    if target_welfare > base_welfare
        lower = 0;
        upper = 0.01;
        while welfare_with_consumption_shift(base_paths, upper, params) < target_welfare
            upper = 2 * upper + 0.01;
            if upper > 100
                error('Unable to bracket positive consumption-equivalent change.');
            end
        end
    else
        lower = -0.999999;
        upper = 0;
    end

    for iter = 1:120
        mid = 0.5 * (lower + upper);
        mid_welfare = welfare_with_consumption_shift(base_paths, mid, params);
        if mid_welfare < target_welfare
            lower = mid;
        else
            upper = mid;
        end
    end
    xi = 0.5 * (lower + upper);
end

function value = welfare_with_consumption_shift(paths, xi, params)
    if xi <= -1
        value = -Inf;
        return;
    end

    periods = numel(paths(1).C);
    discount = params.beta .^ (0:periods - 1)';
    value = 0;
    for i = 1:numel(paths)
        shifted_consumption = (1 + xi) * paths(i).C;
        value = value + paths(i).weight ...
            * sum(discount .* period_utility(shifted_consumption, paths(i).N, params));
    end
end

function utility = period_utility(consumption, labor, params)
    if any(consumption <= 0)
        error('Consumption path contains non-positive values.');
    end
    if any(labor < 0)
        error('Labor path contains negative values.');
    end

    if abs(params.sigma - 1) < 1e-10
        consumption_utility = log(consumption);
    else
        consumption_utility = consumption.^(1 - params.sigma) ...
            / (1 - params.sigma);
    end
    labor_disutility = params.chi_n * labor.^(1 + params.varphi) ...
        / (1 + params.varphi);
    utility = consumption_utility - labor_disutility;
end

function level_path = get_level_path(result, var_name, shock_suffix)
    steady_value = get_steady_state_value(result.M, result.oo, var_name);
    level_path = steady_value + get_irf(result.oo, var_name, shock_suffix);
    level_path = level_path(:);
end

function table_out = build_policy_evaluation_table(stability_metrics, welfare_metrics)
    table_out = table();
    if isempty(stability_metrics) || isempty(welfare_metrics)
        return;
    end

    stability_metrics = sortrows(stability_metrics, 'phi_pi');
    welfare_metrics = sortrows(welfare_metrics, 'phi_pi');

    indicators = [
        "National inflation volatility V_pi";
        "National output volatility V_Y";
        "Regional output desynchronization D_Y";
        "Regional inflation desynchronization D_pi";
        "Debt-service pressure desynchronization D_DS";
        "National welfare CEV, percent";
        "Low-debt welfare CEV, percent";
        "High-debt welfare CEV, percent";
        "Ricardian welfare CEV, percent";
        "Hand-to-mouth welfare CEV, percent"];

    table_out = table(indicators, 'VariableNames', {'indicator'});
    for i = 1:height(stability_metrics)
        phi = stability_metrics.phi_pi(i);
        welfare_idx = find(abs(welfare_metrics.phi_pi - phi) < 1e-10, 1);
        if isempty(welfare_idx)
            error('Missing welfare metrics for phi_pi = %.4g.', phi);
        end

        values = [
            stability_metrics.inflation_volatility(i);
            stability_metrics.output_volatility(i);
            stability_metrics.output_desynchronization(i);
            stability_metrics.inflation_desynchronization(i);
            stability_metrics.debt_service_desynchronization(i);
            welfare_metrics.cev_national_pct(welfare_idx);
            welfare_metrics.cev_low_debt_pct(welfare_idx);
            welfare_metrics.cev_high_debt_pct(welfare_idx);
            welfare_metrics.cev_ricardian_pct(welfare_idx);
            welfare_metrics.cev_htm_pct(welfare_idx)];

        column_name = matlab.lang.makeValidName(sprintf('phi_%.1f', phi));
        table_out.(column_name) = values;
    end
end

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('IRF field not found: %s', field);
    end
    irf = oo_.irfs.(field);
end

function value = get_model_parameter(M_, name)
    names = M_.param_names;
    if ischar(names) || isstring(names)
        names = cellstr(names);
    end
    idx = find(strcmp(names, name), 1);
    if isempty(idx)
        error('Parameter not found in M_: %s', name);
    end
    value = M_.params(idx);
end

function value = get_steady_state_value(M_, oo_, name)
    names = M_.endo_names;
    if ischar(names) || isstring(names)
        names = cellstr(names);
    end
    idx = find(strcmp(names, name), 1);
    if isempty(idx)
        error('Endogenous variable not found in M_: %s', name);
    end
    value = oo_.steady_state(idx);
end

function selected = select_phi_results(results, phi_pi_values)
    selected = results([]);
    for i = 1:numel(phi_pi_values)
        idx = find(abs([results.phi_pi] - phi_pi_values(i)) < 1e-10, 1);
        if ~isempty(idx)
            selected(end + 1) = results(idx); %#ok<AGROW>
        end
    end
end

function make_stability_sync_map(metrics)
    if isempty(metrics)
        return;
    end

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 760 620]);
    x = metrics.output_desynchronization;
    y = metrics.inflation_volatility;
    phi_pi = metrics.phi_pi;

    plot(x, y, '-o', 'Color', [0.05 0.20 0.35], ...
        'MarkerFaceColor', [0.05 0.20 0.35], 'MarkerSize', 6, 'LineWidth', 1.5);
    hold on;
    for i = 1:height(metrics)
        text(x(i), y(i), sprintf('  %.1f', phi_pi(i)), ...
            'VerticalAlignment', 'middle', 'Interpreter', 'none');
    end

    pad_x = 0.08 * max(max(x) - min(x), eps);
    pad_y = 0.08 * max(max(y) - min(y), eps);
    xlim([min(x) - pad_x, max(x) + pad_x]);
    ylim([min(y) - pad_y, max(y) + pad_y]);

    xlabel('Regional output desynchronization D_Y');
    ylabel('National inflation volatility V_pi');
    title({'Figure 4. Inflation stability and regional synchronization by phi_pi', ...
        'Lower-left means lower inflation volatility and stronger regional synchronization'}, ...
        'Interpreter', 'none');
    grid on;
    exportgraphics(fig, 'figure4_negative_demand_stability_sync_map.png', ...
        'Resolution', 180);
    close(fig);
end

function make_welfare_cev_figure(welfare_metrics)
    if isempty(welfare_metrics)
        return;
    end

    welfare_metrics = sortrows(welfare_metrics, 'phi_pi');
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 850 560]);
    phi = welfare_metrics.phi_pi;

    plot(phi, welfare_metrics.cev_national_pct, '-o', ...
        'LineWidth', 1.5, 'Color', [0.05 0.20 0.35], ...
        'MarkerFaceColor', [0.05 0.20 0.35]);
    hold on;
    plot(phi, welfare_metrics.cev_low_debt_pct, '--s', ...
        'LineWidth', 1.3, 'Color', [0.30 0.30 0.30]);
    plot(phi, welfare_metrics.cev_high_debt_pct, '--^', ...
        'LineWidth', 1.3, 'Color', [0.65 0.10 0.10]);
    plot(phi, welfare_metrics.cev_ricardian_pct, ':d', ...
        'LineWidth', 1.3, 'Color', [0.15 0.45 0.35]);
    plot(phi, welfare_metrics.cev_htm_pct, ':v', ...
        'LineWidth', 1.3, 'Color', [0.55 0.35 0.10]);
    yline(0, ':');

    xlabel('Taylor-rule inflation response \phi_\pi');
    ylabel('Consumption-equivalent welfare change relative to \phi_\pi = 1.5 (%)');
    title('Consumption-equivalent welfare under negative demand shock', ...
        'Interpreter', 'none');
    legend({'National','Low-debt region','High-debt region', ...
        'Ricardian households','Hand-to-mouth households'}, ...
        'Location', 'best', 'Interpreter', 'none');
    grid on;
    exportgraphics(fig, 'figure4_negative_demand_welfare_cev.png', ...
        'Resolution', 180);
    close(fig);
end

function make_national_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1120 360]);
    tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'r', '', 'Policy rate');
    plot_policy_panel(results, shock_suffix, 'yagg', '', 'National output');
    plot_policy_panel(results, shock_suffix, 'pinfagg', '', 'National inflation');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('Figure 4a. Aggregate stabilization under a persistent negative demand shock', ...
        'Interpreter', 'none');
    exportgraphics(fig, 'figure4_negative_demand_national_irfs.png', 'Resolution', 180);
    close(fig);
end

function make_high_debt_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'ds2', '', 'High-debt debt service');
    plot_policy_panel(results, shock_suffix, 'ig2', '', 'High-debt public investment');
    plot_policy_panel(results, shock_suffix, 'y2', '', 'High-debt output');
    plot_policy_panel(results, shock_suffix, 'c2', '', 'High-debt consumption');
    plot_policy_panel(results, shock_suffix, 'pinf2', '', 'High-debt inflation');
    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    nexttile;
    axis off;

    sgtitle('Figure 4b. High-debt regional responses under alternative monetary rules', ...
        'Interpreter', 'none');
    exportgraphics(fig, 'figure4_negative_demand_high_debt_irfs.png', 'Resolution', 180);
    close(fig);
end

function make_gap_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1120 660]);
    tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'ds2', 'ds1', 'Debt service gap: high - low');
    plot_policy_panel(results, shock_suffix, 'ig2', 'ig1', 'Public investment gap: high - low');
    plot_policy_panel(results, shock_suffix, 'y2', 'y1', 'Output gap: high - low');
    plot_policy_panel(results, shock_suffix, 'pinf2', 'pinf1', 'Inflation gap: high - low');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('Figure 4c. Regional differentiation under alternative monetary rules', ...
        'Interpreter', 'none');
    exportgraphics(fig, 'figure4_negative_demand_gap_irfs.png', 'Resolution', 180);
    close(fig);
end

function make_appendix_four_line_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

    plot_four_line_panel(results, shock_suffix, 'ds', 'Debt service pressure');
    plot_four_line_panel(results, shock_suffix, 'ig', 'Public investment');
    plot_four_line_panel(results, shock_suffix, 'y', 'Output');
    plot_four_line_panel(results, shock_suffix, 'c', 'Consumption');
    plot_four_line_panel(results, shock_suffix, 'pinf', 'Inflation');
    legend(get_four_line_labels(results), 'Location', 'best', 'Interpreter', 'none');
    nexttile;
    axis off;

    sgtitle('Appendix Figure 4. Two-region responses under alternative monetary rules', ...
        'Interpreter', 'none');
    exportgraphics(fig, 'figure4_negative_demand_appendix_four_line_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function labels = get_labels(results)
    labels = strings(numel(results), 1);
    for i = 1:numel(results)
        labels(i) = string(results(i).label);
    end
end

function labels = get_four_line_labels(results)
    labels = strings(2 * numel(results), 1);
    k = 1;
    for i = 1:numel(results)
        labels(k) = "Low debt, " + string(results(i).label);
        labels(k + 1) = "High debt, " + string(results(i).label);
        k = k + 2;
    end
end

function plot_policy_panel(results, shock_suffix, var_a, var_b, title_text)
    nexttile;
    line_color = [0.05 0.20 0.35];
    for i = 1:numel(results)
        irf_a = get_irf(results(i).oo, var_a, shock_suffix);
        if isempty(var_b)
            y = irf_a;
        else
            irf_b = get_irf(results(i).oo, var_b, shock_suffix);
            y = irf_a - irf_b;
        end
        horizon = 1:numel(y);
        plot(horizon, y, 'LineWidth', 1.5, 'Color', line_color, ...
            'LineStyle', results(i).line_style);
        hold on;
    end
    yline(0, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('period');
    grid on;
end

function plot_four_line_panel(results, shock_suffix, var_prefix, title_text)
    nexttile;
    low_color = [0.25 0.25 0.25];
    high_color = [0.65 0.10 0.10];
    for i = 1:numel(results)
        low = get_irf(results(i).oo, [var_prefix '1'], shock_suffix);
        high = get_irf(results(i).oo, [var_prefix '2'], shock_suffix);
        horizon = 1:numel(low);
        plot(horizon, low, 'LineWidth', 1.3, 'Color', low_color, ...
            'LineStyle', results(i).line_style);
        hold on;
        plot(horizon, high, 'LineWidth', 1.3, 'Color', high_color, ...
            'LineStyle', results(i).line_style);
    end
    yline(0, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('period');
    grid on;
end

function text = replace_exactly_once(text, old, new)
    count_matches = numel(strfind(text, old));
    if count_matches ~= 1
        error('Expected to replace text exactly once; found %d matches: %s', ...
            count_matches, old);
    end
    text = strrep(text, old, new);
end

function text = regex_replace_once(text, pattern, replacement)
    count_matches = numel(regexp(text, pattern, 'match'));
    text = regexprep(text, pattern, replacement, 'once');
    if count_matches ~= 1
        error('Expected regex replacement exactly once; found %d matches: %s', ...
            count_matches, pattern);
    end
end
