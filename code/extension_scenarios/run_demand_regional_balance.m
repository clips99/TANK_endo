function run_demand_regional_balance()
% Demand-only regional-balance configuration experiment; no welfare ranking.
% Reuses the maintained demand baseline, nonlinear policy convention, Dynare,
% audit_rank_solution and publication tools. Does not run other experiments.
here=fileparts(mfilename('fullpath'));
code_dir=fileparts(here);
addpath(here,code_dir,fullfile(code_dir,'utils'));
addpath('C:/dynare/7.0/matlab');
caller=pwd; restore=onCleanup(@()cd(caller));
cd(here);
demand_dir=fullfile(code_dir,'demand_monetary');
source=fileread(fullfile(demand_dir,'negative_demand_baseline_policy.mod'));
source=strrep(source,sprintf('\r\n'),sprintf('\n'));
reference=load(fullfile(demand_dir,'negative_demand_baseline_policy','Output', ...
    'negative_demand_baseline_policy_results.mat'),'M_','oo_');
phis=[0 .5 1 1.5 2];
names=arrayfun(@(p)sprintf('demand_regional_balance_%03d',round(100*p)),phis,'UniformOutput',false);
% Generate all sources before Dynare retains generated-file handles on Windows.
for k=1:numel(phis)
    text=replace_once(source,'phi_pi phi_x tau_x theta_T','phi_pi phi_x phi_reg tau_x theta_T');
    text=replace_once(text,sprintf('\nmodel;'),sprintf('\nphi_reg = %.8g;\n\nmodel;',phis(k)));
    old='* ((pinfagg / pinfbar)^phi_pi * (xagg / xbar)^phi_x)^(1 - rho_r)';
    new=['* ((pinfagg / pinfbar)^phi_pi * (xagg / xbar)^phi_x' ...
        ' * ((xloc2 / xbar2) / (xloc1 / xbar1))^phi_reg)^(1 - rho_r)'];
    text=replace_once(text,old,new);
    write_source(fullfile(here,[names{k} '.mod']),text);
end
metrics=table(); irfs=table(); status=table();
for k=1:numel(phis)
    phi=phis(k); name=names{k};
    fprintf('\n=== Demand regional balance: phi_reg=%.1f ===\n',phi);
    transcript=evalc(sprintf('dynare %s.mod noclearall nolog',name));
    solved=load(fullfile(here,name,'Output',[name '_results.mat']),'M_','oo_','options_');
    M=solved.M_; o=solved.oo_;
    assert_parameters_and_shock(M,reference.M_,phi);
    audit=audit_rank_solution(M,o,solved.options_);
    bk=contains(transcript,'The order and rank conditions are verified.');
    diagnostics=contains(transcript,'No obvious problems with this mod-file were detected.');
    unstable=sum(abs(o.dr.eigval)>1+1e-6); forward=M.nfwrd+M.nboth;
    assert(audit.passed && bk && diagnostics && unstable==forward && M.eq_nbr==M.endo_nbr, ...
        'Steady/BK/diagnostics/accounting gate failed at phi_reg=%.1f',phi);
    values=moments(o);
    metrics=[metrics;array2table([phi values], ...
        'VariableNames',{'phi_reg','inflation_sd_x100','output_sd_x100', ...
        'output_gap_sd_x100','regional_output_correlation','ds_gap_sd_x100','ig_gap_sd_x100'})]; %#ok<AGROW>
    path=collect_irfs(M,o,phi);
    irfs=[irfs;path]; %#ok<AGROW>
    % The extra response is inside the inertial target, as are phi_pi/phi_x.
    rbar=param(M,'rbar'); rho=param(M,'rho_r');
    residual=path.r/rbar-rho*[0;path.r(1:end-1)]/rbar ...
        -(1-rho)*(param(M,'phi_pi')*path.pinfagg/param(M,'pinfbar') ...
        +param(M,'phi_x')*path.xagg/param(M,'xbar'))-path.regional_policy_component;
    rule_error=max(abs(residual));
    assert(rule_error<1e-10,'Linear policy sign/timing check failed.');
    status=[status;table(phi,"ok",audit.max_steady_residual, ...
        audit.static_rank,audit.dynamic_rank,unstable,forward,bk,diagnostics, ...
        audit.max_linear_dynamic_residual,rule_error, ...
        'VariableNames',{'phi_reg','status','max_steady_residual','static_rank', ...
        'dynamic_rank','unstable_roots','forward_variables','bk_verified', ...
        'diagnostics_verified','max_linear_dynamic_residual','policy_rule_residual'})]; %#ok<AGROW>
    writetable(status,fullfile(here,'demand_regional_balance_status.csv'));
    if phi==0
        comparison=compare_baseline(M,o,reference.M_,reference.oo_);
        writetable(comparison,fullfile(here,'demand_regional_balance_baseline_check.csv'));
        assert(all(comparison.passed),'phi_reg=0 does not reproduce the current demand baseline.');
    end
end
writetable(metrics,fullfile(here,'demand_regional_balance_moments.csv'));
writetable(irfs,fullfile(here,'demand_regional_balance_irf_series.csv'));
mechanism=metrics(:,{'phi_reg','ds_gap_sd_x100','ig_gap_sd_x100'});
mechanism.ds_change_pct=100*(mechanism.ds_gap_sd_x100/mechanism.ds_gap_sd_x100(1)-1);
mechanism.ig_change_pct=100*(mechanism.ig_gap_sd_x100/mechanism.ig_gap_sd_x100(1)-1);
writetable(mechanism,fullfile(here,'demand_regional_balance_mechanism.csv'));
plot_demand_regional_balance();
disp(metrics); disp(comparison); disp(status);
end

function assert_parameters_and_shock(M,ref,phi)
names=cellstr(string(ref.param_names));
for k=1:numel(names)
    assert(param(M,names{k})==param(ref,names{k}),'Changed baseline parameter: %s',names{k});
end
assert(param(M,'d_ann1')==.4 && param(M,'d_ann2')==1 && param(M,'phi_pi')==1.5);
assert(param(M,'phi_reg')==phi && param(M,'rho_d')==.8);
assert(isequal(M.Sigma_e,ref.Sigma_e));
ed=find(strcmp(cellstr(string(M.exo_names)),'ed'));
assert(isscalar(ed) && nnz(M.Sigma_e)==1 && abs(M.Sigma_e(ed,ed)-.0025^2)<1e-18);
end

function v=param(M,name)
i=find(strcmp(cellstr(string(M.param_names)),name)); assert(isscalar(i)); v=M.params(i);
end

function values=moments(o)
a=sd(covariance(o,'pinfagg','pinfagg')); b=sd(covariance(o,'xagg','xagg'));
c=sd(gapvar(o,'xloc2','xloc1'));
d=covariance(o,'xloc1','xloc2')/sqrt(covariance(o,'xloc1','xloc1')*covariance(o,'xloc2','xloc2'));
e=sd(gapvar(o,'ds2','ds1')); f=sd(gapvar(o,'ig2','ig1'));
values=[100*a 100*b 100*c d 100*e 100*f];
assert(all(isfinite(values)) && isreal(values));
end

function v=covariance(o,a,b)
names=cellstr(string(o.var_list)); i=find(strcmp(names,a)); j=find(strcmp(names,b));
assert(isscalar(i)&&isscalar(j)); v=.5*(o.var(i,j)+o.var(j,i));
end

function v=gapvar(o,a,b)
v=covariance(o,a,a)+covariance(o,b,b)-2*covariance(o,a,b);
end

function s=sd(v)
assert(v>=-1e-12*max(1,abs(v)),'Negative theoretical variance.'); s=sqrt(max(v,0));
end

function t=collect_irfs(M,o,phi)
% Positive ed is a negative demand innovation: d = rho_d*d(-1) - ed.
vars={'d','r','pinfagg','xagg','xloc1','xloc2','ds1','ds2','fs1','fs2','ig1','ig2','kg1','kg2'};
t=table(repmat(phi,40,1),(1:40)','VariableNames',{'phi_reg','horizon'});
for j=1:numel(vars)
    v=o.irfs.([vars{j} '_ed']); assert(numel(v)==40 && all(isfinite(v)) && isreal(v));
    t.(vars{j})=v(:);
end
assert(abs(t.d(1)+.0025)<1e-12,'Wrong sign or scale of demand innovation.');
t.output_gap=t.xloc2-t.xloc1;t.ds_gap=t.ds2-t.ds1;
t.fs_gap=t.fs2-t.fs1;t.ig_gap=t.ig2-t.ig1;
t.regional_policy_component=(1-param(M,'rho_r'))*phi ...
    *(t.xloc2/param(M,'xbar2')-t.xloc1/param(M,'xbar1'));
end

function t=compare_baseline(M,o,refM,ref)
% Compare every covariance entry and every demand IRF, not rounded CSV values.
[found,idx]=ismember(string(ref.var_list),string(o.var_list)); assert(all(found));
a=o.var(idx,idx); b=ref.var;
cov_error=max(abs(a-b),[],'all'); cov_exact=isequaln(a,b);
fields=fieldnames(ref.irfs); irf_error=0; irf_exact=true;
for j=1:numel(fields)
    if ~endsWith(fields{j},'_ed'),continue;end
    a=o.irfs.(fields{j}); b=ref.irfs.(fields{j});
    irf_error=max(irf_error,max(abs(a(:)-b(:)))); irf_exact=irf_exact&&isequaln(a,b);
end
[found,idx]=ismember(string(refM.endo_names),string(M.endo_names)); assert(all(found));
a=o.steady_state(idx); b=ref.steady_state;
ss_error=max(abs(a-b));ss_exact=isequaln(a,b);
mv=moments(o);rv=moments(ref);
metric_error=max(abs(mv-rv)); metric_exact=isequaln(mv,rv);
t=table(["steady_state";"all_covariances";"all_demand_irfs";"six_reported_moments"], ...
    [ss_error;cov_error;irf_error;metric_error],[ss_exact;cov_exact;irf_exact;metric_exact], ...
    'VariableNames',{'comparison','max_abs_error','bitwise_equal'});
t.tolerance=repmat(1e-10,height(t),1);t.passed=t.max_abs_error<t.tolerance;
end

function text=replace_once(text,old,new)
assert(numel(strfind(text,old))==1,'Expected one source match: %s',old);
text=strrep(text,old,new);
end

function write_source(file,text)
fid=fopen(file,'w'); assert(fid>=0,'Cannot write %s',file);
cleanup=onCleanup(@()fclose(fid)); fwrite(fid,text);
end
