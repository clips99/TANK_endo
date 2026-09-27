function check_steady_state()
% Steady-state consistency checks for RANK_two_region_baseline.mod.
% Run after:
%   dynare RANK_two_region_baseline.mod noclearall

script_dir = fileparts(mfilename('fullpath'));
results_file = fullfile(script_dir, 'RANK_two_region_baseline', 'Output', ...
    'RANK_two_region_baseline_results.mat');

if ~isfile(results_file)
    error('Results file not found: %s. Run Dynare first.', results_file);
end

load(results_file, 'M_', 'oo_');

tol = 1e-9;
params = struct();
for i = 1:numel(M_.param_names)
    params.(strtrim(M_.param_names{i})) = M_.params(i);
end

ss = struct();
for i = 1:numel(M_.endo_names)
    ss.(strtrim(M_.endo_names{i})) = oo_.steady_state(i);
end

checks = {};
add_check = @(name, residual) assignin('caller', 'checks', ...
    [evalin('caller', 'checks'); {name, residual}]);

add_check('R = 1 / beta', ss.r - 1 / params.beta);
add_check('pinf1 = 1', ss.pinf1 - 1);
add_check('pinf2 = 1', ss.pinf2 - 1);
add_check('pim1 = 1', ss.pim1 - 1);
add_check('pim2 = 1', ss.pim2 - 1);
add_check('pinfagg = 1', ss.pinfagg - 1);
add_check('risk sharing: lam2 = xi_rs * lam1 * q11 / q12', ...
    ss.lam2 - params.xi_rs * ss.lam1 * ss.q11 / ss.q12);
add_check('xloc1 = q11 * ym1', ss.xloc1 - ss.q11 * ss.ym1);
add_check('xloc2 = q22 * ym2', ss.xloc2 - ss.q22 * ss.ym2);
add_check('xagg in common national-price units', ...
    ss.xagg - params.s1 * ss.xloc1 * (ss.q12 / ss.q11)^params.gw2 ...
    - params.s2 * ss.xloc2 * (ss.q11 / ss.q12)^params.gw1);
add_check('yagg in common national-price units', ...
    ss.yagg - params.s1 * ss.y1 * (ss.q12 / ss.q11)^params.gw2 ...
    - params.s2 * ss.y2 * (ss.q11 / ss.q12)^params.gw1);
add_check('GDP inflation weights sum to one', params.gw1 + params.gw2 - 1);

rb_rule1 = ss.rb1 / ss.r ...
    - exp(params.mu_b * (ss.dann1 / params.d_ann1 - 1));
rb_rule2 = ss.rb2 / ss.r ...
    - exp(params.mu_b * (ss.dann2 / params.d_ann2 - 1));
add_check('region 1 local bond pricing rule', rb_rule1);
add_check('region 2 local bond pricing rule', rb_rule2);
add_check('annualized debt indicator 1: B/(4X)', ...
    ss.dann1 - ss.b1 / (4 * ss.xloc1));
add_check('annualized debt indicator 2: B/(4X)', ...
    ss.dann2 - ss.b2 / (4 * ss.xloc2));

mc_target = (params.epsilon_p - 1) / params.epsilon_p;
add_check('mc1 = (epsilon_p - 1) / epsilon_p', ss.mc1 - mc_target);
add_check('mc2 = (epsilon_p - 1) / epsilon_p', ss.mc2 - mc_target);

add_check('inv1 = delta_k * k1', ss.inv1 - params.delta_k * ss.k1);
add_check('inv2 = delta_k * k2', ss.inv2 - params.delta_k * ss.k2);
add_check('ig1 = delta_g * kg1', ss.ig1 - params.delta_g * ss.kg1);
add_check('ig2 = delta_g * kg2', ss.ig2 - params.delta_g * ss.kg2);

direct_benefit1 = params.gamma_g / ss.kg1 ...
    * (params.omega_x + ss.lamg1 * (1 - params.theta_T) ...
    * params.tau_x * ss.xloc1);
direct_benefit2 = params.gamma_g / ss.kg2 ...
    * (params.omega_x + ss.lamg2 * (1 - params.theta_T) ...
    * params.tau_x * ss.xloc2);
add_check('region 1 Scheme-A public-capital Euler equation', ...
    ss.qg1 - params.beta_g * ((1 - params.delta_g) * ss.qg1 ...
    + direct_benefit1));
add_check('region 2 Scheme-A public-capital Euler equation', ...
    ss.qg2 - params.beta_g * ((1 - params.delta_g) * ss.qg2 ...
    + direct_benefit2));
add_check('region 1 steady public-investment FOC', ss.lamg1 - ss.qg1);
add_check('region 2 steady public-investment FOC', ss.lamg2 - ss.qg2);

denominator1 = 1 - params.beta_g * (1 - params.delta_g) ...
    - params.beta_g * params.gamma_g * (1 - params.theta_T) ...
    * params.tau_x * ss.xloc1 / ss.kg1;
denominator2 = 1 - params.beta_g * (1 - params.delta_g) ...
    - params.beta_g * params.gamma_g * (1 - params.theta_T) ...
    * params.tau_x * ss.xloc2 / ss.kg2;
analytic_lamg1 = params.beta_g * params.gamma_g * params.omega_x ...
    / ss.kg1 / denominator1;
analytic_lamg2 = params.beta_g * params.gamma_g * params.omega_x ...
    / ss.kg2 / denominator2;
add_check('region 1 Scheme-A analytic shadow value', ...
    ss.lamg1 - analytic_lamg1);
add_check('region 2 Scheme-A analytic shadow value', ...
    ss.lamg2 - analytic_lamg2);
add_check('region 1 steady debt Euler equation', ...
    ss.lamg1 * (1 - params.varphi_b * (ss.b1 / params.xbar1 - params.b_x1)) ...
    - params.beta_g * ss.lamg1 * ss.rb1 / ss.pinf1);
add_check('region 2 steady debt Euler equation', ...
    ss.lamg2 * (1 - params.varphi_b * (ss.b2 / params.xbar2 - params.b_x2)) ...
    - params.beta_g * ss.lamg2 * ss.rb2 / ss.pinf2);

local_tax1 = (1 - params.theta_T) * params.tau_x * ss.xloc1;
local_tax2 = (1 - params.theta_T) * params.tau_x * ss.xloc2;
net_interest1 = (ss.rb1 - 1) * ss.b1;
net_interest2 = (ss.rb2 - 1) * ss.b2;

fiscal_lhs1 = local_tax1 + ss.z1;
fiscal_rhs1 = net_interest1 + ss.g1 + ss.ig1;
fiscal_lhs2 = local_tax2 + ss.z2;
fiscal_rhs2 = net_interest2 + ss.g2 + ss.ig2;

add_check('region 1 government budget', fiscal_lhs1 - fiscal_rhs1);
add_check('region 2 government budget', fiscal_lhs2 - fiscal_rhs2);
add_check('fs1 = ig1', ss.fs1 - ss.ig1);
add_check('fs2 = ig2', ss.fs2 - ss.ig2);
add_check('ds1 definition', ss.ds1 - net_interest1 / ss.xloc1);
add_check('ds2 definition', ss.ds2 - net_interest2 / ss.xloc2);
add_check('region 1 weighted intermediate-market clearing', ...
    params.s1 * ss.ym1 - params.s1 * ss.m11 - params.s2 * ss.m12);
add_check('region 2 weighted intermediate-market clearing', ...
    params.s2 * ss.ym2 - params.s1 * ss.m21 - params.s2 * ss.m22);

fprintf('\nSteady-state consistency checks\n');
fprintf('--------------------------------\n');
max_abs_residual = 0;
for i = 1:size(checks, 1)
    residual = checks{i, 2};
    max_abs_residual = max(max_abs_residual, abs(residual));
    fprintf('%-48s residual = %+ .3e\n', checks{i, 1}, residual);
end

fprintf('\nKey steady-state levels\n');
fprintf('--------------------------------\n');
fprintf('beta = %.6f, R = %.12f, 1/beta = %.12f\n', ...
    params.beta, ss.r, 1 / params.beta);
fprintf('MC target = %.12f, mc1 = %.12f, mc2 = %.12f\n', ...
    mc_target, ss.mc1, ss.mc2);
fprintf(['Scheme-A direct public-capital elasticity gamma_g = %.12f; ' ...
    'shadow-value denominators = %.12f, %.12f\n'], ...
    params.gamma_g, denominator1, denominator2);
fprintf('Quarterly-GDP debt stocks: b1/xloc1 = %.6f, b2/xloc2 = %.6f\n', ...
    ss.b1 / ss.xloc1, ss.b2 / ss.xloc2);
fprintf(['Annualized debt indicators using four times current-quarter GDP: ' ...
    'b1/(4*xloc1) = %.6f, b2/(4*xloc2) = %.6f\n'], ...
    ss.b1 / (4 * ss.xloc1), ss.b2 / (4 * ss.xloc2));
fprintf('Net interest: region 1 = %.12f, region 2 = %.12f\n', ...
    net_interest1, net_interest2);
fprintf('Fiscal closure z: region 1 = %.12f, region 2 = %.12f\n', ...
    ss.z1, ss.z2);
central_residual = params.s1 * (params.theta_T * params.tau_x * ss.xloc1 - ss.z1) ...
    * (ss.q12 / ss.q11)^params.gw2 ...
    + params.s2 * (params.theta_T * params.tau_x * ss.xloc2 - ss.z2) ...
    * (ss.q11 / ss.q12)^params.gw1;
fprintf('Common-price central residual S_C = %.12f\n', central_residual);
fprintf('Max absolute residual = %.3e\n', max_abs_residual);

if denominator1 <= 0 || denominator2 <= 0
    error('Scheme-A steady shadow-value denominator must be positive.');
end
if max_abs_residual > tol
    error('Steady-state checks failed: max residual %.3e exceeds tolerance %.1e.', ...
        max_abs_residual, tol);
end

fprintf('\nAll steady-state checks passed at tolerance %.1e.\n', tol);
end
