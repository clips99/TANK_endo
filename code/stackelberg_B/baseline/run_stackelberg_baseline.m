function run_stackelberg_baseline()
% Solve and validate the two-region Stackelberg baseline.

script_dir = fileparts(mfilename('fullpath'));
caller_dir = pwd;
restore_directory = onCleanup(@() cd(caller_dir));
cd(script_dir); % Dynare writes its generated package beside the model.
addpath(script_dir);

dynare_path = 'C:\dynare\7.0\matlab';
if ~isfolder(dynare_path)
    error('Dynare 7 MATLAB directory not found: %s', dynare_path);
end
addpath(dynare_path, '-begin');
dynare_entry = which('dynare');
if isempty(dynare_entry) || ~contains(dynare_entry, 'dynare\7.0', 'IgnoreCase', true)
    error('Expected Dynare 7.0, but MATLAB resolved dynare to: %s', dynare_entry);
end

root_dir = fileparts(fileparts(script_dir));
validation_dir = fullfile(root_dir, 'stackelberg_B', 'validation');
addpath(validation_dir);

model_file = fullfile(script_dir, 'RANK_two_region_stackelberg.mod');
manifest_file = fullfile(script_dir, 'run_manifest.csv');
run_start = string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
run_id = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
model_sha256 = get_sha256(model_file);
matlab_release = string(version('-release'));
dynare_release = string(dynare_version());
authoritative_log = string(fullfile(validation_dir, 'dynare_console_output.txt'));
write_manifest(manifest_file, run_id, "RUNNING", run_start, "", ...
    model_sha256, matlab_release, dynare_release, 0.0025, 40, ...
    authoritative_log, "PENDING", "PENDING", "Dynare run started");

phase5_status = "NOT_REACHED";
mechanism_status = "NOT_REACHED";
shock_std = NaN;
actual_horizon = 40;
try
    dynare_output = evalc('dynare RANK_two_region_stackelberg.mod noclearall');
    fprintf('%s', dynare_output);
    result = load(fullfile(script_dir, 'RANK_two_region_stackelberg', ...
        'Output', 'RANK_two_region_stackelberg_results.mat'), 'M_', 'oo_', 'options_');
    M_ = result.M_; oo_ = result.oo_; options_ = result.options_;

    phase5_status = export_stackelberg_validation( ...
        M_, oo_, options_, dynare_output, validation_dir);
    mechanism_status = export_stackelberg_irfs(M_, oo_, script_dir);

    shock_index = find(strcmp(M_.exo_names, 'emp'), 1);
    shock_std = sqrt(M_.Sigma_e(shock_index, shock_index));
    actual_horizon = numel(oo_.irfs.r_emp);
    final_status = "PASS";
    if phase5_status ~= "PASS" || mechanism_status ~= "PASS"
        final_status = "FAIL";
    end
    write_manifest(manifest_file, run_id, final_status, run_start, ...
        string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS')), ...
        model_sha256, matlab_release, dynare_release, shock_std, ...
        actual_horizon, authoritative_log, phase5_status, mechanism_status, ...
        "Authoritative console output is the validation text file; the Dynare log may be empty under evalc.");

    fprintf('\nStackelberg baseline runner completed.\n');
    fprintf('  Run id: %s\n', run_id);
    fprintf('  Structural validation: %s\n', phase5_status);
    fprintf('  First-round mechanism audit: %s\n', mechanism_status);

    if phase5_status ~= "PASS"
        error('Structural validation failed; inspect validation CSV files.');
    end
    if mechanism_status ~= "PASS"
        error('First-round mechanism-direction audit failed; inspect baseline_status.csv.');
    end
catch run_exception
    write_manifest(manifest_file, run_id, "FAIL", run_start, ...
        string(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS')), ...
        model_sha256, matlab_release, dynare_release, shock_std, actual_horizon, ...
        authoritative_log, phase5_status, mechanism_status, ...
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
        authoritative_log, phase5_status, mechanism_status, message)
model = "RANK_two_region_stackelberg";
shock = "emp";
manifest = table(run_id, status, start_time, end_time, model, ...
    model_sha256, matlab_release, dynare_release, shock, shock_std, horizon, ...
    authoritative_log, phase5_status, mechanism_status, message);
writetable(manifest, path);
end
