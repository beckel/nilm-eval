function handles = plotSimGraphStarCoordinates(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');
plotTime       = get(handles.chkPlotDisplayTime, 'Value');
plotColored    = get(handles.chkPlotSGColored, 'Value');

n = size(handles.Data, 2);

sFigureTitle = 'Similarity Graph';
if isequal(plotTime, 1)
    sFigureTitle = [sFigureTitle ...
        sprintf(' (created in %.2fs)', handles.timeSimGraph)];
end
sFigureTitle = [sFigureTitle ' - Star Coordinates'];

[handles, handles.figSimGraph] = openPlotFigure(hObject, handles, ...
    'Similarity Graph Plot (Star Coordinates)', sFigureTitle);

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


mapColor  = 'Hot';
EdgeCol   = 'b';
VertixCol = 'r';

dim1Val = zeros(2*n, 1);
dim2Val = zeros(2*n, 1);

if ~isequal(plotColored, 0)
    sMin = min(min(nonzeros(handles.SimGraph)));
    sMax = max(max(handles.SimGraph));
    
    if isequal(sMin, sMax)
        sMin = 0;
    end
    
    map = colormap(mapColor);
end

for ii = 1:n
    nnzs = find(handles.SimGraph(ii, :) > 0);
    nnzsLength = length(nnzs);
    
    if nnzsLength > 0
        dim1Val(1:2:2*nnzsLength) = real(plotPoints(1, ii));
        dim1Val(2:2:2*nnzsLength) = real(plotPoints(1, nnzs));
        dim2Val(1:2:2*nnzsLength) = imag(plotPoints(1, ii));
        dim2Val(2:2:2*nnzsLength) = imag(plotPoints(1, nnzs));
        
        if isequal(plotColored, 0)
            plot(...
                dim1Val(1:2*nnzsLength), ...
                dim2Val(1:2*nnzsLength), ...
                ['-' EdgeCol]);
        else
            for jj = 1:2:2*nnzsLength
                tempColor = 1 - ...
                    (handles.SimGraph(ii, nnzs((jj+1)/2)) - sMin) / (sMax - sMin);
                currentColor = map(1 + floor((size(map, 1) - 1) * tempColor), :);
                
                plot(...
                    dim1Val(jj:jj+1), ...
                    dim2Val(jj:jj+1), ...
                    '-', 'Color', currentColor);
            end
        end
    end
end

scatter(...
    real(plotPoints), ...
    imag(plotPoints), ...
    getPlotMarkerSize(), VertixCol, 'filled');

hold off;

guidata(hObject, handles);