function p = publication_plot_tools(root,intervals,bindingLabel)
% Shared data access, canvas styling and same-handle publication export.
if nargin<2,intervals=zeros(0,2);end
if nargin<3,bindingLabel='';end
s=get_plot_style();
p.readmat=@readmat;
p.readcsv=@readcsv;
p.choose=@choose;
p.irf=@irf;
p.steady=@steady;
p.canvas=@canvas;
p.singlecanvas=@singlecanvas;
p.paneltitle=@paneltitle;
p.curve=@curve;
p.sharedlegend=@sharedlegend;
p.savefigs=@savefigs;

    function r=readmat(rel),r=load(fullfile(root,rel),'oo_','M_');end
    function t=readcsv(rel),t=readtable(fullfile(root,rel),'TextType','string','VariableNamingRule','preserve');end
    function t=choose(t,scenario),t=sortrows(t(t.scenario==scenario,:),'horizon');end
    function y=irf(r,v),y=r.oo_.irfs.([v '_emp'])(:);assert(numel(y)==40&&all(isfinite(y))&&isreal(y));end
    function v=steady(r,name),v=r.oo_.steady_state(strcmp(strtrim(string(r.M_.endo_names)),name));assert(isscalar(v)&&v~=0);end
    function [fig,axs]=canvas(n,rowheight)
        rows=ceil(n/2);height=rows*rowheight+.65;
        fig=figure('Visible','off','Color','white','Units','inches','Position',[1 1 8 height]);
        axs=gobjects(n,1);left=.105;right=.04;bottom=1.04/height;top=.12;
        gapx=.135;gapy=.78;ph=(1-top-bottom)/(rows+(rows-1)*gapy);pw=(1-left-right-gapx)/2;
        for a=1:n
            row=floor((a-1)/2);col=mod(a-1,2);pos=[left+col*(pw+gapx),1-top-(row+1)*ph-row*gapy*ph,pw,ph];
            if n==7&&a==7,pos(3)=1-left-right;end
            axs(a)=axes(fig,'Position',pos);hold(axs(a),'on');apply_axes_style(axs(a),s);
            xlim(axs(a),[1 40]);xticks(axs(a),[1 10 20 30 40]);setappdata(axs(a),'include_zero',true);
            if row==rows-1,xlabel(axs(a),'季度','FontSize',s.LabelFontSize);end
        end
    end
    function [fig,ax]=singlecanvas(w,h,pos)
        fig=figure('Visible','off','Color','white','Units','inches','Position',[1 1 w h]);
        ax=axes(fig,'Position',pos);hold(ax,'on');apply_axes_style(ax,s);setappdata(ax,'include_zero',false);
    end
    function paneltitle(ax,i,label)
        titleObj=title(ax,sprintf('(%s) %s',char(96+i),label),'FontName',s.FontName,...
            'FontSize',s.TitleFontSize,'FontWeight','normal','Interpreter','tex');
        titleObj.Units='normalized';titleObj.Position=[.5 1.30 0];
    end
    function p=curve(ax,x,y,k,mark)
        if nargin<5,mark=false;end
        assert(numel(x)==numel(y)&&all(isfinite(y))&&isreal(y),'Invalid plot data');
        p=plot(ax,x,y,'Color',s.Colors(k,:),'LineStyle',s.LineStyles{k},'LineWidth',s.LineWidth,'Tag','data');
        if mark,p.Marker=s.Markers{k};p.MarkerSize=s.MarkerSize;p.MarkerFaceColor='white';p.MarkerIndices=k:6:numel(y);end
    end
    function sharedlegend(fig,labels,indexes,columns,shaded,markers)
        if nargin<6,markers=s.Markers(indexes);end
        la=axes(fig,'Position',[.10 .012 .85 .055],'Visible','off');hold(la,'on');hs=gobjects(1,numel(labels));
        for z=1:numel(labels),hs(z)=plot(la,nan,nan,'Color',s.Colors(indexes(z),:),...
            'LineStyle',s.LineStyles{indexes(z)},'LineWidth',s.LineWidth,'Marker',markers{z},'MarkerSize',s.MarkerSize,'MarkerFaceColor','white');end
        if shaded,hs(end+1)=patch(la,nan,nan,[.87 .87 .87],'EdgeColor','none');labels{end+1}=bindingLabel;end
        legend(la,hs,labels,'Location','south','Orientation','horizontal','NumColumns',columns,...
            'Box','off','FontName',s.FontName,'FontSize',s.LegendFontSize,'Interpreter','tex');
    end
    function savefigs(fig,axs,num,base,timeaxis,shaded)
        if nargin<5,timeaxis=true;end
        if nargin<6,shaded=false;end
        for a=1:numel(axs)
            ax=axs(a);ls=findobj(ax,'Type','line','Tag','data');ys=[];
            for q=1:numel(ls)
                ys=[ys;ls(q).YData(:)]; %#ok<AGROW>
            end
            if timeaxis||num==7
                if getappdata(ax,'include_zero'),ys=[ys;0];end
                lo=min(ys);hi=max(ys);span=hi-lo;if span<1e-13,span=max(abs(ys))*.1;if span<1e-13,span=1e-8;end,end
                lo=lo-.08*span;hi=hi+.08*span;
                if isappdata(ax,'minimum_upper'),hi=max(hi,getappdata(ax,'minimum_upper'));lo=min(lo,0);end
                ylim(ax,[lo hi]);yticks(ax,linspace(lo,hi,4));
                % Stable exponent based on the full panel, then fixed for export.
                magnitude=max(abs([lo hi]));exponent=floor(log10(magnitude));
                if exponent>-2&&exponent<3,exponent=0;end
                ax.YAxis.Exponent=exponent;ytickformat(ax,'%.1f');
                if exponent==0 && magnitude<1,ytickformat(ax,'%.2f');end
                if ~getappdata(ax,'include_zero'),ax.YAxis.Exponent=0;ytickformat(ax,'%.3f');end
            else
                if num~=10,xticks(ax,linspace(ax.XLim(1),ax.XLim(2),5));end
                yticks(ax,linspace(ax.YLim(1),ax.YLim(2),5));ax.YAxis.Exponent=0;ytickformat(ax,'%.2f');
            end
            if getappdata(ax,'include_zero'),yline(ax,0,':','Color',[.55 .55 .55],'LineWidth',.65,'HandleVisibility','off');end
            if shaded
                yl=ylim(ax);
                for z=1:size(intervals,1)
                    pp=patch(ax,[intervals(z,1)-.5 intervals(z,2)+.5 intervals(z,2)+.5 intervals(z,1)-.5],...
                        [yl(1) yl(1) yl(2) yl(2)],[.87 .87 .87],'EdgeColor','none','HandleVisibility','off');uistack(pp,'bottom');
                end
            end
            apply_axes_style(ax,s);
        end
        export_publication_figure(fig,fullfile(root,[base '.pdf']),fullfile(root,[base '.png']));
        close(fig);fprintf('Figure %d: %s\n',num,base);
    end
end
