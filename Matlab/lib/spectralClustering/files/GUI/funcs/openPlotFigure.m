function [handles, hFig] = openPlotFigure(hObject, handles, Name, Title)
% openPlotFigure Opens a window for plots

hFig = figure('Position', getPlotWindowSize(), ...
              'Name', Name, ...
              'NumberTitle', 'off');
set(gca, 'Color', 'none');

hold on;
title(Title)

guidata(hObject, handles);