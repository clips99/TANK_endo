function result = audit_rank_solution(M_,oo_,options_,outdir)
% Numerical evidence for static/dynamic rank and first-order path accounting.
if exist('simult_','file')~=2
    addpath(fullfile(fileparts(which('dynare')),'stochastic_solver'));
end
export_details=nargin>=4 && ~isempty(outdir);
if export_details && ~isfolder(outdir), mkdir(outdir); end
n=M_.endo_nbr; ss=oo_.steady_state; ex=zeros(1,M_.exo_nbr);
res=feval([M_.fname '.static_resid'],ss,ex,M_.params);
js=feval([M_.fname '.static_g1'],ss,ex,M_.params, ...
    M_.static_g1_sparse_rowval,M_.static_g1_sparse_colval,M_.static_g1_sparse_colptr);
jd=feval([M_.fname '.dynamic_g1'],repmat(ss,3,1),ex,M_.params,ss, ...
    M_.dynamic_g1_sparse_rowval,M_.dynamic_g1_sparse_colval,M_.dynamic_g1_sparse_colptr);
singular=svd(full(js));
result.max_steady_residual=max(abs(res));
result.static_rank=rank(full(js)); result.static_min_singular=min(singular);
result.dynamic_rank=rank(full(jd));
result.finite_paths=true;
result.max_linear_dynamic_residual=0;
result.max_nonlinear_path_residual=0;
result.max_budget_residual=0; result.max_resource_residual=0;
result.max_aggregate_residual=0; result.max_capital_timing_residual=0;
result.max_debt_service_timing_residual=0;
if export_details
eigen=oo_.dr.eigval;
writetable(table((1:numel(eigen))',real(eigen),imag(eigen),abs(eigen), ...
    'VariableNames',{'index','real','imaginary','modulus'}),fullfile(outdir,'eigenvalues.csv'));
writetable(table((1:numel(res))',res,'VariableNames',{'equation','residual'}),fullfile(outdir,'steady_residuals.csv'));
end
get=@(name)find(strcmp(M_.endo_names,name),1);
p=@(name)M_.params(strcmp(M_.param_names,name));
for shock=find(diag(M_.Sigma_e)>0)'
    innovations=zeros(41,M_.exo_nbr); innovations(1,shock)=sqrt(M_.Sigma_e(shock,shock));
    levels=simult_(M_,options_,ss,oo_.dr,innovations,1);
    deviations=levels-ss;
    result.finite_paths=result.finite_paths && all(isfinite(levels),'all') && isreal(levels);
    for h=1:40
        lag=deviations(:,h); now=deviations(:,h+1); lead=deviations(:,h+2);
        linear=jd*[lag;now;lead;innovations(h,:)'];
        result.max_linear_dynamic_residual=max(result.max_linear_dynamic_residual,max(abs(linear)));
        nonlinear=feval([M_.fname '.dynamic_resid'],reshape(levels(:,h:h+2),[],1),innovations(h,:),M_.params,ss);
        result.max_nonlinear_path_residual=max(result.max_nonlinear_path_residual,max(abs(nonlinear)));
        for j=1:2
            v=@(base)get([base num2str(j)]);
            debt=ss(v('rb'))/ss(v('pinf'))*lag(v('b'))+ss(v('b'))/ss(v('pinf'))*lag(v('rb')) ...
                -ss(v('rb'))*ss(v('b'))/ss(v('pinf'))^2*now(v('pinf'));
            budget=now(v('b'))-debt-now(v('g'))-now(v('ig'))-now(v('phiig'))-now(v('phib')) ...
                +(1-p('theta_T'))*p('tau_x')*now(v('xloc'))+now(v('z'));
            resource=now(v('y'))-now(v('c'))-now(v('inv'))-now(v('g'))-now(v('ig'))-now(v('phiig'))-now(v('phib'));
            capital=now(v('kg'))-(1-p('delta_g'))*lag(v('kg'))-now(v('ig'));
            service=(ss(v('rb'))/ss(v('pinf'))-1)*lag(v('b'))/ss(v('xloc')) ...
                +ss(v('b'))/ss(v('xloc'))/ss(v('pinf'))*lag(v('rb')) ...
                -ss(v('rb'))*ss(v('b'))/ss(v('xloc'))/ss(v('pinf'))^2*now(v('pinf')) ...
                -ss(v('ds'))/ss(v('xloc'))*now(v('xloc'));
            result.max_budget_residual=max(result.max_budget_residual,abs(budget));
            result.max_resource_residual=max(result.max_resource_residual,abs(resource));
            result.max_capital_timing_residual=max(result.max_capital_timing_residual,abs(capital));
            result.max_debt_service_timing_residual=max(result.max_debt_service_timing_residual,abs(now(v('ds'))-service));
        end
        relative_price=now(get('q12'))/ss(get('q12'))-now(get('q11'))/ss(get('q11'));
        for base={'xloc','y'}
            if strcmp(base{1},'xloc'), aggregate='xagg'; else, aggregate='yagg'; end
            expected=p('s1')*(ss(get('q12'))/ss(get('q11')))^p('gw2')*(now(get([base{1} '1']))+ss(get([base{1} '1']))*p('gw2')*relative_price) ...
                +p('s2')*(ss(get('q11'))/ss(get('q12')))^p('gw1')*(now(get([base{1} '2']))-ss(get([base{1} '2']))*p('gw1')*relative_price);
            result.max_aggregate_residual=max(result.max_aggregate_residual,abs(now(get(aggregate))-expected));
        end
    end
    if export_details
    paths=array2table(levels(:,2:41)','VariableNames',M_.endo_names);
    paths.period=(1:40)';
    writetable(paths,fullfile(outdir,['path_' char(M_.exo_names{shock}) '.csv']));
    end
end
result.passed=result.max_steady_residual<1e-8 && result.static_rank==n && result.dynamic_rank==n && result.finite_paths ...
    && max([result.max_linear_dynamic_residual,result.max_budget_residual,result.max_resource_residual,result.max_aggregate_residual, ...
    result.max_capital_timing_residual,result.max_debt_service_timing_residual])<1e-8;
if export_details, writetable(struct2table(result),fullfile(outdir,'numerical_checks.csv')); end
end
