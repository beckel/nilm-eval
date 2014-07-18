function handles = togglePlotSimGraph(hObject, handles, state)

set(handles.btnPlotSimGraph, 'Enable', state);

if isequal(handles.foundExportFig, 1)
    set(handles.btnPlotSimGraphSave, 'Enable', state);
end

guidata(hObject, handles);