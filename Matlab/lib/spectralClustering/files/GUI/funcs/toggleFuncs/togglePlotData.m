function handles = togglePlotData(hObject, handles, state)

set(handles.btnPlotData, 'Enable', state);

if isequal(handles.foundExportFig, 1)
    set(handles.btnPlotDataSave, 'Enable', state);
end

guidata(hObject, handles);