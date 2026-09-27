function run_scheme_A()
% Solve and validate the direct-technology Scheme-A benchmark.

script_dir = fileparts(mfilename('fullpath'));
caller_dir = pwd;
restore_directory = onCleanup(@() cd(caller_dir));
cd(script_dir); % Dynare writes its generated package beside the model.

dynare_path = 'C:\dynare\7.0\matlab';
if ~isfolder(dynare_path)
    error('Dynare 7 MATLAB directory not found: %s', dynare_path);
end
addpath(dynare_path, '-begin');
dynare_entry = which('dynare');
if isempty(dynare_entry) || ~contains(dynare_entry, 'dynare\7.0', 'IgnoreCase', true)
    error('Expected Dynare 7.0, but MATLAB resolved dynare to: %s', dynare_entry);
end

stackelberg_root = fileparts(fileparts(script_dir));
shared_validation_dir = fullfile(stackelberg_root, 'validation');
validation_dir = fullfile(script_dir, 'validation');
if ~isfolder(validation_dir)
    mkdir(validation_dir);
end
addpath(shared_validation_dir);
addpath(script_dir);

model_file = fullfile(script_dir, 'RANK_two_region_scheme_A.mod');
manifest_file = fullfile(script_dir, 'scheme_A_run_manifest.csv');
run_start = string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
run_id = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
model_sha256 = get_sha256(model_file);
matlab_release = string(version('-release'));
dynare_release = string(dynare_version());
authoritative_log = string(fullfile(validation_dir, 'dynare_console_output.txt'));
write_manifest(manifest_file, run_id, "RUNNING", run_start, "", ...
    model_sha256, matlab_release, dynare_release, 0.0025, 40, ...
    authoritative_log, "PENDING", "PENDING", "PENDING", ...
    "Scheme-A Dynare run started");

structural_status = "NOT_REACHED";
irf_export_status = "NOT_REACHED";
steady_formula_status = "NOT_REACHED";
shock_std = NaN;
actual_horizon = 40;
try
    dynare_output = evalc('dynare RANK_two_region_scheme_A.mod noclearall');
    fprintf('%s', dynare_output);
    result = load(fullfile(script_dir, 'RANK_two_region_scheme_A', ...
        'Output', 'RANK_two_region_scheme_A_results.mat'), 'M_', 'oo_', 'options_');
    M_ = result.M_; oo_ = result.oo_; options_ = result.options_;

    catalog = scheme_a_irf_catalog();
    validation_config = struct();
    validation_config.expected_endogenous = 78;
    validation_config.expected_equations = 78;
    validation_config.residual_tolerance = 1e-10;
    validation_config.required_irf_variables = catalog.variable;
    validation_config.shock_suffix = catalog.shock_suffix;
    validation_config.irf_description = "Scheme-A comparison";
    structural_status = export_stackelberg_validation( ...
        M_, oo_, options_, dynare_output, validation_dir, validation_config);
    irf_export_status = export_scheme_a_irfs(M_, oo_, script_dir);
    steady_formula_status = export_scheme_a_steady_formula_check(M_, oo_, script_dir);

    shock_index = find(strcmp(M_.exo_names, 'emp'), 1);
    shock_std = sqrt(M_.Sigma_e(shock_index, shock_index));
    actual_horizon = numel(oo_.irfs.r_emp);
    final_status = "PASS";
    if structural_status ~= "PASS" || irf_export_status ~= "PASS" ...
            || steady_formula_status ~= "PASS"
        final_status = "FAIL";
    end

    write_manifest(manifest_file, run_id, final_status, run_start, ...
        string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS')), ...
        model_sha256, matlab_release, dynare_release, shock_std, ...
        actual_horizon, authoritative_log, structural_status, ...
        irf_export_status, steady_formula_status, ...
        "Scheme A retains private GE responses but omits their internalization in the local-government FOC.");

    fprintf('\nScheme-A runner completed.\n');
    fprintf('  Run id: %s\n', run_id);
    fprintf('  Structural validation: %s\n', structural_status);
    fprintf('  IRF data-integrity audit: %s\n', irf_export_status);
    fprintf('  Analytic steady-state formula audit: %s\n', steady_formula_status);

    if structural_status ~= "PASS"
        error('Scheme-A structural validation failed; inspect validation CSV files.');
    end
    if irf_export_status ~= "PASS"
        error('Scheme-A IRF data-integrity audit failed.');
    end
    if steady_formula_status ~= "PASS"
        error('Scheme-A analytic steady-state formula audit failed.');
    end
catch run_exception
    write_manifest(manifest_file, run_id, "FAIL", run_start, ...
        string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS')), ...
        model_sha256, matlab_release, dynare_release, shock_std, actual_horizon, ...
        authoritative_log, structural_status, irf_export_status, ...
        steady_formula_status, ...
        string(run_exception.message));
    rethrow(run_exception);
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

function write_manifest(path, run_id, status, start_time, end_time, ...
        model_sha256, matlab_release, dynare_release, shock_std, horizon, ...
        authoritative_log, structural_status, irf_export_status, ...
        steady_formula_status, message)
model = "RANK_two_region_scheme_A";
shock = "emp";
approximation_order = 1;
manifest = table(run_id, status, start_time, end_time, model, ...
    model_sha256, matlab_release, dynare_release, approximation_order, ...
    shock, shock_std, horizon, authoritative_log, structural_status, ...
    irf_export_status, steady_formula_status, message);
writetable(manifest, path);
end

function overall_status = export_scheme_a_steady_formula_check(M_, oo_, output_dir)
beta_g = get_parameter(M_, 'beta_g');
gamma_g = get_parameter(M_, 'gamma_g');
omega_x = get_parameter(M_, 'omega_x');
delta_g = get_parameter(M_, 'delta_g');
theta_T = get_parameter(M_, 'theta_T');
tau_x = get_parameter(M_, 'tau_x');
tau_local = (1 - theta_T) * tau_x;

region = ["low_debt"; "high_debt"];
xloc = zeros(2, 1);
ig = zeros(2, 1);
kg = zeros(2, 1);
denominator = zeros(2, 1);
analytic_lamg = zeros(2, 1);
dynare_lamg = zeros(2, 1);
dynare_qg = zeros(2, 1);
formula_error = zeros(2, 1);
steady_foc_residual = zeros(2, 1);
status = strings(2, 1);
for idx = 1:2
    xloc(idx) = get_steady(M_, oo_, sprintf('xloc%d', idx));
    ig(idx) = get_steady(M_, oo_, sprintf('ig%d', idx));
    kg(idx) = get_steady(M_, oo_, sprintf('kg%d', idx));
    dynare_lamg(idx) = get_steady(M_, oo_, sprintf('lamg%d', idx));
    dynare_qg(idx) = get_steady(M_, oo_, sprintf('qg%d', idx));
    denominator(idx) = 1 - beta_g * (1 - delta_g) ...
        - beta_g * gamma_g * tau_local * xloc(idx) / kg(idx);
    analytic_lamg(idx) = beta_g * gamma_g * omega_x / kg(idx) ...
        / denominator(idx);
    formula_error(idx) = max(abs([dynare_lamg(idx) - analytic_lamg(idx), ...
        dynare_qg(idx) - analytic_lamg(idx)]));
    steady_foc_residual(idx) = dynare_qg(idx) ...
        - beta_g * ((1 - delta_g) * dynare_qg(idx) ...
        + gamma_g / kg(idx) * (omega_x ...
        + dynare_lamg(idx) * tau_local * xloc(idx)));
    status(idx) = pass_fail(denominator(idx) > 0 ...
        && formula_error(idx) < 1e-12 ...
        && abs(steady_foc_residual(idx)) < 1e-12);
end
check_table = table(region, xloc, ig, kg, repmat(tau_local, 2, 1), ...
    denominator, analytic_lamg, dynare_lamg, dynare_qg, formula_error, ...
    steady_foc_residual, status, 'VariableNames', {'region', 'xloc', ...
    'public_investment', 'public_capital', 'local_tax_rate', ...
    'denominator', 'analytic_lamg', 'dynare_lamg', 'dynare_qg', ...
    'formula_error', 'steady_foc_residual', 'status'});
writetable(check_table, fullfile(output_dir, ...
    'scheme_A_steady_state_formula_check.csv'));
overall_status = string(pass_fail(all(status == "PASS")));
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
end

function label = pass_fail(condition)
if condition
    label = 'PASS';
else
    label = 'FAIL';
end
end
