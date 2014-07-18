function handles = plotDataMatrix(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');

FigureTitle = 'Data';
[handles, handles.figData] = openPlotFigure(hObject, handles, ...
    'Data Plot (Matrix)', FigureTitle);

% OLD --
%plotmatrix((handles.Data(plotDimensions, :))', ...
%    (handles.Data(plotDimensions, :))');
% -- OLD

plotmatrix((handles.Data(plotDimensions, :))');

% Avoid bug
% (plotmatrix takes away the title created by openPlotFigure)
title(FigureTitle)

hold off;

guidata(hObject, handles);