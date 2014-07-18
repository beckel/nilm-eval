function handles = updateNormalized(hObject, handles)
% updateNormalized Make visible to user if current dataset is normalized

switch handles.isNormalized
    case 0
        btnWeight = 'bold';
        btnColor  = handles.statusColorBusy;
    case 1
        btnWeight = 'normal';
        btnColor  = handles.statusColorDone;
end
         
set(handles.btnDataNormalize, ...
     'ForegroundColor', btnColor, ...
     'FontWeight', btnWeight);

guidata(hObject, handles);