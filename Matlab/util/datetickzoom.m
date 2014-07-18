function datetickzoom(varargin)
%DATETICKZOOM Date formatted tick labels, automatically updated when zoomed or panned. 
%   Arguments are completely identical to does of DATETICK. The argument
%   DATEFORM is reset once zoomed or panned.
%
%   See also datetick, datestr, datenum

% taken from http://www.mathworks.com/matlabcentral/fileexchange/15029-datetickzoom-automatically-update-dateticks

if nargin==2 && isstruct(varargin{2}) && isfield(varargin{2},'Axes') && isscalar(varargin{2}.Axes)
    datetickdata = getappdata(varargin{2}.Axes,'datetickdata');
    if isstruct(datetickdata) && isfield(datetickdata,'axh') && datetickdata.axh==varargin{2}.Axes
        axh = datetickdata.axh;
        ax = datetickdata.ax;
        dateform = datetickdata.dateform;
        keep_ticks = datetickdata.keep_ticks;
        if keep_ticks
            set(axh,[ax,'TickMode'],'auto')
            if ~isempty(dateform)
                datetick(axh,ax,dateform,'keeplimits','keepticks')
            else
                datetick(axh,ax,'keeplimits','keepticks')
            end
        else
            if ~isempty(dateform)
                datetick(axh,ax,dateform,'keeplimits')
            else
                datetick(axh,ax,'keeplimits')
            end
        end
    end
else
    [axh,ax,dateform,keep_ticks] = parseinputs(varargin);
    datetickdata = [];
    datetickdata.axh = axh;
    datetickdata.ax = ax;
    datetickdata.dateform = dateform;
    datetickdata.keep_ticks = keep_ticks;
    
    setappdata(axh,'datetickdata',datetickdata);
    set(zoom(axh),'ActionPostCallback',@datetickzoom)
    set(pan(get(axh,'parent')),'ActionPostCallback',@datetickzoom)
    datetick(varargin{:})
end

function [axh,ax,dateform,keep_ticks] = parseinputs(v)
%Parse Inputs

% Defaults;
nin = length(v);
dateform = [];
keep_ticks = 0;

% check to see if an axes was specified
if nin > 0 & ishandle(v{1}) & isequal(get(v{1},'type'),'axes') %#ok ishandle return is not scalar
    % use the axes passed in
    axh = v{1};
    v(1)=[];
    nin=nin-1;
else
    % use gca
    axh = gca;
end
% Look for 'keepticks'
for i=nin:-1:max(1,nin-1),
   if strcmpi(v{i},'keepticks'),
      keep_ticks = 1;
      v(i) = [];
      nin = nin-1;
   end
end

if nin==0, 
   ax = 'x';
else
   ax = v{1};
end
if nin > 1
     % The dateform (Date Format) value should be a scalar or string constant
     % check this out
     dateform = v{2}; 
     if (isnumeric(dateform) && length(dateform) ~= 1) && ~ischar(dateform)
         error('The Date Format value should be a scalar or string');
     end 
end
