function handles = plotClusterStarCoordinates(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');
plotTime       = get(handles.chkPlotDisplayTime, 'Value');

sFigureTitle = 'Clustered Data';
if isequal(plotTime, 1)
    sFigureTitle = [sFigureTitle ...
        sprintf(' (clustered in %.2fs)', handles.timeClustering)];
end
sFigureTitle = [sFigureTitle ' - Star Coordinates'];

[handles, handles.figCluster] = openPlotFigure(hObject, handles, ...
    'Clustered Data Plot (Star Coordinates)', sFigureTitle);

workData = normalizeData(handles.Data);
workData = workData(plotDimensions, :);

d = size(workData, 1);
unitRoot = exp(2 * pi * 1i / d);

starAxes = zeros(1, d);
for ii = 1:d
    starAxes(ii) = unitRoot^ii;
end

starAxes = repmat(starAxes', 1, size(workData, 2));
plotPoints = sum(workData .* starAxes, 1);
gscatter(real(plotPoints), imag(plotPoints), handles.ClusteredData, ...
    handles.PlotColors, [], getPlotMarkerSize(), 'off');

hold off;

guidata(hObject, handles);