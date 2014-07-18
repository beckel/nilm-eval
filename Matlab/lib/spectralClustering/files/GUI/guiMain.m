function varargout = guiMain(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @guiMain_OpeningFcn, ...
                   'gui_OutputFcn',  @guiMain_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function guiMain_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;

handles = setupGUI(hObject, handles);
handles = updateStatus(hObject, handles, 'Welcome!');

guidata(hObject, handles);

function varargout = guiMain_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;


%
% Buttons
%

function btnLoadData_Callback(hObject, ~, handles)

[handles.FileName, handles.PathName] = getOpenDialog(handles.DataOpenDialogTypes, ...
    'Load Data from File', handles.PathName);

if ~isequal(handles.FileName, 0)
    handles = updateStatus(hObject, handles, 'Busy: Load Dataset');
    
    % Avoid a bug
    set(handles.lstSelectedDimensions, 'Value', []);
    set(handles.lstPlotDimensions, 'Value', []);
    
    % Load Dataset
    handles.Data = csvread(fullfile(relativepath(handles.PathName), ...
        handles.FileName));
    [~, DataName, DataExt] = fileparts(handles.FileName);
    
    % if data is labeled, remove labels
    if ~isequal(DataExt, handles.DataNonLabeledExt)
        handles.Data = handles.Data(:, 2:end);
    end
    
    handles.Data = handles.Data';
    
    % Change Information display
    set(handles.txtDataInfoName, 'String', DataName);
    handles = updateDataInfo(hObject, handles);
    
    setPlotDimensionLists(hObject, handles);
    
    % Automatically select all dimensions
    set(handles.lstSelectedDimensions, 'Value', (1:size(handles.Data, 1)));
    set(handles.lstPlotDimensions, 'Value', (1:size(handles.Data, 1)));
    
    handles = enableDataLoaded(hObject, handles);
    handles = disableDataLoaded(hObject, handles);
    
    % check if normalized
    handles.isNormalized = 1;
    valMin = min(handles.Data, [], 2);
    valMax = max(handles.Data, [], 2);
    if size(unique(valMin), 1) > 1 || size(unique(valMax), 1) > 1
       msg = 'The dataset might not be normalized. Please consider normalizing it.';
       warndlg(msg, 'Dataset might not be normalized'); 
       
       handles.isNormalized = 0;
    end
    handles = updateNormalized(hObject, handles);
    
    handles = updateStatus(hObject, handles, 'Done: Load Dataset');
end

guidata(hObject, handles);

function btnSaveData_Callback(hObject, eventdata, handles)

[saveFile, savePath] = getSaveDialog(handles.DataSaveDialogTypes, ...
    'Save Data to File', handles.PathName);

if ~isequal(saveFile, 0)
    handles = updateStatus(hObject, handles, 'Busy: Save Dataset');
    
    [~, ~, fileExt] = fileparts(saveFile);
    saveData = handles.Data';
    
    if ~isequal(fileExt, handles.DataNonLabeledExt)
        indVector = full(convertClusterVector(handles.ClusteredData));
        saveData = [indVector saveData];
    end
    
    csvwrite(fullfile(relativepath(savePath), saveFile), saveData);
    
    handles = updateStatus(hObject, handles, 'Done: Save Dataset');
end

guidata(hObject, handles);

function btnDataNormalize_Callback(hObject, eventdata, handles)

handles = updateStatus(hObject, handles, ...
    'Busy: Normalizing Data');

handles.Data = normalizeData(handles.Data);

handles.isNormalized = 1;
handles = updateNormalized(hObject, handles);

handles = updateStatus(hObject, handles, ...
    'Done: Normalizing Data');

guidata(hObject, handles);

function btnSimGraphLoad_Callback(hObject, ~, handles)

[openFile, openPath] = getOpenDialog(handles.SimGraphOpenDialogTypes, ...
    'Load Similarity Graph from File', handles.PathName);

if ~isequal(openFile, 0)
   handles = updateStatus(hObject, handles, 'Busy: Loading Similarity Graph');
   
   openObj = matfile(fullfile(relativepath(openPath), openFile));
   
   if ~isequal(size(handles.Data, 2), size(openObj.SimGraph, 1)) || ...
      ~isequal(size(openObj.SimGraph, 1), size(openObj.SimGraph, 2))
        warndlg('Dimensions do not match the dataset.', 'Wrong File?');
        handles = updateStatus(hObject, handles, ...
            'Failed to open Similarity Graph');
        
        guidata(hObject, handles);
        return;
   end
   
   handles.SimGraph = openObj.SimGraph;
   
   handles.SimGraphType = openObj.SimGraphType;
   handles.currentSimGraphType = handles.SimGraphType;
   handles.currentSimGraphNeighbors = openObj.Neighbors;
   handles.currentSimGraphEps = openObj.Eps;
   handles.currentSimGraphSigma = openObj.Sigma;
   handles.currentSimGraphComponents = openObj.Components;
   
   set(handles.popSimGraphType, 'Value', handles.currentSimGraphType);
   set(handles.edtSimGraphNeighbors, 'String', handles.currentSimGraphNeighbors);
   set(handles.edtSimGraphEps, 'String', handles.currentSimGraphEps);
   set(handles.edtSimGraphSigma, 'String', handles.currentSimGraphSigma);
   
   handles = setSimGraphEdits(hObject, handles);
   handles = enableSimGraph(hObject, handles);
   
   msg = 'Done: Loading Similarity Graph';
   if handles.currentSimGraphComponents > 0
       msg = [msg sprintf(' - %d connected components found', ...
           handles.currentSimGraphComponents)];
   end
   handles = updateStatus(hObject, handles, msg);
end

guidata(hObject, handles);

function btnSimGraphSave_Callback(hObject, ~, handles)

[saveFile, savePath] = getSaveDialog(handles.SimGraphSaveDialogTypes, ...
    'Save Similarity Graph to File', handles.PathName);

if ~isequal(saveFile, 0)
    handles = updateStatus(hObject, handles, 'Busy: Saving Similarity Graph');
    
    saveObj = matfile(fullfile(relativepath(savePath), saveFile), ...
        'Writable', true);
    
    saveObj.SimGraph = handles.SimGraph;
    
    saveObj.SimGraphType = handles.currentSimGraphType;
    saveObj.Neighbors    = handles.currentSimGraphNeighbors;
    saveObj.Eps          = handles.currentSimGraphEps;
    saveObj.Sigma        = handles.currentSimGraphSigma;
    saveObj.Components   = handles.currentSimGraphComponents;
    
    handles = updateStatus(hObject, handles, 'Done: Saving Similarity Graph');
end

guidata(hObject, handles);

function btnClusterSave_Callback(hObject, ~, handles)

[saveFile, savePath] = getSaveDialog(handles.ClusteredDataSaveDialogTypes, ...
    'Save Data to File', handles.PathName);

if ~isequal(saveFile, 0)
    handles = updateStatus(hObject, handles, 'Busy: Saving Clustered Data');
    
    indVector = convertClusterVector(handles.ClusteredData);
    csvwrite(fullfile(relativepath(savePath), saveFile), ...
        [indVector handles.Data']);
    
    handles = updateStatus(hObject, handles, 'Done: Saving Clustered Data');
end

guidata(hObject, handles);

function btnSimGraphCreate_Callback(hObject, ~, handles)

handles            = setCurrentSimGraphProperties(hObject, handles);
[handles, Param]   = getSimGraphParam(hObject, handles);
selectedDimensions = get(handles.lstSelectedDimensions, 'Value'); 

%hasToNormalizeData = get(handles.chkSimGraphNormalize, 'Value');
%if isequal(hasToNormalizeData, 1)
%    handles = updateStatus(hObject, handles, ...
%        'Busy: Normalizing data');
%    
%    workData = normalizeData(handles.Data);
%    
%    handles = updateStatus(hObject, handles, ...
%        'Done: Normalizing data');
%else
%    workData = handles.Data;
%end

handles = updateStatus(hObject, handles, ...
    'Busy: Creating similarity graph');

handles.timeSimGraph = tic;
switch handles.currentSimGraphType
    case 1
        handles.SimGraph = SimGraph_Full(...
            handles.Data(selectedDimensions, :), ...
            str2double(handles.currentSimGraphSigma));
    case 4
        handles.SimGraph = SimGraph_Epsilon(...
            handles.Data(selectedDimensions, :), ...
            Param);
    case {2,3}
        handles.SimGraph = SimGraph_NearestNeighbors(...
            handles.Data(selectedDimensions, :), ...
            Param, ...
            handles.currentSimGraphType - 1, ...
            str2double(handles.currentSimGraphSigma));
end
handles.timeSimGraph = toc(handles.timeSimGraph);

handles = enableSimGraph(hObject, handles);

msg = sprintf('Done: Creating similarity graph (%fs)', handles.timeSimGraph);
try
    comps = graphconncomp(handles.SimGraph, 'Directed', false);
    msg = [msg sprintf(' - %d connected components found', comps)];
    handles.currentSimGraphComponents = comps;
end
handles = updateStatus(hObject, handles, msg);

guidata(hObject, handles);

function btnClusterData_Callback(hObject, ~, handles)

handles = updateStatus(hObject, handles, ...
    'Busy: Clustering Data');

handles.timeClustering = tic;
handles.ClusteredData = SpectralClustering(handles.SimGraph, ...
    handles.NumberOfClusters, ...
    handles.ClusterType);
handles.timeClustering = toc(handles.timeClustering);

handles = enableDataClustered(hObject, handles);

msg = sprintf('Done: Clustering Data (%fs)', handles.timeClustering);
handles = updateStatus(hObject, handles, msg);

guidata(hObject, handles);

function btnPlotData_Callback(hObject, ~, handles)

handles = updateStatus(hObject, handles, ...
    'Busy: Plotting Data');

plotDimensions = get(handles.lstPlotDimensions, 'Value');
switch size(plotDimensions, 2)
    case 2
        handles = plotData2D(hObject, handles);
    case 3
        plotType = questdlg('Choose a plot type:', 'Plot Type', ...
            'Matrix Plot', 'Star Coordinates', '3D Plot', ...
            '3D Plot');
        
        switch plotType
            case 'Matrix Plot'
                handles = plotDataMatrix(hObject, handles);
            case 'Star Coordinates'
                handles = plotDataStarCoordinates(hObject, handles);
            case '3D Plot'
                handles = plotData3D(hObject, handles);
        end
    otherwise
        plotType = questdlg('Choose a plot type:', 'Plot Type', ...
            'Matrix Plot', 'Star Coordinates', ...
            'Matrix Plot');
        
        if strcmp(plotType, 'Star Coordinates')
            handles = plotDataStarCoordinates(hObject, handles);
        else
            handles = plotDataMatrix(hObject, handles);
        end
end

handles = updateStatus(hObject, handles, ...
    'Done: Plotting Data');

guidata(hObject, handles);

function btnPlotSimGraph_Callback(hObject, ~, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');

if isequal(size(plotDimensions, 2), 1)
    warndlg('Please select at least two dimensions.', ...
        'Not enough Dimensions');
    return
end

questAbort = 'Yes';
nnzs = nnz(handles.SimGraph);
if nnzs > 5000
    msg = sprintf(['The similarity graph contains %d non-zero elements. Plotting' ...
        ' it might take a long time. Do you want to continue?'], nnzs);
    questAbort = questdlg(msg, 'Warning: Many non-zero elements', ...
        'Yes', 'No', 'No');
end

if isequal(questAbort, 'Yes')
    handles = updateStatus(hObject, handles, 'Busy: Plotting Similarity Graph');
    
    switch size(plotDimensions, 2)
        case 2
            handles = plotSimGraph2D(hObject, handles);
        case 3
            plotType = questdlg('Choose a plot type:', 'Plot Type', ...
                '3D Plot', 'Star Coordinates', ...
                '3D Plot');
            
            switch plotType
                case '3D Plot'
                    handles = plotSimGraph3D(hObject, handles);
                case 'Star Coordinates'
                    handles = plotSimGraphStarCoordinates(hObject, handles);
            end
        otherwise
            %msg = ['Please note that a similarity graph plot with more than ' ...
            %    'three dimensions will use star coordinates.'];
            %helpdlg(msg, 'Star Coordinates');
            handles = plotSimGraphStarCoordinates(hObject, handles);
    end
    
    handles = updateStatus(hObject, handles, 'Done: Plotting Similarity Graph');
end

guidata(hObject, handles);

function btnPlotSilhouette_Callback(hObject, ~, handles)

handles = updateStatus(hObject, handles, ...
    'Busy: Plotting Silhouette');

plotDimensions = get(handles.lstPlotDimensions, 'Value');

if size(plotDimensions, 2) < 1
    msg = 'Please select at least one dimension.';
    warndlg(msg, 'Not enough Dimensions');
else
    handles = plotSilhouette(hObject, handles);
end

handles = updateStatus(hObject, handles, ...
    'Done: Plotting Silhouette');

guidata(hObject, handles);

function btnPlotClusteredData_Callback(hObject, ~, handles)

handles = updateStatus(hObject, handles, ...
    'Busy: Plotting Clustered Data');

plotDimensions = get(handles.lstPlotDimensions, 'Value');
switch size(plotDimensions, 2)
    case 2
        handles = plotCluster2D(hObject, handles);
    case 3
        plotType = questdlg('Choose a plot type:', 'Plot Type', ...
            'Matrix Plot', 'Star Coordinates', '3D Plot', ...
            '3D Plot');
        
        switch plotType
            case 'Matrix Plot'
                handles = plotClusterMatrix(hObject, handles);
            case 'Star Coordinates'
                handles = plotClusterStarCoordinates(hObject, handles);
            case '3D Plot'
                handles = plotCluster3D(hObject, handles);
        end
    otherwise
        plotType = questdlg('Choose a plot type:', 'Plot Type', ...
            'Matrix Plot', 'Star Coordinates', ...
            'Matrix Plot');
        
        if strcmp(plotType, 'Star Coordinates')       
            handles = plotClusterStarCoordinates(hObject, handles);
        else
            handles = plotClusterMatrix(hObject, handles);
        end
end

handles = updateStatus(hObject, handles, ...
    'Done: Plotting Clustered Data');

guidata(hObject, handles);

function btnPlotDataSave_Callback(hObject, ~, handles)

if isempty(handles.figData) || ~ishandle(handles.figData)
   return; 
end

[saveFile, savePath] = getSaveDialog(handles.PlotSaveDialogTypes, ...
    'Save Data Plot', handles.PathName);

if ~isequal(saveFile, 0)
    handles = updateStatus(hObject, handles, 'Busy: Saving Data Plot');
    
    set(0, 'CurrentFigure', handles.figData);
    handles = saveCurrentFigure(hObject, handles, saveFile, savePath);
    
    handles = updateStatus(hObject, handles, 'Done: Saving Data Plot');
end

guidata(hObject, handles);

function btnPlotSimGraphSave_Callback(hObject, ~, handles)

if isempty(handles.figSimGraph) || ~ishandle(handles.figSimGraph)
   return; 
end

[saveFile, savePath] = getSaveDialog(handles.PlotSaveDialogTypes, ...
    'Save Similarity Graph Plot', handles.PathName);

if ~isequal(saveFile, 0)
    handles = updateStatus(hObject, handles, 'Busy: Saving Similarity Graph Plot');
    
    set(0, 'CurrentFigure', handles.figSimGraph);
    handles = saveCurrentFigure(hObject, handles, saveFile, savePath);
    
    handles = updateStatus(hObject, handles, 'Done: Saving Similarity Graph Plot');
end

guidata(hObject, handles);

function btnPlotSilhouetteSave_Callback(hObject, ~, handles)

if isempty(handles.figSilhouette) || ~ishandle(handles.figSilhouette)
    return;
end

[saveFile, savePath] = getSaveDialog(handles.PlotSaveDialogTypes, ...
    'Save Silhouette Plot', handles.PathName);

if ~isequal(saveFile, 0)
    handles = updateStatus(hObject, handles, 'Busy: Saving Silhouette Plot');
    
    set(0, 'CurrentFigure', handles.figSilhouette);
    handles = saveCurrentFigure(hObject, handles, saveFile, savePath);
    
    handles = updateStatus(hObject, handles, 'Done: Saving Silhouette Plot');
end

guidata(hObject, handles);

function btnPlotClusteredDataSave_Callback(hObject, ~, handles)

if isempty(handles.figCluster) || ~ishandle(handles.figCluster)
   return; 
end

[saveFile, savePath] = getSaveDialog(handles.PlotSaveDialogTypes, ...
    'Save Clustered Data Plot', handles.PathName);

if ~isequal(saveFile, 0)
    handles = updateStatus(hObject, handles, 'Busy: Saving Clustered Data Plot');
    
    set(0, 'CurrentFigure', handles.figCluster);
    handles = saveCurrentFigure(hObject, handles, saveFile, savePath);
    
    handles = updateStatus(hObject, handles, 'Done: Saving Clustered Data Plot');
end

guidata(hObject, handles);

function btnPlotSetDimensions_Callback(hObject, ~, handles)

selectedDimensions = get(handles.lstSelectedDimensions, 'Value');
set(handles.lstPlotDimensions, 'Value', selectedDimensions);

guidata(hObject, handles);

%
% Edits and Lists
%

function popSimGraphType_Callback(hObject, ~, handles)

handles.SimGraphType = get(hObject, 'Value');
handles = setSimGraphEdits(hObject, handles);

guidata(hObject, handles);

function edtSimGraphNeighbors_Callback(hObject, ~, handles)

newVal = str2double(get(hObject, 'String'));
if isnan(newVal) || ~isequal(fix(newVal), newVal) || newVal < 1
    set(hObject, 'String', int2str(handles.defaultNeighbors));
end

guidata(hObject, handles);

function edtSimGraphEps_Callback(hObject, ~, handles)

newVal = get(hObject, 'String');
newVal = strrep(newVal, ',', '.');
newVal = str2double(newVal);
if isnan(newVal) || newVal < eps
    set(hObject, 'String', num2str(handles.defaultEps));
end

guidata(hObject, handles);

function edtSimGraphSigma_Callback(hObject, ~, handles)

newVal = get(hObject, 'String');
newVal = strrep(newVal, ',', '.');
newVal = str2double(newVal);
if isnan(newVal) || newVal < eps
    set(hObject, 'String', num2str(handles.defaultSigma));
end

guidata(hObject, handles);

function edtClusterNumber_Callback(hObject, ~, handles)

newVal = str2double(get(hObject, 'String'));
if isnan(newVal) || ~isequal(fix(newVal), newVal) || newVal < 2
    set(hObject, 'String', int2str(handles.defaultNumberOfClusters));
    handles.NumberOfClusters = handles.defaultNumberOfClusters;
else
    handles.NumberOfClusters = newVal;
end

guidata(hObject, handles);


%
% Empty Functions
%

function lstSelectedDimensions_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popSimGraphType_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edtSimGraphNeighbors_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edtSimGraphEps_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popClusterType_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edtClusterNumber_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lstPlotDimensions_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edtSimGraphSigma_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lstSelectedDimensions_Callback(~, ~, ~)

function popClusterType_Callback(~, ~, ~)

function lstPlotDimensions_Callback(~, ~, ~)

function chkPlotSGColored_Callback(~, ~, ~)

function chkPlotDisplayTime_Callback(~, ~, ~)
