function handles = enableDataClustered(hObject, handles)

set(handles.btnSaveData, 'Enable', 'on');
set(handles.btnClusterSave, 'Enable', 'on');

handles = togglePlotSilhouette(hObject, handles, 'on');
handles = togglePlotClusteredData(hObject, handles, 'on');

guidata(hObject, handles);