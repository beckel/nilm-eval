function handles = plotClusterMatrix(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');
plotTime       = get(handles.chkPlotDisplayTime, 'Value');

FigureTitle = 'Clustered Data';
if isequal(plotTime, 1)
    FigureTitle = [FigureTitle ...
        sprintf(' (clustered in %.2fs)', handles.timeClustering)];
end

[handles, handles.figCluster] = openPlotFigure(hObject, handles, ...
    'Clustered Data (Matrix)', FigureTitle);

indMatrix = convertClusterVector(handles.ClusteredData);

% OLD --
%gplotmatrix((handles.Data(plotDimensions, :))', ...
%    (handles.Data(plotDimensions, :))', ...
%    indMatrix);
% -- OLD

gplotmatrix((handles.Data(plotDimensions, :))', ...
    [], ...
    indMatrix, ...
    handles.PlotColors, [], [], 'off');

% Avoid bug
% (gplotmatrix takes away the title created by openPlotFigure)
title(FigureTitle)

hold off;

guidata(hObject, handles);