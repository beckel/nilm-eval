function handles = plotData3D(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');

FigureTitle = 'Data';
[handles, handles.figData] = openPlotFigure(hObject, handles, ...
    'Data Plot (3D)', FigureTitle);

view(3);

scatter3(handles.Data(plotDimensions(1), :), ...
         handles.Data(plotDimensions(2), :), ...
         handles.Data(plotDimensions(3), :), ...
         getPlotMarkerSize(), ...
         ['k' getPlotMarkerStyle()]);
    
hold off;

guidata(hObject, handles);