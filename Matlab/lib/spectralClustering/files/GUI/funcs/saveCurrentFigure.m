function handles = saveCurrentFigure(hObject, handles, FileName, PathName)
% saveCurrentFigure Saves current figure using export_fig

try
    export_fig(gcf, ...
        fullfile(relativepath(PathName), FileName), ...
        '-q101', '-transparent');
catch Exception
    warndlg('Could not save plot. Please check if you have export_fig installed.');
    throw(Exception);
end

guidata(hObject, handles);