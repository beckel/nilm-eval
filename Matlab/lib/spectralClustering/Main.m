fprintf('Spectral Clustering: Adding directories to current path...\n');

% make sure we add the correct folders even if this file is
% not called from the current folder
fileName = mfilename();
filePath = mfilename('fullpath');
filePath = filePath(1:end-size(fileName, 2));

% Add folders to current path
path(genpath([filePath 'files']), path);

fprintf('Spectral Clustering: Starting GUI...\n');

% Open main GUI
guiMain;

fprintf('Spectral Clustering: Ready.\n\n');

% clear variables
clearvars fileName filePath