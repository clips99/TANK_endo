function plot_extension_scenarios()
% Sole formal figure implementation for this experiment.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'code','utils'));
s=get_plot_style();
DS='净实际债务服务负担'; FS='新增融资前财政资源'; KG='公共资本 K_{G,t+1}'; GDP='生产 GDP';
H=(1:40)';
pub=publication_plot_tools(root);
% Figure 11: six mechanisms with redundant line/marker encoding.
scenarios={'scenario_01_baseline','scenario_02_risk_premium','scenario_03_transfer_buffer',...
    'scenario_04_risk_and_transfer','scenario_05_strong_io','scenario_06_weak_io'};
[f,ax]=pub.canvas(4,2.35);labels={DS,'公共投资',KG,GDP};vars={'ds','ig','kg','xloc'};
for j=1:6
    r=pub.readmat(['code/extension_scenarios/' scenarios{j} '/Output/' scenarios{j} '_results.mat']);
    for i=1:4,pub.paneltitle(ax(i),i,[labels{i} '响应差']);pub.curve(ax(i),H,pub.irf(r,[vars{i} '2'])-pub.irf(r,[vars{i} '1']),j,true);end
end
pub.sharedlegend(f,{'基准','风险溢价','逆周期转移缓冲','风险溢价与逆周期转移缓冲','强跨地区联系','弱跨地区联系'},1:6,3,false);
pub.savefigs(f,ax,11,'code/extension_scenarios/extension_scenario_diff_irfs');

end

