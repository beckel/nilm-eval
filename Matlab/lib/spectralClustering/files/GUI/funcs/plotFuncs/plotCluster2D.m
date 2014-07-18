function handles = plotCluster2D(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');
plotTime       = get(handles.chkPlotDisplayTime, 'Value');

FigureTitle = 'Clustered Data';
if isequal(plotTime, 1)
    FigureTitle = [FigureTitle ...
        sprintf(' (clustered in %.2fs)', handles.timeClustering)];
end

[handles, handles.figCluster] = openPlotFigure(hObject, handles, ...
    'Clustered Data (2D)', FigureTitle);

cols = handles.PlotColors;

if handles.NumberOfClusters > 7
    cols = repmat(cols, 1, ...
        1 + ceil(handles.NumberOfClusters / size(cols, 2)));
    warning('Not enough colors. Colors will repeat.');
end

for ii = 1:handles.NumberOfClusters
    currentColor = [cols(mod(ii, size(cols, 2))) getPlotMarkerStyle()];
    
    scatter(handles.Data(plotDimensions(1), handles.ClusteredData(:, ii) == 1), ...
            handles.Data(plotDimensions(2), handles.ClusteredData(:, ii) == 1), ...
            getPlotMarkerSize(), currentColor);
end

hold off;

guidata(hObject, handles);