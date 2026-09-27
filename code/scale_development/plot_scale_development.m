function plot_scale_development()
% Sole formal figure implementation for this experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'code','utils'));
s=get_plot_style();
DS='净实际债务服务负担'; FS='新增融资前财政资源'; KG='公共资本 K_{G,t+1}'; GDP='生产 GDP';
H=(1:40)';
pub=publication_plot_tools(root);
% Figure 3: own steady-state normalization, with no extra factor of 100.
[f,ax]=pub.canvas(8,2.1); labels={'政策利率（全国共同）',DS,FS,'公共投资',KG,GDP,'总消费','通胀'};
vars={'r','ds2','fs2','ig2','kg2','xloc2','c2','pinf2'};
for j=1:3
    suffixes={'100','150','200'}; model=['scale_development_y' suffixes{j}];
    r=pub.readmat(['code/scale_development/' model '/Output/' model '_results.mat']);
    for i=1:8,pub.paneltitle(ax(i),i,labels{i});pub.curve(ax(i),H,pub.irf(r,vars{i})/pub.steady(r,vars{i}),j,true);end
end
pub.sharedlegend(f,{'r = 1','r = 1.5','r = 2'},1:3,3,false);
pub.savefigs(f,ax,3,'code/scale_development/figure3_scale_development_region2_irfs');

end

