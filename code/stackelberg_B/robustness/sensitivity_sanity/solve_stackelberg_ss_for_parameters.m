function result = solve_stackelberg_ss_for_parameters(phi_i, gamma_g, chi_ig, alpha)
% Solve the symmetric local Scheme-B multiplier steady state for one
% sensitivity point. The two regions share this solution because steady
% debt-service differences are absorbed by their residual transfers.

if nargin < 4 || isempty(alpha)
    alpha = 0.45;
end

p = struct();
p.beta = 0.99;
p.betaG = p.beta;
p.sigma = 2.00;
p.varphi = 0.50;
p.deltaK = 0.025;
p.deltaG = 0.025;
p.phiI = phi_i;
p.alpha = alpha;
p.gammaG = gamma_g;
p.tauX = 0.20;
p.thetaT = 0.60;
p.tauL = (1 - p.thetaT) * p.tauX;
p.omegaX = 1.00;
p.chiIG = chi_ig;

ss = struct();
ss.qjj = 1.00;
ss.MC = 5 / 6;
ss.V = 1.00;
ss.A = 1.00;
ss.Pi = 1.00;
ss.RB = 1 / p.beta;
ss.Y = 1.00;
ss.YM = 1.00;
ss.X = ss.qjj * ss.YM;
ss.G = 0.10 * ss.X;
ss.IG = 0.12 * ss.X;
ss.KG = ss.IG / p.deltaG;
ss.QK = 1.00;
ss.m = 1.00;
ss.xI = 1.00;
ss.xIG = 1.00;
ss.RK = 1 / p.beta - (1 - p.deltaK);
ss.K = p.alpha * ss.qjj * ss.MC * ss.YM * ss.V / ss.RK;
ss.I = p.deltaK * ss.K;
ss.N = (ss.YM * ss.V / (ss.A * ss.KG^p.gammaG ...
    * ss.K^p.alpha))^(1 / (1 - p.alpha));
ss.W = (1 - p.alpha) * ss.qjj * ss.MC * ss.YM * ss.V / ss.N;
ss.C = ss.Y - ss.I - ss.G - ss.IG;
ss.Lambda = ss.C^(-p.sigma);
p.chiN = ss.C^(-p.sigma) * ss.W / ss.N^p.varphi;

variable_names = ["LambdaG"; "QG"; "muR"; "muK"; "muQ"; "muI"];
initial = [3; 3; -0.15; 0; -70; -1.75];
variable_scale = [3; 3; 0.15; 1; 70; 1.75];
scaled_initial = initial ./ variable_scale;

unscaled_from_z = @(z) local_residuals(z .* variable_scale, p, ss);
initial_jacobian = finite_difference_jacobian(unscaled_from_z, scaled_initial);
equation_scale = max(vecnorm(initial_jacobian, 2, 2), 1e-8);
scaled_objective = @(z) unscaled_from_z(z) ./ equation_scale;

options = optimoptions('fsolve', 'Display', 'off', ...
    'FunctionTolerance', 1e-14, 'StepTolerance', 1e-14, ...
    'OptimalityTolerance', 1e-14, 'MaxIterations', 1000, ...
    'MaxFunctionEvaluations', 20000, 'FiniteDifferenceType', 'central');
[scaled_solution, scaled_fval, exitflag, solver_output, scaled_jacobian] = ...
    fsolve(scaled_objective, scaled_initial, options);
raw_solution = scaled_solution .* variable_scale;

if abs(raw_solution(4)) >= 1e-9
    error('Cannot normalize muK for phi_i=%.6g, gamma_g=%.6g: %.3e.', ...
        phi_i, gamma_g, raw_solution(4));
end
solution = raw_solution;
solution(4) = 0;
raw_residual = local_residuals(solution, p, ss);
raw_jacobian = diag(equation_scale) * scaled_jacobian ...
    * diag(1 ./ variable_scale);
rank_tolerance = max(size(raw_jacobian)) * eps(norm(raw_jacobian, 2));
jacobian_rank = rank(raw_jacobian, rank_tolerance);

result = struct();
result.phi_i = phi_i;
result.gamma_g = gamma_g;
result.chi_ig = chi_ig;
result.alpha = alpha;
result.variable_names = variable_names;
result.solution = solution;
result.raw_solution = raw_solution;
result.raw_residual = raw_residual;
result.exitflag = exitflag;
result.iterations = solver_output.iterations;
result.function_count = solver_output.funcCount;
result.max_scaled_residual = max(abs(scaled_fval));
result.max_raw_residual = max(abs(raw_residual));
result.jacobian_rank = jacobian_rank;
result.jacobian_dimension = size(raw_jacobian, 1);
result.raw_condition_number = cond(raw_jacobian, 2);
result.scaled_condition_number = cond(scaled_jacobian, 2);
result.muI_identity_error = solution(6) - p.deltaK * solution(5);
result.private_steady = ss;
result.parameters = p;
result.private_steady_N = ss.N;
result.private_steady_W = ss.W;
result.public_steady_IG = ss.IG;
result.public_steady_KG = ss.KG;
result.status = string(pass_fail(exitflag > 0 ...
    && result.max_raw_residual < 1e-10 ...
    && jacobian_rank == size(raw_jacobian, 1) ...
    && abs(result.muI_identity_error) < 1e-10));
end

function residual = local_residuals(u, p, ss)
LambdaG = u(1);
QG = u(2);
muR = u(3);
muK = u(4);
muQ = u(5);
muI = u(6);

Theta = muR * ss.Lambda;
marginal_n = ((1 - p.alpha) ...
    * (p.omegaX + LambdaG * p.tauL * ss.X) ...
    + p.alpha * Theta * ss.W ...
    - (p.beta / p.betaG) * muQ * ss.m ...
    * (1 - p.alpha) * ss.RK) / ss.N;

Ainv = 1;
Binv = 0;
Aprime = -p.phiI;
Bprime = p.phiI;

residual = zeros(6, 1);
residual(1) = LambdaG - QG;
residual(2) = QG ...
    - p.betaG * ((1 - p.deltaG) * QG ...
    + p.gammaG / ss.KG ...
    * (p.omegaX + LambdaG * p.tauL * ss.X - Theta * ss.W)) ...
    + p.beta * muQ * ss.m * p.gammaG * ss.RK / ss.KG;
residual(3) = muK ...
    - p.betaG * (p.alpha / ss.K ...
    * (p.omegaX + LambdaG * p.tauL * ss.X - Theta * ss.W) ...
    + (1 - p.deltaK) * muK) ...
    - p.beta * muQ * ss.m * (1 - p.alpha) * ss.RK / ss.K;
residual(4) = marginal_n ...
    + muR * p.chiN * p.varphi * ss.N^(p.varphi - 1);
residual(5) = muQ - Ainv * muI ...
    - (p.beta / p.betaG) * ss.m ...
    * ((1 - p.deltaK) * muQ + Binv * muI);
residual(6) = muK * Ainv + p.betaG * muK * Binv ...
    + muI * (-ss.QK * Aprime / ss.I ...
    + p.beta * ss.m * ss.QK * Bprime * ss.xI / ss.I) ...
    - (p.beta / p.betaG) * muI * ss.m * ss.QK ...
    * Bprime / ss.I ...
    + p.betaG * muI * ss.QK * Aprime * ss.xI / ss.I;
end

function jacobian = finite_difference_jacobian(fun, x)
f0 = fun(x);
jacobian = zeros(numel(f0), numel(x));
for idx = 1:numel(x)
    step = 1e-6 * (1 + abs(x(idx)));
    x_plus = x;
    x_minus = x;
    x_plus(idx) = x_plus(idx) + step;
    x_minus(idx) = x_minus(idx) - step;
    jacobian(:, idx) = (fun(x_plus) - fun(x_minus)) / (2 * step);
end
end

function label = pass_fail(condition)
if condition
    label = 'PASS';
else
    label = 'FAIL';
end
end
