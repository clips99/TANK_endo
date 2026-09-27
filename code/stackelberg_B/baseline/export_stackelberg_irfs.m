function mechanism_status = export_stackelberg_irfs(M_, oo_, output_dir)
% Export the first monetary-tightening mechanism IRFs for Scheme B.

if nargin < 3 || isempty(output_dir)
    output_dir = fileparts(mfilename('fullpath'));
end
catalog = stackelberg_irf_catalog();
shock = catalog.shock;
shock_suffix = catalog.shock_suffix;
variable = catalog.variable;
region = catalog.region;

first_field = [char(variable(1)) shock_suffix];
if ~isfield(oo_.irfs, first_field)
    error('IRF field not found: %s', first_field);
end
horizon = numel(oo_.irfs.(first_field));
if horizon ~= catalog.horizon
    error('Expected IRF horizon %d, but Dynare returned %d.', ...
        catalog.horizon, horizon);
end

period_col = zeros(0, 1);
shock_col = strings(0, 1);
variable_col = strings(0, 1);
region_col = strings(0, 1);
steady_col = zeros(0, 1);
raw_col = zeros(0, 1);
relative_col = zeros(0, 1);
transformation_col = strings(0, 1);

summary_variable = strings(numel(variable), 1);
summary_region = strings(numel(variable), 1);
summary_steady = zeros(numel(variable), 1);
summary_impact = zeros(numel(variable), 1);
summary_t4 = nan(numel(variable), 1);
summary_t8 = nan(numel(variable), 1);
summary_t12 = nan(numel(variable), 1);
summary_peak = zeros(numel(variable), 1);
summary_peak_period = zeros(numel(variable), 1);
summary_cumulative = zeros(numel(variable), 1);

for idx = 1:numel(variable)
    name = char(variable(idx));
    field = [name shock_suffix];
    if ~isfield(oo_.irfs, field)
        error('Required IRF field not found: %s', field);
    end
    response = oo_.irfs.(field)(:);
    if numel(response) ~= horizon
        error('IRF %s has length %d; expected %d.', field, numel(response), horizon);
    end
    ss_index = find(strcmp(M_.endo_names, name), 1);
    if isempty(ss_index)
        error('Steady-state index not found for %s.', name);
    end
    steady = oo_.steady_state(ss_index);
    is_multiplier = startsWith(variable(idx), "mu");
    allow_relative = abs(steady) > 1e-12 && ~is_multiplier;
    if allow_relative
        relative = response / steady;
        transformation = "raw_and_relative_to_steady_state";
    else
        relative = nan(size(response));
        transformation = "raw_level_only";
    end

    period_col = [period_col; (1:horizon)']; %#ok<AGROW>
    shock_col = [shock_col; repmat(shock, horizon, 1)]; %#ok<AGROW>
    variable_col = [variable_col; repmat(variable(idx), horizon, 1)]; %#ok<AGROW>
    region_col = [region_col; repmat(region(idx), horizon, 1)]; %#ok<AGROW>
    steady_col = [steady_col; repmat(steady, horizon, 1)]; %#ok<AGROW>
    raw_col = [raw_col; response]; %#ok<AGROW>
    relative_col = [relative_col; relative]; %#ok<AGROW>
    transformation_col = [transformation_col; repmat(transformation, horizon, 1)]; %#ok<AGROW>

    [~, peak_index] = max(abs(response));
    summary_variable(idx) = variable(idx);
    summary_region(idx) = region(idx);
    summary_steady(idx) = steady;
    summary_impact(idx) = response(1);
    if horizon >= 4, summary_t4(idx) = response(4); end
    if horizon >= 8, summary_t8(idx) = response(8); end
    if horizon >= 12, summary_t12(idx) = response(12); end
    summary_peak(idx) = response(peak_index);
    summary_peak_period(idx) = peak_index;
    summary_cumulative(idx) = sum(response);
end

series_table = table(period_col, shock_col, variable_col, region_col, ...
    steady_col, raw_col, relative_col, transformation_col, ...
    'VariableNames', {'period', 'shock', 'variable', 'region', ...
    'steady_state', 'raw_response', 'relative_response', 'transformation'});

%% Add high-debt-minus-low-debt gap series to the long table
for idx = 1:numel(catalog.gap_name)
    low_name = char(catalog.gap_low(idx));
    high_name = char(catalog.gap_high(idx));
    low = oo_.irfs.([low_name shock_suffix])(:);
    high = oo_.irfs.([high_name shock_suffix])(:);
    gap = high - low;
    low_ss_index = find(strcmp(M_.endo_names, low_name), 1);
    high_ss_index = find(strcmp(M_.endo_names, high_name), 1);
    gap_steady_state = oo_.steady_state(high_ss_index) ...
        - oo_.steady_state(low_ss_index);
    gap_name = catalog.gap_name(idx);
    gap_rows = table((1:horizon)', repmat(shock, horizon, 1), ...
        repmat(gap_name, horizon, 1), repmat("high_minus_low", horizon, 1), ...
        repmat(gap_steady_state, horizon, 1), gap, nan(horizon, 1), ...
        repmat("raw_level_gap", horizon, 1), ...
        'VariableNames', series_table.Properties.VariableNames);
    series_table = [series_table; gap_rows]; %#ok<AGROW>
end
writetable(series_table, fullfile(output_dir, 'baseline_irf_series.csv'));

summary_table = table(summary_variable, summary_region, summary_steady, ...
    summary_impact, summary_t4, summary_t8, summary_t12, summary_peak, ...
    summary_peak_period, summary_cumulative, ...
    'VariableNames', {'variable', 'region', 'steady_state', 'impact', ...
    't4', 't8', 't12', 'signed_absolute_peak', 'peak_period', ...
    'cumulative_1_40'});
writetable(summary_table, fullfile(output_dir, 'baseline_irf_summary.csv'));

%% Core mechanism-direction audit
% The acceptance statistics and windows are fixed ex ante by economic timing:
% policy and inflation on impact; debt service and fiscal space over quarters
% 1--4; investment, accumulated public capital, and output over quarters 1--12.
% No max/min is selected according to the expected sign.
check_name = ["policy_rate_impact"; "aggregate_inflation_impact"; ...
    "debt_service_gap"; "fiscal_space_gap"; "public_investment_gap"; ...
    "public_capital_gap"; "local_output_gap"];
check_variable = ["r"; "pinfagg"; "ds2-ds1"; "fs2-fs1"; ...
    "ig2-ig1"; "kg2-kg1"; "xloc2-xloc1"];
expected_sign = ["positive"; repmat("negative", 6, 1)];
expected_sign(3) = "positive";
statistic = ["impact"; "impact"; "window_sum"; "window_sum"; ...
    "window_sum"; "window_sum"; "window_sum"];
window_start = ones(numel(check_name), 1);
window_end = [1; 1; 4; 4; 12; 12; 12];
threshold = repmat(1e-12, numel(check_name), 1);
audit_value = zeros(numel(check_name), 1);
signed_absolute_peak = zeros(numel(check_name), 1);
peak_period = zeros(numel(check_name), 1);

audit_series = cell(numel(check_name), 1);
audit_series{1} = oo_.irfs.r_emp(:);
audit_series{2} = oo_.irfs.pinfagg_emp(:);
audit_low = ["ds1"; "fs1"; "ig1"; "kg1"; "xloc1"];
audit_high = ["ds2"; "fs2"; "ig2"; "kg2"; "xloc2"];
for idx = 1:numel(audit_low)
    audit_series{idx + 2} = oo_.irfs.([char(audit_high(idx)) shock_suffix])(:) ...
        - oo_.irfs.([char(audit_low(idx)) shock_suffix])(:);
end
for idx = 1:numel(check_name)
    selected = audit_series{idx}(window_start(idx):window_end(idx));
    if statistic(idx) == "impact"
        audit_value(idx) = selected(1);
    else
        audit_value(idx) = sum(selected);
    end
    [~, peak_period(idx)] = max(abs(audit_series{idx}));
    signed_absolute_peak(idx) = audit_series{idx}(peak_period(idx));
end

direction_ok = (expected_sign == "positive" & audit_value > threshold) ...
    | (expected_sign == "negative" & audit_value < -threshold);
status = strings(numel(direction_ok), 1);
for idx = 1:numel(direction_ok)
    status(idx) = pass_fail(direction_ok(idx));
end
mechanism_status = string(pass_fail(all(direction_ok)));
baseline_status = table(check_name, check_variable, statistic, window_start, ...
    window_end, expected_sign, threshold, audit_value, ...
    signed_absolute_peak, peak_period, status);
baseline_status = [baseline_status; table("overall", "all", "all_pass", ...
    0, 0, "all_pass", 0, double(all(direction_ok)), NaN, 0, mechanism_status, ...
    'VariableNames', baseline_status.Properties.VariableNames)];
writetable(baseline_status, fullfile(output_dir, 'baseline_status.csv'));

fprintf('First-round monetary-tightening mechanism audit: %s\n', mechanism_status);
disp(baseline_status);
end

function label = pass_fail(condition)
if condition
    label = 'PASS';
else
    label = 'FAIL';
end
end
