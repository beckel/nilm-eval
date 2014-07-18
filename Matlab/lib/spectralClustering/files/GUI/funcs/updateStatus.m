function handles = updateStatus(hObject, handles, message)
% updateStatus Sets status bar text to 'message'

set(handles.txtStatus, 'String', message);

if strcmp(message(1:4), 'Busy')
    set(handles.txtStatus, 'ForegroundColor', handles.statusColorBusy);
elseif strcmp(message(1:4), 'Done')
    set(handles.txtStatus, 'ForegroundColor', handles.statusColorDone);    
else
    set(handles.txtStatus, 'ForegroundColor', handles.statusColorNone);    
end

drawnow;

guidata(hObject, handles);