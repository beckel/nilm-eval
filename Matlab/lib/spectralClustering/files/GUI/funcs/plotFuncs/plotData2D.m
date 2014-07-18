function handles = plotData2D(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');

FigureTitle = 'Data';
[handles, handles.figData] = openPlotFigure(hObject, handles, ...
    'Data Plot (2D)', FigureTitle);

scatter(handles.Data(plotDimensions(1), :), ...
        handles.Data(plotDimensions(2), :), ...
        getPlotMarkerSize(), ...
        ['k' getPlotMarkerStyle()]);
    
hold off;

guidata(hObject, handles);