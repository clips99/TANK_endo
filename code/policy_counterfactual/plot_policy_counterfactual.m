function plot_policy_counterfactual()
% Sole formal figure implementation for this experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'code','utils'));
s=get_plot_style();
DS='净实际债务服务负担'; FS='新增融资前财政资源'; KG='公共资本 K_{G,t+1}'; GDP='生产 GDP';
H=(1:40)';
cap=load(fullfile(root,'code/policy_counterfactual/policy_cf_strict_debt_cap/Output/policy_cf_strict_debt_cap_results.mat'),'oo_');
hist=cap.oo_.occbin.simul.regime_history;
if iscell(hist), hist=hist{1}; end
hist=hist(1); intervals=zeros(0,2);
for k=1:numel(hist.regime)
    if hist.regime(k)==1
        last=40; if k<numel(hist.regimestart),last=hist.regimestart(k+1)-1;end
        intervals(end+1,:)=[hist.regimestart(k) last]; %#ok<AGROW>
    end
end
bindingLabel='实际绑定期：无';
if ~isempty(intervals)
    parts=strings(size(intervals,1),1);
    for k=1:size(intervals,1)
        if intervals(k,1)==intervals(k,2),parts(k)=string(intervals(k,1));
        else,parts(k)=sprintf('%d–%d',intervals(k,:));end
    end
    bindingLabel=char('实际绑定期（季度 '+strjoin(parts,', ')+')');
end

pub=publication_plot_tools(root,intervals,bindingLabel);
% Figure 5 (two blocks), 8 and 9: OccBin binding comes from the NEW run.
t=pub.readcsv('code/policy_counterfactual/policy_counterfactual_irf_series.csv');
base=pub.choose(t,'policy_cf_baseline');cap=pub.choose(t,'policy_cf_strict_debt_cap');
labels={'限额使用率 B_t^2 / B_{max}^2','公共投资',KG,GDP};vars={'u2','ig2','kg2','xloc2'};
for difference=0:1
    [f,ax]=pub.canvas(4,2.1);
    for i=1:4
        lab=labels{i};if difference,lab=[lab '政策差'];end
        pub.paneltitle(ax(i),i,lab);
        if difference,pub.curve(ax(i),base.horizon,cap.(vars{i})-base.(vars{i}),2);
        else
            pub.curve(ax(i),base.horizon,base.(vars{i}),1);pub.curve(ax(i),base.horizon,cap.(vars{i}),2);
            if i==1,setappdata(ax(i),'include_zero',false);yline(ax(i),1,':','上限 = 1','FontName',s.FontName,'FontSize',8.5);end
        end
    end
    if difference
        pub.sharedlegend(f,{'严格限额情景减基准情景'},2,2,true);name='figure5_debt_limit_diff_irfs';
    else
        pub.sharedlegend(f,{'基准情景','严格限额情景'},[1 2],3,true);name='figure5_debt_limit_high_debt_irfs';
    end
    pub.savefigs(f,ax,5,['code/policy_counterfactual/' name],true,true);
end
[f,ax]=pub.canvas(8,2.1);labels={DS,FS,'公共投资',GDP};vars={'ds','fs','ig','xloc'};
for i=1:4
    for j=1:2
        n=2*(i-1)+j;prefix={'低债务：','高债务：'};pub.paneltitle(ax(n),n,[prefix{j} labels{i}]);v=[vars{i} num2str(j)];
        pub.curve(ax(n),base.horizon,base.(v),1);pub.curve(ax(n),base.horizon,cap.(v),2);
    end
end
pub.sharedlegend(f,{'基准情景','严格限额情景'},[1 2],3,true);
pub.savefigs(f,ax,8,'code/policy_counterfactual/figure5_debt_limit_region_irfs',true,true);
[f,ax]=pub.canvas(4,2.35);labels={'年化债务率 B_t^2 / (4X_t^2)',DS};vars={'debt_ratio2','ds2'};
for i=1:2
    pub.paneltitle(ax(i),i,labels{i});pub.curve(ax(i),base.horizon,base.(vars{i}),1);pub.curve(ax(i),base.horizon,cap.(vars{i}),2);
    pub.paneltitle(ax(i+2),i+2,[labels{i} '政策差']);pub.curve(ax(i+2),base.horizon,cap.(vars{i})-base.(vars{i}),2);
end
pub.sharedlegend(f,{'基准情景','严格限额情景'},[1 2],3,true);
pub.savefigs(f,ax,9,'code/policy_counterfactual/figure5_debt_limit_fiscal_details',true,true);

% Figure 6: two transfer regimes.
t=pub.readcsv('code/policy_counterfactual/policy_counterfactual_transfer_irf_series.csv');
[f,ax]=pub.canvas(6,2.1);labels={'中央转移支付',DS,FS,'公共投资',KG,GDP};vars={'z2','ds2','fs2','ig2','kg2','xloc2'};
scenarios={'policy_cf_no_transfer_stabilizer','policy_cf_central_transfer_stabilizer'};
for i=1:6
    pub.paneltitle(ax(i),i,labels{i});
    for j=1:2,r=pub.choose(t,scenarios{j});pub.curve(ax(i),r.horizon,r.(vars{i}),j);end
end
pub.sharedlegend(f,{'无逆周期转移反馈','有逆周期转移反馈'},1:2,2,false);
pub.savefigs(f,ax,6,'code/policy_counterfactual/figure6_central_transfer_high_debt_irfs');

% Figure 12: standard / regional-balance Taylor rules.
t=pub.readcsv('code/policy_counterfactual/policy_counterfactual_regional_balance_irf_series.csv');
[f,ax]=pub.canvas(6,2.1);labels={DS,FS,'公共投资',KG,GDP,'地区通胀'};
vars={'ds_gap','fs_gap','ig_gap','kg_gap','y_gap','pinf_gap'};
scenarios={'policy_cf_standard_taylor','policy_cf_regional_balance_taylor'};
for i=1:6
    pub.paneltitle(ax(i),i,[labels{i} '响应差']);
    for j=1:2,r=pub.choose(t,scenarios{j});pub.curve(ax(i),r.horizon,r.(vars{i}),j);end
end
pub.sharedlegend(f,{'标准 Taylor 规则','地区平衡型 Taylor 规则'},1:2,2,false);
pub.savefigs(f,ax,12,'code/policy_counterfactual/figure7_regional_balance_gap_irfs');
end

