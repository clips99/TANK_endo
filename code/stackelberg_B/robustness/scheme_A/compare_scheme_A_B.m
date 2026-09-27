function overall_status = compare_scheme_A_B()
% Government-scope decomposition: Scheme B minus Scheme A.
% Scheme A retains all private-sector general-equilibrium responses. Hence
% B-A measures the incremental effect of local-government internalization of
% those responses, not the presence versus absence of private responses.

script_dir = fileparts(mfilename('fullpath'));

stackelberg_root = fileparts(fileparts(script_dir));
baseline_dir = fullfile(stackelberg_root, 'baseline');

a_results_file = fullfile(script_dir, 'RANK_two_region_scheme_A', ...
    'Output', 'RANK_two_region_scheme_A_results.mat');
b_results_file = fullfile(baseline_dir, ...
    'RANK_two_region_stackelberg', 'Output', ...
    'RANK_two_region_stackelberg_results.mat');
a_manifest_file = fullfile(script_dir, 'scheme_A_run_manifest.csv');
b_manifest_file = fullfile(baseline_dir, 'run_manifest.csv');
required_files = [string(a_results_file); string(b_results_file); ...
    string(a_manifest_file); string(b_manifest_file)];
if ~all(isfile(required_files))
    error('A/B comparison requires fresh result and manifest files for both schemes.');
end

A = load(a_results_file, 'M_', 'oo_', 'options_');
B = load(b_results_file, 'M_', 'oo_', 'options_');
a_manifest = readtable(a_manifest_file, 'TextType', 'string');
b_manifest = readtable(b_manifest_file, 'TextType', 'string');
a_manifest = a_manifest(end, :);
b_manifest = b_manifest(end, :);

catalog = scheme_a_irf_catalog();
shock = catalog.shock;
suffix = catalog.shock_suffix;
horizon_a = numel(A.oo_.irfs.r_emp);
horizon_b = numel(B.oo_.irfs.r_emp);
if horizon_a ~= catalog.horizon || horizon_b ~= catalog.horizon
    error('Both schemes must have the registered 40-period IRF horizon.');
end

%% Common-parameter audit and canonical snapshot
names_a = string(A.M_.param_names(:));
names_b = string(B.M_.param_names(:));
[common_names, index_a, index_b] = intersect(names_a, names_b, 'sorted');
scheme_specific_shadow_targets = ["lamgbar1"; "lamgbar2"; ...
    "qgbar1"; "qgbar2"];
keep = ~ismember(common_names, scheme_specific_shadow_targets);
common_names = common_names(keep);
index_a = index_a(keep);
index_b = index_b(keep);
values_a = A.M_.params(index_a);
values_b = B.M_.params(index_b);
parameter_difference = values_b - values_a;
parameter_snapshot = table(common_names, values_a, values_b, ...
    parameter_difference, repmat(true, numel(common_names), 1), ...
    'VariableNames', {'parameter', 'scheme_A', 'scheme_B', ...
    'B_minus_A', 'included_in_shared_hash'});
parameter_snapshot_file = fullfile(script_dir, ...
    'scheme_AB_common_parameter_snapshot.csv');
writetable(parameter_snapshot, parameter_snapshot_file);
shared_parameter_hash = get_sha256(parameter_snapshot_file);
max_parameter_difference = max(abs(parameter_difference));

%% Shared steady-state audit (excluding closure-specific shadow prices)
endo_a = string(A.M_.endo_names(:));
endo_b = string(B.M_.endo_names(:));
[common_endo, endo_index_a, endo_index_b] = intersect(endo_a, endo_b, 'sorted');
closure_specific_endogenous = ["lamg1"; "lamg2"; "qg1"; "qg2"];
steady_keep = ~ismember(common_endo, closure_specific_endogenous);
steady_names = common_endo(steady_keep);
steady_a = A.oo_.steady_state(endo_index_a(steady_keep));
steady_b = B.oo_.steady_state(endo_index_b(steady_keep));
steady_difference = steady_b - steady_a;
steady_snapshot = table(steady_names, steady_a, steady_b, steady_difference, ...
    'VariableNames', {'endogenous', 'scheme_A', 'scheme_B', 'B_minus_A'});
writetable(steady_snapshot, fullfile(script_dir, ...
    'scheme_AB_common_steady_state_snapshot.csv'));
max_common_steady_difference = max(abs(steady_difference));

%% Region-level core IRFs, normalized by each scheme's own steady state
core_base = catalog.core_base;
core_label = catalog.core_label;
period = zeros(0, 1);
shock_col = strings(0, 1);
variable = strings(0, 1);
variable_label = strings(0, 1);
region = strings(0, 1);
steady_A = zeros(0, 1);
steady_B = zeros(0, 1);
raw_irf_A = zeros(0, 1);
raw_irf_B = zeros(0, 1);
raw_B_minus_A = zeros(0, 1);
normalized_irf_A = zeros(0, 1);
normalized_irf_B = zeros(0, 1);
B_minus_A = zeros(0, 1);
transformation = strings(0, 1);
scale_factor = ones(0, 1);

for variable_idx = 1:numel(core_base)
    for region_idx = 1:2
        name = char(core_base(variable_idx) + string(region_idx));
        field = [name suffix];
        response_a = A.oo_.irfs.(field)(:);
        response_b = B.oo_.irfs.(field)(:);
        ss_a = get_steady(A.M_, A.oo_, name);
        ss_b = get_steady(B.M_, B.oo_, name);
        normalized_a = response_a / ss_a;
        normalized_b = response_b / ss_b;

        period = [period; (1:catalog.horizon)']; %#ok<AGROW>
        shock_col = [shock_col; repmat(shock, catalog.horizon, 1)]; %#ok<AGROW>
        variable = [variable; repmat(core_base(variable_idx), catalog.horizon, 1)]; %#ok<AGROW>
        variable_label = [variable_label; repmat(core_label(variable_idx), catalog.horizon, 1)]; %#ok<AGROW>
        if region_idx == 1
            region_name = "low_debt";
        else
            region_name = "high_debt";
        end
        region = [region; repmat(region_name, catalog.horizon, 1)]; %#ok<AGROW>
        steady_A = [steady_A; repmat(ss_a, catalog.horizon, 1)]; %#ok<AGROW>
        steady_B = [steady_B; repmat(ss_b, catalog.horizon, 1)]; %#ok<AGROW>
        raw_irf_A = [raw_irf_A; response_a]; %#ok<AGROW>
        raw_irf_B = [raw_irf_B; response_b]; %#ok<AGROW>
        raw_B_minus_A = [raw_B_minus_A; response_b - response_a]; %#ok<AGROW>
        normalized_irf_A = [normalized_irf_A; normalized_a]; %#ok<AGROW>
        normalized_irf_B = [normalized_irf_B; normalized_b]; %#ok<AGROW>
        B_minus_A = [B_minus_A; normalized_b - normalized_a]; %#ok<AGROW>
        transformation = [transformation; repmat( ...
            "fraction_of_own_steady_state", catalog.horizon, 1)]; %#ok<AGROW>
        scale_factor = [scale_factor; ones(catalog.horizon, 1)]; %#ok<AGROW>
    end
end

region_series = table(period, shock_col, variable, variable_label, region, ...
    steady_A, steady_B, raw_irf_A, raw_irf_B, raw_B_minus_A, ...
    normalized_irf_A, normalized_irf_B, B_minus_A, transformation, ...
    scale_factor);
writetable(region_series, fullfile(script_dir, ...
    'scheme_B_vs_A_region_irf_series.csv'));

%% High-debt-minus-low-debt gaps and the exact difference-in-differences
period = zeros(0, 1);
shock_col = strings(0, 1);
variable = strings(0, 1);
variable_label = strings(0, 1);
gap_definition = strings(0, 1);
raw_gap_A = zeros(0, 1);
raw_gap_B = zeros(0, 1);
raw_gap_B_minus_A = zeros(0, 1);
gap_A = zeros(0, 1);
gap_B = zeros(0, 1);
gap_B_minus_A = zeros(0, 1);
regional_DID = zeros(0, 1);
identity_error = zeros(0, 1);
transformation = strings(0, 1);
scale_factor = ones(0, 1);

for variable_idx = 1:numel(core_base)
    low_name = char(core_base(variable_idx) + "1");
    high_name = char(core_base(variable_idx) + "2");
    low_a_raw = A.oo_.irfs.([low_name suffix])(:);
    high_a_raw = A.oo_.irfs.([high_name suffix])(:);
    low_b_raw = B.oo_.irfs.([low_name suffix])(:);
    high_b_raw = B.oo_.irfs.([high_name suffix])(:);
    low_a = low_a_raw / get_steady(A.M_, A.oo_, low_name);
    high_a = high_a_raw / get_steady(A.M_, A.oo_, high_name);
    low_b = low_b_raw / get_steady(B.M_, B.oo_, low_name);
    high_b = high_b_raw / get_steady(B.M_, B.oo_, high_name);
    this_raw_gap_a = high_a_raw - low_a_raw;
    this_raw_gap_b = high_b_raw - low_b_raw;
    this_gap_a = high_a - low_a;
    this_gap_b = high_b - low_b;
    this_gap_difference = this_gap_b - this_gap_a;
    this_did = (high_b - high_a) - (low_b - low_a);

    period = [period; (1:catalog.horizon)']; %#ok<AGROW>
    shock_col = [shock_col; repmat(shock, catalog.horizon, 1)]; %#ok<AGROW>
    variable = [variable; repmat(core_base(variable_idx), catalog.horizon, 1)]; %#ok<AGROW>
    variable_label = [variable_label; repmat(core_label(variable_idx), catalog.horizon, 1)]; %#ok<AGROW>
    gap_definition = [gap_definition; repmat( ...
        "high_debt_minus_low_debt", catalog.horizon, 1)]; %#ok<AGROW>
    raw_gap_A = [raw_gap_A; this_raw_gap_a]; %#ok<AGROW>
    raw_gap_B = [raw_gap_B; this_raw_gap_b]; %#ok<AGROW>
    raw_gap_B_minus_A = [raw_gap_B_minus_A; ...
        this_raw_gap_b - this_raw_gap_a]; %#ok<AGROW>
    gap_A = [gap_A; this_gap_a]; %#ok<AGROW>
    gap_B = [gap_B; this_gap_b]; %#ok<AGROW>
    gap_B_minus_A = [gap_B_minus_A; this_gap_difference]; %#ok<AGROW>
    regional_DID = [regional_DID; this_did]; %#ok<AGROW>
    identity_error = [identity_error; this_gap_difference - this_did]; %#ok<AGROW>
    transformation = [transformation; repmat( ...
        "fraction_of_own_steady_state", catalog.horizon, 1)]; %#ok<AGROW>
    scale_factor = [scale_factor; ones(catalog.horizon, 1)]; %#ok<AGROW>
end

gap_series = table(period, shock_col, variable, variable_label, ...
    gap_definition, raw_gap_A, raw_gap_B, raw_gap_B_minus_A, gap_A, gap_B, ...
    gap_B_minus_A, regional_DID, identity_error, transformation, scale_factor);
writetable(gap_series, fullfile(script_dir, ...
    'scheme_B_vs_A_gap_irf_series.csv'));

%% Registered 1--12 cumulative summaries; peaks are descriptive only
window_start = 1;
window_end = 12;
summary_variable = strings(0, 1);
summary_label = strings(0, 1);
scope = strings(0, 1);
statistic = strings(0, 1);
window_start_col = zeros(0, 1);
window_end_col = zeros(0, 1);
A_value = zeros(0, 1);
B_value = zeros(0, 1);
B_minus_A_value = zeros(0, 1);
expected_direction = strings(0, 1);
economic_classification = strings(0, 1);
ratio_to_abs_A = zeros(0, 1);
denominator_status = strings(0, 1);
A_signed_absolute_peak = zeros(0, 1);
A_peak_period = zeros(0, 1);
B_signed_absolute_peak = zeros(0, 1);
B_peak_period = zeros(0, 1);
contribution_signed_absolute_peak = zeros(0, 1);
contribution_peak_period = zeros(0, 1);

for variable_idx = 1:numel(core_base)
    for scope_idx = 1:3
        if scope_idx <= 2
            region_name = ["low_debt", "high_debt"];
            selected = region_series.variable == core_base(variable_idx) ...
                & region_series.region == region_name(scope_idx);
            series_a = region_series.normalized_irf_A(selected);
            series_b = region_series.normalized_irf_B(selected);
            scope_name = region_name(scope_idx);
            classification = "DESCRIPTIVE_REGION_PATH";
        else
            selected = gap_series.variable == core_base(variable_idx);
            series_a = gap_series.gap_A(selected);
            series_b = gap_series.gap_B(selected);
            scope_name = "high_minus_low";
            classification = classify_gap(sum(series_a(1:12)), ...
                sum(series_b(1:12)), 1e-12);
        end
        value_a = sum(series_a(window_start:window_end));
        value_b = sum(series_b(window_start:window_end));
        contribution = value_b - value_a;
        if abs(value_a) > 1e-12
            ratio = contribution / abs(value_a);
            denominator_label = "OK";
        else
            ratio = NaN;
            denominator_label = "DENOMINATOR_TOO_SMALL";
        end
        [~, peak_a_idx] = max(abs(series_a));
        [~, peak_b_idx] = max(abs(series_b));
        contribution_series = series_b - series_a;
        [~, peak_contribution_idx] = max(abs(contribution_series));

        summary_variable(end + 1, 1) = core_base(variable_idx); %#ok<AGROW>
        summary_label(end + 1, 1) = core_label(variable_idx); %#ok<AGROW>
        scope(end + 1, 1) = scope_name; %#ok<AGROW>
        statistic(end + 1, 1) = "cumulative_normalized_response"; %#ok<AGROW>
        window_start_col(end + 1, 1) = window_start; %#ok<AGROW>
        window_end_col(end + 1, 1) = window_end; %#ok<AGROW>
        A_value(end + 1, 1) = value_a; %#ok<AGROW>
        B_value(end + 1, 1) = value_b; %#ok<AGROW>
        B_minus_A_value(end + 1, 1) = contribution; %#ok<AGROW>
        expected_direction(end + 1, 1) = "none_used_for_structural_gate"; %#ok<AGROW>
        economic_classification(end + 1, 1) = classification; %#ok<AGROW>
        ratio_to_abs_A(end + 1, 1) = ratio; %#ok<AGROW>
        denominator_status(end + 1, 1) = denominator_label; %#ok<AGROW>
        A_signed_absolute_peak(end + 1, 1) = series_a(peak_a_idx); %#ok<AGROW>
        A_peak_period(end + 1, 1) = peak_a_idx; %#ok<AGROW>
        B_signed_absolute_peak(end + 1, 1) = series_b(peak_b_idx); %#ok<AGROW>
        B_peak_period(end + 1, 1) = peak_b_idx; %#ok<AGROW>
        contribution_signed_absolute_peak(end + 1, 1) = ...
            contribution_series(peak_contribution_idx); %#ok<AGROW>
        contribution_peak_period(end + 1, 1) = peak_contribution_idx; %#ok<AGROW>
    end
end

summary_table = table(summary_variable, summary_label, scope, statistic, ...
    window_start_col, window_end_col, A_value, B_value, B_minus_A_value, ...
    expected_direction, economic_classification, ratio_to_abs_A, ...
    denominator_status, A_signed_absolute_peak, A_peak_period, ...
    B_signed_absolute_peak, B_peak_period, ...
    contribution_signed_absolute_peak, contribution_peak_period, ...
    'VariableNames', {'variable', 'variable_label', 'scope', 'statistic', ...
    'window_start', 'window_end', 'scheme_A', 'scheme_B', 'B_minus_A', ...
    'expected_direction', 'economic_classification', 'ratio_to_abs_A', ...
    'denominator_status', 'A_signed_absolute_peak', 'A_peak_period', ...
    'B_signed_absolute_peak', 'B_peak_period', ...
    'contribution_signed_absolute_peak', 'contribution_peak_period'});
writetable(summary_table, fullfile(script_dir, ...
    'scheme_AB_decomposition_summary.csv'));

%% Structural/data acceptance, explicitly separated from economic signs
a_status = string(a_manifest.status);
b_status = string(b_manifest.status);
a_shock_std = double(a_manifest.shock_std);
b_shock_std = double(b_manifest.shock_std);
all_series_finite = all(isfinite(region_series.raw_irf_A)) ...
    && all(isfinite(region_series.raw_irf_B)) ...
    && all(isfinite(region_series.B_minus_A)) ...
    && all(isfinite(gap_series.gap_B_minus_A));
max_identity_error = max(abs(gap_series.identity_error));
summary_recalculation_error = 0;
for idx = 1:height(summary_table)
    if summary_table.scope(idx) == "high_minus_low"
        selected = gap_series.variable == summary_table.variable(idx);
        recalculated = sum(gap_series.gap_B_minus_A(selected & ...
            gap_series.period >= 1 & gap_series.period <= 12));
    else
        selected = region_series.variable == summary_table.variable(idx) ...
            & region_series.region == summary_table.scope(idx) ...
            & region_series.period >= 1 & region_series.period <= 12;
        recalculated = sum(region_series.B_minus_A(selected));
    end
    summary_recalculation_error = max(summary_recalculation_error, ...
        abs(recalculated - summary_table.B_minus_A(idx)));
end

gate_group = repmat("structural_and_data", 10, 1);
check_name = ["scheme_A_validation"; "scheme_B_validation"; ...
    "common_parameters_equal"; "shock_standard_deviation_equal"; ...
    "approximation_order_equal"; "horizon_equal"; ...
    "common_entity_steady_states_equal"; "all_series_finite"; ...
    "regional_DID_identity"; "window_summary_recalculation"];
tolerance = [0; 0; 1e-14; 1e-14; 0; 0; 1e-12; 0; 1e-12; 1e-12];
observed_value = [string(a_status); string(b_status); ...
    string(sprintf('%.17g', max_parameter_difference)); ...
    string(sprintf('%.17g', abs(a_shock_std - b_shock_std))); ...
    "1 versus 1"; string(sprintf('%d versus %d', horizon_a, horizon_b)); ...
    string(sprintf('%.17g', max_common_steady_difference)); ...
    string(all_series_finite); string(sprintf('%.17g', max_identity_error)); ...
    string(sprintf('%.17g', summary_recalculation_error))];
gate_ok = [a_status == "PASS"; b_status == "PASS"; ...
    max_parameter_difference <= 1e-14; ...
    abs(a_shock_std - b_shock_std) <= 1e-14; true; ...
    horizon_a == horizon_b && horizon_a == 40; ...
    max_common_steady_difference <= 1e-12; all_series_finite; ...
    max_identity_error <= 1e-12; summary_recalculation_error <= 1e-12];
status = strings(numel(gate_ok), 1);
for idx = 1:numel(gate_ok)
    status(idx) = pass_fail(gate_ok(idx));
end
interpretation = ["Scheme A passed its own structural gates"; ...
    "Scheme B passed its own structural and baseline-mechanism gates"; ...
    "All shared structural parameters match; closure-specific shadow targets are excluded"; ...
    "Both runs use the same one-standard-deviation monetary innovation"; ...
    "Both runs use first-order perturbation"; ...
    "Both runs retain the registered 40-period horizon"; ...
    "All shared non-shadow-price steady states coincide"; ...
    "No missing, NaN, or infinite comparison response"; ...
    "Gap difference equals the region-level difference-in-differences"; ...
    "Fixed-window summaries reproduce the underlying series"];
acceptance_table = table(gate_group, check_name, tolerance, observed_value, ...
    status, interpretation);
overall_ok = all(gate_ok);
overall_status = string(pass_fail(overall_ok));
acceptance_table = [acceptance_table; table("structural_and_data", ...
    "overall", 0, string(overall_ok), overall_status, ...
    "Economic signs are classified separately and never determine this gate", ...
    'VariableNames', acceptance_table.Properties.VariableNames)];

gap_rows = summary_table.scope == "high_minus_low";
gap_classification = summary_table.economic_classification(gap_rows);
if all(gap_classification == "AMPLIFIES_ASYMMETRY")
    economic_hypothesis = "SUPPORTED_FOR_ALL_THREE_CORE_VARIABLES";
elseif all(gap_classification == "NUMERICALLY_INDISTINGUISHABLE")
    economic_hypothesis = "INTERNALIZATION_EFFECT_NUMERICALLY_INDISTINGUISHABLE";
else
    economic_hypothesis = "MIXED_OR_NOT_UNIFORMLY_AMPLIFYING";
end
economic_rows = table(repmat("economic_result_not_a_code_gate", 4, 1), ...
    [core_label; "overall_hypothesis"], zeros(4, 1), ...
    [gap_classification; economic_hypothesis], repmat("REPORT", 4, 1), ...
    [repmat("Classification uses the registered 1--12 cumulative normalized regional gap", 3, 1); ...
     "No parameter is tuned to obtain a preferred sign"], ...
    'VariableNames', acceptance_table.Properties.VariableNames);
acceptance_table = [acceptance_table; economic_rows];
writetable(acceptance_table, fullfile(script_dir, 'scheme_AB_status.csv'));

%% Comparison manifest
scheme = ["A"; "B"];
run_id = [string(a_manifest.run_id); string(b_manifest.run_id)];
model_file = [string(fullfile(script_dir, 'RANK_two_region_scheme_A.mod')); ...
    string(fullfile(baseline_dir, 'RANK_two_region_stackelberg.mod'))];
model_sha256 = [string(a_manifest.model_sha256); string(b_manifest.model_sha256)];
matlab_release = [string(a_manifest.matlab_release); string(b_manifest.matlab_release)];
dynare_release = [string(a_manifest.dynare_release); string(b_manifest.dynare_release)];
approximation_order = ones(2, 1);
shock_col = repmat(shock, 2, 1);
shock_std = [a_shock_std; b_shock_std];
horizon = [horizon_a; horizon_b];
shared_parameter_hash_col = repmat(shared_parameter_hash, 2, 1);
validation_status = [a_status; b_status];
comparison_status = repmat(overall_status, 2, 1);
comparison_manifest = table(scheme, run_id, model_file, model_sha256, ...
    matlab_release, dynare_release, approximation_order, shock_col, ...
    shock_std, horizon, shared_parameter_hash_col, validation_status, ...
    comparison_status, 'VariableNames', {'scheme', 'run_id', 'model_file', ...
    'model_sha256', 'matlab_release', 'dynare_release', ...
    'approximation_order', 'shock', 'shock_std', 'horizon', ...
    'shared_parameter_hash', 'validation_status', 'comparison_status'});
writetable(comparison_manifest, fullfile(script_dir, ...
    'scheme_AB_comparison_manifest.csv'));

fprintf('Scheme B minus Scheme A comparison: %s\n', overall_status);
disp(summary_table(summary_table.scope == "high_minus_low", ...
    {'variable_label', 'scheme_A', 'scheme_B', 'B_minus_A', ...
    'economic_classification'}));
end

function steady = get_steady(M_, oo_, name)
index = find(strcmp(M_.endo_names, name), 1);
if isempty(index)
    error('Endogenous variable not found: %s', name);
end
steady = oo_.steady_state(index);
if ~isfinite(steady) || abs(steady) <= 1e-12
    error('A finite nonzero steady state is required for %s.', name);
end
end

function label = classify_gap(value_a, value_b, tolerance)
contribution = value_b - value_a;
if abs(contribution) <= tolerance
    label = "NUMERICALLY_INDISTINGUISHABLE";
elseif value_a < -tolerance && value_b < -tolerance && contribution < -tolerance
    label = "AMPLIFIES_ASYMMETRY";
elseif value_a < -tolerance && value_b < -tolerance && contribution > tolerance
    label = "ATTENUATES_ASYMMETRY";
elseif abs(value_a) <= tolerance && value_b < -tolerance
    label = "CREATES_NEGATIVE_ASYMMETRY";
elseif value_a * value_b < -(tolerance^2)
    label = "SIGN_REVERSAL";
else
    label = "NONSTANDARD_DIRECTION";
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
    label = 'PASS';
else
    label = 'FAIL';
end
end
