function handles = plotSimGraph3D(hObject, handles)

plotDimensions = get(handles.lstPlotDimensions, 'Value');
plotTime       = get(handles.chkPlotDisplayTime, 'Value');
plotColored    = get(handles.chkPlotSGColored, 'Value');

n = size(handles.Data, 2);

sFigureTitle = 'Similarity Graph';
if isequal(plotTime, 1)
    sFigureTitle = [sFigureTitle ...
        sprintf(' (created in %.2fs)', handles.timeSimGraph)];
end

[handles, handles.figSimGraph] = openPlotFigure(hObject, handles, ...
    'Similarity Graph Plot (3D)', sFigureTitle);

view(3);

mapColor  = 'Hot';
EdgeCol   = 'b';
VertixCol = 'r';

dim1Val = zeros(2*n, 1);
dim2Val = zeros(2*n, 1);
dim3Val = zeros(2*n, 1);

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
        dim1Val(1:2:2*nnzsLength) = handles.Data(plotDimensions(1), ii);
        dim1Val(2:2:2*nnzsLength) = handles.Data(plotDimensions(1), nnzs);
        dim2Val(1:2:2*nnzsLength) = handles.Data(plotDimensions(2), ii);
        dim2Val(2:2:2*nnzsLength) = handles.Data(plotDimensions(2), nnzs);
        dim3Val(1:2:2*nnzsLength) = handles.Data(plotDimensions(3), ii);
        dim3Val(2:2:2*nnzsLength) = handles.Data(plotDimensions(3), nnzs);  
        
        if isequal(plotColored, 0)
            plot3(...
                dim1Val(1:2*nnzsLength), ...
                dim2Val(1:2*nnzsLength), ...
                dim3Val(1:2*nnzsLength), ...
                ['-' EdgeCol]);
        else
            for jj = 1:2:2*nnzsLength
                tempColor = 1 - ...
                    (handles.SimGraph(ii, nnzs((jj+1)/2)) - sMin) / (sMax - sMin);
                currentColor = map(1 + floor((size(map, 1) - 1) * tempColor), :);
                
                plot3(...
                    dim1Val(jj:jj+1), ...
                    dim2Val(jj:jj+1), ...
                    dim3Val(jj:jj+1), ...
                    '-', 'Color', currentColor);
            end
        end
    end
end

scatter3(...
    handles.Data(plotDimensions(1), :), ...
    handles.Data(plotDimensions(2), :), ...
    handles.Data(plotDimensions(3), :), ...
    getPlotMarkerSize(), VertixCol, 'filled');

hold off;

guidata(hObject, handles);