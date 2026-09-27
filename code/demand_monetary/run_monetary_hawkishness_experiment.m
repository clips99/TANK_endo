function run_monetary_hawkishness_experiment()
% Monetary policy stabilization experiment under a persistent demand slump.
%
% Introduce a common persistent negative demand shock into the risk-free Euler
% equation and vary the Taylor-rule inflation response coefficient. The main
% statistics summarize each rule by welfare, theoretical unconditional standard
% deviations, regional synchronization, and finite-horizon IRF diagnostics.


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

baseline_phi_pi = 1.50;

% Refresh the legacy monetary-shock hawkishness files as auditable X-GDP
% variants too. They are not used for Figure 4, but remain part of the codebase.
legacy_phi = [1.10 1.50 2.00 3.00];
for legacy_i = 1:numel(legacy_phi)
    legacy_name = sprintf('hawkish_phi_%03d', round(100 * legacy_phi(legacy_i)));
    legacy_text = set_parameter_line(base_text, 'phi_pi', legacy_phi(legacy_i));
    write_text_file(fullfile(script_dir, [legacy_name '.mod']), legacy_text);
end

% Generate every scenario before starting Dynare. On Windows, repeated
% in-process Dynare calls can temporarily retain enough file descriptors to
% make a later fopen fail even though the target .mod file is writable.
% Pre-generation also makes the complete experiment design auditable before
% any solver run begins.
for scenario_i = 1:numel(policy_rules)
    rule = policy_rules(scenario_i);
    scenario_text = make_negative_demand_model( ...
        base_text, rho_demand, demand_shock_stderr);
    scenario_text = set_parameter_line(scenario_text, 'phi_pi', rule.phi_pi);
    write_text_file(fullfile(script_dir, ['negative_demand_' rule.name '.mod']), scenario_text);
end

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

    scenario_mod = [scenario_name '.mod'];

    try
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        result_file = fullfile(script_dir, scenario_name, 'Output', [scenario_name '_results.mat']);
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

writetable(status, fullfile(script_dir, 'negative_demand_policy_status.csv'));
writetable(summary, fullfile(script_dir, 'negative_demand_policy_summary.csv'));
writetable(irf_series, fullfile(script_dir, 'negative_demand_policy_irf_series.csv'));
writetable(tradeoff_metrics, fullfile(script_dir, 'negative_demand_policy_tradeoff_metrics.csv'));
writetable(welfare_metrics, fullfile(script_dir, 'negative_demand_policy_welfare_metrics.csv'));
writetable(evaluation_table, fullfile(script_dir, 'negative_demand_policy_evaluation_table.csv'));

fprintf('\nNegative demand policy experiment status\n');
fprintf('--------------------------------\n');
disp(status);

fprintf('\nAggregate stabilization and regional synchronization summary\n');
fprintf('--------------------------------\n');
disp(summary(:, {'label','min_r','min_xagg','min_pinfagg', ...
    'max_ds2','min_ig2','max_abs_y_gap','max_abs_pinf_gap'}));

if ~isempty(tradeoff_metrics)
    fprintf('\nUnconditional stability and regional synchronization metrics\n');
    fprintf('--------------------------------\n');
    disp(tradeoff_metrics(:, {'label','reported_inflation_sd_x100', ...
        'reported_output_sd_x100','reported_output_gap_sd_x100', ...
        'regional_output_correlation','cumulative_output_loss_gap_40'}));
end

if ~isempty(welfare_metrics)
    fprintf('\nConsumption-equivalent welfare changes relative to phi_pi = %.1f\n', ...
        baseline_phi_pi);
    fprintf('--------------------------------\n');
    disp(welfare_metrics(:, {'label','cev_national_pct','cev_low_debt_pct', ...
        'cev_high_debt_pct'}));
end

if any(status.status == "failed")
    error('One or more negative-demand scenarios failed; see negative_demand_policy_status.csv.');
end

figure4_grid = collect_figure4_grid(base_text, results, rho_demand, demand_shock_stderr);
writetable(figure4_grid, fullfile(script_dir,'figure4_stability_sync_grid.csv'));
plot_demand_monetary();
end

function grid = collect_figure4_grid(base_text, results, rho_demand, shock_stderr)
% Figure 4 only: fixed debt scenarios crossed with the exact policy grid.
% Reuse the five freshly solved baseline-debt nodes. Solve the other 25 in
% a disposable Dynare workspace, leaving all maintained .mod/MAT files intact.
    debt_grid = [0.80 1.00 1.20 1.40 1.60];
    phi_grid = [1.1 1.3 1.5 2.0 2.5 3.0];
    scratch = tempname;
    mkdir(scratch);
    caller_dir = pwd;
    cleanup = onCleanup(@() cleanup_figure4_workspace(scratch,caller_dir));
    names = strings(5,6);
    for d=1:5
        for j=1:6
            names(d,j)=sprintf('figure4_d%03d_phi%03d',round(100*debt_grid(d)),round(100*phi_grid(j)));
            if debt_grid(d)==1 && any(abs([results.phi_pi]-phi_grid(j))<1e-12),continue;end
            source=make_negative_demand_model(base_text,rho_demand,shock_stderr);
            source=set_parameter_line(source,'d_ann1',0.40);
            source=set_parameter_line(source,'d_ann2',debt_grid(d));
            source=set_parameter_line(source,'phi_pi',phi_grid(j));
            % The unchanged model calibration recalculates B, DS and Z from
            % each debt target, exactly as in the debt-intensity experiment.
            write_text_file(fullfile(scratch,names(d,j)+".mod"),source);
        end
    end
    grid=table();
    cd(scratch);
    for d=1:5
        for j=1:6
            existing=find(abs([results.phi_pi]-phi_grid(j))<1e-12,1);
            reused=debt_grid(d)==1 && ~isempty(existing);
            if reused
                M=results(existing).M; o=results(existing).oo;
            else
                transcript=evalc(sprintf('dynare %s.mod noclearall nolog',names(d,j)));
                assert(contains(transcript,'The order and rank conditions are verified.') && ...
                    contains(transcript,'No obvious problems with this mod-file were detected.'), ...
                    'Figure 4 node failed BK or diagnostics: %s',names(d,j));
                solved=load(fullfile(scratch,names(d,j),'Output',names(d,j)+"_results.mat"),'M_','oo_');
                M=solved.M_; o=solved.oo_;
            end
            % Preserve the original Figure 4 objects and unconditional-moment
            % convention used in collect_stability_sync_metrics below.
            sd_gap=safe_standard_deviation(difference_variance(o,'xloc2','xloc1'));
            sd_inflation=safe_standard_deviation(get_theoretical_covariance(o,'pinfagg','pinfagg'));
            assert(isfinite(sd_gap) && isfinite(sd_inflation));
            assert(abs(get_model_parameter(M,'d_ann1')-.4)<1e-12 && ...
                abs(get_model_parameter(M,'d_ann2')-debt_grid(d))<1e-12);
            row=table(.4,debt_grid(d),phi_grid(j),sd_gap,sd_inflation,100*sd_gap,100*sd_inflation,reused, ...
                'VariableNames',{'d1_ann','d2_ann','phi_pi','unconditional_output_gap_sd', ...
                'unconditional_inflation_sd','reported_output_gap_sd_x100', ...
                'reported_inflation_sd_x100','reused_baseline_node'});
            grid=[grid;row]; %#ok<AGROW>
            fprintf('Figure 4 d2=%.2f phi_pi=%.1f: 100*sd(Y2-Y1)=%.9f, 100*sd(Pi)=%.9f\n', ...
                debt_grid(d),phi_grid(j),100*sd_gap,100*sd_inflation);
        end
    end
end

function cleanup_figure4_workspace(scratch,caller_dir)
    cd(caller_dir);
    entries=strsplit(path,pathsep);
    for i=1:numel(entries)
        if strcmp(entries{i},scratch) || startsWith(entries{i},[scratch filesep])
            rmpath(entries{i});
        end
    end
    assert(startsWith(scratch,tempdir),'Refusing to remove a non-temporary workspace.');
    if isfolder(scratch),rmdir(scratch,'s');end
end

function text = make_negative_demand_model(text, rho_demand, demand_shock_stderr)
    text = set_parameter_line(text, 'rho_d', rho_demand);

    shock_block = sprintf(['shocks;\n' ...
        '    var emp; stderr 0;\n' ...
        '    var ed; stderr %.8g;\n' ...
        'end;'], demand_shock_stderr);
    text = regex_replace_once(text, 'shocks;[\s\S]*?end;', shock_block);

    simul_block = sprintf(['stoch_simul(order = 1, irf = 40, nograph)\n' ...
        '    mp d r rb1 rb2 xagg pinfagg\n' ...
        '    ds1 ds2 fs1 fs2\n' ...
        '    ig1 ig2 kg1 kg2\n' ...
        '    c1 n1 c2 n2\n' ...
        '    ym1 ym2 xloc1 xloc2 inv1 inv2 n1 n2 w1 w2 c1 c2\n' ...
        '    pinf1 pinf2;']);
    text = regex_replace_once(text, ...
        'stoch_simul\(order = 1, irf = 40, nograph\)[\s\S]*?;', ...
        simul_block);
end

function write_text_file(path, text)
    [fid, message] = fopen(path, 'w');
    if fid < 0
        error('Could not write scenario file %s: %s', path, message);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, text);
    clear cleaner;
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
    demand = get_irf(oo_, 'd', shock_suffix);
    r = get_irf(oo_, 'r', shock_suffix);
    xagg = get_irf(oo_, 'xagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);

    ds1 = get_irf(oo_, 'ds1', shock_suffix);
    ds2 = get_irf(oo_, 'ds2', shock_suffix);
    fs2 = get_irf(oo_, 'fs2', shock_suffix);
    ig1 = get_irf(oo_, 'ig1', shock_suffix);
    ig2 = get_irf(oo_, 'ig2', shock_suffix);
    kg2 = get_irf(oo_, 'kg2', shock_suffix);
    xloc1 = get_irf(oo_, 'xloc1', shock_suffix);
    xloc2 = get_irf(oo_, 'xloc2', shock_suffix);
    c2 = get_irf(oo_, 'c2', shock_suffix);
    pinf1 = get_irf(oo_, 'pinf1', shock_suffix);
    pinf2 = get_irf(oo_, 'pinf2', shock_suffix);

    ds_gap = ds2 - ds1;
    ig_gap = ig2 - ig1;
    y_gap = xloc2 - xloc1;
    pinf_gap = pinf2 - pinf1;

    summary = table(string(scenario.name), string(scenario.label), scenario.phi_pi, ...
        scenario.rho_demand, scenario.shock_stderr, ...
        min(demand), min(r), min(xagg), min(pinfagg), ...
        max(ds2), min(fs2), min(ig2), min(kg2), min(xloc2), min(c2), min(pinf2), ...
        max(abs(ds_gap)), max(abs(ig_gap)), max(abs(y_gap)), max(abs(pinf_gap)), ...
        xagg(periods(1)), xagg(periods(2)), xagg(periods(3)), xagg(periods(4)), ...
        pinfagg(periods(1)), pinfagg(periods(2)), pinfagg(periods(3)), pinfagg(periods(4)), ...
        ds2(periods(1)), ds2(periods(2)), ds2(periods(3)), ds2(periods(4)), ...
        ig2(periods(1)), ig2(periods(2)), ig2(periods(3)), ig2(periods(4)), ...
        y_gap(periods(1)), y_gap(periods(2)), y_gap(periods(3)), y_gap(periods(4)), ...
        pinf_gap(periods(1)), pinf_gap(periods(2)), pinf_gap(periods(3)), pinf_gap(periods(4)), ...
        'VariableNames', {'scenario','label','phi_pi','rho_demand','shock_stderr', ...
        'min_demand','min_r','min_xagg','min_pinfagg', ...
        'max_ds2','min_fs2','min_ig2','min_kg2','min_xloc2','min_c2','min_pinf2', ...
        'max_abs_ds_gap','max_abs_ig_gap','max_abs_y_gap','max_abs_pinf_gap', ...
        'xagg_t1','xagg_t4','xagg_t8','xagg_t12', ...
        'pinfagg_t1','pinfagg_t4','pinfagg_t8','pinfagg_t12', ...
        'ds2_t1','ds2_t4','ds2_t8','ds2_t12', ...
        'ig2_t1','ig2_t4','ig2_t8','ig2_t12', ...
        'y_gap_t1','y_gap_t4','y_gap_t8','y_gap_t12', ...
        'pinf_gap_t1','pinf_gap_t4','pinf_gap_t8','pinf_gap_t12'});
end

function series = collect_irf_series(oo_, scenario, shock_suffix)
    demand = get_irf(oo_, 'd', shock_suffix);
    r = get_irf(oo_, 'r', shock_suffix);
    xagg = get_irf(oo_, 'xagg', shock_suffix);
    pinfagg = get_irf(oo_, 'pinfagg', shock_suffix);
    n1 = get_irf(oo_, 'n1', shock_suffix);
    n2 = get_irf(oo_, 'n2', shock_suffix);
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
    horizon = (1:numel(xagg))';

    ds_gap = ds2(:) - ds1(:);
    fs_gap = fs2(:) - fs1(:);
    ig_gap = ig2(:) - ig1(:);
    kg_gap = kg2(:) - kg1(:);
    y_gap = xloc2(:) - xloc1(:);
    c_gap = c2(:) - c1(:);
    pinf_gap = pinf2(:) - pinf1(:);

    series = table(repmat(string(scenario.name), numel(horizon), 1), ...
        repmat(string(scenario.label), numel(horizon), 1), ...
        repmat(scenario.phi_pi, numel(horizon), 1), ...
        repmat(scenario.rho_demand, numel(horizon), 1), ...
        repmat(scenario.shock_stderr, numel(horizon), 1), ...
        horizon, demand(:), r(:), xagg(:), pinfagg(:), ...
        n1(:), n2(:), ...
        ds1(:), ds2(:), fs1(:), fs2(:), ig1(:), ig2(:), kg1(:), kg2(:), ...
        xloc1(:), xloc2(:), c1(:), c2(:), pinf1(:), pinf2(:), ...
        ds_gap, fs_gap, ig_gap, kg_gap, y_gap, c_gap, pinf_gap, ...
        abs(ds_gap), abs(ig_gap), abs(y_gap), abs(pinf_gap), ...
        'VariableNames', {'scenario','label','phi_pi','rho_demand','shock_stderr', ...
        'horizon','demand','r','xagg','pinfagg', ...
        'n1','n2', ...
        'ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2', ...
        'xloc1','xloc2','c1','c2','pinf1','pinf2', ...
        'ds_gap','fs_gap','ig_gap','kg_gap','y_gap','c_gap','pinf_gap', ...
        'abs_ds_gap','abs_ig_gap','abs_y_gap','abs_pinf_gap'});
end

function metrics = collect_stability_sync_metrics(results, shock_suffix)
    metrics = table();
    for i = 1:numel(results)
        pinfagg_irf = get_irf(results(i).oo, 'pinfagg', shock_suffix);
        xagg_irf = get_irf(results(i).oo, 'xagg', shock_suffix);
        xloc1_irf = get_irf(results(i).oo, 'xloc1', shock_suffix);
        xloc2_irf = get_irf(results(i).oo, 'xloc2', shock_suffix);
        pinf1_irf = get_irf(results(i).oo, 'pinf1', shock_suffix);
        pinf2_irf = get_irf(results(i).oo, 'pinf2', shock_suffix);
        ds1_irf = get_irf(results(i).oo, 'ds1', shock_suffix);
        ds2_irf = get_irf(results(i).oo, 'ds2', shock_suffix);
        inflation_var = get_theoretical_covariance(results(i).oo, 'pinfagg', 'pinfagg');
        output_var = get_theoretical_covariance(results(i).oo, 'xagg', 'xagg');
        output_gap_var = difference_variance(results(i).oo, 'xloc2', 'xloc1');
        inflation_gap_var = difference_variance(results(i).oo, 'pinf2', 'pinf1');
        debt_service_gap_var = difference_variance(results(i).oo, 'ds2', 'ds1');

        % The unprefixed columns are the raw model-unit standard deviations.
        % Separate reported_*_x100 columns retain the conventional scale used
        % in the figure and prevent a 100-fold transformation from being
        % mislabeled as an unscaled theoretical standard deviation.
        unconditional_inflation_sd = safe_standard_deviation(inflation_var);
        unconditional_output_sd = safe_standard_deviation(output_var);
        unconditional_output_gap_sd = safe_standard_deviation(output_gap_var);
        unconditional_inflation_gap_sd = safe_standard_deviation(inflation_gap_var);
        unconditional_debt_service_gap_sd = safe_standard_deviation(debt_service_gap_var);
        reported_inflation_sd_x100 = 100 * unconditional_inflation_sd;
        reported_output_sd_x100 = 100 * unconditional_output_sd;
        reported_output_gap_sd_x100 = 100 * unconditional_output_gap_sd;
        reported_inflation_gap_sd_x100 = 100 * unconditional_inflation_gap_sd;
        reported_debt_service_gap_sd_x100 = 100 * unconditional_debt_service_gap_sd;
        regional_output_correlation = theoretical_correlation(results(i).oo, 'xloc1', 'xloc2');

        % Positive values mean that the high-debt region (region 2) suffers a
        % larger cumulative output loss. This signed statistic prevents an
        % absolute dispersion measure from being interpreted as incidence.
        cumulative_output_loss_gap_40 = sum(xloc1_irf(:) - xloc2_irf(:));
        reported_cumulative_output_loss_gap_40_x100 = ...
            100 * cumulative_output_loss_gap_40;

        % Retain the original 40-period IRF norms for auditability and as a
        % finite-horizon robustness check. They approximate the unconditional
        % standard deviations when the IRFs are generated by a one-s.d. shock.
        irf40_inflation_norm = sqrt(sum(pinfagg_irf(:).^2));
        irf40_output_norm = sqrt(sum(xagg_irf(:).^2));
        irf40_output_gap_norm = sqrt(sum((xloc2_irf(:) - xloc1_irf(:)).^2));
        irf40_inflation_gap_norm = sqrt(sum((pinf2_irf(:) - pinf1_irf(:)).^2));
        irf40_debt_service_gap_norm = sqrt(sum((ds2_irf(:) - ds1_irf(:)).^2));
        reported_irf40_inflation_norm_x100 = 100 * irf40_inflation_norm;
        reported_irf40_output_norm_x100 = 100 * irf40_output_norm;
        reported_irf40_output_gap_norm_x100 = 100 * irf40_output_gap_norm;
        reported_irf40_inflation_gap_norm_x100 = 100 * irf40_inflation_gap_norm;
        reported_irf40_debt_service_gap_norm_x100 = 100 * irf40_debt_service_gap_norm;

        row = table(string(results(i).name), string(results(i).label), ...
            results(i).phi_pi, numel(pinfagg_irf), ...
            unconditional_inflation_sd, unconditional_output_sd, ...
            unconditional_output_gap_sd, unconditional_inflation_gap_sd, ...
            unconditional_debt_service_gap_sd, regional_output_correlation, ...
            cumulative_output_loss_gap_40, ...
            irf40_inflation_norm, irf40_output_norm, irf40_output_gap_norm, ...
            irf40_inflation_gap_norm, irf40_debt_service_gap_norm, ...
            reported_inflation_sd_x100, reported_output_sd_x100, ...
            reported_output_gap_sd_x100, reported_inflation_gap_sd_x100, ...
            reported_debt_service_gap_sd_x100, ...
            reported_cumulative_output_loss_gap_40_x100, ...
            reported_irf40_inflation_norm_x100, ...
            reported_irf40_output_norm_x100, ...
            reported_irf40_output_gap_norm_x100, ...
            reported_irf40_inflation_gap_norm_x100, ...
            reported_irf40_debt_service_gap_norm_x100, ...
            'VariableNames', {'scenario','label','phi_pi','irf_periods', ...
            'unconditional_inflation_sd','unconditional_output_sd', ...
            'unconditional_output_gap_sd','unconditional_inflation_gap_sd', ...
            'unconditional_debt_service_gap_sd','regional_output_correlation', ...
            'cumulative_output_loss_gap_40', ...
            'irf40_inflation_norm','irf40_output_norm','irf40_output_gap_norm', ...
            'irf40_inflation_gap_norm','irf40_debt_service_gap_norm', ...
            'reported_inflation_sd_x100','reported_output_sd_x100', ...
            'reported_output_gap_sd_x100','reported_inflation_gap_sd_x100', ...
            'reported_debt_service_gap_sd_x100', ...
            'reported_cumulative_output_loss_gap_40_x100', ...
            'reported_irf40_inflation_norm_x100', ...
            'reported_irf40_output_norm_x100', ...
            'reported_irf40_output_gap_norm_x100', ...
            'reported_irf40_inflation_gap_norm_x100', ...
            'reported_irf40_debt_service_gap_norm_x100'});
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

        row = table(string(welfare_results(i).scenario), string(welfare_results(i).label), ...
            welfare_results(i).phi_pi, current.irf_periods, baseline_phi_pi, ...
            current.W_national, current.W_low_debt, current.W_high_debt, ...
            100 * cev_national, 100 * cev_low, 100 * cev_high, ...
            'VariableNames', {'scenario','label','phi_pi','irf_periods','baseline_phi_pi', ...
            'welfare_national','welfare_low_debt','welfare_high_debt', ...
            'cev_national_pct','cev_low_debt_pct','cev_high_debt_pct'});
        welfare_metrics = [welfare_metrics; row]; %#ok<AGROW>
    end

    welfare_metrics = sortrows(welfare_metrics, 'phi_pi');
end

function welfare = compute_conditional_welfare(result, shock_suffix)
    % Finite-horizon conditional allocation measure on first-order paths.
    % This is not second-order unconditional welfare.
    params = get_welfare_parameters(result.M);
    c1 = get_level_path(result, 'c1', shock_suffix);
    c2 = get_level_path(result, 'c2', shock_suffix);
    n1 = get_level_path(result, 'n1', shock_suffix);
    n2 = get_level_path(result, 'n2', shock_suffix);
    periods = numel(c1);
    discount = params.beta .^ (0:periods - 1)';
    welfare.params = params;
    welfare.irf_periods = periods;
    welfare.W_low_debt = sum(discount .* period_utility(c1, n1, params));
    welfare.W_high_debt = sum(discount .* period_utility(c2, n2, params));
    welfare.W_national = params.s1*welfare.W_low_debt + params.s2*welfare.W_high_debt;
    welfare.paths.national = make_welfare_paths({c1,c2}, {n1,n2}, [params.s1,params.s2]);
    welfare.paths.low_debt = make_welfare_paths({c1}, {n1}, 1);
    welfare.paths.high_debt = make_welfare_paths({c2}, {n2}, 1);
end

function params = get_welfare_parameters(M_)
    params = struct();
    params.beta = get_model_parameter(M_, 'beta');
    params.sigma = get_model_parameter(M_, 'sigma');
    params.varphi = get_model_parameter(M_, 'varphi');
    params.chi_n = get_model_parameter(M_, 'chi_n');
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
        "National inflation unconditional standard deviation, x100";
        "National production-GDP unconditional standard deviation, x100";
        "Regional production-GDP-gap unconditional standard deviation, x100";
        "Regional inflation-gap unconditional standard deviation, x100";
        "Net real debt-service-burden-gap unconditional standard deviation, x100";
        "Regional production-GDP correlation";
        "40-period cumulative production-GDP-loss gap, high minus low";
        "National welfare CEV, percent";
        "Low-debt welfare CEV, percent";
        "High-debt welfare CEV, percent"];

    table_out = table(indicators, 'VariableNames', {'indicator'});
    for i = 1:height(stability_metrics)
        phi = stability_metrics.phi_pi(i);
        welfare_idx = find(abs(welfare_metrics.phi_pi - phi) < 1e-10, 1);
        if isempty(welfare_idx)
            error('Missing welfare metrics for phi_pi = %.4g.', phi);
        end

        values = [
            stability_metrics.reported_inflation_sd_x100(i);
            stability_metrics.reported_output_sd_x100(i);
            stability_metrics.reported_output_gap_sd_x100(i);
            stability_metrics.reported_inflation_gap_sd_x100(i);
            stability_metrics.reported_debt_service_gap_sd_x100(i);
            stability_metrics.regional_output_correlation(i);
            stability_metrics.cumulative_output_loss_gap_40(i);
            welfare_metrics.cev_national_pct(welfare_idx);
            welfare_metrics.cev_low_debt_pct(welfare_idx);
            welfare_metrics.cev_high_debt_pct(welfare_idx)];

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

function covariance = get_theoretical_covariance(oo_, first_name, second_name)
    if ~isfield(oo_, 'var') || isempty(oo_.var)
        error('Dynare theoretical covariance matrix oo_.var is unavailable.');
    end
    if ~isfield(oo_, 'var_list') || isempty(oo_.var_list)
        error('Dynare variable list oo_.var_list is unavailable.');
    end

    names = oo_.var_list;
    if ischar(names) || isstring(names)
        names = cellstr(names);
    end
    first_idx = find(strcmp(names, first_name), 1);
    second_idx = find(strcmp(names, second_name), 1);
    if isempty(first_idx) || isempty(second_idx)
        error('Variables %s and/or %s are absent from oo_.var_list.', ...
            first_name, second_name);
    end
    covariance = 0.5 * (oo_.var(first_idx, second_idx) ...
        + oo_.var(second_idx, first_idx));
end

function variance = difference_variance(oo_, first_name, second_name)
    variance = get_theoretical_covariance(oo_, first_name, first_name) ...
        + get_theoretical_covariance(oo_, second_name, second_name) ...
        - 2 * get_theoretical_covariance(oo_, first_name, second_name);
end

function standard_deviation = safe_standard_deviation(variance)
    tolerance = 1e-12 * max(1, abs(variance));
    if variance < -tolerance
        error('Encountered a materially negative theoretical variance: %.16g.', variance);
    end
    standard_deviation = sqrt(max(variance, 0));
end

function correlation = theoretical_correlation(oo_, first_name, second_name)
    first_var = get_theoretical_covariance(oo_, first_name, first_name);
    second_var = get_theoretical_covariance(oo_, second_name, second_name);
    denominator = safe_standard_deviation(first_var) ...
        * safe_standard_deviation(second_var);
    if denominator <= eps
        error('Cannot compute correlation for a variable with zero variance.');
    end
    correlation = get_theoretical_covariance(oo_, first_name, second_name) ...
        / denominator;
    correlation = min(max(correlation, -1), 1);
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
