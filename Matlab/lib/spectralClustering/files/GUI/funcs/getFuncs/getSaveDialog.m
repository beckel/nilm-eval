function [FileName, PathName] = getSaveDialog(Types, Name, defDir)
% getSaveDialog Asks for a file to be saved to

[FileName, PathName] = uiputfile(Types, Name, fullfile(defDir, ''));

if (isequal(FileName, 0) || isequal(PathName, 0))
    FileName = 0;
    PathName = 0;
end