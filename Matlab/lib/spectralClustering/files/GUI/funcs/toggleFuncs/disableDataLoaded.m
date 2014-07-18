function handles = disableDataLoaded(hObject, handles)

set(handles.btnClusterData, 'Enable', 'off');
set(handles.btnClusterSave, 'Enable', 'off');
set(handles.btnSimGraphSave, 'Enable', 'off');

handles = togglePlotSimGraph(hObject, handles, 'off');
handles = togglePlotSilhouette(hObject, handles, 'off');
handles = togglePlotClusteredData(hObject, handles, 'off');

guidata(hObject, handles);