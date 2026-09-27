function export_publication_figure(fig,pdf_file,png_file)
% Export BOTH artifacts from this fully configured, unchanged figure handle.
% Fixed paper canvas avoids R2026a exportgraphics raster clipping of titles
% and tick glyphs observed in this project's PDF/PNG side-by-side QA.
s=get_plot_style();
fig.Units='inches';
fig.Color='white';
fig.InvertHardcopy='off';
fig.PaperPositionMode='auto';
sz=fig.Position(3:4);
fig.PaperUnits='inches';
fig.PaperSize=sz;
fig.PaperPosition=[0 0 sz];
fig.PaperPositionMode='manual';
drawnow;
% Stage each export to avoid Windows preview locks on a replaced artifact.
staged_pdf=[tempname(fileparts(pdf_file)) '.pdf'];
staged_png=[tempname(fileparts(png_file)) '.png'];
print(fig,staged_pdf,'-dpdf','-painters');
print(fig,staged_png,'-dpng','-painters',['-r' num2str(s.Resolution)]);
movefile(staged_pdf,pdf_file,'f');
movefile(staged_png,png_file,'f');
end
