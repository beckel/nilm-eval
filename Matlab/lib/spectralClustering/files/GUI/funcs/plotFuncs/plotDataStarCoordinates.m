function handles = plotDataStarCoordinates(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');

sFigureTitle = 'Data';
sFigureTitle = [sFigureTitle ' - Star Coordinates'];
[handles, handles.figData] = openPlotFigure(hObject, handles, ...
    'Data Plot (Star Coordinates)', sFigureTitle);

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
scatter(real(plotPoints), imag(plotPoints), ...
    getPlotMarkerSize(), ['k' getPlotMarkerStyle()]);

hold off;

guidata(hObject, handles);