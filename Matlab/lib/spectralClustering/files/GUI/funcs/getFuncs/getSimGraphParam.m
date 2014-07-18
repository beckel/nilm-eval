function [handles, Param] = getSimGraphParam(hObject, handles)
% getSimGraphParam Returns parameter for similarity graph depending on the
% type

switch handles.currentSimGraphType
    case 1
        Param = '0';
    case 4
        Param = handles.currentSimGraphEps;
    case {2,3}
        Param = handles.currentSimGraphNeighbors;
    otherwise
        ME = MException('InvalidArgument:SimGraphType', ...
            'Unknown similarity graph type');
        throw(ME);
end
Param = str2double(Param);

guidata(hObject, handles);