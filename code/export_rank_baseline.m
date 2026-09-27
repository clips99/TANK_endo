function export_rank_baseline()
% Export baseline parameters, steady state and model-variable monetary IRFs.
root=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(root,'code/baseline');
s=load(fullfile(folder,'RANK_two_region_baseline/Output/RANK_two_region_baseline_results.mat'),'M_','oo_');
writetable(table(string(s.M_.endo_names),s.oo_.steady_state,'VariableNames',{'variable','value'}),fullfile(folder,'baseline_steady_state.csv'));
writetable(table(string(s.M_.param_names),s.M_.params,'VariableNames',{'parameter','value'}),fullfile(folder,'baseline_parameters.csv'));
paths=table((1:40)','VariableNames',{'period'});
fields=fieldnames(s.oo_.irfs);
% noclearall can leave other models' fields in oo_.irfs; export only this model.
fields=fields(ismember(string(fields),string(s.M_.endo_names)+"_emp"));
for i=1:numel(fields)
    if endsWith(fields{i},'_emp'),paths.(extractBefore(fields{i},strlength(fields{i})-3))=s.oo_.irfs.(fields{i})(:);end
end
writetable(paths,fullfile(folder,'baseline_full_irf.csv'));
end
