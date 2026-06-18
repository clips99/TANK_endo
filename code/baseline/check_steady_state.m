% Steady-state consistency checks for TANK_two_region_baseline.mod.
% Run after:
%   dynare TANK_two_region_baseline.mod noclearall

clear;
clc;

results_file = fullfile(pwd, 'TANK_two_region_baseline', 'Output', ...
    'TANK_two_region_baseline_results.mat');

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
add_check('risk sharing: lam2 = lam1 * q11 / q12', ...
    ss.lam2 - ss.lam1 * ss.q11 / ss.q12);

rb_rule1 = ss.rb1 / ss.r ...
    - exp(params.mu_b * ((ss.b1 / ss.y1) / params.b_y1 - 1));
rb_rule2 = ss.rb2 / ss.r ...
    - exp(params.mu_b * ((ss.b2 / ss.y2) / params.b_y2 - 1));
add_check('region 1 local bond pricing rule', rb_rule1);
add_check('region 2 local bond pricing rule', rb_rule2);

mc_target = (params.epsilon_p - 1) / params.epsilon_p;
add_check('mc1 = (epsilon_p - 1) / epsilon_p', ss.mc1 - mc_target);
add_check('mc2 = (epsilon_p - 1) / epsilon_p', ss.mc2 - mc_target);

add_check('inv1 = delta_k * k1', ss.inv1 - params.delta_k * ss.k1);
add_check('inv2 = delta_k * k2', ss.inv2 - params.delta_k * ss.k2);
add_check('ig1 = delta_g * kg1', ss.ig1 - params.delta_g * ss.kg1);
add_check('ig2 = delta_g * kg2', ss.ig2 - params.delta_g * ss.kg2);

local_tax1 = (1 - params.theta_T) * params.tau_y * ss.y1;
local_tax2 = (1 - params.theta_T) * params.tau_y * ss.y2;
net_interest1 = (ss.rb1 - 1) * ss.b1;
net_interest2 = (ss.rb2 - 1) * ss.b2;

fiscal_lhs1 = local_tax1 + ss.z1;
fiscal_rhs1 = net_interest1 + ss.g1 + ss.ig1 + params.lambda1 * ss.tr1;
fiscal_lhs2 = local_tax2 + ss.z2;
fiscal_rhs2 = net_interest2 + ss.g2 + ss.ig2 + params.lambda2 * ss.tr2;

add_check('region 1 government budget', fiscal_lhs1 - fiscal_rhs1);
add_check('region 2 government budget', fiscal_lhs2 - fiscal_rhs2);
add_check('fs1 = ig1', ss.fs1 - ss.ig1);
add_check('fs2 = ig2', ss.fs2 - ss.ig2);
add_check('ds1 definition', ss.ds1 - net_interest1 / ss.y1);
add_check('ds2 definition', ss.ds2 - net_interest2 / ss.y2);

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
fprintf('Debt ratios: b1/y1 = %.6f, b2/y2 = %.6f\n', ...
    ss.b1 / ss.y1, ss.b2 / ss.y2);
fprintf('Net interest: region 1 = %.12f, region 2 = %.12f\n', ...
    net_interest1, net_interest2);
fprintf('Fiscal closure z: region 1 = %.12f, region 2 = %.12f\n', ...
    ss.z1, ss.z2);
fprintf('Max absolute residual = %.3e\n', max_abs_residual);

if max_abs_residual > tol
    error('Steady-state checks failed: max residual %.3e exceeds tolerance %.1e.', ...
        max_abs_residual, tol);
end

fprintf('\nAll steady-state checks passed at tolerance %.1e.\n', tol);
