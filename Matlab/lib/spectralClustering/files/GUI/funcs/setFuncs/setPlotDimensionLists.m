function setPlotDimensionLists(hObject, handles)
% setPlotDimensionLists Creates and displays a list of dimensions with the
% length of the currently loaded dataset for the dimension selections

numDimensions = size(handles.Data, 1);
plotDimensions = (1:numDimensions)';

set(handles.lstSelectedDimensions, 'String', ...
    plotDimensions);
set(handles.lstPlotDimensions, 'String', ...
    plotDimensions);

set(handles.lstSelectedDimensions, ...
    'Min', 1, ...
    'Max', numDimensions + 1);
set(handles.lstPlotDimensions, ...
    'Min', 1, ...
    'Max', numDimensions + 1);

guidata(hObject, handles);