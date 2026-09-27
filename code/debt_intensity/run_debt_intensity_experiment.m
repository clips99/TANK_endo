function run_debt_intensity_experiment()
% Debt intensity experiment.
%
% Keep the low-debt region's annualized debt indicator B/(4X) fixed at 40%,
% where 4X is four times the current-quarter GDP flow (not rolling four-quarter
% GDP). Set the high-debt indicator to 40%, 80%, 120%, and 160%, and compare
% monetary-tightening IRFs across debt intensities.

script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir, fullfile(script_dir, '..', 'utils'));
original_dir = pwd;
restore_dir = onCleanup(@() cd(original_dir));
cd(script_dir);

dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

base_mod = fullfile(script_dir, '..', 'baseline', 'RANK_two_region_baseline.mod');
base_text = fileread(base_mod);

debt_ratios = [0.40 0.80 1.20 1.60];
periods = [1 4 8 12];
shock_suffix = '_emp';

status = table();
high_region_summary = table();
gap_summary = table();
irf_series = table();

for i = 1:numel(debt_ratios)
    debt_ratio = debt_ratios(i);
    scenario_name = sprintf('debt_intensity_b%03d', round(100 * debt_ratio));
    scenario_label = sprintf('B2/(4X2) = %.0f%%', 100 * debt_ratio);
    fprintf('\n=== Running %s: %s ===\n', scenario_name, scenario_label);

    scenario_text = base_text;
    scenario_text = set_parameter_line(scenario_text, 'd_ann1', 0.40);
    scenario_text = set_parameter_line(scenario_text, 'd_ann2', debt_ratio);

    scenario_mod = [scenario_name '.mod'];
    fid = fopen(fullfile(script_dir, scenario_mod), 'w');
    if fid < 0
        error('Could not write scenario file: %s', scenario_mod);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, scenario_text);
    clear cleaner;

    try
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        result_file = fullfile(script_dir, scenario_name, 'Output', [scenario_name '_results.mat']);
        loaded = load(result_file, 'oo_');

        scenario = struct('name', scenario_name, ...
            'label', scenario_label, 'debt_ratio', debt_ratio);
        high_region_summary = [high_region_summary; ...
            collect_high_region_summary(loaded.oo_, scenario, periods, shock_suffix)]; %#ok<AGROW>
        gap_summary = [gap_summary; ...
            collect_gap_summary(loaded.oo_, scenario, periods, shock_suffix)]; %#ok<AGROW>
        irf_series = [irf_series; ...
            collect_irf_series(loaded.oo_, scenario, shock_suffix)]; %#ok<AGROW>


        status = [status; table(string(scenario_name), string(scenario_label), ...
            debt_ratio, "ok", "", ...
            'VariableNames', {'scenario','label','debt_ratio','status','notes'})]; %#ok<AGROW>
    catch err
        warning('Debt intensity scenario %s failed: %s', scenario_name, err.message);
        status = [status; table(string(scenario_name), string(scenario_label), ...
            debt_ratio, "failed", string(err.message), ...
            'VariableNames', {'scenario','label','debt_ratio','status','notes'})]; %#ok<AGROW>
    end
end

writetable(status, fullfile(script_dir, 'debt_intensity_status.csv'));
writetable(high_region_summary, fullfile(script_dir, 'debt_intensity_high_region_summary.csv'));
writetable(gap_summary, fullfile(script_dir, 'debt_intensity_gap_summary.csv'));
writetable(irf_series, fullfile(script_dir, 'debt_intensity_irf_series.csv'));

fprintf('\nDebt intensity scenario status\n');
fprintf('--------------------------------\n');
disp(status);

if any(status.status == "failed")
    error('One or more debt-intensity scenarios failed; see debt_intensity_status.csv.');
end
plot_debt_intensity();
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

function summary = collect_high_region_summary(oo_, scenario, periods, shock_suffix)
    metrics = {
        'Net real debt-service burden', 'ds2';
        'Public investment',     'ig2';
        'Public capital',        'kg2';
        'Production GDP',        'xloc2';
        'Consumption',           'c2';
        'Inflation',             'pinf2'
    };

    summary = table();
    for i = 1:size(metrics, 1)
        irf = get_irf(oo_, metrics{i, 2}, shock_suffix);
        row = table(string(scenario.name), string(scenario.label), scenario.debt_ratio, ...
            string(metrics{i, 1}), string(metrics{i, 2}), ...
            irf(periods(1)), irf(periods(2)), irf(periods(3)), irf(periods(4)), ...
            'VariableNames', {'scenario','label','debt_ratio','metric','variable', ...
            't1','t4','t8','t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function summary = collect_gap_summary(oo_, scenario, periods, shock_suffix)
    pairs = {
        'Net real debt-service burden', 'ds1', 'ds2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Production GDP',        'xloc1', 'xloc2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    summary = table();
    for i = 1:size(pairs, 1)
        low_irf = get_irf(oo_, pairs{i, 2}, shock_suffix);
        high_irf = get_irf(oo_, pairs{i, 3}, shock_suffix);
        diff_irf = high_irf - low_irf;

        row = table(string(scenario.name), string(scenario.label), scenario.debt_ratio, ...
            string(pairs{i, 1}), string(pairs{i, 2}), string(pairs{i, 3}), ...
            diff_irf(periods(1)), diff_irf(periods(2)), ...
            diff_irf(periods(3)), diff_irf(periods(4)), ...
            'VariableNames', {'scenario','label','debt_ratio','metric','low_var','high_var', ...
            'diff_t1','diff_t4','diff_t8','diff_t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function series = collect_irf_series(oo_, scenario, shock_suffix)
    pairs = {
        'Net real debt-service burden', 'ds1', 'ds2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Production GDP',        'xloc1', 'xloc2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    series = table();
    for i = 1:size(pairs, 1)
        low_irf = get_irf(oo_, pairs{i, 2}, shock_suffix);
        high_irf = get_irf(oo_, pairs{i, 3}, shock_suffix);
        diff_irf = high_irf - low_irf;
        horizon = (1:numel(high_irf))';

        rows = table(repmat(string(scenario.name), numel(horizon), 1), ...
            repmat(string(scenario.label), numel(horizon), 1), ...
            repmat(scenario.debt_ratio, numel(horizon), 1), ...
            repmat(string(pairs{i, 1}), numel(horizon), 1), ...
            horizon, low_irf(:), high_irf(:), diff_irf(:), ...
            'VariableNames', {'scenario','label','debt_ratio','metric', ...
            'horizon','low_irf','high_irf','diff_irf'});
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
