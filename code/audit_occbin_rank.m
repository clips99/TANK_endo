function audit_occbin_rank()
% Audit the actual piecewise solution, not the unconstrained comparison path.
root=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(root,'code/policy_counterfactual'); old=pwd; cleanup=onCleanup(@()cd(old)); cd(folder);
addpath('C:/dynare/7.0/matlab');
s=load('policy_cf_strict_debt_cap/Output/policy_cf_strict_debt_cap_results.mat');
M=s.M_; o=s.oo_; ss=o.occbin.simul.ys;
% Dynare 7 stores piecewise in levels (the policy exporter also subtracts ys).
dev=o.occbin.simul.piecewise'-ss;
assert(size(dev,1)==M.endo_nbr && size(dev,2)==40);
hist=o.occbin.simul.regime_history; if iscell(hist),hist=hist{1};end
hist=hist(1); binding=false(40,1);
for i=1:numel(hist.regime)
    stop=40;if i<numel(hist.regimestart),stop=min(40,hist.regimestart(i+1)-1);end
    if hist.regime(i)==1,binding(hist.regimestart(i):stop)=true;end
end
idx=@(name)find(strcmp(M.endo_names,name),1);
p=@(name)M.params(strcmp(M.param_names,name));
cap=p('debt_cap2'); debt=ss(idx('b2'))+dev(idx('b2'),:)'; multiplier=ss(idx('xicap2'))+dev(idx('xicap2'),:)';
period=(1:40)';
out=folder;
writetable(table(period,binding,debt,multiplier,cap-debt,'VariableNames',{'period','binding','debt_balance','cap_multiplier','cap_slack'}),fullfile(out,'occbin_regime_history.csv'));
% The generated residual uses a regime parameter; evaluate its exact Jacobian
% and nonzero constant separately for each regime at the common expansion point.
regime_idx=find(strcmp(M.param_names,'occbin_DEBTCAP2_bind'),1);
assert(~isempty(regime_idx),'Missing generated OccBin regime parameter.');
params=M.params; ex=zeros(1,M.exo_nbr); n=M.endo_nbr;
max_res=0;
for h=1:39
    params(regime_idx)=double(binding(h));
    J=feval([M.fname '.dynamic_g1'],repmat(ss,3,1),ex,params,ss,M.dynamic_g1_sparse_rowval,M.dynamic_g1_sparse_colval,M.dynamic_g1_sparse_colptr);
    constant=feval([M.fname '.dynamic_resid'],repmat(ss,3,1),ex,params,ss);
    if h==1,lag=zeros(n,1);else,lag=dev(:,h-1);end
    innovation=zeros(M.exo_nbr,1);if h==1,innovation(strcmp(M.exo_names,'emp'))=.0025;end
    residual=constant+J*[lag;dev(:,h);dev(:,h+1);innovation];
    max_res=max(max_res,max(abs(residual)));
end
finite=all(isfinite(dev),'all')&&isreal(dev);
cap_violation=max(max(debt-cap),0);
binding_residual=max([0;abs(debt(binding)-cap)]);
slack_multiplier=max([0;abs(multiplier(~binding))]);
negative_multiplier=max([0;-multiplier(binding)]);
passed=o.occbin.simul.error_flag==0 && finite && max_res<1e-8 && cap_violation<=p('cap_bind_tol') ...
    && binding_residual<1e-8 && slack_multiplier<1e-8 && negative_multiplier<=p('cap_relax_tol');
checks=table(o.occbin.simul.error_flag,sum(binding),finite,max_res,cap_violation,binding_residual,slack_multiplier,negative_multiplier,passed,...
    'VariableNames',{'solver_error_flag','binding_period_count','finite_real_path','max_piecewise_linear_residual_q1_q39','max_cap_violation',...
    'max_binding_debt_residual','max_slack_multiplier','max_negative_binding_multiplier','passed'});
writetable(checks,fullfile(out,'occbin_path_checks.csv'));
disp(checks);disp(table(period(binding),'VariableNames',{'binding_quarter'}));
assert(passed,'OccBin path validation failed.');
end
