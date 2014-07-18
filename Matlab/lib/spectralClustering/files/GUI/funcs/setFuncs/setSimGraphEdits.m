function handles = setSimGraphEdits(hObject, handles)
% setSimGraphEdits Enables or disables the text edits depending on the
% current similarity graph type

switch handles.SimGraphType
    case 1
        enableNeighbors = 'off';
        enableEps = 'off';
        enableSigma = 'on';
    case {2,3}
        enableNeighbors = 'on';
        enableEps = 'off';
        enableSigma = 'on';
    case 4
        enableNeighbors = 'off';
        enableEps = 'on';
        enableSigma = 'off';
end

set(handles.edtSimGraphNeighbors, 'Enable', enableNeighbors);
set(handles.edtSimGraphEps, 'Enable', enableEps);
set(handles.edtSimGraphSigma, 'Enable', enableSigma);

guidata(hObject, handles);