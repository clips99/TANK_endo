function plot_stackelberg_irf_compare()
% Sole appendix C.2 figure: frozen baseline A/B IRFs, no model re-solving.
here=fileparts(mfilename('fullpath'));
root=fileparts(fileparts(fileparts(fileparts(here))));
addpath(fullfile(root,'code','utils'));
pub=publication_plot_tools(root);s=get_plot_style();
prefix='code/stackelberg_B/robustness/sensitivity_sanity/';
A=pub.readmat([prefix 'generated/baseline/A/RANK_scheme_A_baseline/Output/RANK_scheme_A_baseline_results.mat']);
B=pub.readmat([prefix 'generated/baseline/B/RANK_scheme_B_baseline/Output/RANK_scheme_B_baseline_results.mat']);
% Shadow-value targets depend on the government closure; common calibration
% and the innovation covariance must otherwise agree across the two models.
[names,ia,ib]=intersect(string(A.M_.param_names),string(B.M_.param_names));
keep=~ismember(names,["lamgbar1","lamgbar2","qgbar1","qgbar2"]);
assert(max(abs(A.M_.params(ia(keep))-B.M_.params(ib(keep))))<1e-12);
assert(isequal(A.M_.exo_names,B.M_.exo_names) && isequal(A.M_.Sigma_e,B.M_.Sigma_e));
frozen=pub.readcsv([prefix 'sensitivity_gap_irf_series.csv']);
summary=pub.readcsv([prefix 'sensitivity_summary.csv']);
H=(1:40)';vars={'ig','kg','xloc'};
titles={'(a) 公共投资地区差','(b) 公共资本地区差','(c) 生产 GDP 地区差'};
[f,first]=pub.singlecanvas(8,3.4,[.085 .30 .235 .53]);
axs=gobjects(3,1);axs(1)=first;
for j=1:3
    if j>1
        axs(j)=axes(f,'Position',[.085+(j-1)*.325 .30 .235 .53]);
        hold(axs(j),'on');apply_axes_style(axs(j),s);
    end
    ax=axs(j);v=vars{j};low=[v '1'];high=[v '2'];
    % Normalize each region by its own steady state BEFORE taking the gap.
    gapA=pub.irf(A,high)/pub.steady(A,high)-pub.irf(A,low)/pub.steady(A,low);
    gapB=pub.irf(B,high)/pub.steady(B,high)-pub.irf(B,low)/pub.steady(B,low);
    old=sortrows(frozen(frozen.scenario_id=="baseline" & frozen.variable==v,:),'period');
    assert(height(old)==40 && isequal(old.period,H));
    assert(max(abs(gapA-old.gap_A))<1e-12 && max(abs(gapB-old.gap_B))<1e-12);
    row=summary(summary.scenario_id=="baseline" & summary.variable==v & summary.scope=="high_minus_low",:);
    assert(height(row)==1 && abs(sum(gapA(1:12))-row.cumulative_A)<1e-12 ...
        && abs(sum(gapB(1:12))-row.cumulative_B)<1e-12);
    pub.curve(ax,H,gapA,1);pub.curve(ax,H,gapB,2);
    title(ax,titles{j},'FontSize',s.TitleFontSize,'FontWeight','normal');
    xlabel(ax,'季度');ylabel(ax,'标准化地区差');
    xlim(ax,[1 40]);xticks(ax,[1 10 20 30 40]);
    % Shared limits are computed from BOTH settings within each panel.
    setappdata(ax,'include_zero',true);
    fprintf('%s: max |B-A| = %.9g; first-12 sums A/B = %.9g / %.9g\n', ...
        v,max(abs(gapB-gapA)),sum(gapA(1:12)),sum(gapB(1:12)));
end
pub.sharedlegend(f,{'Baseline local-decision','Stackelberg extension'},1:2,2,false,{'none','none'});
% The helper scales axes only; it never rescales or offsets either IRF.
pub.savefigs(f,axs,8,[prefix 'figure_AB_irf_compare'],true);
end
