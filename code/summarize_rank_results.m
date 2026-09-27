function summary = summarize_rank_results()
% Reproduce derived manuscript quantities from formal CSVs; no TeX generation.
folder=fileparts(mfilename('fullpath'));
summary=table(strings(0,1),zeros(0,1),'VariableNames',{'quantity','value'});
ss=read('baseline/baseline_steady_state.csv');
par=read('baseline/baseline_parameters.csv');
v=@(name)ss.value(ss.variable==name);
p=@(name)par.value(par.parameter==name);
put('central_steady_balance',p('theta_T')*p('tau_x')*(p('s1')*v('xloc1')+p('s2')*v('xloc2'))-p('s1')*v('z1')-p('s2')*v('z2'));
put('household_net_outflow',v('xloc1')-v('c1')-v('inv1'));
put('scheme_A_denominator',1-p('beta_g')*(1-p('delta_g'))-p('beta_g')*p('gamma_g')*(1-p('theta_T'))*p('tau_x')*v('xloc1')/v('kg1'));
b=read('baseline/baseline_full_irf.csv');
put('baseline_ds_peak_ratio',max(b.ds2)/max(b.ds1));
put('baseline_fs_trough_ratio',min(b.fs2)/min(b.fs1));
put('baseline_ig_trough_ratio',min(b.ig2)/min(b.ig1));
for name=["ds1","ds2","fs1","fs2","ig1","ig2","kg1","kg2"]
    pathstats("baseline_"+name,b.(name));
end
d=read('debt_intensity/debt_intensity_irf_series.csv');
put('symmetric_debt_max_gap',max(abs(d.diff_irf(abs(d.debt_ratio-.4)<1e-10))));
for name=["Net real debt-service burden","Public investment","Public capital"]
    r=sortrows(d(abs(d.debt_ratio-1.6)<1e-10 & d.metric==name,:),'horizon');
    pathstats("debt160_"+matlab.lang.makeValidName(name),r.diff_irf);
end
t=sortrows(read('demand_monetary/negative_demand_policy_tradeoff_metrics.csv'),'phi_pi');
put('demand_inflation_sd_reduction_pct',100*(1-t.reported_inflation_sd_x100(end)/t.reported_inflation_sd_x100(1)));
t=read('scale_development/scale_development_irf_series.csv');
for scenario=unique(t.scenario)'
    for name=["Net real debt-service burden","Public investment","Local production GDP"]
        row=t(t.scenario==scenario & t.metric==name & t.horizon==1,:);
        assert(height(row)==1,'Missing scale-experiment impact.');
        put(scenario+"_"+matlab.lang.makeValidName(name)+"_impact_pct",100*row.less_developed_normalized_response);
    end
end
t=read('policy_counterfactual/policy_counterfactual_transfer_irf_series.csv');
a=sortrows(t(t.scenario=="policy_cf_no_transfer_stabilizer",:),'horizon');
z=sortrows(t(t.scenario=="policy_cf_central_transfer_stabilizer",:),'horizon');
for name=["ig2","kg2"]
    put("transfer_"+name+"_trough_improvement_pct",100*(1-min(z.(name))/min(a.(name))));
    pathstats("transfer_"+name,z.(name));
end
pathstats('transfer_z2',z.z2);
t=read('policy_counterfactual/policy_counterfactual_irf_series.csv');
a=sortrows(t(t.scenario=="policy_cf_baseline",:),'horizon');
z=sortrows(t(t.scenario=="policy_cf_strict_debt_cap",:),'horizon');
for name=["ig2","kg2","xloc2"]
    pathstats("cap_minus_baseline_"+name,z.(name)-a.(name));
end
t=read('stackelberg_B/robustness/sensitivity_sanity/sensitivity_summary.csv');
put('stackelberg_max_effective_ratio',max(t.effective_ratio));
put('stackelberg_gap_max_effective_ratio',max(t.effective_ratio(t.scope=="high_minus_low")));
writetable(summary,fullfile(folder,'numerical_summary.csv'));
disp(summary);
    function t=read(rel)
        t=readtable(fullfile(folder,rel),'TextType','string');
    end
    function put(name,value)
        summary(end+1,:)={string(name),value};
    end
    function pathstats(name,x)
        assert(numel(x)==40 && all(isfinite(x)),'Invalid path: %s',name);
        [lo,qlo]=min(x);[hi,qhi]=max(x);
        put(name+"_minimum",lo);put(name+"_minimum_quarter",qlo);
        put(name+"_maximum",hi);put(name+"_maximum_quarter",qhi);
        put(name+"_quarter40",x(end));
        crossing=find(x(qlo+1:end)>=0,1);
        if isempty(crossing),crossing=NaN;else,crossing=crossing+qlo;end
        put(name+"_post_trough_crossing_quarter",crossing);
    end
end
