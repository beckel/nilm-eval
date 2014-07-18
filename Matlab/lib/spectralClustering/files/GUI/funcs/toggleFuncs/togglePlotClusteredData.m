function handles = togglePlotClusteredData(hObject, handles, state)

set(handles.btnPlotClusteredData, 'Enable', state);

if isequal(handles.foundExportFig, 1)
    set(handles.btnPlotClusteredDataSave, 'Enable', state);
end

guidata(hObject, handles);