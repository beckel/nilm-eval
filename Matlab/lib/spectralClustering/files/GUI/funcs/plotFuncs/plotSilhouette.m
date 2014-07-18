function handles = plotSilhouette(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');

FigureTitle = 'Silhouette';

[handles, handles.figSilhouette] = openPlotFigure(hObject, handles, ...
    'Silhouette', FigureTitle);

indVector = convertClusterVector(handles.ClusteredData);

[S, handles.figSilhouette] = silhouette((handles.Data(plotDimensions, :))', ...
    indVector');

Avg = sum(S) / size(S, 1);
FigureTitle = sprintf('Silhouette (Average: %.3f)', Avg);
title(FigureTitle);

hold off;

guidata(hObject, handles);