function run_policy_counterfactual_experiment()
% Policy counterfactual experiments.
%
% The script keeps the baseline monetary tightening shock and steady state
% fixed, then changes one institutional arrangement at a time:
% 1. a hard local debt-balance quota solved with OccBin;
% 2. central fiscal stabilization through transfers to local governments.


script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir,'../utils'));
caller_dir = pwd;
restore_directory = onCleanup(@() cd(caller_dir));
cd(script_dir);
addpath(script_dir);

dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

base_mod = fullfile(script_dir, '..', 'baseline', 'RANK_two_region_baseline.mod');
base_text = fileread(base_mod);
base_text = strrep(base_text, sprintf('\r\n'), sprintf('\n'));

% Hard local-debt quota. The quota is imposed on the debt balance B_j rather
% than on B_j/(4X_j), matching China's local government debt-balance limit system.
% Region 2 starts below the quota, but the baseline monetary-tightening path
% pushes B_2 above the threshold and activates the OccBin regime.
limit_settings = struct( ...
    'cap_threshold', 1.000, ...
    'ubar1', 1.60 / (1.002 * 1.60), ...
    'ubar2', 4.00 / (1.002 * 4.00), ...
    'debt_cap1', 1.002 * 1.60, ...
    'debt_cap2', 1.002 * 4.00, ...
    'bind_tol', 1.0e-6, ...
    'relax_tol', 1.0e-8);

policy_rules = struct( ...
    'name', {'policy_cf_baseline', 'policy_cf_strict_debt_cap'}, ...
    'label', {'基准模型', '严格债务余额限额规则'}, ...
    'use_occbin', {false, true}, ...
    'line_style', {'-', '--'});

transfer_rules = struct( ...
    'name', {'policy_cf_no_transfer_stabilizer', 'policy_cf_central_transfer_stabilizer'}, ...
    'label', {'无中央转移稳定器', '中央转移稳定器'}, ...
    'rho_z', {0.00, 0.70}, ...
    'phi_z_ds', {0.00, 0.015}, ...
    'phi_z_b', {0.00, 0.005}, ...
    'line_style', {'-', '--'});

balance_rules = struct( ...
    'name', {'policy_cf_standard_taylor', 'policy_cf_regional_balance_taylor'}, ...
    'label', {'标准 Taylor 规则', '地区平衡型 Taylor 规则'}, ...
    'phi_reg', {0.00, 2.00}, ...
    'line_style', {'-', '--'});

shock_suffix = '_emp';
periods = [1 4 8 12];
d_ann1 = 0.40;
d_ann2 = 1.00;

status = table();
summary = table();
irf_series = table();
results = struct('name', {}, 'label', {}, 'use_occbin', {}, ...
    'line_style', {}, 'limit_settings', {}, 'oo', {}, 'M', {});

transfer_status = table();
transfer_summary = table();
transfer_irf_series = table();
transfer_results = struct('name', {}, 'label', {}, ...
    'rho_z', {}, 'phi_z_ds', {}, 'phi_z_b', {}, ...
    'line_style', {}, 'oo', {});

balance_status = table();
balance_summary = table();
balance_irf_series = table();
balance_results = struct('name', {}, 'label', {}, ...
    'phi_reg', {}, 'line_style', {}, 'oo', {});

for i = 1:numel(policy_rules)
    rule = policy_rules(i);
    fprintf('\n=== Running %s: %s ===\n', rule.name, rule.label);

    if rule.use_occbin
        scenario_text = make_strict_debt_cap_model(base_text, limit_settings);
        scenario_text = set_policy_occbin_solver_block(scenario_text);
    else
        scenario_text = set_policy_stoch_simul_list(base_text);
    end

    scenario_mod = [rule.name '.mod'];
    fid = fopen(fullfile(script_dir, scenario_mod), 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        evalin('base', 'clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;');
        result_file = fullfile(script_dir, rule.name, 'Output', [rule.name '_results.mat']);
        delete_stale_result_file(result_file);
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        loaded = load(result_file, 'oo_', 'M_');
        if rule.use_occbin
            loaded.oo_ = occbin_to_irfs(loaded.oo_, loaded.M_, 40, shock_suffix);
        end

        scenario = struct('name', rule.name, 'label', rule.label, ...
            'use_occbin', rule.use_occbin, ...
            'limit_settings', limit_settings);
        summary = [summary; collect_summary(loaded.oo_, loaded.M_, scenario, ...
            periods, shock_suffix)]; %#ok<AGROW>
        irf_series = [irf_series; collect_irf_series(loaded.oo_, loaded.M_, scenario, ...
            shock_suffix)]; %#ok<AGROW>

        results(end + 1).name = rule.name; %#ok<SAGROW>
        results(end).label = rule.label;
        results(end).use_occbin = rule.use_occbin;
        results(end).line_style = rule.line_style;
        results(end).limit_settings = limit_settings;
        results(end).oo = loaded.oo_;
        results(end).M = loaded.M_;

        status = [status; table(string(rule.name), string(rule.label), ...
            limit_settings.cap_threshold, ...
            limit_settings.ubar1, limit_settings.ubar2, "ok", "", ...
            'VariableNames', {'scenario','label','cap_threshold', ...
            'ubar1','ubar2','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Policy counterfactual %s failed: %s', rule.name, err.message);
        status = [status; table(string(rule.name), string(rule.label), ...
            limit_settings.cap_threshold, ...
            limit_settings.ubar1, limit_settings.ubar2, "failed", string(err.message), ...
            'VariableNames', {'scenario','label','cap_threshold', ...
            'ubar1','ubar2','status','notes'})]; %#ok<AGROW>
    end
end
% End of policy counterfactual helpers.
writetable(status, fullfile(script_dir, 'policy_counterfactual_status.csv'));
writetable(summary, fullfile(script_dir, 'policy_counterfactual_summary.csv'));
writetable(irf_series, fullfile(script_dir, 'policy_counterfactual_irf_series.csv'));

fprintf('\nPolicy counterfactual status\n');
fprintf('--------------------------------\n');
disp(status);

fprintf('\nDebt-limit discipline counterfactual summary\n');
fprintf('--------------------------------\n');
disp(summary(:, {'label','max_u2','max_debt_ratio2', ...
    'max_ds2','min_ig2','min_xloc2','max_abs_ig_gap','max_abs_y_gap'}));


for i = 1:numel(transfer_rules)
    rule = transfer_rules(i);
    fprintf('\n=== Running %s: %s ===\n', rule.name, rule.label);

    scenario_text = make_central_transfer_model(base_text, rule);
    scenario_text = set_transfer_stoch_simul_list(scenario_text);

    scenario_mod = [rule.name '.mod'];
    fid = fopen(fullfile(script_dir, scenario_mod), 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        evalin('base', 'clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;');
        result_file = fullfile(script_dir, rule.name, 'Output', [rule.name '_results.mat']);
        delete_stale_result_file(result_file);
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        loaded = load(result_file, 'oo_');

        scenario = struct('name', rule.name, 'label', rule.label, ...
            'rho_z', rule.rho_z, ...
            'phi_z_ds', rule.phi_z_ds, 'phi_z_b', rule.phi_z_b);
        transfer_summary = [transfer_summary; collect_transfer_summary( ...
            loaded.oo_, scenario, periods, shock_suffix, d_ann1, d_ann2)]; %#ok<AGROW>
        transfer_irf_series = [transfer_irf_series; collect_transfer_irf_series( ...
            loaded.oo_, scenario, shock_suffix, d_ann1, d_ann2)]; %#ok<AGROW>

        transfer_results(end + 1).name = rule.name; %#ok<SAGROW>
        transfer_results(end).label = rule.label;
        transfer_results(end).rho_z = rule.rho_z;
        transfer_results(end).phi_z_ds = rule.phi_z_ds;
        transfer_results(end).phi_z_b = rule.phi_z_b;
        transfer_results(end).line_style = rule.line_style;
        transfer_results(end).oo = loaded.oo_;

        transfer_status = [transfer_status; table(string(rule.name), string(rule.label), ...
            rule.rho_z, rule.phi_z_ds, rule.phi_z_b, ...
            "ok", "", ...
            'VariableNames', {'scenario','label','rho_z', ...
            'phi_z_ds','phi_z_b','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Central transfer counterfactual %s failed: %s', rule.name, err.message);
        transfer_status = [transfer_status; table(string(rule.name), string(rule.label), ...
            rule.rho_z, rule.phi_z_ds, rule.phi_z_b, ...
            "failed", string(err.message), ...
            'VariableNames', {'scenario','label','rho_z', ...
            'phi_z_ds','phi_z_b','status','notes'})]; %#ok<AGROW>
    end
end

writetable(transfer_status, fullfile(script_dir, 'policy_counterfactual_transfer_status.csv'));
writetable(transfer_summary, fullfile(script_dir, 'policy_counterfactual_transfer_summary.csv'));
writetable(transfer_irf_series, fullfile(script_dir, 'policy_counterfactual_transfer_irf_series.csv'));

fprintf('\nCentral transfer stabilization counterfactual status\n');
fprintf('--------------------------------\n');
disp(transfer_status);

fprintf('\nCentral transfer stabilization counterfactual summary\n');
fprintf('--------------------------------\n');
disp(transfer_summary(:, {'label','max_z2','max_ds2','min_fs2', ...
    'min_ig2','min_xloc2','min_pinf2','max_abs_z_gap','max_abs_y_gap'}));


for i = 1:numel(balance_rules)
    rule = balance_rules(i);
    fprintf('\n=== Running %s: %s ===\n', rule.name, rule.label);

    scenario_text = make_regional_balance_model(base_text, rule);
    scenario_text = set_balance_stoch_simul_list(scenario_text);

    scenario_mod = [rule.name '.mod'];
    fid = fopen(fullfile(script_dir, scenario_mod), 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        evalin('base', 'clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;');
        result_file = fullfile(script_dir, rule.name, 'Output', [rule.name '_results.mat']);
        delete_stale_result_file(result_file);
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        loaded = load(result_file, 'oo_');

        scenario = struct('name', rule.name, 'label', rule.label, ...
            'phi_reg', rule.phi_reg);
        balance_summary = [balance_summary; collect_balance_summary( ...
            loaded.oo_, scenario, periods, shock_suffix)]; %#ok<AGROW>
        balance_irf_series = [balance_irf_series; collect_balance_irf_series( ...
            loaded.oo_, scenario, shock_suffix)]; %#ok<AGROW>

        balance_results(end + 1).name = rule.name; %#ok<SAGROW>
        balance_results(end).label = rule.label;
        balance_results(end).phi_reg = rule.phi_reg;
        balance_results(end).line_style = rule.line_style;
        balance_results(end).oo = loaded.oo_;

        balance_status = [balance_status; table(string(rule.name), string(rule.label), ...
            rule.phi_reg, "ok", "", ...
            'VariableNames', {'scenario','label','phi_reg','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Regional-balance monetary counterfactual %s failed: %s', ...
            rule.name, err.message);
        balance_status = [balance_status; table(string(rule.name), string(rule.label), ...
            rule.phi_reg, "failed", string(err.message), ...
            'VariableNames', {'scenario','label','phi_reg','status','notes'})]; %#ok<AGROW>
    end
end

writetable(balance_status, fullfile(script_dir, 'policy_counterfactual_regional_balance_status.csv'));
writetable(balance_summary, fullfile(script_dir, 'policy_counterfactual_regional_balance_summary.csv'));
writetable(balance_irf_series, fullfile(script_dir, 'policy_counterfactual_regional_balance_irf_series.csv'));

fprintf('\nRegional-balance monetary counterfactual status\n');
fprintf('--------------------------------\n');
disp(balance_status);

fprintf('\nRegional-balance monetary counterfactual summary\n');
fprintf('--------------------------------\n');
disp(balance_summary(:, {'label','phi_reg','max_r','min_r','min_xagg','min_pinfagg', ...
    'sync_y_l2','inflation_l2','output_l2','min_xloc2','max_ds2','min_ig2'}));

if any(status.status == "failed") || any(transfer_status.status == "failed") ...
        || any(balance_status.status == "failed")
    error('One or more policy-counterfactual scenarios failed; inspect the status CSV files.');
end

plot_policy_counterfactual();
end

function text = make_strict_debt_cap_model(text, settings)
    text = add_strict_debt_cap_variables(text);
    text = add_strict_debt_cap_parameters(text);
    text = add_strict_debt_cap_calibration(text, settings);
    text = add_strict_debt_cap_shadow_terms(text);
    text = add_occbin_debt_cap_block(text, settings);
end

function text = make_central_transfer_model(text, rule)
    text = set_parameter_value(text, 'rho_z', rule.rho_z);
    text = set_parameter_value(text, 'phi_z_ds', rule.phi_z_ds);
    text = set_parameter_value(text, 'phi_z_b', rule.phi_z_b);
end

function text = make_regional_balance_model(text, rule)
    text = add_regional_balance_parameter(text);
    text = add_regional_balance_calibration(text, rule.phi_reg);
    text = replace_taylor_rule_with_balance_target(text);
end

function text = add_strict_debt_cap_variables(text)
    old_line = '    yagg xloc1 xloc2 xagg pinfagg r mp d;';
    new_line = '    yagg xloc1 xloc2 xagg pinfagg r mp d xicap2;';
    text = replace_exactly_once(text, old_line, new_line);
end

function text = add_strict_debt_cap_parameters(text)
    old_line = 'mu_b phi_z_ds phi_z_b';
    new_line = ['mu_b phi_z_ds phi_z_b' newline ...
        '    debt_cap2 cap_bind_tol cap_relax_tol'];
    text = replace_exactly_once(text, old_line, new_line);
end

function text = add_strict_debt_cap_calibration(text, settings)
    insert_after = 'phi_z_b    = 0.00;';
    calibration = sprintf([insert_after '\n' ...
        '\n// Hard high-debt-region debt-balance quota for the OccBin counterfactual.\n' ...
        'debt_cap2  = %.8g;\n' ...
        'cap_bind_tol  = %.8g;\n' ...
        'cap_relax_tol = %.8g;'], ...
        settings.debt_cap2, settings.bind_tol, settings.relax_tol);
    text = replace_exactly_once(text, insert_after, calibration);
end

function text = add_strict_debt_cap_shadow_terms(text)
    old_euler2 = sprintf(['    lamg2 * (1 - varphi_b * (b2 / xbar2 - b_x2))\n' ...
        '        = beta_g * lamg2(+1) * rb2 / pinf2(+1);']);
    new_euler2 = sprintf(['    lamg2 * (1 - varphi_b * (b2 / xbar2 - b_x2))\n' ...
        '        = beta_g * lamg2(+1) * rb2 / pinf2(+1) + xicap2;']);
    text = replace_exactly_once(text, old_euler2, new_euler2);

    old_budget2 = sprintf(['    b2 = rb2(-1) / pinf2 * b2(-1) + g2 + ig2 + phiig2 + phib2\n' ...
        '         - (1 - theta_T) * tau_x * xloc2 - z2;']);
    new_budget2 = sprintf([old_budget2 '\n' ...
        '    [name=''Debt cap slack 2'', relax=''DEBTCAP2'']\n' ...
        '    xicap2 = 0;\n' ...
        '    [name=''Debt cap slack 2'', bind=''DEBTCAP2'']\n' ...
        '    b2 = debt_cap2;']);
    text = replace_exactly_once(text, old_budget2, new_budget2);

    steady_marker = sprintf(['    r = rbar;\n' ...
        '    mp = 0;\n' ...
        '    d = 0;']);
    steady_replacement = sprintf(['    r = rbar;\n' ...
        '    mp = 0;\n' ...
        '    d = 0;\n' ...
        '    xicap2 = 0;']);
    text = replace_exactly_once(text, steady_marker, steady_replacement);
end

function text = add_occbin_debt_cap_block(text, settings) %#ok<INUSD>
    marker = 'steady_state_model;';
    occbin_block = sprintf(['occbin_constraints;\n' ...
        '    name ''DEBTCAP2''; bind b2 - debt_cap2 > cap_bind_tol; relax xicap2 < -cap_relax_tol;\n' ...
        'end;\n\n' marker]);
    text = replace_exactly_once(text, marker, occbin_block);
end

function text = add_regional_balance_parameter(text)
    old_line = 'phi_pi phi_x tau_x theta_T';
    new_line = 'phi_pi phi_x phi_reg tau_x theta_T';
    text = replace_exactly_once(text, old_line, new_line);
end

function text = add_regional_balance_calibration(text, phi_reg)
    calibration = sprintf('$1\nphi_reg    = %.8g;', phi_reg);
    text = regex_replace_once(text, '(?m)^(phi_x\s*=\s*[^;]+;)', calibration);
end

function text = replace_taylor_rule_with_balance_target(text)
    old_rule = sprintf(['    r / rbar = (r(-1) / rbar)^rho_r\n' ...
        '        * ((pinfagg / pinfbar)^phi_pi * (xagg / xbar)^phi_x)^(1 - rho_r)\n' ...
        '        * exp(mp);']);
    new_rule = sprintf(['    // Normative regional-balance extension: when high-debt-region production GDP\n' ...
        '    // falls relative to low-debt-region production GDP, this term lowers the\n' ...
        '    // common policy rate for phi_reg > 0.\n' ...
        '    r / rbar = (r(-1) / rbar)^rho_r\n' ...
        '        * ((pinfagg / pinfbar)^phi_pi * (xagg / xbar)^phi_x\n' ...
        '           * (((xloc2 / xbar2) / (xloc1 / xbar1))^phi_reg))^(1 - rho_r)\n' ...
        '        * exp(mp);']);
    text = replace_exactly_once(text, old_rule, new_rule);
end

function text = set_policy_stoch_simul_list(text)
    text = set_emp_shock_stderr(text, 0.0025);
    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp r rb1 rb2 xagg pinfagg\n' ...
        '    z1 z2 g1 g2\n' ...
        '    b1 b2 ds1 ds2 fs1 fs2\n' ...
        '    ig1 ig2 kg1 kg2\n' ...
        '    xloc1 xloc2 c1 c2 inv1 inv2 pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function text = set_policy_occbin_solver_block(text)
    text = set_emp_shock_stderr(text, 0.0025);
    occbin_solver_block = sprintf(['shocks(surprise);\n' ...
        '    var emp;\n' ...
        '    periods 1;\n' ...
        '    values 0.0025;\n' ...
        'end;\n\n' ...
        'occbin_setup;\n' ...
        'occbin_solver(simul_periods = 40, simul_check_ahead_periods = 120, simul_max_check_ahead_periods = 120, simul_maxit = 200);']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        occbin_solver_block);
end

function text = set_transfer_stoch_simul_list(text)
    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp r rb1 rb2 xagg pinfagg\n' ...
        '    z1 z2 b1 b2 ds1 ds2 fs1 fs2\n' ...
        '    ig1 ig2 kg1 kg2\n' ...
        '    xloc1 xloc2 c1 c2 inv1 inv2 pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function text = set_balance_stoch_simul_list(text)
    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp r rb1 rb2 xagg pinfagg\n' ...
        '    ds1 ds2 fs1 fs2 ig1 ig2 kg1 kg2\n' ...
        '    xloc1 xloc2 c1 c2 inv1 inv2 pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function summary = collect_summary(oo_, M_, scenario, periods, shock_suffix)
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    xloc1 = get_irf(oo_, 'xloc1', shock_suffix);
    xloc2 = get_irf(oo_, 'xloc2', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    limit = scenario.limit_settings;
    u1 = debt_limit_series(oo_, M_, limit, shock_suffix, 1);
    u2 = debt_limit_series(oo_, M_, limit, shock_suffix, 2);
    u1_dev = u1 - limit.ubar1;
    u2_dev = u2 - limit.ubar2;

    debt_ratio1 = debt_to_gdp_deviation_series(oo_, M_, shock_suffix, 1);
    debt_ratio2 = debt_to_gdp_deviation_series(oo_, M_, shock_suffix, 2);
    ig_gap = ig2 - ig1;
    y_gap = xloc2 - xloc1;

    summary = table(string(scenario.name), string(scenario.label), ...
        limit.cap_threshold, limit.ubar1, limit.ubar2, ...
        max(u2), max(debt_ratio2), max(ds2), ...
        min(fs2), min(ig2), min(kg2), min(xloc2), min(c2), min(pinf2), ...
        max(abs(u2_dev - u1_dev)), ...
        max(abs(debt_ratio2 - debt_ratio1)), max(abs(ds2 - ds1)), ...
        max(abs(ig_gap)), max(abs(y_gap)), ...
        u2(periods(1)), u2(periods(2)), u2(periods(3)), u2(periods(4)), ...
        ig2(periods(1)), ig2(periods(2)), ig2(periods(3)), ig2(periods(4)), ...
        xloc2(periods(1)), xloc2(periods(2)), xloc2(periods(3)), xloc2(periods(4)), ...
        'VariableNames', {'scenario','label','cap_threshold','ubar1','ubar2', ...
        'max_u2','max_debt_ratio2','max_ds2', ...
        'min_fs2','min_ig2','min_kg2','min_xloc2','min_c2','min_pinf2', ...
        'max_abs_u_gap','max_abs_debt_ratio_gap', ...
        'max_abs_ds_gap','max_abs_ig_gap','max_abs_y_gap', ...
        'u2_t1','u2_t4','u2_t8','u2_t12', ...
        'ig2_t1','ig2_t4','ig2_t8','ig2_t12', ...
        'xloc2_t1','xloc2_t4','xloc2_t8','xloc2_t12'});
end

function series = collect_irf_series(oo_, M_, scenario, shock_suffix)
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs1 = get_irf(oo_, 'fs1', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg1 = get_irf(oo_, 'kg1', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    xloc1 = get_irf(oo_, 'xloc1', shock_suffix);
    xloc2 = get_irf(oo_, 'xloc2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);
    horizon = (1:numel(xloc2))';

    limit = scenario.limit_settings;
    u1 = debt_limit_series(oo_, M_, limit, shock_suffix, 1);
    u2 = debt_limit_series(oo_, M_, limit, shock_suffix, 2);
    u1_dev = u1 - limit.ubar1;
    u2_dev = u2 - limit.ubar2;
    debt_ratio1 = debt_to_gdp_deviation_series(oo_, M_, shock_suffix, 1);
    debt_ratio2 = debt_to_gdp_deviation_series(oo_, M_, shock_suffix, 2);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(limit.cap_threshold, numel(horizon), 1), ...
        horizon, u1, u2, u1_dev, u2_dev, debt_ratio1, debt_ratio2, ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        xloc1(:), xloc2(:), c1(:), c2(:), pinf1(:), pinf2(:), ...
        u2_dev - u1_dev, debt_ratio2 - debt_ratio1, ...
        ds2(:) - ds1(:), fs2(:) - fs1(:), ig2(:) - ig1(:), ...
        kg2(:) - kg1(:), xloc2(:) - xloc1(:), c2(:) - c1(:), ...
        pinf2(:) - pinf1(:), ...
        'VariableNames', {'scenario','label','cap_threshold','horizon', ...
        'u1','u2','u1_dev','u2_dev','debt_ratio1','debt_ratio2', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'xloc1','xloc2','c1','c2','pinf1','pinf2', ...
        'u_gap','debt_ratio_gap','ds_gap','fs_gap', ...
        'ig_gap','kg_gap','y_gap','c_gap','pinf_gap'});
end

function summary = collect_transfer_summary(oo_, scenario, periods, shock_suffix, d_ann1, d_ann2)
    z1 = get_irf(oo_, 'z1', shock_suffix);
    z2 = get_irf(oo_, 'z2', shock_suffix);
    b1 = get_irf(oo_, 'b1', shock_suffix);
    b2 = get_irf(oo_, 'b2', shock_suffix);
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs1 = get_irf(oo_, 'fs1', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg1 = get_irf(oo_, 'kg1', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    xloc1 = get_irf(oo_, 'xloc1', shock_suffix);
    xloc2 = get_irf(oo_, 'xloc2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    % First-order deviations of the annualized debt indicator d=B/(4X),
    % where 4X is four times current-quarter GDP, not rolling four-quarter GDP.
    debt_ratio1 = (b1 - 4 * d_ann1 * xloc1) / 4;
    debt_ratio2 = (b2 - 4 * d_ann2 * xloc2) / 4;

    summary = table(string(scenario.name), string(scenario.label), ...
        scenario.rho_z, scenario.phi_z_ds, scenario.phi_z_b, ...
        max(z2), max(debt_ratio2), max(ds2), min(fs2), ...
        min(ig2), min(kg2), min(xloc2), min(c2), min(pinf2), ...
        max(abs(z2 - z1)), max(abs(debt_ratio2 - debt_ratio1)), ...
        max(abs(ds2 - ds1)), max(abs(fs2 - fs1)), ...
        max(abs(ig2 - ig1)), max(abs(kg2 - kg1)), ...
        max(abs(xloc2 - xloc1)), max(abs(c2 - c1)), max(abs(pinf2 - pinf1)), ...
        z2(periods(1)), z2(periods(2)), z2(periods(3)), z2(periods(4)), ...
        ig2(periods(1)), ig2(periods(2)), ig2(periods(3)), ig2(periods(4)), ...
        xloc2(periods(1)), xloc2(periods(2)), xloc2(periods(3)), xloc2(periods(4)), ...
        pinf2(periods(1)), pinf2(periods(2)), pinf2(periods(3)), pinf2(periods(4)), ...
        'VariableNames', {'scenario','label','rho_z','phi_z_ds','phi_z_b', ...
        'max_z2','max_debt_ratio2','max_ds2','min_fs2', ...
        'min_ig2','min_kg2','min_xloc2','min_c2','min_pinf2', ...
        'max_abs_z_gap','max_abs_debt_ratio_gap','max_abs_ds_gap','max_abs_fs_gap', ...
        'max_abs_ig_gap','max_abs_kg_gap','max_abs_y_gap','max_abs_c_gap','max_abs_pinf_gap', ...
        'z2_t1','z2_t4','z2_t8','z2_t12', ...
        'ig2_t1','ig2_t4','ig2_t8','ig2_t12', ...
        'xloc2_t1','xloc2_t4','xloc2_t8','xloc2_t12', ...
        'pinf2_t1','pinf2_t4','pinf2_t8','pinf2_t12'});
end

function series = collect_transfer_irf_series(oo_, scenario, shock_suffix, d_ann1, d_ann2)
    z1 = get_irf(oo_, 'z1', shock_suffix);
    z2 = get_irf(oo_, 'z2', shock_suffix);
    b1 = get_irf(oo_, 'b1', shock_suffix);
    b2 = get_irf(oo_, 'b2', shock_suffix);
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs1 = get_irf(oo_, 'fs1', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg1 = get_irf(oo_, 'kg1', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    xloc1 = get_irf(oo_, 'xloc1', shock_suffix);
    xloc2 = get_irf(oo_, 'xloc2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);
    horizon = (1:numel(xloc2))';

    debt_ratio1 = (b1(:) - 4 * d_ann1 * xloc1(:)) / 4;
    debt_ratio2 = (b2(:) - 4 * d_ann2 * xloc2(:)) / 4;

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.rho_z, numel(horizon), 1), ...
        repmat(scenario.phi_z_ds, numel(horizon), 1), ...
        repmat(scenario.phi_z_b, numel(horizon), 1), ...
        horizon, z1(:), z2(:), b1(:), b2(:), debt_ratio1, debt_ratio2, ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        xloc1(:), xloc2(:), c1(:), c2(:), pinf1(:), pinf2(:), ...
        z2(:) - z1(:), debt_ratio2 - debt_ratio1, ds2(:) - ds1(:), ...
        fs2(:) - fs1(:), ig2(:) - ig1(:), kg2(:) - kg1(:), ...
        xloc2(:) - xloc1(:), c2(:) - c1(:), pinf2(:) - pinf1(:), ...
        'VariableNames', {'scenario','label','rho_z','phi_z_ds','phi_z_b','horizon', ...
        'z1','z2','b1','b2','debt_ratio1','debt_ratio2', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'xloc1','xloc2','c1','c2','pinf1','pinf2', ...
        'z_gap','debt_ratio_gap','ds_gap','fs_gap','ig_gap','kg_gap', ...
        'y_gap','c_gap','pinf_gap'});
end

function summary = collect_balance_summary(oo_, scenario, periods, shock_suffix)
    r = get_irf(oo_, 'r', shock_suffix);
    xagg = get_irf(oo_, 'xagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs1 = get_irf(oo_, 'fs1', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg1 = get_irf(oo_, 'kg1', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    xloc1 = get_irf(oo_, 'xloc1', shock_suffix);
    xloc2 = get_irf(oo_, 'xloc2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    y_gap = xloc2 - xloc1;
    pinf_gap = pinf2 - pinf1;

    summary = table(string(scenario.name), string(scenario.label), scenario.phi_reg, ...
        max(r), min(r), min(xagg), min(pinfagg), ...
        l2_norm(pinfagg), l2_norm(xagg), l2_norm(y_gap), l2_norm(pinf_gap), ...
        max(abs(y_gap)), max(abs(pinf_gap)), ...
        max(ds2), min(fs2), min(ig2), min(kg2), min(xloc2), min(c2), min(pinf2), ...
        max(abs(ds2 - ds1)), max(abs(fs2 - fs1)), max(abs(ig2 - ig1)), ...
        max(abs(kg2 - kg1)), max(abs(c2 - c1)), ...
        r(periods(1)), r(periods(2)), r(periods(3)), r(periods(4)), ...
        xagg(periods(1)), xagg(periods(2)), xagg(periods(3)), xagg(periods(4)), ...
        pinfagg(periods(1)), pinfagg(periods(2)), pinfagg(periods(3)), pinfagg(periods(4)), ...
        y_gap(periods(1)), y_gap(periods(2)), y_gap(periods(3)), y_gap(periods(4)), ...
        'VariableNames', {'scenario','label','phi_reg', ...
        'max_r','min_r','min_xagg','min_pinfagg', ...
        'inflation_l2','output_l2','sync_y_l2','sync_pinf_l2', ...
        'max_abs_y_gap','max_abs_pinf_gap', ...
        'max_ds2','min_fs2','min_ig2','min_kg2','min_xloc2','min_c2','min_pinf2', ...
        'max_abs_ds_gap','max_abs_fs_gap','max_abs_ig_gap', ...
        'max_abs_kg_gap','max_abs_c_gap', ...
        'r_t1','r_t4','r_t8','r_t12', ...
        'xagg_t1','xagg_t4','xagg_t8','xagg_t12', ...
        'pinfagg_t1','pinfagg_t4','pinfagg_t8','pinfagg_t12', ...
        'y_gap_t1','y_gap_t4','y_gap_t8','y_gap_t12'});
end

function series = collect_balance_irf_series(oo_, scenario, shock_suffix)
    r = get_irf(oo_, 'r', shock_suffix);
    xagg = get_irf(oo_, 'xagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs1 = get_irf(oo_, 'fs1', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg1 = get_irf(oo_, 'kg1', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    xloc1 = get_irf(oo_, 'xloc1', shock_suffix);
    xloc2 = get_irf(oo_, 'xloc2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    inv1 = get_irf(oo_, 'inv1', shock_suffix);
    inv2 = get_irf(oo_, 'inv2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);
    horizon = (1:numel(xloc2))';

    y_gap = xloc2(:) - xloc1(:);
    pinf_gap = pinf2(:) - pinf1(:);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.phi_reg, numel(horizon), 1), ...
        horizon, r(:), xagg(:), pinfagg(:), ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        xloc1(:), xloc2(:), c1(:), c2(:), inv1(:), inv2(:), pinf1(:), pinf2(:), ...
        y_gap, pinf_gap, ds2(:) - ds1(:), fs2(:) - fs1(:), ...
        ig2(:) - ig1(:), kg2(:) - kg1(:), c2(:) - c1(:), ...
        inv2(:) - inv1(:), ...
        'VariableNames', {'scenario','label','phi_reg','horizon', ...
        'r','xagg','pinfagg', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'xloc1','xloc2','c1','c2','inv1','inv2','pinf1','pinf2', ...
        'y_gap','pinf_gap','ds_gap','fs_gap','ig_gap','kg_gap', ...
        'c_gap','inv_gap'});
end

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('IRF field not found: %s', field);
    end
    irf = oo_.irfs.(field);
    irf = irf(:);
end

function oo_ = occbin_to_irfs(oo_, M_, horizon, shock_suffix)
    if ~isfield(oo_, 'occbin') || ~isfield(oo_.occbin, 'simul') ...
            || ~isfield(oo_.occbin.simul, 'piecewise')
        error('OccBin piecewise simulation output not found.');
    end

    piecewise = oo_.occbin.simul.piecewise;
    if size(piecewise, 2) ~= M_.endo_nbr && size(piecewise, 1) == M_.endo_nbr
        piecewise = piecewise';
    end
    if size(piecewise, 2) ~= M_.endo_nbr
        error('Unexpected OccBin output size: %d x %d.', ...
            size(piecewise, 1), size(piecewise, 2));
    end

    horizon = min(horizon, size(piecewise, 1));
    steady = oo_.steady_state(:)';
    names = cellstr(M_.endo_names);
    if ~isfield(oo_, 'irfs') || isempty(oo_.irfs)
        oo_.irfs = struct();
    end
    for j = 1:M_.endo_nbr
        field = [names{j} shock_suffix];
        oo_.irfs.(field) = piecewise(1:horizon, j) - steady(j);
    end
end

function delete_stale_result_file(result_file)
    if isfile(result_file)
        delete(result_file);
    end
end

function u = debt_limit_series(oo_, M_, settings, shock_suffix, region)
    suffix = string(region);
    b = level_series(oo_, M_, ['b' char(suffix)], shock_suffix);
    cap_field = ['debt_cap' char(suffix)];
    if ~isfield(settings, cap_field)
        error('Missing hard debt-balance cap for region %s.', char(suffix));
    end
    u = b ./ settings.(cap_field);
end

function x = level_series(oo_, M_, var_name, shock_suffix)
    irf = get_irf(oo_, var_name, shock_suffix);
    x = steady_value(oo_, M_, var_name) + irf(:);
end

function dev = debt_to_gdp_deviation_series(oo_, M_, shock_suffix, region)
    suffix = char(string(region));
    b = level_series(oo_, M_, ['b' suffix], shock_suffix);
    xloc = level_series(oo_, M_, ['xloc' suffix], shock_suffix);
    steady_ratio = steady_value(oo_, M_, ['b' suffix]) ...
        / (4 * steady_value(oo_, M_, ['xloc' suffix]));
    dev = b ./ (4 * xloc) - steady_ratio;
end

function value = steady_value(oo_, M_, var_name)
    names = cellstr(M_.endo_names);
    idx = find(strcmp(names, var_name), 1);
    if isempty(idx)
        error('Endogenous variable not found: %s', var_name);
    end
    value = oo_.steady_state(idx);
end

function value = l2_norm(x)
    value = sqrt(sum(x(:).^2));
end

function text = set_parameter_value(text, name, value)
    pattern = ['(?m)^\s*' name '\s*=\s*[-+0-9.eE]+;\s*$'];
    replacement = sprintf('%-11s= %.8g;', name, value);
    text = regex_replace_once(text, pattern, replacement);
end

function text = set_emp_shock_stderr(text, value)
    pattern = 'var emp; stderr [-+0-9.eE]+;';
    replacement = sprintf('var emp; stderr %.8g;', value);
    text = regex_replace_once(text, pattern, replacement);
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
