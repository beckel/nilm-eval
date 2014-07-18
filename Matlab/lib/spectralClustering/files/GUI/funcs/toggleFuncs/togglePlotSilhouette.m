function handles = togglePlotSilhouette(hObject, handles, state)

set(handles.btnPlotSilhouette, 'Enable', state);

if isequal(handles.foundExportFig, 1)
    set(handles.btnPlotSilhouetteSave, 'Enable', state);
end

guidata(hObject, handles);