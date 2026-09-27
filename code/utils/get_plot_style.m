function s = get_plot_style()
% Shared publication style for the manuscript's fixed plotting areas.
s.FontName = 'Microsoft YaHei';
s.AxisFontSize = 9;
s.LabelFontSize = 10;
s.TitleFontSize = 10.5;
s.LegendFontSize = 10;
s.LineWidth = 1.65;
s.MarkerSize = 3.5;
s.AxisLineWidth = 0.65;
s.Resolution = 600;
s.Colors = [0 114 178;213 94 0;0 158 115;204 121 167;122 101 0;86 86 86]/255;
s.LineStyles = {'-','--','-.',':','--',':'};
s.Markers = {'none','none','o','s','^','d'};
end
