function handles = enableDataLoaded(hObject, handles)

set(handles.btnSimGraphCreate, 'Enable', 'on');
set(handles.btnSimGraphLoad, 'Enable', 'on');
set(handles.btnDataNormalize, 'Enable', 'on');
set(handles.btnSaveData, 'Enable', 'on');

handles = togglePlotData(hObject, handles, 'on');

guidata(hObject, handles);