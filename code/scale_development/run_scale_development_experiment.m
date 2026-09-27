function run_scale_development_experiment()
% Joint regional scale, development, and trade-balance heterogeneity experiment.
%
% The target R is the steady-state ratio of total regional GDP:
%       R = (s1*xbar1)/(s2*xbar2).
% To avoid attributing the whole experiment to a Taylor-rule weight, R is
% split symmetrically between (i) economic mass and (ii) GDP per unit of
% mass: s1/s2 = sqrt(R) and xbar1/xbar2 = sqrt(R). National steady GDP is
% normalized to one. Inflation weights are steady GDP shares (gw1, gw2),
% National GDP and final absorption use the same common-price conversion
% as the baseline; at the deterministic steady state the conversion factors
% equal one, so their targets reduce to the mass-weighted sums. Maintaining
% Ybar_j=Xbar_j and zero steady relative prices also requires a linked
% calibration of home-bias weights to preserve balanced bilateral trade.

% Region 1 is the larger/developed, low-debt region. Region 2 is the
% smaller/less-developed, high-debt region. Annual debt/GDP targets remain
% fixed at 40 and 100 percent in every scenario. The model internally uses
% quarterly-GDP denominators, hence b_xj = 4*d_annj.

% This function generates each scenario from the maintained
% baseline model. Scenario overrides are appended immediately before the
% model block, so the procedure does not depend on calibration comments or
% the exact spacing of individual baseline assignments.
%
% Cross-scenario IRFs are reported as first-order deviations relative to
% each scenario's own positive steady state: normalized_response=level_IRF/
% steady_state. A regional gap is the normalized response of region 2 minus
% that of region 1. This removes mechanical level effects from heterogeneous
% xbarj while retaining economically meaningful dynamic differences.

script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir, fullfile(script_dir, '..', 'utils'));
original_dir = pwd;
restore_dir = onCleanup(@() cd(original_dir));
cd(script_dir);

dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

base_mod = fullfile(script_dir, '..', 'baseline', ...
    'RANK_two_region_baseline.mod');
base_text = fileread(base_mod);
assert_updated_baseline(base_text);

% Experiment design.
total_gdp_ratios = [1.00 1.50 2.00];
d_ann1 = 0.40;
d_ann2 = 1.00;
baseline_home_bias = read_numeric_assignment(base_text, 'omega1');
baseline_mass = read_numeric_assignment(base_text, 's1');
baseline_unit_gdp = read_numeric_assignment(base_text, 'ybar1');
trade = baseline_mass * (1 - baseline_home_bias) * baseline_unit_gdp;
public_investment_share = 0.12;
government_consumption_share = 0.10;
periods = [1 4 8 12];
shock_suffix = '_emp';

% Primitive values needed only to construct a common-labor-disutility
% heterogeneous steady state. Reading them from the baseline prevents the
% experiment from silently drifting away from the maintained calibration.
beta = read_numeric_assignment(base_text, 'beta');
sigma = read_numeric_assignment(base_text, 'sigma');
varphi = read_numeric_assignment(base_text, 'varphi');
delta_k = read_numeric_assignment(base_text, 'delta_k');
delta_g = read_numeric_assignment(base_text, 'delta_g');
alpha = read_numeric_assignment(base_text, 'alpha');
gamma_g = read_numeric_assignment(base_text, 'gamma_g');
epsilon_p = read_numeric_assignment(base_text, 'epsilon_p');
theta_T = read_numeric_assignment(base_text, 'theta_T');
tau_x = read_numeric_assignment(base_text, 'tau_x');
omega_x = read_numeric_assignment(base_text, 'omega_x');

rbar = 1 / beta;
mcbar = (epsilon_p - 1) / epsilon_p;
rkbar = rbar - 1 + delta_k;
kg0 = public_investment_share / delta_g;
k0 = alpha * mcbar / rkbar;
n0 = (1 / (kg0^gamma_g * k0^alpha))^(1 / (1 - alpha));

status = table();
region2_summary = table();
gap_summary = table();
irf_series = table();

for i = 1:numel(total_gdp_ratios)
    total_gdp_ratio = total_gdp_ratios(i);
    scale_ratio = sqrt(total_gdp_ratio);
    development_ratio = sqrt(total_gdp_ratio);

    s1 = scale_ratio / (1 + scale_ratio);
    s2 = 1 / (1 + scale_ratio);

    % xbar1/xbar2=development_ratio and s1*xbar1+s2*xbar2=1.
    xbar2 = 1 / (s1 * development_ratio + s2);
    xbar1 = development_ratio * xbar2;
    xbar = s1 * xbar1 + s2 * xbar2;
    ybar1 = xbar1;
    ybar2 = xbar2;
    ybar = s1 * ybar1 + s2 * ybar2;

    regional_gdp1 = s1 * xbar1;
    regional_gdp2 = s2 * xbar2;
    realized_total_gdp_ratio = regional_gdp1 / regional_gdp2;
    gw1 = regional_gdp1 / xbar;
    gw2 = regional_gdp2 / xbar;

    % Preserve balanced bilateral trade and its aggregate baseline volume.
    omega1 = 1 - trade / (s1 * ybar1);
    omega2 = 1 - trade / (s2 * ybar2);
    imports1 = s1 * (1 - omega1) * ybar1;
    imports2 = s2 * (1 - omega2) * ybar2;
    if any([omega1 omega2] <= 0) || any([omega1 omega2] >= 1)
        error('R=%.3f implies invalid home-bias weights.', total_gdp_ratio);
    end

    % Scale all steady private/public quantities with local unit GDP. Choose
    % labor so the same chi_n supports both regions, then back out regional
    % productivity. The risk-sharing wedge only aligns heterogeneous steady
    % consumption levels; it does not change the log-linear dynamic slope.
    ymbar1 = (s1 * omega1 * ybar1 + s2 * (1 - omega2) * ybar2) / s1;
    ymbar2 = (s1 * (1 - omega1) * ybar1 + s2 * omega2 * ybar2) / s2;
    igbar1 = public_investment_share * xbar1;
    igbar2 = public_investment_share * xbar2;
    kgbar1 = igbar1 / delta_g;
    kgbar2 = igbar2 / delta_g;
    kbar1 = alpha * mcbar * xbar1 / rkbar;
    kbar2 = alpha * mcbar * xbar2 / rkbar;
    invbar1 = delta_k * kbar1;
    invbar2 = delta_k * kbar2;
    nbar1 = n0 * xbar1^((1 - sigma) / (1 + varphi));
    nbar2 = n0 * xbar2^((1 - sigma) / (1 + varphi));
    abar1 = xbar1 / (kgbar1^gamma_g * kbar1^alpha * nbar1^(1 - alpha));
    abar2 = xbar2 / (kgbar2^gamma_g * kbar2^alpha * nbar2^(1 - alpha));
    wbar1 = (1 - alpha) * mcbar * xbar1 / nbar1;
    wbar2 = (1 - alpha) * mcbar * xbar2 / nbar2;
    gbar1 = government_consumption_share * xbar1;
    gbar2 = government_consumption_share * xbar2;
    cbar1 = ybar1 - invbar1 - gbar1 - igbar1;
    cbar2 = ybar2 - invbar2 - gbar2 - igbar2;
    chi_n = cbar1^(-sigma) * wbar1 / nbar1^varphi;
    xi_rs = (cbar2 / cbar1)^(-sigma);

    b_x1 = 4 * d_ann1;
    b_x2 = 4 * d_ann2;
    bbar1 = b_x1 * xbar1;
    bbar2 = b_x2 * xbar2;

    % Scheme-A direct-technology public-capital FOC. This replaces the
    % retired perceived-elasticity/mbg closure and remains valid when the
    % two regions have heterogeneous steady-state scale and productivity.
    denominator1 = 1 - beta * (1 - delta_g) ...
        - beta * gamma_g * (1 - theta_T) * tau_x * xbar1 / kgbar1;
    denominator2 = 1 - beta * (1 - delta_g) ...
        - beta * gamma_g * (1 - theta_T) * tau_x * xbar2 / kgbar2;
    if denominator1 <= 0 || denominator2 <= 0
        error('Scheme-A shadow-value denominator is nonpositive for R=%.3f.', ...
            total_gdp_ratio);
    end
    lamgbar1 = beta * gamma_g * omega_x / kgbar1 / denominator1;
    lamgbar2 = beta * gamma_g * omega_x / kgbar2 / denominator2;
    qgbar1 = lamgbar1;
    qgbar2 = lamgbar2;
    dsbar1 = (rbar - 1) * bbar1 / xbar1;
    dsbar2 = (rbar - 1) * bbar2 / xbar2;
    fsbar1 = igbar1;
    fsbar2 = igbar2;
    zbar1 = fsbar1 + (rbar - 1) * bbar1 + gbar1 ...
        - (1 - theta_T) * tau_x * xbar1;
    zbar2 = fsbar2 + (rbar - 1) * bbar2 + gbar2 ...
        - (1 - theta_T) * tau_x * xbar2;

    scenario_name = sprintf('scale_development_y%03d', ...
        round(100 * total_gdp_ratio));
    scenario_label = sprintf(['R=%.1f, scale=%.3f, ' ...
        'unit GDP=%.3f'], total_gdp_ratio, scale_ratio, development_ratio);
    fprintf(['\n=== %s: total GDP ratio %.3f, scale ratio %.3f, ' ...
        'unit-GDP ratio %.3f ===\n'], scenario_name, total_gdp_ratio, ...
        scale_ratio, development_ratio);

    overrides = struct( ...
        's1', s1, 's2', s2, 'gw1', gw1, 'gw2', gw2, ...
        'omega1', omega1, 'omega2', omega2, ...
        'xbar1', xbar1, 'xbar2', xbar2, 'xbar', xbar, ...
        'ybar1', ybar1, 'ybar2', ybar2, 'ybar', ybar, ...
        'ymbar1', ymbar1, 'ymbar2', ymbar2, ...
        'd_ann1', d_ann1, 'd_ann2', d_ann2, ...
        'b_x1', b_x1, 'b_x2', b_x2, 'bbar1', bbar1, 'bbar2', bbar2, ...
        'igbar1', igbar1, 'igbar2', igbar2, ...
        'kgbar1', kgbar1, 'kgbar2', kgbar2, ...
        'kbar1', kbar1, 'kbar2', kbar2, ...
        'invbar1', invbar1, 'invbar2', invbar2, ...
        'nbar1', nbar1, 'nbar2', nbar2, ...
        'abar1', abar1, 'abar2', abar2, ...
        'wbar1', wbar1, 'wbar2', wbar2, ...
        'gbar1', gbar1, 'gbar2', gbar2, ...
        'cbar1', cbar1, 'cbar2', cbar2, ...
        'chi_n', chi_n, 'xi_rs', xi_rs, ...
        'lamgbar1', lamgbar1, 'lamgbar2', lamgbar2, ...
        'qgbar1', qgbar1, 'qgbar2', qgbar2, ...
        'dsbar1', dsbar1, 'dsbar2', dsbar2, ...
        'fsbar1', fsbar1, 'fsbar2', fsbar2, ...
        'zbar1', zbar1, 'zbar2', zbar2);
    scenario_text = insert_scenario_overrides(base_text, overrides, ...
        scenario_name, total_gdp_ratio, scale_ratio, development_ratio);

    scenario_mod = [scenario_name '.mod'];
    write_text_file(fullfile(script_dir, scenario_mod), scenario_text);

    meta = struct('name', scenario_name, 'label', scenario_label, ...
        'total_gdp_ratio', total_gdp_ratio, ...
        'scale_ratio', scale_ratio, ...
        'development_ratio', development_ratio, ...
        's1', s1, 's2', s2, 'gw1', gw1, 'gw2', gw2, ...
        'xbar1', xbar1, 'xbar2', xbar2, ...
        'omega1', omega1, 'omega2', omega2);

    try
        evalc(sprintf('dynare %s noclearall', scenario_mod));
        result_file = fullfile(script_dir, scenario_name, 'Output', ...
            [scenario_name '_results.mat']);
        loaded = load(result_file, 'oo_', 'M_');

        region2_summary = [region2_summary; collect_region2_summary( ...
            loaded.oo_, loaded.M_, meta, periods, shock_suffix)]; %#ok<AGROW>
        gap_summary = [gap_summary; collect_gap_summary( ...
            loaded.oo_, loaded.M_, meta, periods, shock_suffix)]; %#ok<AGROW>
        irf_series = [irf_series; collect_irf_series( ...
            loaded.oo_, loaded.M_, meta, shock_suffix)]; %#ok<AGROW>


        status = [status; scenario_status_row(meta, ...
            realized_total_gdp_ratio, regional_gdp1, regional_gdp2, ...
            imports1, imports2, d_ann1, d_ann2, abar1, abar2, ...
            xi_rs, "ok", "")]; %#ok<AGROW>
    catch err
        warning('Scenario %s failed: %s', scenario_name, err.message);
        status = [status; scenario_status_row(meta, ...
            realized_total_gdp_ratio, regional_gdp1, regional_gdp2, ...
            imports1, imports2, d_ann1, d_ann2, abar1, abar2, ...
            xi_rs, "failed", string(err.message))]; %#ok<AGROW>
    end
end

writetable(status, fullfile(script_dir, 'scale_development_status.csv'));
writetable(region2_summary, fullfile(script_dir, 'scale_development_region2_summary.csv'));
writetable(gap_summary, fullfile(script_dir, 'scale_development_gap_summary.csv'));
writetable(irf_series, fullfile(script_dir, 'scale_development_irf_series.csv'));

fprintf('\nScale-and-development scenario status\n');
fprintf('-------------------------------------\n');
disp(status);

if any(status.status == "failed")
    error('One or more scale-development scenarios failed; see scale_development_status.csv.');
end
plot_scale_development();
end

function assert_updated_baseline(text)
    required = {'xloc1','xloc2','xagg','gw1','gw2','xbar1','xbar2', ...
        'd_ann1','d_ann2','b_x1','b_x2','tau_x','omega_x', ...
        'abar1','abar2','xi_rs'};
    for i = 1:numel(required)
        if isempty(regexp(text, ['\<' required{i} '\>'], 'once'))
            error(['Baseline is not yet on the maintained X-GDP specification: ' ...
                'missing %s.'], required{i});
        end
    end
end

function value = read_numeric_assignment(text, name)
    pattern = ['(?m)^\s*' regexptranslate('escape', name) ...
        '\s*=\s*([-+0-9.eE]+)\s*;'];
    token = regexp(text, pattern, 'tokens', 'once');
    if isempty(token)
        error('Could not read a unique numeric baseline assignment for %s.', name);
    end
    value = str2double(token{1});
    if ~isfinite(value)
        error('Baseline assignment for %s is not finite.', name);
    end
end

function text = insert_scenario_overrides(text, values, scenario_name, R, rs, rd)
    fields = fieldnames(values);
    lines = strings(numel(fields) + 7, 1);
    lines(1) = "";
    lines(2) = "// -------------------------------------------------------------------------";
    lines(3) = "// GENERATED SCALE-AND-DEVELOPMENT SCENARIO OVERRIDES";
    lines(4) = "// Scenario: " + string(scenario_name);
    lines(5) = sprintf(['// Total-GDP ratio R=%.15g; scale ratio=%.15g; ' ...
        'unit-GDP ratio=%.15g.'], R, rs, rd);
    lines(6) = "// -------------------------------------------------------------------------";
    for i = 1:numel(fields)
        lines(i + 6) = sprintf('%-12s = %.17g;', fields{i}, values.(fields{i}));
    end
    lines(end) = "";
    block = strjoin(lines, newline);

    matches = regexp(text, '(?m)^\s*model\s*;', 'start');
    if numel(matches) ~= 1
        error('Expected exactly one model; statement in the baseline; found %d.', ...
            numel(matches));
    end
    idx = matches(1);
    text = [text(1:idx-1) char(block) text(idx:end)];
end

function write_text_file(file_name, text)
    fid = fopen(file_name, 'w', 'n', 'UTF-8');
    if fid < 0
        error('Could not write scenario file: %s', file_name);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, text, 'char');
    clear cleaner;
end

function row = scenario_status_row(s, realized_R, total1, total2, ...
        imports1, imports2, d_ann1, d_ann2, abar1, abar2, xi_rs, ...
        run_status, notes)
    row = table(string(s.name), string(s.label), ...
        s.total_gdp_ratio, realized_R, s.scale_ratio, ...
        s.development_ratio, s.s1, s.s2, s.gw1, s.gw2, ...
        s.xbar1, s.xbar2, total1, total2, s.omega1, s.omega2, ...
        imports1, imports2, d_ann1, d_ann2, abar1, abar2, xi_rs, ...
        string(run_status), string(notes), ...
        'VariableNames', {'scenario','label','total_gdp_ratio', ...
        'realized_total_gdp_ratio','scale_ratio','development_ratio', ...
        's1','s2','gw1','gw2','xbar1','xbar2', ...
        'regional_gdp1','regional_gdp2','omega1','omega2', ...
        'imports1','imports2','d_ann1','d_ann2','abar1','abar2', ...
        'xi_rs','status','notes'});
end

function summary = collect_region2_summary(oo_, M_, scenario, periods, shock_suffix)
    metrics = {
        'Policy rate',           'r';
        'Net real debt-service burden', 'ds2';
        'Pre-financing fiscal resources','fs2';
        'Public investment',     'ig2';
        'Public capital',        'kg2';
        'Local production GDP',  'xloc2';
        'Consumption',           'c2';
        'Inflation',             'pinf2'
    };

    summary = table();
    for i = 1:size(metrics, 1)
        [response, steady_state, transformation] = normalized_irf( ...
            oo_, M_, metrics{i, 2}, shock_suffix);
        row = table(string(scenario.name), string(scenario.label), ...
            scenario.total_gdp_ratio, scenario.scale_ratio, ...
            scenario.development_ratio, scenario.s1, scenario.s2, ...
            scenario.gw1, scenario.gw2, scenario.xbar1, scenario.xbar2, ...
            string(metrics{i, 1}), string(metrics{i, 2}), ...
            steady_state, transformation, ...
            response(periods(1)), response(periods(2)), ...
            response(periods(3)), response(periods(4)), ...
            'VariableNames', {'scenario','label','total_gdp_ratio', ...
            'scale_ratio','development_ratio','s1','s2','gw1','gw2', ...
            'xbar1','xbar2','metric','variable','steady_state', ...
            'transformation','normalized_t1','normalized_t4', ...
            'normalized_t8','normalized_t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function summary = collect_gap_summary(oo_, M_, scenario, periods, shock_suffix)
    pairs = {
        'Net real debt-service burden', 'ds1',   'ds2';
        'Pre-financing fiscal resources','fs1',   'fs2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Private investment',    'inv1',  'inv2';
        'Local production GDP',  'xloc1', 'xloc2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    summary = table();
    for i = 1:size(pairs, 1)
        [developed_response, developed_steady, transformation1] = ...
            normalized_irf(oo_, M_, pairs{i, 2}, shock_suffix);
        [less_developed_response, less_developed_steady, transformation2] = ...
            normalized_irf(oo_, M_, pairs{i, 3}, shock_suffix);
        if transformation1 ~= transformation2
            error('Inconsistent transformations for regional pair %s.', ...
                pairs{i, 1});
        end
        normalized_gap = less_developed_response - developed_response;
        row = table(string(scenario.name), string(scenario.label), ...
            scenario.total_gdp_ratio, scenario.scale_ratio, ...
            scenario.development_ratio, scenario.s1, scenario.s2, ...
            scenario.gw1, scenario.gw2, scenario.xbar1, scenario.xbar2, ...
            string(pairs{i, 1}), string(pairs{i, 2}), string(pairs{i, 3}), ...
            developed_steady, less_developed_steady, transformation1, ...
            normalized_gap(periods(1)), normalized_gap(periods(2)), ...
            normalized_gap(periods(3)), normalized_gap(periods(4)), ...
            'VariableNames', {'scenario','label','total_gdp_ratio', ...
            'scale_ratio','development_ratio','s1','s2','gw1','gw2', ...
            'xbar1','xbar2','metric','developed_var','less_developed_var', ...
            'developed_steady_state','less_developed_steady_state', ...
            'transformation','normalized_gap_t1','normalized_gap_t4', ...
            'normalized_gap_t8','normalized_gap_t12'});
        summary = [summary; row]; %#ok<AGROW>
    end
end

function series = collect_irf_series(oo_, M_, scenario, shock_suffix)
    pairs = {
        'Net real debt-service burden', 'ds1',   'ds2';
        'Pre-financing fiscal resources','fs1',   'fs2';
        'Public investment',     'ig1',   'ig2';
        'Public capital',        'kg1',   'kg2';
        'Private investment',    'inv1',  'inv2';
        'Local production GDP',  'xloc1', 'xloc2';
        'Consumption',           'c1',    'c2';
        'Inflation',             'pinf1', 'pinf2'
    };

    series = table();
    for i = 1:size(pairs, 1)
        [developed_response, developed_steady, transformation1] = ...
            normalized_irf(oo_, M_, pairs{i, 2}, shock_suffix);
        [less_developed_response, less_developed_steady, transformation2] = ...
            normalized_irf(oo_, M_, pairs{i, 3}, shock_suffix);
        if transformation1 ~= transformation2
            error('Inconsistent transformations for regional pair %s.', ...
                pairs{i, 1});
        end
        normalized_gap = less_developed_response - developed_response;
        horizon = (1:numel(less_developed_response))';
        n = numel(horizon);
        rows = table(repmat(string(scenario.name), n, 1), ...
            repmat(string(scenario.label), n, 1), ...
            repmat(scenario.total_gdp_ratio, n, 1), ...
            repmat(scenario.scale_ratio, n, 1), ...
            repmat(scenario.development_ratio, n, 1), ...
            repmat(scenario.s1, n, 1), repmat(scenario.s2, n, 1), ...
            repmat(scenario.gw1, n, 1), repmat(scenario.gw2, n, 1), ...
            repmat(scenario.xbar1, n, 1), repmat(scenario.xbar2, n, 1), ...
            repmat(string(pairs{i, 1}), n, 1), ...
            repmat(string(pairs{i, 2}), n, 1), ...
            repmat(string(pairs{i, 3}), n, 1), ...
            repmat(developed_steady, n, 1), ...
            repmat(less_developed_steady, n, 1), ...
            repmat(transformation1, n, 1), horizon, ...
            developed_response(:), less_developed_response(:), ...
            normalized_gap(:), ...
            'VariableNames', {'scenario','label','total_gdp_ratio', ...
            'scale_ratio','development_ratio','s1','s2','gw1','gw2', ...
            'xbar1','xbar2','metric','developed_var','less_developed_var', ...
            'developed_steady_state','less_developed_steady_state', ...
            'transformation','horizon','developed_normalized_response', ...
            'less_developed_normalized_response','normalized_gap'});
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

function [response, steady_state, transformation] = normalized_irf( ...
        oo_, M_, var_name, shock_suffix)
    irf = get_irf(oo_, var_name, shock_suffix);
    names = cellstr(M_.endo_names);
    index = find(strcmp(strtrim(names), var_name));
    if numel(index) ~= 1
        error('Could not identify a unique endogenous variable: %s.', var_name);
    end
    steady_state = oo_.steady_state(index);
    if ~isfinite(steady_state) || steady_state <= 0
        error(['Variable %s has non-positive/non-finite steady state %.16g; ' ...
            'relative normalization is not admissible.'], var_name, steady_state);
    end
    response = irf / steady_state;
    transformation = "first_order_relative_deviation=level_IRF/steady_state";
end
