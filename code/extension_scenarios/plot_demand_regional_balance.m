function plot_demand_regional_balance()
% Sole three-panel main-text figure for the demand regional-balance experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'code','utils'));
pub=publication_plot_tools(root);
s=get_plot_style();
t=sortrows(pub.readcsv('code/extension_scenarios/demand_regional_balance_moments.csv'),'phi_reg');
assert(isequal(t.phi_reg,[0;.5;1;1.5;2]));
[f,ax]=pub.singlecanvas(8,6.2,[.14 .58 .81 .33]);
x=t.output_gap_sd_x100;y=t.inflation_sd_x100;
p=pub.curve(ax,x,y,1);p.Marker='o';p.MarkerFaceColor='white';p.MarkerSize=5;
dx=max(x)-min(x);dy=max(y)-min(y);
dx=max(dx,1e-4);dy=max(dy,1e-4);
xlim(ax,[min(x)-.12*dx max(x)+.3*dx]);ylim(ax,[min(y)-.18*dy max(y)+.18*dy]);
for k=1:height(t)
    text(ax,x(k)+.025*dx,y(k)+.03*dy,sprintf('$\\phi_{reg}=%.1f$',t.phi_reg(k)), ...
        'Interpreter','latex','FontSize',9,'VerticalAlignment','bottom');
end
xlabel(ax,'Regional dispersion: 100 × sd(Y2 - Y1)','Interpreter','none');
ylabel(ax,{'National inflation volatility','100 × sd(Pi)'},'Interpreter','none');
xtickformat(ax,'%.2f');ytickformat(ax,'%.2f');
title(ax,'(a) Aggregate stability versus regional dispersion', ...
    'FontSize',s.TitleFontSize,'FontWeight','normal');

axs=gobjects(2,1);
positions={[.12 .13 .34 .28],[.62 .13 .34 .28]};
series={t.ds_gap_sd_x100,t.ig_gap_sd_x100};
labels={'100 × sd(DS2 - DS1)','100 × sd(IG2 - IG1)'};
titles={'(b) Debt-service dispersion','(c) Public-investment dispersion'};
for k=1:2
    axs(k)=axes(f,'Position',positions{k});ax=axs(k);hold(ax,'on');
    apply_axes_style(ax,s);
    p=pub.curve(ax,t.phi_reg,series{k},k);
    p.Marker='o';p.MarkerFaceColor='white';p.MarkerSize=4.5;
    xlim(ax,[-.08 2.08]);xticks(ax,t.phi_reg);
    lo=min(series{k});hi=max(series{k});span=max(hi-lo,1e-6);
    ylim(ax,[lo-.12*span hi+.12*span]);
    xlabel(ax,'\phi_{reg}');
    ylabel(ax,labels{k},'Interpreter','none');
    ytickformat(ax,'%.2f');
    title(ax,titles{k},'FontSize',s.TitleFontSize,'FontWeight','normal');
end
export_pair(f,root,'demand_regional_balance_configuration');
end

function export_pair(f,root,name)
base=fullfile(root,'code','extension_scenarios',name);
export_publication_figure(f,[base '.pdf'],[base '.png']);close(f);
end
