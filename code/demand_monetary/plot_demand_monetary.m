function plot_demand_monetary()
% Sole formal figure implementation for this experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'code','utils'));
s=get_plot_style();
DS='净实际债务服务负担'; FS='新增融资前财政资源'; KG='公共资本 K_{G,t+1}'; GDP='生产 GDP';
H=(1:40)';
pub=publication_plot_tools(root);
% Figure 4: one fixed debt ratio per curve, joined in increasing phi_pi order.
grid=pub.readcsv('code/demand_monetary/figure4_stability_sync_grid.csv');
debts=[.8 1 1.2 1.4 1.6]; policies=[1.1 1.3 1.5 2 2.5 3];
assert(height(grid)==30 && all(grid.d1_ann==.4));
[f,ax]=pub.singlecanvas(8,5.4,[.13 .25 .83 .68]);
marks={'o','s','d','^','v'};
style_indices=[2 3 4 1 5];
lines=gobjects(numel(debts),1);
for k=1:numel(debts)
    r=sortrows(grid(abs(grid.d2_ann-debts(k))<1e-12,:),'phi_pi');
    assert(height(r)==6 && all(abs(r.phi_pi-policies')<1e-12));
    assert(max(abs(r.reported_output_gap_sd_x100-100*r.unconditional_output_gap_sd))<1e-12);
    assert(max(abs(r.reported_inflation_sd_x100-100*r.unconditional_inflation_sd))<1e-12);
    % Retain each remaining curve's original color, line style and marker.
    style_index=style_indices(k);
    lines(k)=pub.curve(ax,r.reported_output_gap_sd_x100,r.reported_inflation_sd_x100,style_index);
    lines(k).Marker=marks{style_index};lines(k).MarkerIndices=1:6;
    lines(k).MarkerSize=4.5;lines(k).MarkerFaceColor='white';
    if debts(k)==1,lines(k).LineWidth=2.1;lines(k).MarkerSize=5;end
end
shown=grid(ismember(grid.d2_ann,debts),:);
x=shown.reported_output_gap_sd_x100;y=shown.reported_inflation_sd_x100;
dx=max(x)-min(x);dy=max(y)-min(y);
% Tight, linear axes with readable decimal ticks; preserve all model nodes.
xlim(ax,[.025 .425]);xticks(ax,.05:.05:.40);xtickformat(ax,'%.2f');
ylim(ax,[.15 .40]);yticks(ax,.15:.05:.40);ytickformat(ax,'%.2f');
ax.XAxis.Exponent=0;ax.YAxis.Exponent=0;
assert(all(x>ax.XLim(1) & x<ax.XLim(2)) && all(y>ax.YLim(1) & y<ax.YLim(2)));
r=sortrows(grid(abs(grid.d2_ann-1)<1e-12,:),'phi_pi');
for j=1:6
    % Annotation offsets never alter the six model coordinates.
    label_x=r.reported_output_gap_sd_x100(j)+.012*dx;
    label_y=r.reported_inflation_sd_x100(j)+.035*dy;
    text(ax,label_x,label_y, ...
        sprintf('%.1f',r.phi_pi(j)), ...
        'Interpreter','latex','FontSize',9,'VerticalAlignment','bottom');
end
xlabel(ax,'Regional dispersion: 100 × sd(Y2 - Y1)','Interpreter','none');
ylabel(ax,'National inflation volatility: 100 × sd(Pi)','Interpreter','none');
labels=arrayfun(@(d)sprintf('High-debt region debt ratio = %.2f',d),debts,'UniformOutput',false);
legend(ax,lines,labels,'Location','southoutside','NumColumns',2,'Box','off', ...
    'FontName',s.FontName,'FontSize',8.5,'Interpreter','none');
% Preserve the existing axes layout and room for the legend.
ax.Position=[.13 .29 .83 .64];
% Use the shared same-handle exporter without replacing the custom ticks.
base=fullfile(root,'code/demand_monetary/figure4_negative_demand_stability_sync_map');
export_publication_figure(f,[base '.pdf'],[base '.png']);
close(f);fprintf('Figure 4: %s\n',base);
% Figure 10 retains its original five-node baseline-debt data and rendering.
t=sortrows(pub.readcsv('code/demand_monetary/negative_demand_policy_tradeoff_metrics.csv'),'phi_pi');
[f,ax]=pub.singlecanvas(6.6,3.8,[.16 .20 .80 .73]);
p=pub.curve(ax,t.phi_pi,t.regional_output_correlation,1);p.Marker='o';
xlabel(ax,'通胀反应系数 \phi_\pi');ylabel(ax,{'两地产出相关系数','Corr(X^1,X^2)'});
xlim(ax,[min(t.phi_pi)-.08 max(t.phi_pi)+.08]);xticks(ax,t.phi_pi);
ylim(ax,[min(.55,min(t.regional_output_correlation)-.03) max(1.02,max(t.regional_output_correlation)+.02)]);
pub.savefigs(f,ax,10,'code/demand_monetary/figure4_policy_output_correlation',false);

end


