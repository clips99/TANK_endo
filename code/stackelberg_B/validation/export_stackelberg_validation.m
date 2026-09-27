function overall_status = export_stackelberg_validation(M_, oo_, options_, dynare_output, output_dir, validation_config)
% Export auditable structural diagnostics for the two-region government model.
% The optional validation_config lets Scheme A reuse exactly the same gates
% without changing the accepted Scheme-B defaults.

if nargin < 5 || isempty(output_dir)
    output_dir = fileparts(mfilename('fullpath'));
end
if ~isfolder(output_dir)
    mkdir(output_dir);
end

if nargin < 6 || isempty(validation_config)
    validation_config = struct();
end

model_name = string(M_.fname);
expected_endogenous = 86;
expected_equations = 86;
residual_tolerance = 1e-10;
base_catalog = stackelberg_irf_catalog();
required_irf_variables = base_catalog.variable;
shock_suffix = string(base_catalog.shock_suffix);
irf_description = "first-round mechanism";
if isfield(validation_config, 'expected_endogenous')
    expected_endogenous = validation_config.expected_endogenous;
end
if isfield(validation_config, 'expected_equations')
    expected_equations = validation_config.expected_equations;
end
if isfield(validation_config, 'residual_tolerance')
    residual_tolerance = validation_config.residual_tolerance;
end
if isfield(validation_config, 'required_irf_variables')
    required_irf_variables = string(validation_config.required_irf_variables(:));
end
if isfield(validation_config, 'shock_suffix')
    shock_suffix = string(validation_config.shock_suffix);
end
if isfield(validation_config, 'irf_description')
    irf_description = string(validation_config.irf_description);
end

%% Equation and variable count
n_endogenous = M_.endo_nbr;
n_equations = M_.eq_nbr;
count_ok = n_endogenous == expected_endogenous ...
    && n_equations == expected_equations ...
    && n_endogenous == n_equations;
equation_count = table(model_name, n_endogenous, n_equations, ...
    n_equations - n_endogenous, expected_endogenous, expected_equations, ...
    string(pass_fail(count_ok)), ...
    'VariableNames', {'model', 'n_endogenous', 'n_equations', 'difference', ...
    'expected_endogenous', 'expected_equations', 'status'});
writetable(equation_count, fullfile(output_dir, 'equation_count.csv'));

%% Static residuals and full-system Jacobian
static_residual = feval([M_.fname '.static_resid'], ...
    oo_.steady_state, oo_.exo_steady_state, M_.params);
static_jacobian = feval([M_.fname '.static_g1'], ...
    oo_.steady_state, oo_.exo_steady_state, M_.params, ...
    M_.static_g1_sparse_rowval, M_.static_g1_sparse_colval, ...
    M_.static_g1_sparse_colptr);
static_jacobian = full(static_jacobian);
singular_values = svd(static_jacobian);
rank_tolerance = max(size(static_jacobian)) * eps(max(singular_values));
static_rank = sum(singular_values > rank_tolerance);
full_rank = static_rank == min(size(static_jacobian));
max_residual = max(abs(static_residual));
residual_ok = max_residual < residual_tolerance;

equation_number = (1:numel(static_residual))';
equation = compose('equation_%03d', equation_number);
equation_name = repmat("", numel(static_residual), 1);
if isfield(M_, 'equations_tags') && ~isempty(M_.equations_tags)
    for idx = 1:numel(static_residual)
        tagged_name = get_equation_name_by_number(idx, M_);
        if ~isempty(tagged_name)
            equation_name(idx) = string(tagged_name);
        end
    end
end
steady_residuals = table(equation_number, equation, equation_name, ...
    static_residual(:), ...
    abs(static_residual(:)), ...
    repmat(residual_tolerance, numel(static_residual), 1), ...
    string(arrayfun(@(x) pass_fail(x < residual_tolerance), ...
    abs(static_residual(:)), 'UniformOutput', false)), ...
    'VariableNames', {'equation_number', 'equation', 'equation_name', ...
    'residual', 'absolute_residual', 'tolerance', 'status'});
writetable(steady_residuals, ...
    fullfile(output_dir, 'steady_state_residuals.csv'));

% model_diagnostics has no formal return value, so retain its exact text and
% separately audit the success phrase emitted by Dynare 7.
diagnostics_output = evalc('model_diagnostics(M_, options_, oo_);');
diagnostics_ok = contains(diagnostics_output, ...
    'No obvious problems with this mod-file were detected.');
writelines(string(diagnostics_output), ...
    fullfile(output_dir, 'model_diagnostics.txt'));

jacobian_ok = residual_ok && full_rank && diagnostics_ok;
jacobian_status = table(model_name, max_residual, residual_tolerance, ...
    size(static_jacobian, 1), size(static_jacobian, 2), static_rank, ...
    rank_tolerance, min(singular_values), max(singular_values), ...
    rcond(static_jacobian), cond(static_jacobian, 2), full_rank, ...
    diagnostics_ok, string(pass_fail(jacobian_ok)), ...
    'VariableNames', {'model', 'max_absolute_steady_residual', ...
    'residual_tolerance', 'jacobian_rows', 'jacobian_columns', ...
    'jacobian_rank', 'rank_tolerance', 'min_singular_value', ...
    'max_singular_value', 'reciprocal_condition_number', ...
    'condition_number_2', 'full_rank', 'model_diagnostics_ok', 'status'});
writetable(jacobian_status, fullfile(output_dir, 'jacobian_status.csv'));

%% Dynare's formal BK order-and-rank test
check_options = options_;
check_options.noprint = true;
check_error = "";
try
    [eigenvalues, bk_verified, bk_info] = check(M_, check_options, oo_);
catch check_exception
    bk_verified = false;
    bk_info = NaN;
    check_error = string(check_exception.message);
    if isfield(oo_, 'dr') && isfield(oo_.dr, 'eigval')
        eigenvalues = oo_.dr.eigval(:);
    else
        eigenvalues = complex(zeros(0, 1));
    end
end
if isnumeric(bk_info) && isscalar(bk_info)
    bk_info_code = double(bk_info);
else
    bk_info_code = NaN;
end
bk_info_text = strjoin(string(bk_info(:)), ';');
if isempty(options_.qz_criterium)
    qz_criterium = 1 + 1e-6;
else
    qz_criterium = options_.qz_criterium;
end
unstable_roots = sum(abs(eigenvalues) > qz_criterium);
order_condition = unstable_roots == M_.nsfwrd;
if ~order_condition
    rank_condition_status = "NOT_EVALUABLE";
elseif bk_verified
    rank_condition_status = "PASS";
else
    rank_condition_status = "FAIL";
end
bk_ok = order_condition && bk_verified && isequal(bk_info, 0) ...
    && strlength(check_error) == 0;

bk_status = table(model_name, qz_criterium, M_.nstatic, M_.npred, ...
    M_.nfwrd, M_.nboth, M_.nspred, M_.nsfwrd, numel(eigenvalues), ...
    unstable_roots, order_condition, logical(bk_verified), bk_info_code, ...
    bk_info_text, check_error, rank_condition_status, string(pass_fail(bk_ok)), ...
    'VariableNames', {'model', 'qz_criterium', 'nstatic', 'npred', ...
    'nfwrd', 'nboth', 'nspred', 'nsfwrd', 'eigenvalue_count', ...
    'unstable_roots', 'order_condition', 'dynare_check_result', ...
    'dynare_check_info_code', 'dynare_check_info_text', ...
    'dynare_check_error', 'rank_condition_status', 'bk_status'});
writetable(bk_status, fullfile(output_dir, 'bk_status.csv'));

root_index = (1:numel(eigenvalues))';
real_part = real(eigenvalues(:));
imaginary_part = imag(eigenvalues(:));
modulus = abs(eigenvalues(:));
classified_unstable = modulus > qz_criterium;
root_table = table(root_index, real_part, imaginary_part, modulus, ...
    classified_unstable);
writetable(root_table, fullfile(output_dir, 'bk_eigenvalues.csv'));

%% IRF-field completeness and overall gate
irf_fields = required_irf_variables + shock_suffix;
irf_complete = all(arrayfun(@(x) isfield(oo_.irfs, char(x)), irf_fields));

overall_ok = count_ok && residual_ok && full_rank && diagnostics_ok ...
    && bk_ok && irf_complete;
check_name = ["equation_count"; "steady_state_residual"; ...
    "static_jacobian_full_rank"; "model_diagnostics"; ...
    "bk_order_condition"; "bk_order_and_rank"; ...
    "required_irf_fields"; "overall"];
value = [string(sprintf('%d endogenous / %d equations', n_endogenous, n_equations)); ...
    string(sprintf('%.17g', max_residual)); ...
    string(sprintf('%d / %d', static_rank, size(static_jacobian, 2))); ...
    string(diagnostics_ok); ...
    string(sprintf('%d unstable / %d forward-looking', unstable_roots, M_.nsfwrd)); ...
    string(sprintf('check=%d, info=%g', bk_verified, bk_info_code)); ...
    string(sprintf('%d / %d present', sum(arrayfun(@(x) isfield(oo_.irfs, char(x)), irf_fields)), numel(irf_fields))); ...
    string(overall_ok)];
criterion = [string(sprintf('%d endogenous and %d equations', ...
    expected_endogenous, expected_equations)); ...
    string(sprintf('< %.1e', residual_tolerance)); ...
    string(sprintf('rank %d', expected_endogenous)); ...
    "Dynare reports no obvious problem"; ...
    "unstable roots equal M_.nsfwrd"; ...
    "Dynare check verifies order and QZ rank"; ...
    "all " + irf_description + " fields present"; "all gates pass"];
status = string({pass_fail(count_ok); pass_fail(residual_ok); ...
    pass_fail(full_rank); pass_fail(diagnostics_ok); ...
    pass_fail(order_condition); pass_fail(bk_ok); ...
    pass_fail(irf_complete); pass_fail(overall_ok)});
validation_status = table(check_name, value, criterion, status);
writetable(validation_status, ...
    fullfile(output_dir, 'model_validation_status.csv'));

% Preserve the captured Dynare console text as a supplementary audit trail.
if nargin >= 4 && ~isempty(dynare_output)
    writelines(string(dynare_output), ...
        fullfile(output_dir, 'dynare_console_output.txt'));
end

overall_status = string(pass_fail(overall_ok));
fprintf('Structural validation: %s\n', overall_status);
fprintf('  variables/equations: %d/%d\n', n_endogenous, n_equations);
fprintf('  maximum static residual: %.3e\n', max_residual);
fprintf('  static Jacobian rank: %d/%d\n', static_rank, size(static_jacobian, 2));
fprintf('  Dynare BK order-and-rank check: %d (info=%g)\n', ...
    bk_verified, bk_info_code);
end

function label = pass_fail(condition)
if condition
    label = 'PASS';
else
    label = 'FAIL';
end
end
