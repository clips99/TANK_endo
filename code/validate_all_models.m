% Reproducible validation harness for every maintained Dynare model.
% Runs each .mod independently and writes model_validation_status.csv.

clear;
clc;

code_dir = fileparts(mfilename('fullpath'));
addpath(code_dir);
dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

listing = dir(fullfile(code_dir, '**', '*.mod'));
% Include all generated sensitivity variants and exclude solver scratch files.
excluded = contains(string({listing.name}), '_validation_tmp');
listing = listing(~excluded);
rows = table();

for i = 1:numel(listing)
    model_dir = listing(i).folder;
    model_file = listing(i).name;
    [~, model_name] = fileparts(model_file);
    rel_file = string(fullfile(erase(model_dir, [code_dir filesep]), model_file));
    old_dir = pwd;
    cleaner = onCleanup(@() cd(old_dir));
    cd(model_dir);

    status = "ok";
    notes = "";
    n_equations = NaN;
    n_endogenous = NaN;
    max_steady_residual = NaN;
    bk_verified = false;
    diagnostics_verified = false;
    static_rank = NaN; dynamic_rank = NaN;
    finite_paths = false; accounting_verified = false;
    max_linear_dynamic_residual = NaN;
    unstable_roots = NaN; forward_variables = NaN;
    gamma_g = NaN;
    closure = "UNCLASSIFIED";
    scheme_a_denominator_min = NaN;
    % Do not name this flag `occbin`: that would shadow Dynare's +occbin
    % package when the generated driver calls occbin.set_default_options.
    model_source = fileread(model_file);
    is_occbin = contains(model_source, 'occbin_constraints;');
    if contains(model_source, 'muR_1') && contains(model_source, 'muQ_1')
        closure = "STACKELBERG_B_EXTENSION";
    elseif contains(model_source, 'gamma_g / kg1(+1)') ...
            && ~contains(model_source, 'vartheta_g')
        closure = "SCHEME_A_MAIN";
    elseif contains(model_source, 'vartheta_g')
        closure = "RETIRED_PERCEIVED_ELASTICITY";
    end
    try
        original_model_name = model_name;
        if is_occbin
            % Validate the maintained hard-cap file without executing its
            % terminal piecewise solver; the policy generator separately
            % runs the full OccBin simulation and checks cap activation.
            source = fileread(model_file);
            source = regexprep(source, ...
                'shocks\(surprise\);[\s\S]*?occbin_solver\([^;]*\);', '');
            source = [source newline 'stoch_simul(order=1, irf=40, nograph);' newline];
            validation_model_name = [model_name '_validation_tmp'];
            validation_file = [validation_model_name '.mod'];
            fid = fopen(validation_file, 'w');
            if fid < 0
                error('Cannot write temporary validation file for %s.', model_file);
            end
            fwrite(fid, source);
            fclose(fid);
            tmp_cleanup = onCleanup(@() cleanup_validation_artifacts( ...
                model_dir, validation_file, validation_model_name));
            output = evalc(sprintf('dynare %s noclearall nolog', validation_file));
        else
            output = evalc(sprintf('dynare %s noclearall nolog', model_file));
        end
        n_endogenous = M_.endo_nbr;
        n_equations = M_.eq_nbr;
        if iscell(M_.param_names)
            param_names = string(strtrim(M_.param_names));
        else
            param_names = string(strtrim(cellstr(M_.param_names)));
        end
        gamma_idx = find(param_names == "gamma_g", 1);
        if ~isempty(gamma_idx)
            gamma_g = M_.params(gamma_idx);
        end
        if closure == "SCHEME_A_MAIN"
            beta_g = get_parameter(M_, 'beta_g');
            delta_g = get_parameter(M_, 'delta_g');
            theta_T = get_parameter(M_, 'theta_T');
            tau_x = get_parameter(M_, 'tau_x');
            kg1 = get_steady(M_, oo_, 'kg1');
            kg2 = get_steady(M_, oo_, 'kg2');
            xloc1 = get_steady(M_, oo_, 'xloc1');
            xloc2 = get_steady(M_, oo_, 'xloc2');
            denominators = 1 - beta_g * (1 - delta_g) ...
                - beta_g * gamma_g * (1 - theta_T) * tau_x ...
                * [xloc1 / kg1; xloc2 / kg2];
            scheme_a_denominator_min = min(denominators);
            if scheme_a_denominator_min <= 0
                status = "failed";
                notes = "Scheme-A shadow-value denominator is nonpositive";
            end
        end
        numerical = audit_rank_solution(M_,oo_,options_);
        max_steady_residual = numerical.max_steady_residual;
        static_rank = numerical.static_rank;
        dynamic_rank = numerical.dynamic_rank;
        finite_paths = numerical.finite_paths;
        accounting_verified = numerical.passed;
        max_linear_dynamic_residual = numerical.max_linear_dynamic_residual;
        unstable_roots = sum(abs(oo_.dr.eigval)>1+1e-6);
        forward_variables = M_.nfwrd + M_.nboth;
        diagnostics_verified = contains(output,'No obvious problems with this mod-file were detected.');
        bk_verified = contains(output, 'The order and rank conditions are verified.');
        if is_occbin
            % Dynare stores equation metadata differently after OccBin setup;
            % preprocessing/steady/check already succeeded before the
            % piecewise solver, which is exercised by the policy generator.
            bk_verified = contains(output, 'The order and rank conditions are verified.');
            notes = "Relaxed-regime Jacobian/BK/accounting audited; actual piecewise path checked separately in occbin_path_checks.csv";
        elseif ~bk_verified
            status = "failed";
            notes = "Dynare output did not verify the BK order and rank conditions";
        end
        if ~numerical.passed || ~bk_verified || ~diagnostics_verified || n_equations~=n_endogenous
            status = "failed";
            notes = notes + " Numerical/count/diagnostics gate failed; inspect this status row.";
        end
        model_name = original_model_name;
    catch err
        status = "failed";
        notes = string(err.message);
    end
    if exist('tmp_cleanup', 'var')
        clear tmp_cleanup;
    end
    clear cleaner;
    cd(old_dir);

    row = table(rel_file, string(model_name), status, n_equations, ...
        n_endogenous, max_steady_residual, bk_verified, is_occbin, ...
        gamma_g, closure, scheme_a_denominator_min, static_rank, dynamic_rank, ...
        diagnostics_verified, finite_paths, accounting_verified, max_linear_dynamic_residual, ...
        unstable_roots, forward_variables, notes, ...
        'VariableNames', {'file','model','status','n_equations', ...
        'n_endogenous','max_steady_residual','bk_verified','occbin', ...
        'gamma_g','closure','scheme_a_denominator_min','static_rank','dynamic_rank', ...
        'diagnostics_verified','finite_paths','accounting_verified','max_linear_dynamic_residual', ...
        'unstable_roots','forward_variables','notes'});
    rows = [rows; row]; %#ok<AGROW>
    writetable(rows, fullfile(code_dir, 'model_validation_status.csv'));
    fprintf('%d/%d %s: %s\n',i,numel(listing),model_name,status);
end

rows = sortrows(rows, 'file');
writetable(rows, fullfile(code_dir, 'model_validation_status.csv'));
disp(rows(:, {'file','status','n_equations','n_endogenous', ...
    'max_steady_residual','bk_verified','occbin','closure', ...
    'scheme_a_denominator_min'}));

if any(rows.status == "failed")
    error('At least one Dynare model failed validation; inspect model_validation_status.csv.');
end

function value = get_parameter(M_, name)
    names = string(strtrim(M_.param_names));
    index = find(names == string(name), 1);
    if isempty(index)
        error('Parameter not found: %s.', name);
    end
    value = M_.params(index);
end

function value = get_steady(M_, oo_, name)
    names = string(strtrim(M_.endo_names));
    index = find(names == string(name), 1);
    if isempty(index)
        error('Endogenous variable not found: %s.', name);
    end
    value = oo_.steady_state(index);
end

function cleanup_validation_artifacts(model_dir, validation_file, validation_model_name)
    source_path = fullfile(model_dir, validation_file);
    if isfile(source_path)
        delete(source_path);
    end
    generated_paths = {fullfile(model_dir, ['+' validation_model_name]), ...
        fullfile(model_dir, validation_model_name)};
    for j = 1:numel(generated_paths)
        candidate = generated_paths{j};
        if ~startsWith(candidate, [model_dir filesep])
            error('Refusing to clean validation artifact outside model directory.');
        end
        if isfolder(candidate)
            rmdir(candidate, 's');
        end
    end
end
