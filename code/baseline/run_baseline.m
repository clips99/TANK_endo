% Run the baseline mechanism experiment.
%
% Baseline experiment:
%   - regions are symmetric except for steady-state local debt ratios
%   - only the common monetary policy shock is active
%   - diagnostics and Figure 1 are refreshed after Dynare runs

clear;
clc;

script_dir = fileparts(mfilename('fullpath'));
if ~isempty(script_dir)
    cd(script_dir);
end

dynare_path = 'C:\dynare\7.0\matlab';
if isfolder(dynare_path)
    addpath(dynare_path);
end

dynare TANK_two_region_baseline.mod noclearall nolog

run('check_steady_state.m');
run('analyze_baseline_irf.m');
