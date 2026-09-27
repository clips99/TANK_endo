function plot_debt_intensity()
% Sole formal figure implementation for this experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'code','utils'));
s=get_plot_style();
DS='净实际债务服务负担'; FS='新增融资前财政资源'; KG='公共资本 K_{G,t+1}'; GDP='生产 GDP';
H=(1:40)';
pub=publication_plot_tools(root);
% Figure 2: retain the original four-point design.
t=pub.readcsv('code/debt_intensity/debt_intensity_irf_series.csv');
metrics={'Net real debt-service burden','Public investment','Public capital','Production GDP'};
labels={DS,'公共投资',KG,GDP}; [f,ax]=pub.canvas(4,2.35);
for i=1:4
    pub.paneltitle(ax(i),i,[labels{i} '响应差']);
    for j=1:4
        ratios=[.4 .8 1.2 1.6]; r=t(t.metric==metrics{i}&abs(t.debt_ratio-ratios(j))<1e-9,:);
        r=sortrows(r,'horizon');pub.curve(ax(i),r.horizon,r.diff_irf,j,true);
    end
end
pub.sharedlegend(f,{'地区2稳态年化债务率 = 40%','地区2稳态年化债务率 = 80%',...
    '地区2稳态年化债务率 = 120%','地区2稳态年化债务率 = 160%'},1:4,2,false);
pub.savefigs(f,ax,2,'code/debt_intensity/figure2_debt_intensity_gap_irfs');

end

