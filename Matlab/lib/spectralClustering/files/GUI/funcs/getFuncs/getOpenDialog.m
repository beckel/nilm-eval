function [FileName, PathName] = getOpenDialog(Types, Name, defDir)
% getOpenDialog Asks for a file to be opened

[FileName, PathName] = uigetfile(Types, Name, fullfile(defDir, ''));

if (isequal(FileName, 0) || isequal(PathName, 0))
    FileName = 0;
    PathName = 0;
end