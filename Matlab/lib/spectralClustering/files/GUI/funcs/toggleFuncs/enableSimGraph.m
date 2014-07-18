function handles = enableSimGraph(hObject, handles)

set(handles.btnSimGraphSave, 'Enable', 'on');
set(handles.btnClusterData, 'Enable', 'on');

handles = togglePlotSimGraph(hObject, handles, 'on');

guidata(hObject, handles);