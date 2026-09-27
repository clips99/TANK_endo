function export_status = export_scheme_a_irfs(M_, oo_, output_dir)
% Export auditable Scheme-A IRFs without imposing an ex-post sign gate.

if nargin < 3 || isempty(output_dir)
    output_dir = fileparts(mfilename('fullpath'));
end
if ~isfolder(output_dir)
    mkdir(output_dir);
end

catalog = scheme_a_irf_catalog();
shock = catalog.shock;
suffix = catalog.shock_suffix;
horizon = catalog.horizon;
nvar = numel(catalog.variable);

period_col = zeros(0, 1);
shock_col = strings(0, 1);
variable_col = strings(0, 1);
region_col = strings(0, 1);
steady_col = zeros(0, 1);
raw_col = zeros(0, 1);
normalized_col = zeros(0, 1);
transformation_col = strings(0, 1);
scale_factor_col = ones(0, 1);

summary_variable = strings(nvar, 1);
summary_region = strings(nvar, 1);
summary_steady = zeros(nvar, 1);
summary_impact_raw = zeros(nvar, 1);
summary_t4_raw = zeros(nvar, 1);
summary_t8_raw = zeros(nvar, 1);
summary_t12_raw = zeros(nvar, 1);
summary_cumulative_1_12_raw = zeros(nvar, 1);
summary_cumulative_1_40_raw = zeros(nvar, 1);
summary_cumulative_1_12_normalized = nan(nvar, 1);
summary_signed_peak_raw = zeros(nvar, 1);
summary_peak_period = zeros(nvar, 1);

all_fields_present = true;
all_finite = true;
for idx = 1:nvar
    name = char(catalog.variable(idx));
    field = [name suffix];
    if ~isfield(oo_.irfs, field)
        all_fields_present = false;
        error('Required Scheme-A IRF field not found: %s', field);
    end
    response = oo_.irfs.(field)(:);
    if numel(response) ~= horizon
        error('IRF %s has length %d; expected %d.', ...
            field, numel(response), horizon);
    end
    all_finite = all_finite && all(isfinite(response));
    ss_index = find(strcmp(M_.endo_names, name), 1);
    if isempty(ss_index)
        error('Steady-state index not found for %s.', name);
    end
    steady = oo_.steady_state(ss_index);
    if abs(steady) > 1e-12
        normalized = response / steady;
        transformation = "raw_and_fraction_of_own_steady_state";
    else
        normalized = nan(size(response));
        transformation = "raw_level_only_zero_steady_state";
    end

    period_col = [period_col; (1:horizon)']; %#ok<AGROW>
    shock_col = [shock_col; repmat(shock, horizon, 1)]; %#ok<AGROW>
    variable_col = [variable_col; repmat(catalog.variable(idx), horizon, 1)]; %#ok<AGROW>
    region_col = [region_col; repmat(catalog.region(idx), horizon, 1)]; %#ok<AGROW>
    steady_col = [steady_col; repmat(steady, horizon, 1)]; %#ok<AGROW>
    raw_col = [raw_col; response]; %#ok<AGROW>
    normalized_col = [normalized_col; normalized]; %#ok<AGROW>
    transformation_col = [transformation_col; repmat(transformation, horizon, 1)]; %#ok<AGROW>
    scale_factor_col = [scale_factor_col; ones(horizon, 1)]; %#ok<AGROW>

    [~, peak_index] = max(abs(response));
    summary_variable(idx) = catalog.variable(idx);
    summary_region(idx) = catalog.region(idx);
    summary_steady(idx) = steady;
    summary_impact_raw(idx) = response(1);
    summary_t4_raw(idx) = response(4);
    summary_t8_raw(idx) = response(8);
    summary_t12_raw(idx) = response(12);
    summary_cumulative_1_12_raw(idx) = sum(response(1:12));
    summary_cumulative_1_40_raw(idx) = sum(response);
    if abs(steady) > 1e-12
        summary_cumulative_1_12_normalized(idx) = sum(normalized(1:12));
    end
    summary_signed_peak_raw(idx) = response(peak_index);
    summary_peak_period(idx) = peak_index;
end

series_table = table(period_col, shock_col, variable_col, region_col, ...
    steady_col, raw_col, normalized_col, transformation_col, scale_factor_col, ...
    'VariableNames', {'period', 'shock', 'variable', 'region', ...
    'steady_state', 'raw_response', 'normalized_response', ...
    'transformation', 'scale_factor'});

summary_table = table(summary_variable, summary_region, summary_steady, ...
    summary_impact_raw, summary_t4_raw, summary_t8_raw, summary_t12_raw, ...
    summary_cumulative_1_12_raw, summary_cumulative_1_40_raw, ...
    summary_cumulative_1_12_normalized, summary_signed_peak_raw, ...
    summary_peak_period, ...
    'VariableNames', {'variable', 'region', 'steady_state', 'impact_raw', ...
    't4_raw', 't8_raw', 't12_raw', 'cumulative_1_12_raw', ...
    'cumulative_1_40_raw', 'cumulative_1_12_normalized', ...
    'signed_absolute_peak_raw', 'peak_period'});

ngap = numel(catalog.gap_name);
gap_variable = catalog.gap_name;
gap_raw_cumulative_1_12 = zeros(ngap, 1);
gap_normalized_cumulative_1_12 = zeros(ngap, 1);
gap_signed_peak_raw = zeros(ngap, 1);
gap_peak_period = zeros(ngap, 1);
for idx = 1:ngap
    low_name = char(catalog.gap_low(idx));
    high_name = char(catalog.gap_high(idx));
    low = oo_.irfs.([low_name suffix])(:);
    high = oo_.irfs.([high_name suffix])(:);
    low_ss = oo_.steady_state(find(strcmp(M_.endo_names, low_name), 1));
    high_ss = oo_.steady_state(find(strcmp(M_.endo_names, high_name), 1));
    raw_gap = high - low;
    normalized_gap = high / high_ss - low / low_ss;
    gap_rows = table((1:horizon)', repmat(shock, horizon, 1), ...
        repmat(catalog.gap_name(idx), horizon, 1), ...
        repmat("high_minus_low", horizon, 1), ...
        repmat(high_ss - low_ss, horizon, 1), raw_gap, normalized_gap, ...
        repmat("high_minus_low_fraction_of_own_steady_state", horizon, 1), ...
        ones(horizon, 1), 'VariableNames', series_table.Properties.VariableNames);
    series_table = [series_table; gap_rows]; %#ok<AGROW>
    gap_raw_cumulative_1_12(idx) = sum(raw_gap(1:12));
    gap_normalized_cumulative_1_12(idx) = sum(normalized_gap(1:12));
    [~, peak_idx] = max(abs(raw_gap));
    gap_signed_peak_raw(idx) = raw_gap(peak_idx);
    gap_peak_period(idx) = peak_idx;
end

gap_summary = table(gap_variable, gap_raw_cumulative_1_12, ...
    gap_normalized_cumulative_1_12, gap_signed_peak_raw, gap_peak_period, ...
    'VariableNames', {'variable', 'cumulative_1_12_raw', ...
    'cumulative_1_12_normalized', 'signed_absolute_peak_raw', 'peak_period'});

writetable(series_table, fullfile(output_dir, 'scheme_A_irf_series.csv'));
writetable(summary_table, fullfile(output_dir, 'scheme_A_irf_summary.csv'));
writetable(gap_summary, fullfile(output_dir, 'scheme_A_gap_irf_summary.csv'));

mp_impact = oo_.irfs.mp_emp(1);
check_name = ["all_required_fields"; "horizon_40"; ...
    "all_raw_irfs_finite"; "positive_emp_orientation"];
observed_value = [string(sprintf('%d/%d', nvar, nvar)); ...
    string(horizon); string(all_finite); string(sprintf('%.17g', mp_impact))];
criterion = ["all catalog fields present"; "40 periods"; ...
    "all finite"; "mp response on impact equals +0.0025"];
ok = [all_fields_present; horizon == 40; all_finite; abs(mp_impact - 0.0025) < 1e-12];
status = strings(numel(ok), 1);
for idx = 1:numel(ok)
    status(idx) = pass_fail(ok(idx));
end
export_status = string(pass_fail(all(ok)));
status_table = table(check_name, observed_value, criterion, status);
status_table = [status_table; table("overall", string(all(ok)), ...
    "all data-integrity gates pass", export_status, ...
    'VariableNames', status_table.Properties.VariableNames)];
writetable(status_table, fullfile(output_dir, 'scheme_A_irf_status.csv'));
end

function label = pass_fail(condition)
if condition
    label = 'PASS';
else
    label = 'FAIL';
end
end
