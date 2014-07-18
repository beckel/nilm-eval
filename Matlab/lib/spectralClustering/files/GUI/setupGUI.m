function handles = setupGUI(hObject, handles)

% Initialize variables
handles.Data          = [];
handles.ClusteredData = [];
handles.figData       = [];
handles.figSimGraph   = [];
handles.figCluster    = [];
handles.figSilhouette = [];

handles.isNormalized = 0;

handles.currentSimGraphType       = 0;
handles.currentSimGraphEps        = 0;
handles.currentSimGraphSigma      = 0;
handles.currentSimGraphNeighbors  = 0;
handles.currentSimGraphComponents = 0;

handles.FileName = '';
handles.PathName = '';

% set default values
handles.defaultSimGraphType     = 2;
handles.defaultNeighbors        = 15;
handles.defaultEps              = 1;
handles.defaultSigma            = 1;
handles.defaultClusterType      = 2;
handles.defaultNumberOfClusters = 2;

handles.DataNonLabeledExt            = '.nld';
handles.DataOpenDialogTypes          = {'*.csv; *.nld', 'All Files (*.csv, *.nld)';
                                        '.csv', 'Labeled Files (*.csv)';
                                        '.nld', 'Non-Labeled Files (*.nld)'};
handles.DataSaveDialogTypes          = {'*.nld', 'Non-Labeled Files (*.nld)'};
handles.ClusteredDataSaveDialogTypes = {'*.csv', 'Labeled Files (*.csv)'};
handles.PlotSaveDialogTypes          = {'*.pdf', 'PDF Files (*.pdf)'};
handles.SimGraphSaveDialogTypes      = {'*.mat', 'MAT Files (*.mat)'};
handles.SimGraphOpenDialogTypes      = handles.SimGraphSaveDialogTypes;

handles.statusColorBusy = [0.4 0 0];
handles.statusColorDone = [0 0.4 0];
handles.statusColorNone = [0 0 0.8];

handles.PlotColors = 'brgcmykw';

% setup GUI
handles.NumberOfClusters = handles.defaultNumberOfClusters;
set(handles.edtClusterNumber, 'String', ...
    int2str(handles.NumberOfClusters));

handles.SimGraphType = handles.defaultSimGraphType;
set(handles.popSimGraphType, 'Value', ...
    handles.SimGraphType);
handles = setSimGraphEdits(hObject, handles);

handles.ClusterType = handles.defaultClusterType;
set(handles.popClusterType, 'Value', ...
    handles.ClusterType);

set(handles.edtSimGraphNeighbors, 'String', ...
    int2str(handles.defaultNeighbors));
    
set(handles.edtSimGraphEps, 'String', ...
    num2str(handles.defaultEps));

set(handles.edtSimGraphSigma, 'String', ...
    num2str(handles.defaultSigma));

% Check if export_fig is installed
fprintf('Spectral Clustering: Checking for export_fig...\n');
handles.foundExportFig = 1;
if ~isequal(exist('export_fig', 'file'), 2)
    msg = ['The script ''export_fig'' couldn''t be found. Saving plots will ' ...
        'only be available through built-in functions. Please make sure ' ...
        '''export_fig'' is installed and configured to save *.pdf files.'];
    warndlg(msg, 'export_fig not found');
    fprintf(['Spectral Clustering: ' msg '\n']);
    
    handles.foundExportFig = 0;
end

% Check if kmeans is available
fprintf('Spectral Clustering: Checking for kmeans...\n');
if ~isequal(exist('kmeans', 'file'), 2)
    msg = ['''kMeans'' couldn''t be found. Please make sure that the Statistics ' ...
        'Toolbox is available. This program cannot be launched without ''kmeans''.'];
    errordlg(msg, 'kmeans not found');
    ME = MException('FileNotFound:kMeans', msg);
    throw(ME); 
end

guidata(hObject, handles);