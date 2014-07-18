function handles = updateDataInfo(hObject, handles)
% updateDataInfo Sets the information in the Dataset panel

datasize = size(handles.Data);

set(handles.txtDataInfoSize, 'String', ...
    int2str(datasize(2)));
set(handles.txtDataInfoDimensions, 'String', ...
    int2str(datasize(1)));
drawnow;

guidata(hObject, handles);