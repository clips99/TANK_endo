function run_baseline()
% Solve the baseline, export numerical results and generate manuscript Figure 1.
%
% Baseline experiment:
%   - regions are symmetric except for steady-state local debt ratios
%   - only the common monetary policy shock is active
%   - diagnostics and Figure 1 are refreshed after Dynare runs

script_dir = fileparts(mfilename('fullpath'));
caller_dir = pwd;
restore_directory = onCleanup(@() cd(caller_dir));
addpath(script_dir,fileparts(script_dir));
cd(script_dir); % Dynare generates its package beside the model.

dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

% Keep the Dynare log synchronized with the maintained model; a stale log
% can otherwise appear to document an obsolete calibration.
dynare RANK_two_region_baseline.mod noclearall

check_steady_state();
analyze_baseline_irf();
export_rank_baseline();
plot_baseline();
end
