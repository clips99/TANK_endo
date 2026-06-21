% Policy counterfactual experiments.
%
% The script keeps the baseline monetary tightening shock and steady state
% fixed, then changes one institutional arrangement at a time:
% 1. local debt-limit discipline;
% 2. central fiscal stabilization through transfers to local governments.

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

% Debt-limit pressure is based on the pre-public-investment financing gap:
% Utilde_j = (B_{j,-1} + FG_j) / Bmax_j.  For this counterfactual stress test,
% the high-debt region is calibrated at the warning margin so the rule's
% macro trade-off is visible relative to the unconstrained baseline.
limit_settings = struct( ...
    'ucrit', 0.995, ...
    'nu', 250.00, ...
    'ubar1', 0.975, ...
    'ubar2', 0.995);

policy_rules = struct( ...
    'name', {'policy_cf_baseline', 'policy_cf_fiscal_discipline'}, ...
    'label', {'基准模型', '严格债务限额规则'}, ...
    'psi_L', {0.00, 20.00}, ...
    'line_style', {'-', '--'});

transfer_rules = struct( ...
    'name', {'policy_cf_no_transfer_stabilizer', 'policy_cf_central_transfer_stabilizer'}, ...
    'label', {'无中央转移稳定器', '中央转移稳定器'}, ...
    'rho_z', {0.00, 0.70}, ...
    'phi_z_ds', {0.00, 0.05}, ...
    'phi_z_b', {0.00, 0.02}, ...
    'line_style', {'-', '--'});

balance_rules = struct( ...
    'name', {'policy_cf_standard_taylor', 'policy_cf_regional_balance_taylor'}, ...
    'label', {'标准 Taylor 规则', '地区平衡型 Taylor 规则'}, ...
    'phi_reg', {0.00, 2.00}, ...
    'line_style', {'-', '--'});

shock_suffix = '_emp';
periods = [1 4 8 12];
b_y1 = 0.35;
b_y2 = 1.00;

status = table();
summary = table();
irf_series = table();
results = struct('name', {}, 'label', {}, 'psi_L', {}, ...
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

    scenario_text = make_debt_limit_model(base_text, rule.psi_L, limit_settings);
    scenario_text = set_policy_stoch_simul_list(scenario_text);

    scenario_mod = [rule.name '.mod'];
    fid = fopen(scenario_mod, 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
        result_file = fullfile(rule.name, 'Output', [rule.name '_results.mat']);
        delete_stale_result_file(result_file);
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        loaded = load(result_file, 'oo_', 'M_');

        scenario = struct('name', rule.name, 'label', rule.label, ...
            'psi_L', rule.psi_L, 'limit_settings', limit_settings);
        summary = [summary; collect_summary(loaded.oo_, loaded.M_, scenario, ...
            periods, shock_suffix, b_y1, b_y2)]; %#ok<AGROW>
        irf_series = [irf_series; collect_irf_series(loaded.oo_, loaded.M_, scenario, ...
            shock_suffix, b_y1, b_y2)]; %#ok<AGROW>

        results(end + 1).name = rule.name; %#ok<SAGROW>
        results(end).label = rule.label;
        results(end).psi_L = rule.psi_L;
        results(end).line_style = rule.line_style;
        results(end).limit_settings = limit_settings;
        results(end).oo = loaded.oo_;
        results(end).M = loaded.M_;

        status = [status; table(string(rule.name), string(rule.label), ...
            rule.psi_L, limit_settings.ucrit, limit_settings.nu, ...
            limit_settings.ubar1, limit_settings.ubar2, "ok", "", ...
            'VariableNames', {'scenario','label','psi_L','ucrit','nu', ...
            'ubar1','ubar2','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Policy counterfactual %s failed: %s', rule.name, err.message);
        status = [status; table(string(rule.name), string(rule.label), ...
            rule.psi_L, limit_settings.ucrit, limit_settings.nu, ...
            limit_settings.ubar1, limit_settings.ubar2, "failed", string(err.message), ...
            'VariableNames', {'scenario','label','psi_L','ucrit','nu', ...
            'ubar1','ubar2','status','notes'})]; %#ok<AGROW>
    end
end

writetable(status, 'policy_counterfactual_status.csv');
writetable(summary, 'policy_counterfactual_summary.csv');
writetable(irf_series, 'policy_counterfactual_irf_series.csv');

fprintf('\nPolicy counterfactual status\n');
fprintf('--------------------------------\n');
disp(status);

fprintf('\nDebt-limit discipline counterfactual summary\n');
fprintf('--------------------------------\n');
disp(summary(:, {'label','max_u2','max_pressure2','max_debt_ratio2', ...
    'max_ds2','min_ig2','min_y2','max_abs_ig_gap','max_abs_y_gap'}));

if ~isempty(results)
    make_debt_limit_difference_figure(results, shock_suffix, b_y1, b_y2);
    make_region_irf_figure(results, shock_suffix);
    make_high_debt_figure(results, shock_suffix, b_y1, b_y2);
    make_gap_figure(results, shock_suffix, b_y1, b_y2);
end

for i = 1:numel(transfer_rules)
    rule = transfer_rules(i);
    fprintf('\n=== Running %s: %s ===\n', rule.name, rule.label);

    scenario_text = make_central_transfer_model(base_text, rule);
    scenario_text = set_transfer_stoch_simul_list(scenario_text);

    scenario_mod = [rule.name '.mod'];
    fid = fopen(scenario_mod, 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
        result_file = fullfile(rule.name, 'Output', [rule.name '_results.mat']);
        delete_stale_result_file(result_file);
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        loaded = load(result_file, 'oo_');

        scenario = struct('name', rule.name, 'label', rule.label, ...
            'rho_z', rule.rho_z, ...
            'phi_z_ds', rule.phi_z_ds, 'phi_z_b', rule.phi_z_b);
        transfer_summary = [transfer_summary; collect_transfer_summary( ...
            loaded.oo_, scenario, periods, shock_suffix, b_y1, b_y2)]; %#ok<AGROW>
        transfer_irf_series = [transfer_irf_series; collect_transfer_irf_series( ...
            loaded.oo_, scenario, shock_suffix, b_y1, b_y2)]; %#ok<AGROW>

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

writetable(transfer_status, 'policy_counterfactual_transfer_status.csv');
writetable(transfer_summary, 'policy_counterfactual_transfer_summary.csv');
writetable(transfer_irf_series, 'policy_counterfactual_transfer_irf_series.csv');

fprintf('\nCentral transfer stabilization counterfactual status\n');
fprintf('--------------------------------\n');
disp(transfer_status);

fprintf('\nCentral transfer stabilization counterfactual summary\n');
fprintf('--------------------------------\n');
disp(transfer_summary(:, {'label','max_z2','max_ds2','min_fs2', ...
    'min_ig2','min_y2','min_pinf2','max_abs_z_gap','max_abs_y_gap'}));

if ~isempty(transfer_results)
    make_transfer_high_debt_figure(transfer_results, shock_suffix);
    make_transfer_gap_figure(transfer_results, shock_suffix);
end

for i = 1:numel(balance_rules)
    rule = balance_rules(i);
    fprintf('\n=== Running %s: %s ===\n', rule.name, rule.label);

    scenario_text = make_regional_balance_model(base_text, rule);
    scenario_text = set_balance_stoch_simul_list(scenario_text);

    scenario_mod = [rule.name '.mod'];
    fid = fopen(scenario_mod, 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
        result_file = fullfile(rule.name, 'Output', [rule.name '_results.mat']);
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

writetable(balance_status, 'policy_counterfactual_regional_balance_status.csv');
writetable(balance_summary, 'policy_counterfactual_regional_balance_summary.csv');
writetable(balance_irf_series, 'policy_counterfactual_regional_balance_irf_series.csv');

fprintf('\nRegional-balance monetary counterfactual status\n');
fprintf('--------------------------------\n');
disp(balance_status);

fprintf('\nRegional-balance monetary counterfactual summary\n');
fprintf('--------------------------------\n');
disp(balance_summary(:, {'label','phi_reg','max_r','min_r','min_yagg','min_pinfagg', ...
    'sync_y_l2','inflation_l2','output_l2','min_y2','max_ds2','min_ig2'}));

if ~isempty(balance_results)
    make_balance_aggregate_figure(balance_results, shock_suffix);
    make_balance_high_debt_figure(balance_results, shock_suffix);
    make_balance_gap_figure(balance_results, shock_suffix);
end

function text = make_debt_limit_model(text, psi_L, settings)
    if psi_L == 0
        return;
    end
    text = add_debt_limit_parameters(text);
    text = add_debt_limit_calibration(text, psi_L, settings);
    text = add_debt_limit_wedge_to_public_investment_focs(text);
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

function text = add_debt_limit_parameters(text)
    old_line = 'mu_b phi_z_ds phi_z_b';
    new_line = ['mu_b phi_z_ds phi_z_b' newline ...
        '    psi_L ucrit_L nu_L ubar_L1 ubar_L2 bmax1 bmax2 pbar_L1 pbar_L2'];
    text = replace_exactly_once(text, old_line, new_line);
end

function text = add_regional_balance_parameter(text)
    old_line = 'phi_pi phi_y tau_y theta_T';
    new_line = 'phi_pi phi_y phi_reg tau_y theta_T';
    text = replace_exactly_once(text, old_line, new_line);
end

function text = add_regional_balance_calibration(text, phi_reg)
    calibration = sprintf('$1\nphi_reg    = %.8g;', phi_reg);
    text = regex_replace_once(text, '(?m)^(phi_y\s*=\s*[^;]+;)', calibration);
end

function text = replace_taylor_rule_with_balance_target(text)
    old_rule = sprintf(['    r / rbar = (r(-1) / rbar)^rho_r\n' ...
        '        * ((pinfagg / pinfbar)^phi_pi * (yagg / ybar)^phi_y)^(1 - rho_r)\n' ...
        '        * exp(mp);']);
    new_rule = sprintf(['    // Normative regional-balance extension: when high-debt region output\n' ...
        '    // falls relative to low-debt region output, this term lowers the\n' ...
        '    // common policy rate for phi_reg > 0.\n' ...
        '    r / rbar = (r(-1) / rbar)^rho_r\n' ...
        '        * ((pinfagg / pinfbar)^phi_pi * (yagg / ybar)^phi_y\n' ...
        '           * (((y2 / ybar2) / (y1 / ybar1))^phi_reg))^(1 - rho_r)\n' ...
        '        * exp(mp);']);
    text = replace_exactly_once(text, old_rule, new_rule);
end

function text = add_debt_limit_calibration(text, psi_L, settings)
    insert_after = sprintf(['zbar2      = fsbar2 + (rbar - 1) * bbar2 + gbar2 + lambda2 * trbar2\n' ...
        '             - (1 - theta_T) * tau_y * ybar2;']);
    calibration = sprintf([insert_after '\n\n' ...
        '// Smooth debt-limit pressure parameters based on pre-investment financing gaps.\n' ...
        'psi_L      = %.8g;\n' ...
        'ucrit_L    = %.8g;\n' ...
        'nu_L       = %.8g;\n' ...
        'ubar_L1    = %.8g;\n' ...
        'ubar_L2    = %.8g;\n' ...
        'bmax1      = (bbar1 + (rbar - 1) * bbar1 + gbar1 + lambda1 * trbar1 - (1 - theta_T) * tau_y * ybar1 - zbar1) / ubar_L1;\n' ...
        'bmax2      = (bbar2 + (rbar - 1) * bbar2 + gbar2 + lambda2 * trbar2 - (1 - theta_T) * tau_y * ybar2 - zbar2) / ubar_L2;\n' ...
        'pbar_L1    = log(1 + exp(nu_L * (ubar_L1 - ucrit_L))) / nu_L;\n' ...
        'pbar_L2    = log(1 + exp(nu_L * (ubar_L2 - ucrit_L))) / nu_L;'], ...
        psi_L, settings.ucrit, settings.nu, settings.ubar1, settings.ubar2);
    text = replace_exactly_once(text, insert_after, calibration);
end

function text = add_debt_limit_wedge_to_public_investment_focs(text)
    local_marker = sprintf(['    # rig2  = ig2 / ig2(-1);\n' ...
        '    # rig2p = ig2(+1) / ig2;\n']);
    local_block = sprintf([local_marker ...
        '    # fgL1_now = (rb1(-1) / pinf1 - 1) * b1(-1) + g1 + lambda1 * tr1\n' ...
        '                  - (1 - theta_T) * tau_y * y1 - z1;\n' ...
        '    # uL1_now = (b1(-1) + fgL1_now) / bmax1;\n' ...
        '    # pL1_now = log(1 + exp(nu_L * (uL1_now - ucrit_L))) / nu_L;\n' ...
        '    # fgL2_now = (rb2(-1) / pinf2 - 1) * b2(-1) + g2 + lambda2 * tr2\n' ...
        '                  - (1 - theta_T) * tau_y * y2 - z2;\n' ...
        '    # uL2_now = (b2(-1) + fgL2_now) / bmax2;\n' ...
        '    # pL2_now = log(1 + exp(nu_L * (uL2_now - ucrit_L))) / nu_L;\n']);
    text = replace_exactly_once(text, local_marker, local_block);

    old_foc1 = sprintf(['    lamg1 * (1 + chi_ig * (rig1 - 1) * rig1\n' ...
        '              + chi_ig / 2 * (rig1 - 1)^2)\n' ...
        '        = qg1 + beta_g * lamg1(+1) * chi_ig * (rig1p - 1) * rig1p^2;']);
    new_foc1 = sprintf(['    lamg1 * (1 + chi_ig * (rig1 - 1) * rig1\n' ...
        '              + chi_ig / 2 * (rig1 - 1)^2)\n' ...
        '        + lamg1 * psi_L * (pL1_now - pbar_L1)\n' ...
        '        = qg1 + beta_g * lamg1(+1) * chi_ig * (rig1p - 1) * rig1p^2;']);

    old_foc2 = sprintf(['    lamg2 * (1 + chi_ig * (rig2 - 1) * rig2\n' ...
        '              + chi_ig / 2 * (rig2 - 1)^2)\n' ...
        '        = qg2 + beta_g * lamg2(+1) * chi_ig * (rig2p - 1) * rig2p^2;']);
    new_foc2 = sprintf(['    lamg2 * (1 + chi_ig * (rig2 - 1) * rig2\n' ...
        '              + chi_ig / 2 * (rig2 - 1)^2)\n' ...
        '        + lamg2 * psi_L * (pL2_now - pbar_L2)\n' ...
        '        = qg2 + beta_g * lamg2(+1) * chi_ig * (rig2p - 1) * rig2p^2;']);

    text = replace_exactly_once(text, old_foc1, new_foc1);
    text = replace_exactly_once(text, old_foc2, new_foc2);
end

function text = set_policy_stoch_simul_list(text)
    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp r rb1 rb2 yagg pinfagg\n' ...
        '    z1 z2 g1 g2 tr1 tr2\n' ...
        '    b1 b2 ds1 ds2 fs1 fs2\n' ...
        '    ig1 ig2 kg1 kg2\n' ...
        '    y1 y2 c1 c2 inv1 inv2 pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function text = set_transfer_stoch_simul_list(text)
    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp r rb1 rb2 yagg pinfagg\n' ...
        '    z1 z2 b1 b2 ds1 ds2 fs1 fs2\n' ...
        '    ig1 ig2 kg1 kg2\n' ...
        '    y1 y2 c1 c2 inv1 inv2 pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function text = set_balance_stoch_simul_list(text)
    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp r rb1 rb2 yagg pinfagg\n' ...
        '    ds1 ds2 fs1 fs2 ig1 ig2 kg1 kg2\n' ...
        '    y1 y2 c1 c2 inv1 inv2 pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function summary = collect_summary(oo_, M_, scenario, periods, shock_suffix, b_y1, b_y2)
    b1 = get_irf(oo_, 'b1', shock_suffix);
    b2 = get_irf(oo_, 'b2', shock_suffix);
    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    y1 = get_irf(oo_, 'y1', shock_suffix);
    y2 = get_irf(oo_, 'y2', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    limit = scenario.limit_settings;
    [u1, pressure1] = debt_limit_series(oo_, M_, limit, shock_suffix, 1);
    [u2, pressure2] = debt_limit_series(oo_, M_, limit, shock_suffix, 2);
    u1_dev = u1 - limit.ubar1;
    u2_dev = u2 - limit.ubar2;

    debt_ratio1 = b1 - b_y1 * y1;
    debt_ratio2 = b2 - b_y2 * y2;
    ig_gap = ig2 - ig1;
    y_gap = y2 - y1;

    summary = table(string(scenario.name), string(scenario.label), ...
        scenario.psi_L, limit.ucrit, limit.nu, limit.ubar1, limit.ubar2, ...
        max(u2), max(pressure2), max(debt_ratio2), max(ds2), ...
        min(fs2), min(ig2), min(kg2), min(y2), min(c2), min(pinf2), ...
        max(abs(u2_dev - u1_dev)), max(abs(pressure2 - pressure1)), ...
        max(abs(debt_ratio2 - debt_ratio1)), max(abs(ds2 - ds1)), ...
        max(abs(ig_gap)), max(abs(y_gap)), ...
        u2(periods(1)), u2(periods(2)), u2(periods(3)), u2(periods(4)), ...
        pressure2(periods(1)), pressure2(periods(2)), ...
        pressure2(periods(3)), pressure2(periods(4)), ...
        ig2(periods(1)), ig2(periods(2)), ig2(periods(3)), ig2(periods(4)), ...
        y2(periods(1)), y2(periods(2)), y2(periods(3)), y2(periods(4)), ...
        'VariableNames', {'scenario','label','psi_L','ucrit','nu','ubar1','ubar2', ...
        'max_u2','max_pressure2','max_debt_ratio2','max_ds2', ...
        'min_fs2','min_ig2','min_kg2','min_y2','min_c2','min_pinf2', ...
        'max_abs_u_gap','max_abs_pressure_gap','max_abs_debt_ratio_gap', ...
        'max_abs_ds_gap','max_abs_ig_gap','max_abs_y_gap', ...
        'u2_t1','u2_t4','u2_t8','u2_t12', ...
        'pressure2_t1','pressure2_t4','pressure2_t8','pressure2_t12', ...
        'ig2_t1','ig2_t4','ig2_t8','ig2_t12', ...
        'y2_t1','y2_t4','y2_t8','y2_t12'});
end

function series = collect_irf_series(oo_, M_, scenario, shock_suffix, b_y1, b_y2)
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
    y1 = get_irf(oo_, 'y1', shock_suffix);
    y2 = get_irf(oo_, 'y2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);
    horizon = (1:numel(y2))';

    limit = scenario.limit_settings;
    [u1, pressure1] = debt_limit_series(oo_, M_, limit, shock_suffix, 1);
    [u2, pressure2] = debt_limit_series(oo_, M_, limit, shock_suffix, 2);
    u1_dev = u1 - limit.ubar1;
    u2_dev = u2 - limit.ubar2;
    debt_ratio1 = b1(:) - b_y1 * y1(:);
    debt_ratio2 = b2(:) - b_y2 * y2(:);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.psi_L, numel(horizon), 1), ...
        repmat(limit.ucrit, numel(horizon), 1), ...
        repmat(limit.nu, numel(horizon), 1), ...
        horizon, u1, u2, u1_dev, u2_dev, pressure1, pressure2, debt_ratio1, debt_ratio2, ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        y1(:), y2(:), c1(:), c2(:), pinf1(:), pinf2(:), ...
        u2_dev - u1_dev, pressure2 - pressure1, debt_ratio2 - debt_ratio1, ...
        ds2(:) - ds1(:), fs2(:) - fs1(:), ig2(:) - ig1(:), ...
        kg2(:) - kg1(:), y2(:) - y1(:), c2(:) - c1(:), ...
        pinf2(:) - pinf1(:), ...
        'VariableNames', {'scenario','label','psi_L','ucrit','nu','horizon', ...
        'u1','u2','u1_dev','u2_dev','pressure1','pressure2','debt_ratio1','debt_ratio2', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'y1','y2','c1','c2','pinf1','pinf2', ...
        'u_gap','pressure_gap','debt_ratio_gap','ds_gap','fs_gap', ...
        'ig_gap','kg_gap','y_gap','c_gap','pinf_gap'});
end

function summary = collect_transfer_summary(oo_, scenario, periods, shock_suffix, b_y1, b_y2)
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
    y1 = get_irf(oo_, 'y1', shock_suffix);
    y2 = get_irf(oo_, 'y2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    debt_ratio1 = b1 - b_y1 * y1;
    debt_ratio2 = b2 - b_y2 * y2;

    summary = table(string(scenario.name), string(scenario.label), ...
        scenario.rho_z, scenario.phi_z_ds, scenario.phi_z_b, ...
        max(z2), max(debt_ratio2), max(ds2), min(fs2), ...
        min(ig2), min(kg2), min(y2), min(c2), min(pinf2), ...
        max(abs(z2 - z1)), max(abs(debt_ratio2 - debt_ratio1)), ...
        max(abs(ds2 - ds1)), max(abs(fs2 - fs1)), ...
        max(abs(ig2 - ig1)), max(abs(kg2 - kg1)), ...
        max(abs(y2 - y1)), max(abs(c2 - c1)), max(abs(pinf2 - pinf1)), ...
        z2(periods(1)), z2(periods(2)), z2(periods(3)), z2(periods(4)), ...
        ig2(periods(1)), ig2(periods(2)), ig2(periods(3)), ig2(periods(4)), ...
        y2(periods(1)), y2(periods(2)), y2(periods(3)), y2(periods(4)), ...
        pinf2(periods(1)), pinf2(periods(2)), pinf2(periods(3)), pinf2(periods(4)), ...
        'VariableNames', {'scenario','label','rho_z','phi_z_ds','phi_z_b', ...
        'max_z2','max_debt_ratio2','max_ds2','min_fs2', ...
        'min_ig2','min_kg2','min_y2','min_c2','min_pinf2', ...
        'max_abs_z_gap','max_abs_debt_ratio_gap','max_abs_ds_gap','max_abs_fs_gap', ...
        'max_abs_ig_gap','max_abs_kg_gap','max_abs_y_gap','max_abs_c_gap','max_abs_pinf_gap', ...
        'z2_t1','z2_t4','z2_t8','z2_t12', ...
        'ig2_t1','ig2_t4','ig2_t8','ig2_t12', ...
        'y2_t1','y2_t4','y2_t8','y2_t12', ...
        'pinf2_t1','pinf2_t4','pinf2_t8','pinf2_t12'});
end

function series = collect_transfer_irf_series(oo_, scenario, shock_suffix, b_y1, b_y2)
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
    y1 = get_irf(oo_, 'y1', shock_suffix);
    y2 = get_irf(oo_, 'y2', shock_suffix);
    c1 = get_irf(oo_, 'c1', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);
    horizon = (1:numel(y2))';

    debt_ratio1 = b1(:) - b_y1 * y1(:);
    debt_ratio2 = b2(:) - b_y2 * y2(:);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.rho_z, numel(horizon), 1), ...
        repmat(scenario.phi_z_ds, numel(horizon), 1), ...
        repmat(scenario.phi_z_b, numel(horizon), 1), ...
        horizon, z1(:), z2(:), b1(:), b2(:), debt_ratio1, debt_ratio2, ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        y1(:), y2(:), c1(:), c2(:), pinf1(:), pinf2(:), ...
        z2(:) - z1(:), debt_ratio2 - debt_ratio1, ds2(:) - ds1(:), ...
        fs2(:) - fs1(:), ig2(:) - ig1(:), kg2(:) - kg1(:), ...
        y2(:) - y1(:), c2(:) - c1(:), pinf2(:) - pinf1(:), ...
        'VariableNames', {'scenario','label','rho_z','phi_z_ds','phi_z_b','horizon', ...
        'z1','z2','b1','b2','debt_ratio1','debt_ratio2', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'y1','y2','c1','c2','pinf1','pinf2', ...
        'z_gap','debt_ratio_gap','ds_gap','fs_gap','ig_gap','kg_gap', ...
        'y_gap','c_gap','pinf_gap'});
end

function summary = collect_balance_summary(oo_, scenario, periods, shock_suffix)
    r = get_irf(oo_, 'r', shock_suffix);
    yagg = get_irf(oo_, 'yagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);
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

    y_gap = y2 - y1;
    pinf_gap = pinf2 - pinf1;

    summary = table(string(scenario.name), string(scenario.label), scenario.phi_reg, ...
        max(r), min(r), min(yagg), min(pinfagg), ...
        l2_norm(pinfagg), l2_norm(yagg), l2_norm(y_gap), l2_norm(pinf_gap), ...
        max(abs(y_gap)), max(abs(pinf_gap)), ...
        max(ds2), min(fs2), min(ig2), min(kg2), min(y2), min(c2), min(pinf2), ...
        max(abs(ds2 - ds1)), max(abs(fs2 - fs1)), max(abs(ig2 - ig1)), ...
        max(abs(kg2 - kg1)), max(abs(c2 - c1)), ...
        r(periods(1)), r(periods(2)), r(periods(3)), r(periods(4)), ...
        yagg(periods(1)), yagg(periods(2)), yagg(periods(3)), yagg(periods(4)), ...
        pinfagg(periods(1)), pinfagg(periods(2)), pinfagg(periods(3)), pinfagg(periods(4)), ...
        y_gap(periods(1)), y_gap(periods(2)), y_gap(periods(3)), y_gap(periods(4)), ...
        'VariableNames', {'scenario','label','phi_reg', ...
        'max_r','min_r','min_yagg','min_pinfagg', ...
        'inflation_l2','output_l2','sync_y_l2','sync_pinf_l2', ...
        'max_abs_y_gap','max_abs_pinf_gap', ...
        'max_ds2','min_fs2','min_ig2','min_kg2','min_y2','min_c2','min_pinf2', ...
        'max_abs_ds_gap','max_abs_fs_gap','max_abs_ig_gap', ...
        'max_abs_kg_gap','max_abs_c_gap', ...
        'r_t1','r_t4','r_t8','r_t12', ...
        'yagg_t1','yagg_t4','yagg_t8','yagg_t12', ...
        'pinfagg_t1','pinfagg_t4','pinfagg_t8','pinfagg_t12', ...
        'y_gap_t1','y_gap_t4','y_gap_t8','y_gap_t12'});
end

function series = collect_balance_irf_series(oo_, scenario, shock_suffix)
    r = get_irf(oo_, 'r', shock_suffix);
    yagg = get_irf(oo_, 'yagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);
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
    inv1 = get_irf(oo_, 'inv1', shock_suffix);
    inv2 = get_irf(oo_, 'inv2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);
    horizon = (1:numel(y2))';

    y_gap = y2(:) - y1(:);
    pinf_gap = pinf2(:) - pinf1(:);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.phi_reg, numel(horizon), 1), ...
        horizon, r(:), yagg(:), pinfagg(:), ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        y1(:), y2(:), c1(:), c2(:), inv1(:), inv2(:), pinf1(:), pinf2(:), ...
        y_gap, pinf_gap, ds2(:) - ds1(:), fs2(:) - fs1(:), ...
        ig2(:) - ig1(:), kg2(:) - kg1(:), c2(:) - c1(:), ...
        inv2(:) - inv1(:), ...
        'VariableNames', {'scenario','label','phi_reg','horizon', ...
        'r','yagg','pinfagg', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'y1','y2','c1','c2','inv1','inv2','pinf1','pinf2', ...
        'y_gap','pinf_gap','ds_gap','fs_gap','ig_gap','kg_gap', ...
        'c_gap','inv_gap'});
end

function irf = get_irf(oo_, var_name, shock_suffix)
    field = [var_name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('IRF field not found: %s', field);
    end
    irf = oo_.irfs.(field);
end

function delete_stale_result_file(result_file)
    if isfile(result_file)
        delete(result_file);
    end
end

function make_debt_limit_difference_figure(results, shock_suffix, b_y1, b_y2)
    if numel(results) < 2
        return;
    end

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

    plot_limit_difference_panel(results, shock_suffix, 2, ...
        '限额使用率差异');
    plot_debt_ratio_difference_panel(results, shock_suffix, b_y2, ...
        '债务/GDP 差异');
    plot_policy_difference_panel(results, shock_suffix, 'ds2', '', [], ...
        '实际付息压力差异');
    plot_policy_difference_panel(results, shock_suffix, 'ig2', '', [], ...
        '公共投资差异');
    plot_policy_difference_panel(results, shock_suffix, 'kg2', '', [], ...
        '公共资本差异');
    plot_policy_difference_panel(results, shock_suffix, 'y2', '', [], ...
        '最终产出差异');

    sgtitle('严格债务限额规则相对基准模型的差异响应', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure5_debt_limit_diff_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_region_irf_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1250 760]);
    tiledlayout(2, 4, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'ds1', '', [], ...
        '低债务：实际付息压力');
    plot_policy_panel(results, shock_suffix, 'ds2', '', [], ...
        '高债务：实际付息压力');
    plot_policy_panel(results, shock_suffix, 'fs1', '', [], ...
        '低债务：财政空间');
    plot_policy_panel(results, shock_suffix, 'fs2', '', [], ...
        '高债务：财政空间');
    plot_policy_panel(results, shock_suffix, 'ig1', '', [], ...
        '低债务：公共投资');
    plot_policy_panel(results, shock_suffix, 'ig2', '', [], ...
        '高债务：公共投资');
    plot_policy_panel(results, shock_suffix, 'y1', '', [], ...
        '低债务：最终产出');
    plot_policy_panel(results, shock_suffix, 'y2', '', [], ...
        '高债务：最终产出');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('债务限额规则下各地区核心变量 IRF', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure5_debt_limit_region_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_high_debt_figure(results, shock_suffix, b_y1, b_y2) %#ok<INUSD>
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_limit_panel(results, shock_suffix, 2, ...
        '高债务：限额使用率');
    plot_policy_panel(results, shock_suffix, 'b2', 'y2', b_y2, ...
        '高债务：债务/GDP');
    plot_policy_panel(results, shock_suffix, 'ds2', '', [], ...
        '高债务：实际付息压力');
    plot_policy_panel(results, shock_suffix, 'ig2', '', [], ...
        '高债务：公共投资');
    plot_policy_panel(results, shock_suffix, 'kg2', '', [], ...
        '高债务：公共资本');
    plot_policy_panel(results, shock_suffix, 'y2', '', [], ...
        '高债务：最终产出');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('高债务地区在债务限额规则下的 IRF', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure5_debt_limit_high_debt_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_gap_figure(results, shock_suffix, b_y1, b_y2)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_limit_gap_panel(results, shock_suffix, '限额使用率缺口：高债务 - 低债务');
    plot_pressure_gap_panel(results, shock_suffix, '限额压力缺口：高债务 - 低债务');
    plot_debt_ratio_gap_panel(results, shock_suffix, b_y1, b_y2, ...
        '债务/GDP 缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'ig2', 'ig1', [], ...
        '公共投资缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'kg2', 'kg1', [], ...
        '公共资本缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'y2', 'y1', [], ...
        '最终产出缺口：高债务 - 低债务');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('严格债务限额规则下的地区差异响应', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure5_debt_limit_gap_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_transfer_high_debt_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'z2', '', [], ...
        '高债务：中央转移支付');
    plot_policy_panel(results, shock_suffix, 'ds2', '', [], ...
        '高债务：实际付息压力');
    plot_policy_panel(results, shock_suffix, 'fs2', '', [], ...
        '高债务：财政空间');
    plot_policy_panel(results, shock_suffix, 'ig2', '', [], ...
        '高债务：公共投资');
    plot_policy_panel(results, shock_suffix, 'kg2', '', [], ...
        '高债务：公共资本');
    plot_policy_panel(results, shock_suffix, 'y2', '', [], ...
        '高债务：最终产出');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('反周期中央转移支付稳定器：高债务地区 IRF', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure6_central_transfer_high_debt_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_transfer_gap_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'z2', 'z1', [], ...
        '中央转移支付缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'ds2', 'ds1', [], ...
        '实际付息压力缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'fs2', 'fs1', [], ...
        '财政空间缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'ig2', 'ig1', [], ...
        '公共投资缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'y2', 'y1', [], ...
        '最终产出缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'pinf2', 'pinf1', [], ...
        '通胀缺口：高债务 - 低债务');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('反周期中央转移支付稳定器下的地区差异响应', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure6_central_transfer_gap_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_balance_aggregate_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'r', '', [], ...
        '政策利率');
    plot_policy_panel(results, shock_suffix, 'yagg', '', [], ...
        '全国总产出');
    plot_policy_panel(results, shock_suffix, 'pinfagg', '', [], ...
        '全国通胀');
    plot_policy_panel(results, shock_suffix, 'y2', 'y1', [], ...
        '最终产出缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'pinf2', 'pinf1', [], ...
        '通胀缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'ds2', 'ds1', [], ...
        '实际付息压力缺口：高债务 - 低债务');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('地区平衡型 Taylor 规则的总量稳定效果', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure7_regional_balance_aggregate_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_balance_high_debt_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 800]);
    tiledlayout(2, 4, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'ds2', '', [], ...
        '高债务：实际付息压力');
    plot_policy_panel(results, shock_suffix, 'fs2', '', [], ...
        '高债务：财政空间');
    plot_policy_panel(results, shock_suffix, 'ig2', '', [], ...
        '高债务：公共投资');
    plot_policy_panel(results, shock_suffix, 'kg2', '', [], ...
        '高债务：公共资本');
    plot_policy_panel(results, shock_suffix, 'y2', '', [], ...
        '高债务：最终产出');
    plot_policy_panel(results, shock_suffix, 'c2', '', [], ...
        '高债务：总消费');
    plot_policy_panel(results, shock_suffix, 'inv2', '', [], ...
        '高债务：私人投资');
    plot_policy_panel(results, shock_suffix, 'pinf2', '', [], ...
        '高债务：通胀');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('地区平衡型 Taylor 规则下高债务地区 IRF', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure7_regional_balance_high_debt_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function make_balance_gap_figure(results, shock_suffix)
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 720]);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    labels = get_labels(results);

    plot_policy_panel(results, shock_suffix, 'ds2', 'ds1', [], ...
        '实际付息压力缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'fs2', 'fs1', [], ...
        '财政空间缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'ig2', 'ig1', [], ...
        '公共投资缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'kg2', 'kg1', [], ...
        '公共资本缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'y2', 'y1', [], ...
        '最终产出缺口：高债务 - 低债务');
    plot_policy_panel(results, shock_suffix, 'pinf2', 'pinf1', [], ...
        '通胀缺口：高债务 - 低债务');

    legend(labels, 'Location', 'best', 'Interpreter', 'none');
    sgtitle('地区平衡型 Taylor 规则下的地区差异响应', ...
        'FontWeight', 'bold');
    exportgraphics(fig, 'figure7_regional_balance_gap_irfs.png', ...
        'Resolution', 180);
    close(fig);
end

function labels = get_labels(results)
    labels = strings(numel(results), 1);
    for i = 1:numel(results)
        labels(i) = string(results(i).label);
    end
end

function plot_policy_panel(results, shock_suffix, var_a, var_b, ratio_base, title_text)
    nexttile;
    color = [0.05 0.20 0.35];
    for i = 1:numel(results)
        irf_a = get_irf(results(i).oo, var_a, shock_suffix);
        if isempty(var_b)
            y = irf_a;
        elseif isempty(ratio_base)
            irf_b = get_irf(results(i).oo, var_b, shock_suffix);
            y = irf_a - irf_b;
        else
            irf_b = get_irf(results(i).oo, var_b, shock_suffix);
            y = irf_a - ratio_base * irf_b;
        end
        horizon = 1:numel(y);
        plot(horizon, y, 'LineWidth', 1.5, 'Color', color, ...
            'LineStyle', results(i).line_style);
        hold on;
    end
    yline(0, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('期数');
    grid on;
end

function plot_policy_difference_panel(results, shock_suffix, var_a, var_b, ratio_base, title_text)
    nexttile;
    baseline = policy_series(results(1).oo, shock_suffix, var_a, var_b, ratio_base);
    counterfactual = policy_series(results(2).oo, shock_suffix, var_a, var_b, ratio_base);
    y = counterfactual - baseline;
    horizon = 1:numel(y);
    plot(horizon, y, 'LineWidth', 1.8, 'Color', [0.70 0.10 0.10]);
    hold on;
    yline(0, ':', 'Color', [0.25 0.25 0.25]);
    title(title_text, 'Interpreter', 'none');
    xlabel('季度');
    ylabel('反事实 - 基准');
    grid on;
end

function y = policy_series(oo_, shock_suffix, var_a, var_b, ratio_base)
    irf_a = get_irf(oo_, var_a, shock_suffix);
    if isempty(var_b)
        y = irf_a;
    elseif isempty(ratio_base)
        irf_b = get_irf(oo_, var_b, shock_suffix);
        y = irf_a - irf_b;
    else
        irf_b = get_irf(oo_, var_b, shock_suffix);
        y = irf_a - ratio_base * irf_b;
    end
end

function plot_limit_difference_panel(results, shock_suffix, region, title_text)
    nexttile;
    [baseline, ~] = debt_limit_series(results(1).oo, results(1).M, ...
        results(1).limit_settings, shock_suffix, region);
    [counterfactual, ~] = debt_limit_series(results(2).oo, results(2).M, ...
        results(2).limit_settings, shock_suffix, region);
    y = counterfactual - baseline;
    horizon = 1:numel(y);
    plot(horizon, y, 'LineWidth', 1.8, 'Color', [0.70 0.10 0.10]);
    hold on;
    yline(0, ':', 'Color', [0.25 0.25 0.25]);
    title(title_text, 'Interpreter', 'none');
    xlabel('季度');
    ylabel('反事实 - 基准');
    grid on;
end

function plot_debt_ratio_difference_panel(results, shock_suffix, ratio_base, title_text)
    nexttile;
    baseline = policy_series(results(1).oo, shock_suffix, 'b2', 'y2', ratio_base);
    counterfactual = policy_series(results(2).oo, shock_suffix, 'b2', 'y2', ratio_base);
    y = counterfactual - baseline;
    horizon = 1:numel(y);
    plot(horizon, y, 'LineWidth', 1.8, 'Color', [0.70 0.10 0.10]);
    hold on;
    yline(0, ':', 'Color', [0.25 0.25 0.25]);
    title(title_text, 'Interpreter', 'none');
    xlabel('季度');
    ylabel('反事实 - 基准');
    grid on;
end

function plot_limit_panel(results, shock_suffix, region, title_text)
    nexttile;
    color = [0.05 0.20 0.35];
    for i = 1:numel(results)
        [y, ~] = debt_limit_series(results(i).oo, results(i).M, ...
            results(i).limit_settings, shock_suffix, region);
        horizon = 1:numel(y);
        plot(horizon, y, 'LineWidth', 1.5, 'Color', color, ...
            'LineStyle', results(i).line_style);
        hold on;
    end
    yline(results(1).limit_settings.ucrit, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('期数');
    grid on;
end

function plot_pressure_panel(results, shock_suffix, region, title_text)
    nexttile;
    color = [0.05 0.20 0.35];
    for i = 1:numel(results)
        [~, pressure_value] = debt_limit_series(results(i).oo, results(i).M, ...
            results(i).limit_settings, shock_suffix, region);
        horizon = 1:numel(pressure_value);
        plot(horizon, pressure_value, 'LineWidth', 1.5, 'Color', color, ...
            'LineStyle', results(i).line_style);
        hold on;
    end
    yline(0, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('期数');
    grid on;
end

function plot_limit_gap_panel(results, shock_suffix, title_text)
    nexttile;
    color = [0.05 0.20 0.35];
    for i = 1:numel(results)
        [u1, ~] = debt_limit_series(results(i).oo, results(i).M, ...
            results(i).limit_settings, shock_suffix, 1);
        [u2, ~] = debt_limit_series(results(i).oo, results(i).M, ...
            results(i).limit_settings, shock_suffix, 2);
        y = (u2 - results(i).limit_settings.ubar2) ...
            - (u1 - results(i).limit_settings.ubar1);
        horizon = 1:numel(y);
        plot(horizon, y, 'LineWidth', 1.5, 'Color', color, ...
            'LineStyle', results(i).line_style);
        hold on;
    end
    yline(0, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('期数');
    grid on;
end

function plot_pressure_gap_panel(results, shock_suffix, title_text)
    nexttile;
    color = [0.05 0.20 0.35];
    for i = 1:numel(results)
        [~, p1] = debt_limit_series(results(i).oo, results(i).M, ...
            results(i).limit_settings, shock_suffix, 1);
        [~, p2] = debt_limit_series(results(i).oo, results(i).M, ...
            results(i).limit_settings, shock_suffix, 2);
        y = p2 - p1;
        horizon = 1:numel(y);
        plot(horizon, y, 'LineWidth', 1.5, 'Color', color, ...
            'LineStyle', results(i).line_style);
        hold on;
    end
    yline(0, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('期数');
    grid on;
end

function plot_debt_ratio_gap_panel(results, shock_suffix, b_y1, b_y2, title_text)
    nexttile;
    color = [0.05 0.20 0.35];
    for i = 1:numel(results)
        b1 = get_irf(results(i).oo, 'b1', shock_suffix);
        b2 = get_irf(results(i).oo, 'b2', shock_suffix);
        y1 = get_irf(results(i).oo, 'y1', shock_suffix);
        y2 = get_irf(results(i).oo, 'y2', shock_suffix);
        debt_ratio1 = b1 - b_y1 * y1;
        debt_ratio2 = b2 - b_y2 * y2;
        y = debt_ratio2 - debt_ratio1;
        horizon = 1:numel(y);
        plot(horizon, y, 'LineWidth', 1.5, 'Color', color, ...
            'LineStyle', results(i).line_style);
        hold on;
    end
    yline(0, ':');
    title(title_text, 'Interpreter', 'none');
    xlabel('期数');
    grid on;
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

function p = pressure(u, ucrit, nu)
    p = log(1 + exp(nu * (u - ucrit))) / nu;
end

function value = l2_norm(x)
    value = sqrt(sum(x(:).^2));
end

function text = set_parameter_value(text, name, value)
    pattern = ['(?m)^\s*' name '\s*=\s*[-+0-9.eE]+;\s*$'];
    replacement = sprintf('%-11s= %.8g;', name, value);
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
