function plot_baseline()
% Sole formal figure implementation for this experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'code','utils'));
s=get_plot_style();
DS='净实际债务服务负担'; FS='新增融资前财政资源'; KG='公共资本 K_{G,t+1}'; GDP='生产 GDP';
H=(1:40)';
pub=publication_plot_tools(root);
% Figure 1: seven panels, GDP spans the bottom row.
b=pub.readmat('code/baseline/RANK_two_region_baseline/Output/RANK_two_region_baseline_results.mat');
labels={'政策利率（全国共同）','通胀',DS,FS,'公共投资',KG,GDP};
vars={'r','pinf','ds','fs','ig','kg','xloc'};
[f,ax]=pub.canvas(7,2.1);
for i=1:7
    pub.paneltitle(ax(i),i,labels{i});
    if i==1,pub.curve(ax(i),H,pub.irf(b,'r'),1);else
        pub.curve(ax(i),H,pub.irf(b,[vars{i} '1']),1);pub.curve(ax(i),H,pub.irf(b,[vars{i} '2']),2);
    end
end
pub.sharedlegend(f,{'低债务地区','高债务地区'},[1 2],2,false);
pub.savefigs(f,ax,1,'code/baseline/baseline_irf_comparison');

end

