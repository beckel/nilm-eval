function handles = setCurrentSimGraphProperties(hObject, handles)
% setCurrentSimGraphProperties Updates the current similarity graph
% information

handles.currentSimGraphType      = handles.SimGraphType;
handles.currentSimGraphNeighbors = get(handles.edtSimGraphNeighbors, 'String');
handles.currentSimGraphEps       = get(handles.edtSimGraphEps, 'String');
handles.currentSimGraphSigma     = get(handles.edtSimGraphSigma, 'String');

guidata(hObject, handles);