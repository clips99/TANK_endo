function freeze_decision = run_ba_sensitivity_sanity()
% Low-cost Scheme-B-minus-Scheme-A parameter-sensitivity sanity check.
%
% The design and materiality rule are written to disk before any Dynare
% model is run. Every A/B model is generated and executed in an isolated
% directory; the audited canonical baseline files are never overwritten.

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir,'../../../utils'));
stackelberg_root = fileparts(fileparts(script_dir));
scheme_a_dir = fullfile(stackelberg_root, 'robustness', 'scheme_A');
baseline_dir = fullfile(stackelberg_root, 'baseline');
validation_code_dir = fullfile(stackelberg_root, 'validation');
generated_root = fullfile(script_dir, 'generated');

dynare_path = 'C:\dynare\7.0\matlab';
if ~isfolder(dynare_path)
    error('Dynare 7 MATLAB directory not found: %s', dynare_path);
end
addpath(dynare_path, '-begin');
addpath(validation_code_dir);
addpath(scheme_a_dir);
addpath(script_dir);
dynare_entry = which('dynare');
if isempty(dynare_entry) || ~contains(dynare_entry, 'dynare\7.0', 'IgnoreCase', true)
    error('Expected Dynare 7.0, but MATLAB resolved dynare to: %s', dynare_entry);
end
if ~isfolder(generated_root)
    mkdir(generated_root);
end

template_a_path = fullfile(scheme_a_dir, 'RANK_two_region_scheme_A.mod');
template_b_path = fullfile(baseline_dir, 'RANK_two_region_stackelberg.mod');
if ~isfile(template_a_path) || ~isfile(template_b_path)
    error('Canonical Scheme-A or Scheme-B template is missing.');
end
template_a = fileread(template_a_path);
template_b = fileread(template_b_path);

%% Pre-registered OAT design: conservative ranges around the calibration
scenario_id = ["baseline"; "gamma_low"; "gamma_high"; ...
    "phiI_low"; "phiI_high"; "chiIG_low"; "chiIG_high"; ...
    "alpha_low"; "alpha_high"];
varied_parameter = ["baseline"; "gamma_g"; "gamma_g"; ...
    "phi_i"; "phi_i"; "chi_ig"; "chi_ig"; "alpha"; "alpha"];
level = ["baseline"; "low"; "high"; "low"; "high"; ...
    "low"; "high"; "low"; "high"];
is_baseline = [true; false(8, 1)];
gamma_g = [0.10; 0.05; 0.15; 0.10; 0.10; 0.10; 0.10; 0.10; 0.10];
phi_i = [2.50; 2.50; 2.50; 1.25; 5.00; 2.50; 2.50; 2.50; 2.50];
chi_ig = [20; 20; 20; 20; 20; 10; 40; 20; 20];
alpha = [0.45; 0.45; 0.45; 0.45; 0.45; 0.45; 0.45; 0.40; 0.50];
design = table(scenario_id, varied_parameter, level, is_baseline, ...
    gamma_g, alpha, phi_i, chi_ig);
design_file = fullfile(script_dir, 'sensitivity_design.csv');
writetable(design, design_file);

rule_id = ["fixed_window"; "full_path"; "cancellation_guard"; ...
    "small_effect"; "borderline"; "material"; "structural_gate"; ...
    "sign_and_order_gate"; "peak_rule"];
definition = ["Rcum=abs(sum_1_12(B-A))/abs(sum_1_12(A))"; ...
    "Rpath=norm_2(B-A)/norm_2(A), periods 1-40"; ...
    "If abs(sum(A))<0.1*sum(abs(A)), Rcum is unavailable and Rpath governs"; ...
    "effective_ratio<0.05"; ...
    "0.05<=effective_ratio<0.10"; ...
    "effective_ratio>=0.10, or a core sign/order reversal"; ...
    "All 18 runs and every A/B comparability check must pass"; ...
    "Cumulative response signs and high-minus-low ordering must be preserved"; ...
    "Peaks are descriptive only and never determine the decision"];
threshold = [NaN; NaN; 0.10; 0.05; 0.10; 0.10; NaN; NaN; NaN];
interpretation = ["Registered 1-12 cumulative contribution"; ...
    "No-cancellation whole-path diagnostic"; ...
    "Prevents an unstable cumulative denominator"; ...
    "Conservative quantitative-materiality screen, not a statistical test"; ...
    "Requires substantive review before model freeze"; ...
    "B extension is quantitatively material"; ...
    "A failed or missing case makes the conclusion inconclusive"; ...
    "The qualitative mechanism may not be overturned"; ...
    "No ex-post selection based on an attractive peak"];
rule_table = table(rule_id, definition, threshold, interpretation);
writetable(rule_table, fullfile(script_dir, 'sensitivity_preregistered_rule.csv'));

batch_run_id = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
batch_start = string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
fprintf('Pre-registered design written: %d scenarios, %d A/B runs.\n', ...
    height(design), 2 * height(design));

manifest_all = table();
multiplier_all = table();
region_all = table();
gap_all = table();
summary_all = table();
pair_status_all = table();

for scenario_index = 1:height(design)
    row = design(scenario_index, :);
    scenario = row.scenario_id;
    fprintf('\n[%d/%d] Scenario %s\n', scenario_index, height(design), scenario);

    ss_b = solve_stackelberg_ss_for_parameters( ...
        row.phi_i, row.gamma_g, row.chi_ig, row.alpha);
    multiplier_all = [multiplier_all; multiplier_result_table( ...
        batch_run_id, scenario, ss_b)]; %#ok<AGROW>
    if ss_b.status ~= "PASS"
        error('Scheme-B steady multiplier solution failed for %s.', scenario);
    end

    scenario_root = fullfile(generated_root, char(scenario));
    a_dir = fullfile(scenario_root, 'A');
    b_dir = fullfile(scenario_root, 'B');
    ensure_directory(a_dir);
    ensure_directory(b_dir);

    model_a_name = "RANK_scheme_A_" + scenario;
    model_b_name = "RANK_scheme_B_" + scenario;
    model_a_path = fullfile(a_dir, char(model_a_name + ".mod"));
    model_b_path = fullfile(b_dir, char(model_b_name + ".mod"));

    content_a = calibrate_template(template_a, row, [], "A");
    content_b = calibrate_template(template_b, row, ss_b, "B");
    write_text_file(model_a_path, content_a);
    write_text_file(model_b_path, content_b);

    [result_a, manifest_a] = run_single_model(model_a_path, "A", ...
        batch_run_id, scenario, row, template_a_path, ss_b, ...
        validation_code_dir, scheme_a_dir);
    manifest_all = [manifest_all; manifest_a]; %#ok<AGROW>

    [result_b, manifest_b] = run_single_model(model_b_path, "B", ...
        batch_run_id, scenario, row, template_b_path, ss_b, ...
        validation_code_dir, scheme_a_dir);
    manifest_all = [manifest_all; manifest_b]; %#ok<AGROW>

    if manifest_a.status ~= "PASS" || manifest_b.status ~= "PASS"
        fprintf('  Pair comparison skipped because one structural run failed.\n');
        continue;
    end

    [region_table, gap_table, summary_table, pair_status] = ...
        compare_pair(result_a, result_b, row, batch_run_id);
    region_all = [region_all; region_table]; %#ok<AGROW>
    gap_all = [gap_all; gap_table]; %#ok<AGROW>
    summary_all = [summary_all; summary_table]; %#ok<AGROW>
    pair_status_all = [pair_status_all; pair_status]; %#ok<AGROW>
end

%% Cross-scenario sign audit and final materiality decision
if ~isempty(summary_all)
    summary_all = attach_baseline_sign_checks(summary_all);
end

writetable(manifest_all, fullfile(script_dir, 'sensitivity_run_manifest.csv'));
writetable(multiplier_all, fullfile(script_dir, 'sensitivity_multiplier_ss.csv'));
writetable(region_all, fullfile(script_dir, 'sensitivity_region_irf_series.csv'));
writetable(gap_all, fullfile(script_dir, 'sensitivity_gap_irf_series.csv'));
writetable(summary_all, fullfile(script_dir, 'sensitivity_summary.csv'));
writetable(pair_status_all, fullfile(script_dir, 'sensitivity_pair_status.csv'));

expected_runs = 2 * height(design);
all_runs_present = height(manifest_all) == expected_runs;
all_runs_pass = all_runs_present && all(manifest_all.status == "PASS");
if isempty(pair_status_all)
    overall_pair_rows = false(0, 1);
else
    overall_pair_rows = pair_status_all.check_name == "overall";
end
all_pairs_present = sum(overall_pair_rows) == height(design);
all_pairs_pass = all_pairs_present && all(pair_status_all.status == "PASS");
all_summaries_present = height(summary_all) == height(design) * 3 * 3;
all_signs_preserved = all_summaries_present ...
    && all(summary_all.sign_preserved_within_pair) ...
    && all(summary_all.baseline_A_sign_preserved) ...
    && all(summary_all.baseline_B_sign_preserved);
all_orderings_preserved = all_summaries_present ...
    && all(summary_all.high_low_ordering_preserved);

if isempty(summary_all)
    global_max_ratio = NaN;
    max_row = table();
else
    [global_max_ratio, max_index] = max(summary_all.effective_ratio);
    max_row = summary_all(max_index, :);
end

if ~(all_runs_pass && all_pairs_pass && all_summaries_present)
    freeze_decision = "INCONCLUSIVE_STRUCTURAL_OR_DATA_FAILURE";
elseif ~(all_signs_preserved && all_orderings_preserved)
    freeze_decision = "DO_NOT_FREEZE_QUALITATIVE_REVERSAL";
elseif global_max_ratio < 0.05
    freeze_decision = "FREEZE_A_AS_MAIN_BASELINE";
elseif global_max_ratio < 0.10
    freeze_decision = "BORDERLINE_REVIEW_BEFORE_FREEZE";
else
    freeze_decision = "DO_NOT_FREEZE_B_IS_MATERIAL";
end

check_name = ["all_18_runs_present"; "all_structural_runs_pass"; ...
    "all_9_pair_checks_present"; "all_pair_comparability_checks_pass"; ...
    "all_81_registered_summaries_present"; ...
    "all_cumulative_signs_preserved"; "all_high_low_orderings_preserved"; ...
    "global_effective_ratio_below_5_percent"; "final_decision"];
observed_value = [string(all_runs_present); string(all_runs_pass); ...
    string(all_pairs_present); string(all_pairs_pass); ...
    string(all_summaries_present); string(all_signs_preserved); ...
    string(all_orderings_preserved); string(sprintf('%.17g', global_max_ratio)); ...
    freeze_decision];
criterion = ["18"; "all PASS"; "9"; "all PASS"; "81"; ...
    "true"; "true"; "<0.05"; "all preceding gates and materiality rule"];
status = [pass_fail(all_runs_present); pass_fail(all_runs_pass); ...
    pass_fail(all_pairs_present); pass_fail(all_pairs_pass); ...
    pass_fail(all_summaries_present); pass_fail(all_signs_preserved); ...
    pass_fail(all_orderings_preserved); ...
    pass_fail(isfinite(global_max_ratio) && global_max_ratio < 0.05); ...
    decision_status(freeze_decision)];
note = ["Every scenario must have one A and one B run"; ...
    "Residual, Jacobian, diagnostics, BK, IRF, and shadow-target gates"; ...
    "No failed case may be silently dropped"; ...
    "Shared parameters, shared steady states, shock, order, horizon, DID"; ...
    "9 scenarios x 3 variables x 3 scopes"; ...
    "Within-pair and relative-to-baseline cumulative signs"; ...
    "High-minus-low cumulative sign is the regional ordering"; ...
    "Maximum of registered Rcum and Rpath metrics"; ...
    "5 percent is an economic-materiality screen, not statistical significance"];
status_table = table(check_name, observed_value, criterion, status, note);
if ~isempty(max_row)
    status_table.max_ratio_scenario = repmat(string(max_row.scenario_id), ...
        height(status_table), 1);
    status_table.max_ratio_variable = repmat(string(max_row.variable), ...
        height(status_table), 1);
    status_table.max_ratio_scope = repmat(string(max_row.scope), ...
        height(status_table), 1);
else
    status_table.max_ratio_scenario = repmat("", height(status_table), 1);
    status_table.max_ratio_variable = repmat("", height(status_table), 1);
    status_table.max_ratio_scope = repmat("", height(status_table), 1);
end
writetable(status_table, fullfile(script_dir, 'sensitivity_acceptance.csv'));

scenario_summary = build_scenario_summary(summary_all, design);
writetable(scenario_summary, fullfile(script_dir, 'sensitivity_scenario_summary.csv'));

batch_end = string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
decision_table = table(batch_run_id, batch_start, batch_end, ...
    get_sha256(template_a_path), get_sha256(template_b_path), ...
    get_sha256(design_file), global_max_ratio, freeze_decision, ...
    'VariableNames', {'batch_run_id', 'start_time', 'end_time', ...
    'scheme_A_template_sha256', 'scheme_B_template_sha256', ...
    'design_sha256', 'global_max_effective_ratio', 'decision'});
writetable(decision_table, fullfile(script_dir, 'sensitivity_decision.csv'));
plot_stackelberg_irf_compare();

fprintf('\nSensitivity sanity check completed: %s\n', freeze_decision);
fprintf('Global maximum registered B-A ratio: %.6f\n', global_max_ratio);
if ~isempty(max_row)
    fprintf('Binding case: %s / %s / %s\n', ...
        max_row.scenario_id, max_row.variable, max_row.scope);
end
end

function content = calibrate_template(template, design_row, ss_b, scheme)
content = template;
content = replace_assignment(content, 'phi_i', design_row.phi_i);
content = replace_assignment(content, 'gamma_g', design_row.gamma_g);
content = replace_assignment(content, 'chi_ig', design_row.chi_ig);
content = replace_assignment(content, 'alpha', design_row.alpha);
if scheme == "B"
    u = ss_b.solution;
    content = replace_assignment(content, 'lamgbar1', u(1));
    content = replace_assignment(content, 'murbar1', u(3));
    content = replace_assignment(content, 'mukbar1', u(4));
    content = replace_assignment(content, 'muqbar1', u(5));
end
end

function content = replace_assignment(content, name, value)
pattern = ['(?m)^\s*' regexptranslate('escape', name) '\s*=\s*[^;]+;'];
matches = regexp(content, pattern, 'match');
if numel(matches) ~= 1
    error('Expected exactly one calibration assignment for %s; found %d.', ...
        name, numel(matches));
end
replacement = sprintf('%-12s = %.17g;', name, value);
content = regexprep(content, pattern, replacement, 'once');
end

function [result, manifest] = run_single_model(model_path, scheme, ...
        batch_run_id, scenario, design_row, template_path, ss_b, ...
        validation_code_dir, scheme_a_dir)
run_start = string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
run_id = batch_run_id + "_" + scenario + "_" + scheme;
model_dir = fileparts(model_path);
[~, model_name, ~] = fileparts(model_path);
validation_dir = fullfile(model_dir, 'validation');
ensure_directory(validation_dir);
log_path = fullfile(validation_dir, 'dynare_console_output.txt');

result = struct();
validation_status = "NOT_REACHED";
shadow_status = "NOT_REACHED";
shadow_error = NaN;
shadow_denominator = NaN;
status = "FAIL";
error_message = "";
endo_count = NaN;
equation_count = NaN;
max_residual = NaN;
jacobian_rank = NaN;
jacobian_dimension = NaN;
unstable_roots = NaN;
forward_looking = NaN;
bk_status = "NOT_REACHED";
shock_std = NaN;
approximation_order = NaN;
horizon = NaN;
matlab_release = string(version('-release'));
dynare_release = string(dynare_version());

old_dir = pwd;
cleanup = onCleanup(@() cd(old_dir)); %#ok<NASGU>
try
    cd(model_dir);
    addpath(validation_code_dir);
    addpath(scheme_a_dir);
    command = sprintf('dynare %s.mod noclearall', model_name);
    dynare_output = evalc(command);
    % Dynare 7 executes its generated package driver in a separate function
    % workspace. Load the authoritative saved structures instead of relying
    % on M_, oo_, and options_ leaking into this local helper workspace.
    dynare_result_path = fullfile(model_dir, model_name, 'Output', ...
        [model_name '_results.mat']);
    if ~isfile(dynare_result_path)
        error('Dynare result snapshot was not created: %s', dynare_result_path);
    end
    dynare_result = load(dynare_result_path, 'M_', 'oo_', 'options_');
    M_ = dynare_result.M_;
    oo_ = dynare_result.oo_;
    options_ = dynare_result.options_;

    if scheme == "A"
        catalog = scheme_a_irf_catalog();
        config = struct();
        config.expected_endogenous = 78;
        config.expected_equations = 78;
        config.residual_tolerance = 1e-10;
        config.required_irf_variables = catalog.variable;
        config.shock_suffix = catalog.shock_suffix;
        config.irf_description = "Scheme-A sensitivity";
        validation_status = export_stackelberg_validation( ...
            M_, oo_, options_, dynare_output, validation_dir, config);
        [shadow_status, shadow_error, shadow_denominator] = ...
            check_scheme_a_shadow(M_, oo_);
    else
        validation_status = export_stackelberg_validation( ...
            M_, oo_, options_, dynare_output, validation_dir);
        [shadow_status, shadow_error] = check_scheme_b_shadow(M_, oo_);
    end

    shock_index = find(strcmp(M_.exo_names, 'emp'), 1);
    shock_std = sqrt(M_.Sigma_e(shock_index, shock_index));
    approximation_order = options_.order;
    horizon = numel(oo_.irfs.r_emp);
    endo_count = M_.endo_nbr;
    equation_count = M_.eq_nbr;
    jacobian_table = readtable(fullfile(validation_dir, 'jacobian_status.csv'), ...
        'TextType', 'string');
    bk_table = readtable(fullfile(validation_dir, 'bk_status.csv'), ...
        'TextType', 'string');
    max_residual = jacobian_table.max_absolute_steady_residual(end);
    jacobian_rank = jacobian_table.jacobian_rank(end);
    jacobian_dimension = jacobian_table.jacobian_columns(end);
    unstable_roots = bk_table.unstable_roots(end);
    forward_looking = bk_table.nsfwrd(end);
    bk_status = bk_table.bk_status(end);

    if validation_status == "PASS" && shadow_status == "PASS" ...
            && abs(shock_std - 0.0025) <= 1e-14 ...
            && approximation_order == 1 && horizon == 40
        status = "PASS";
    end

    result.M_ = M_;
    result.oo_ = oo_;
    result.options_ = options_;
    result.validation_status = validation_status;
    result.shadow_status = shadow_status;
catch run_exception
    error_message = string(getReport(run_exception, 'extended', ...
        'hyperlinks', 'off'));
    if ~isfile(log_path)
        writelines(error_message, log_path);
    end
end

run_end = string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
if scheme == "B"
    solver_status = ss_b.status;
    solver_exitflag = ss_b.exitflag;
    solver_max_residual = ss_b.max_raw_residual;
    solver_jacobian_rank = ss_b.jacobian_rank;
    solver_condition_number = ss_b.scaled_condition_number;
else
    solver_status = "NOT_APPLICABLE";
    solver_exitflag = NaN;
    solver_max_residual = NaN;
    solver_jacobian_rank = NaN;
    solver_condition_number = NaN;
end
manifest = table(batch_run_id, run_id, scenario, scheme, run_start, run_end, ...
    status, string(template_path), string(model_path), ...
    get_sha256(template_path), get_sha256(model_path), ...
    design_row.gamma_g, design_row.alpha, design_row.phi_i, design_row.chi_ig, ...
    matlab_release, dynare_release, endo_count, equation_count, max_residual, ...
    jacobian_rank, jacobian_dimension, unstable_roots, forward_looking, ...
    bk_status, shock_std, approximation_order, horizon, validation_status, ...
    shadow_status, shadow_error, shadow_denominator, solver_status, ...
    solver_exitflag, solver_max_residual, solver_jacobian_rank, ...
    solver_condition_number, string(log_path), error_message, ...
    'VariableNames', {'batch_run_id', 'run_id', 'scenario_id', 'scheme', ...
    'start_time', 'end_time', 'status', 'template_path', 'generated_model_path', ...
    'template_sha256', 'generated_model_sha256', 'gamma_g', 'alpha', ...
    'phi_i', 'chi_ig', 'matlab_release', 'dynare_release', ...
    'endogenous_count', 'equation_count', 'max_steady_residual', ...
    'jacobian_rank', 'jacobian_dimension', 'unstable_roots', ...
    'forward_looking_variables', 'bk_status', 'shock_std', ...
    'approximation_order', 'horizon', 'validation_status', ...
    'shadow_target_status', 'shadow_target_max_error', ...
    'scheme_A_denominator_min', 'B_solver_status', 'B_solver_exitflag', ...
    'B_solver_max_residual', 'B_solver_jacobian_rank', ...
    'B_solver_scaled_condition_number', 'log_path', 'error_message'});
fprintf('  Scheme %s: %s (residual %.3e, BK %s)\n', ...
    scheme, status, max_residual, bk_status);
end

function [region_table, gap_table, summary_table, pair_status] = ...
        compare_pair(A, B, design_row, batch_run_id)
catalog = scheme_a_irf_catalog();
core_base = catalog.core_base;
horizon = catalog.horizon;
suffix = char(catalog.shock_suffix);
scenario = design_row.scenario_id;

names_a = string(A.M_.param_names(:));
names_b = string(B.M_.param_names(:));
[common_names, ia, ib] = intersect(names_a, names_b, 'sorted');
excluded_parameters = ["lamgbar1"; "lamgbar2"; "qgbar1"; "qgbar2"];
keep = ~ismember(common_names, excluded_parameters);
parameter_difference = B.M_.params(ib(keep)) - A.M_.params(ia(keep));
max_parameter_difference = max(abs(parameter_difference));

endo_a = string(A.M_.endo_names(:));
endo_b = string(B.M_.endo_names(:));
[common_endo, ea, eb] = intersect(endo_a, endo_b, 'sorted');
excluded_endo = ["lamg1"; "lamg2"; "qg1"; "qg2"];
keep_steady = ~ismember(common_endo, excluded_endo);
steady_difference = B.oo_.steady_state(eb(keep_steady)) ...
    - A.oo_.steady_state(ea(keep_steady));
max_steady_difference = max(abs(steady_difference));

shock_a = get_shock_std(A.M_, 'emp');
shock_b = get_shock_std(B.M_, 'emp');
horizon_a = numel(A.oo_.irfs.r_emp);
horizon_b = numel(B.oo_.irfs.r_emp);

region_table = table();
gap_table = table();
summary_table = table();
max_did_error = 0;
all_finite = true;

for variable_index = 1:numel(core_base)
    variable = core_base(variable_index);
    normalized_a = zeros(horizon, 2);
    normalized_b = zeros(horizon, 2);
    raw_a = zeros(horizon, 2);
    raw_b = zeros(horizon, 2);
    for region_index = 1:2
        name = char(variable + string(region_index));
        field = [name suffix];
        raw_a(:, region_index) = A.oo_.irfs.(field)(:);
        raw_b(:, region_index) = B.oo_.irfs.(field)(:);
        normalized_a(:, region_index) = raw_a(:, region_index) ...
            / get_steady(A.M_, A.oo_, name);
        normalized_b(:, region_index) = raw_b(:, region_index) ...
            / get_steady(B.M_, B.oo_, name);
        if region_index == 1
            scope = "low_debt";
        else
            scope = "high_debt";
        end
        this_region = common_series_columns(batch_run_id, design_row, ...
            variable, scope, horizon);
        this_region.raw_A = raw_a(:, region_index);
        this_region.raw_B = raw_b(:, region_index);
        this_region.raw_B_minus_A = raw_b(:, region_index) - raw_a(:, region_index);
        this_region.normalized_A = normalized_a(:, region_index);
        this_region.normalized_B = normalized_b(:, region_index);
        this_region.B_minus_A = normalized_b(:, region_index) ...
            - normalized_a(:, region_index);
        region_table = [region_table; this_region]; %#ok<AGROW>
        summary_table = [summary_table; summarize_series( ...
            batch_run_id, design_row, variable, scope, ...
            normalized_a(:, region_index), normalized_b(:, region_index))]; %#ok<AGROW>
    end

    gap_a = normalized_a(:, 2) - normalized_a(:, 1);
    gap_b = normalized_b(:, 2) - normalized_b(:, 1);
    gap_difference = gap_b - gap_a;
    did = (normalized_b(:, 2) - normalized_a(:, 2)) ...
        - (normalized_b(:, 1) - normalized_a(:, 1));
    did_error = gap_difference - did;
    max_did_error = max(max_did_error, max(abs(did_error)));

    this_gap = common_series_columns(batch_run_id, design_row, ...
        variable, "high_minus_low", horizon);
    this_gap.gap_A = gap_a;
    this_gap.gap_B = gap_b;
    this_gap.B_minus_A = gap_difference;
    this_gap.regional_DID = did;
    this_gap.identity_error = did_error;
    gap_table = [gap_table; this_gap]; %#ok<AGROW>
    summary_table = [summary_table; summarize_series( ...
        batch_run_id, design_row, variable, "high_minus_low", gap_a, gap_b)]; %#ok<AGROW>

    all_finite = all_finite && all(isfinite([raw_a(:); raw_b(:); ...
        normalized_a(:); normalized_b(:); gap_a; gap_b]));
end

gate_name = ["common_parameters_equal"; "common_nonshadow_steady_states_equal"; ...
    "shock_std_equal_and_registered"; "order_equal_and_registered"; ...
    "horizon_equal_and_registered"; "all_core_series_finite"; ...
    "regional_DID_identity"];
observed_value = [string(sprintf('%.17g', max_parameter_difference)); ...
    string(sprintf('%.17g', max_steady_difference)); ...
    string(sprintf('%.17g / %.17g', shock_a, shock_b)); ...
    string(sprintf('%g / %g', A.options_.order, B.options_.order)); ...
    string(sprintf('%d / %d', horizon_a, horizon_b)); string(all_finite); ...
    string(sprintf('%.17g', max_did_error))];
gate_ok = [max_parameter_difference <= 1e-14; max_steady_difference <= 1e-12; ...
    abs(shock_a - shock_b) <= 1e-14 && abs(shock_a - 0.0025) <= 1e-14; ...
    A.options_.order == 1 && B.options_.order == 1; ...
    horizon_a == horizon && horizon_b == horizon; all_finite; ...
    max_did_error <= 1e-12];
status = arrayfun(@pass_fail, gate_ok, 'UniformOutput', false);
status = string(status(:));
pair_status = table(repmat(batch_run_id, numel(gate_name), 1), ...
    repmat(scenario, numel(gate_name), 1), gate_name, observed_value, ...
    status, 'VariableNames', {'batch_run_id', 'scenario_id', ...
    'check_name', 'observed_value', 'status'});
overall = table(batch_run_id, scenario, "overall", string(all(gate_ok)), ...
    pass_fail(all(gate_ok)), 'VariableNames', pair_status.Properties.VariableNames);
pair_status = [pair_status; overall];
end

function output = common_series_columns(batch_run_id, design_row, ...
        variable, scope, horizon)
output = table(repmat(batch_run_id, horizon, 1), ...
    repmat(design_row.scenario_id, horizon, 1), ...
    repmat(design_row.varied_parameter, horizon, 1), ...
    repmat(design_row.level, horizon, 1), ...
    repmat(design_row.gamma_g, horizon, 1), ...
    repmat(design_row.alpha, horizon, 1), ...
    repmat(design_row.phi_i, horizon, 1), ...
    repmat(design_row.chi_ig, horizon, 1), (1:horizon)', ...
    repmat(variable, horizon, 1), repmat(scope, horizon, 1), ...
    'VariableNames', {'batch_run_id', 'scenario_id', 'varied_parameter', ...
    'level', 'gamma_g', 'alpha', 'phi_i', 'chi_ig', 'period', ...
    'variable', 'scope'});
end

function output = summarize_series(batch_run_id, design_row, variable, ...
        scope, series_a, series_b)
window = 1:12;
sum_a = sum(series_a(window));
sum_b = sum(series_b(window));
sum_difference = sum_b - sum_a;
absolute_path_sum_a = sum(abs(series_a(window)));
cancellation_index = abs(sum_a) / max(absolute_path_sum_a, realmin);
if abs(sum_a) > 1e-14 && cancellation_index >= 0.10
    Rcum = abs(sum_difference) / abs(sum_a);
    cumulative_denominator_status = "OK";
else
    Rcum = NaN;
    cumulative_denominator_status = "CANCELLATION_OR_NEAR_ZERO";
end
norm_a = norm(series_a, 2);
if norm_a > 1e-14
    Rpath = norm(series_b - series_a, 2) / norm_a;
else
    Rpath = NaN;
end
if isfinite(Rcum)
    effective_ratio = max(Rcum, Rpath);
else
    effective_ratio = Rpath;
end
if effective_ratio < 0.05
    materiality = "SMALL";
elseif effective_ratio < 0.10
    materiality = "BORDERLINE";
else
    materiality = "MATERIAL";
end
sign_preserved = same_sign(sum_a, sum_b, 1e-12);
[~, peak_a_period] = max(abs(series_a));
[~, peak_b_period] = max(abs(series_b));
[~, peak_difference_period] = max(abs(series_b - series_a));
output = table(batch_run_id, design_row.scenario_id, ...
    design_row.varied_parameter, design_row.level, design_row.gamma_g, ...
    design_row.alpha, design_row.phi_i, design_row.chi_ig, variable, scope, ...
    1, 12, sum_a, sum_b, sum_difference, cancellation_index, Rcum, Rpath, ...
    effective_ratio, cumulative_denominator_status, materiality, ...
    sign_preserved, series_a(peak_a_period), peak_a_period, ...
    series_b(peak_b_period), peak_b_period, ...
    (series_b(peak_difference_period) - series_a(peak_difference_period)), ...
    peak_difference_period, ...
    'VariableNames', {'batch_run_id', 'scenario_id', 'varied_parameter', ...
    'level', 'gamma_g', 'alpha', 'phi_i', 'chi_ig', 'variable', 'scope', ...
    'window_start', 'window_end', 'cumulative_A', 'cumulative_B', ...
    'cumulative_B_minus_A', 'cancellation_index', 'Rcum', 'Rpath', ...
    'effective_ratio', 'cumulative_denominator_status', 'materiality', ...
    'sign_preserved_within_pair', 'A_signed_absolute_peak', 'A_peak_period', ...
    'B_signed_absolute_peak', 'B_peak_period', ...
    'B_minus_A_signed_absolute_peak', 'B_minus_A_peak_period'});
end

function summary = attach_baseline_sign_checks(summary)
summary.baseline_A_sign_preserved = false(height(summary), 1);
summary.baseline_B_sign_preserved = false(height(summary), 1);
summary.high_low_ordering_preserved = true(height(summary), 1);
for idx = 1:height(summary)
    baseline = summary.scenario_id == "baseline" ...
        & summary.variable == summary.variable(idx) ...
        & summary.scope == summary.scope(idx);
    if sum(baseline) ~= 1
        error('Expected one baseline summary for %s / %s.', ...
            summary.variable(idx), summary.scope(idx));
    end
    base_a = summary.cumulative_A(baseline);
    base_b = summary.cumulative_B(baseline);
    summary.baseline_A_sign_preserved(idx) = same_sign( ...
        summary.cumulative_A(idx), base_a, 1e-12);
    summary.baseline_B_sign_preserved(idx) = same_sign( ...
        summary.cumulative_B(idx), base_b, 1e-12);
    if summary.scope(idx) == "high_minus_low"
        summary.high_low_ordering_preserved(idx) = ...
            summary.sign_preserved_within_pair(idx) ...
            && summary.baseline_A_sign_preserved(idx) ...
            && summary.baseline_B_sign_preserved(idx);
    end
end
end

function scenario_summary = build_scenario_summary(summary, design)
if isempty(summary)
    scenario_summary = table();
    return;
end
scenario_id = design.scenario_id;
varied_parameter = design.varied_parameter;
level = design.level;
gamma_g = design.gamma_g;
alpha = design.alpha;
phi_i = design.phi_i;
chi_ig = design.chi_ig;
max_effective_ratio = zeros(height(design), 1);
binding_variable = strings(height(design), 1);
binding_scope = strings(height(design), 1);
scenario_classification = strings(height(design), 1);
for idx = 1:height(design)
    selected = summary.scenario_id == scenario_id(idx);
    if ~any(selected)
        max_effective_ratio(idx) = NaN;
        scenario_classification(idx) = "MISSING";
        continue;
    end
    rows = find(selected);
    [max_effective_ratio(idx), local_index] = max(summary.effective_ratio(selected));
    binding = rows(local_index);
    binding_variable(idx) = summary.variable(binding);
    binding_scope(idx) = summary.scope(binding);
    if max_effective_ratio(idx) < 0.05
        scenario_classification(idx) = "SMALL";
    elseif max_effective_ratio(idx) < 0.10
        scenario_classification(idx) = "BORDERLINE";
    else
        scenario_classification(idx) = "MATERIAL";
    end
end
scenario_summary = table(scenario_id, varied_parameter, level, gamma_g, ...
    alpha, phi_i, chi_ig, max_effective_ratio, binding_variable, ...
    binding_scope, scenario_classification);
end

function output = multiplier_result_table(batch_run_id, scenario, result)
u = result.solution;
output = table(batch_run_id, scenario, result.phi_i, result.gamma_g, ...
    result.chi_ig, result.alpha, u(1), u(2), u(3), u(4), u(5), u(6), ...
    result.exitflag, result.iterations, result.function_count, ...
    result.max_raw_residual, result.jacobian_rank, ...
    result.jacobian_dimension, result.raw_condition_number, ...
    result.scaled_condition_number, result.muI_identity_error, ...
    result.private_steady_N, result.private_steady_W, result.status, ...
    'VariableNames', {'batch_run_id', 'scenario_id', 'phi_i', 'gamma_g', ...
    'chi_ig', 'alpha', 'LambdaG', 'QG', 'muR', 'muK', ...
    'muQ', 'muI', 'exitflag', 'iterations', 'function_count', ...
    'max_raw_residual', 'jacobian_rank', 'jacobian_dimension', ...
    'raw_condition_number', 'scaled_condition_number', ...
    'muI_identity_error', 'private_steady_N', 'private_steady_W', 'status'});
end

function [status, max_error, denominator] = check_scheme_a_shadow(M_, oo_)
beta_g = get_parameter(M_, 'beta_g');
gamma_g = get_parameter(M_, 'gamma_g');
omega_x = get_parameter(M_, 'omega_x');
delta_g = get_parameter(M_, 'delta_g');
theta_T = get_parameter(M_, 'theta_T');
tau_x = get_parameter(M_, 'tau_x');
errors = zeros(2, 1);
denominators = zeros(2, 1);
for region = 1:2
    xloc = get_steady(M_, oo_, sprintf('xloc%d', region));
    kg = get_steady(M_, oo_, sprintf('kg%d', region));
    lamg = get_steady(M_, oo_, sprintf('lamg%d', region));
    qg = get_steady(M_, oo_, sprintf('qg%d', region));
    denominators(region) = 1 - beta_g * (1 - delta_g) ...
        - beta_g * gamma_g * (1 - theta_T) * tau_x * xloc / kg;
    analytic = beta_g * gamma_g * omega_x / kg / denominators(region);
    euler = qg - beta_g * ((1 - delta_g) * qg ...
        + gamma_g / kg * (omega_x + lamg * (1 - theta_T) * tau_x * xloc));
    errors(region) = max(abs([lamg - analytic, qg - analytic, euler]));
end
max_error = max(errors);
denominator = min(denominators);
status = pass_fail(denominator > 0 && max_error < 1e-12);
end

function [status, max_error] = check_scheme_b_shadow(M_, oo_)
variable = ["lamg1"; "qg1"; "muR_1"; ...
    "muK_1"; "muQ_1"; "muI_1"; "lamg2"; "qg2"; "muR_2"; ...
    "muK_2"; "muQ_2"; "muI_2"];
parameter = ["lamgbar1"; "qgbar1"; "murbar1"; ...
    "mukbar1"; "muqbar1"; "muibar1"; ...
    "lamgbar2"; "qgbar2"; "murbar2"; ...
    "mukbar2"; "muqbar2"; "muibar2"];
errors = zeros(numel(variable), 1);
for idx = 1:numel(variable)
    errors(idx) = get_steady_allow_zero(M_, oo_, char(variable(idx))) ...
        - get_parameter(M_, char(parameter(idx)));
end
max_error = max(abs(errors));
status = pass_fail(max_error < 1e-12);
end

function value = get_steady_allow_zero(M_, oo_, name)
index = find(strcmp(M_.endo_names, name), 1);
if isempty(index)
    error('Endogenous variable not found: %s', name);
end
value = oo_.steady_state(index);
if ~isfinite(value)
    error('Finite steady state required for %s.', name);
end
end

function value = get_parameter(M_, name)
index = find(strcmp(M_.param_names, name), 1);
if isempty(index)
    error('Parameter not found: %s', name);
end
value = M_.params(index);
end

function value = get_steady(M_, oo_, name)
index = find(strcmp(M_.endo_names, name), 1);
if isempty(index)
    error('Endogenous variable not found: %s', name);
end
value = oo_.steady_state(index);
if ~isfinite(value) || abs(value) <= 1e-14
    error('Finite nonzero steady state required for %s.', name);
end
end

function value = get_shock_std(M_, shock_name)
index = find(strcmp(M_.exo_names, shock_name), 1);
if isempty(index)
    error('Shock not found: %s', shock_name);
end
value = sqrt(M_.Sigma_e(index, index));
end

function tf = same_sign(a, b, tolerance)
if abs(a) <= tolerance && abs(b) <= tolerance
    tf = true;
elseif abs(a) <= tolerance || abs(b) <= tolerance
    tf = false;
else
    tf = sign(a) == sign(b);
end
end

function status = decision_status(decision)
if decision == "FREEZE_A_AS_MAIN_BASELINE"
    status = "PASS";
elseif startsWith(decision, "INCONCLUSIVE")
    status = "INCONCLUSIVE";
else
    status = "REVIEW";
end
end

function ensure_directory(path)
if ~isfolder(path)
    mkdir(path);
end
end

function write_text_file(path, content)
file_id = fopen(path, 'w', 'n', 'UTF-8');
if file_id < 0
    error('Unable to open file for writing: %s', path);
end
cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
count = fwrite(file_id, content, 'char');
if count ~= strlength(string(content))
    error('Incomplete write for %s.', path);
end
end

function sha256 = get_sha256(file_path)
escaped_path = strrep(file_path, '"', '""');
command = sprintf('certutil -hashfile "%s" SHA256', escaped_path);
[status, output] = system(command);
if status ~= 0
    error('Unable to compute SHA-256 for %s.', file_path);
end
hash_match = regexp(output, '[0-9A-Fa-f]{64}', 'match', 'once');
if isempty(hash_match)
    error('SHA-256 output could not be parsed for %s.', file_path);
end
sha256 = lower(string(hash_match));
end

function label = pass_fail(condition)
if condition
    label = "PASS";
else
    label = "FAIL";
end
end
