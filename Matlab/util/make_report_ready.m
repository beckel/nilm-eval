% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich & TU Darmstadt, 2012
% Authors: Leyna Sadamori (sadamori@inf.ethz.ch), Christian Beckel (beckel@inf.ethz.ch)

function varargout = make_report_ready(fig_h, varargin)
	% Minimum number of default arguments
	nargin_min = 1;
	
	if (not(strcmpi(get(fig_h, 'Type'), 'figure')))
		error('fig_h is not a figure handle!');
	end
	
	%% Set Properties
	
	% Default values
	linewidth = 1;
	fontsize = 9;
	fontname = 'Times';
    
	% Default real figure size in cm
    width = 10.6;
	height = 7.8;
	
	% Get other settings
	if (nargin > nargin_min)
		% If number of optional arguments is odd, then throw error
		if (mod(nargin-nargin_min,2) == 1)
			error('make_report_ready only accepts pairs of ''Property'', ''Value''!');
		else
			% Get each property-value pair
			for i_argin = 1:2:(nargin-nargin_min)-1
				property = varargin{i_argin};
				value = varargin{i_argin+1};
				% Set the respective property to the given value
				if (strcmpi(property, 'size'))
					size = value;
					if (strcmpi(value, 'subfig'))
						width = 9.6;
						height = 7.2;
						fontsize = 8;
					elseif (strcmpi(value, 'short'))
						width = 9.6;
						height = 5.4;
						fontsize = 8;
					elseif (strcmpi(value, 'presentation'))
						width = 6.4;
						height = 4.8; 
						linewidth = 4;
						fontsize = 8;
					elseif (strcmpi(value, 'presentation_large'))
						width = 18;
						height = 13.5; 
						linewidth = 4;
						fontsize = 22;
					elseif (strcmpi(value, 'regression'))
						width = 25;
						height = 20; 
						linewidth = 2;
						fontsize = 16;
					elseif (strcmpi(value, 'subplot'))
						width = 8.4;
						height = 3.2;
						fontsize = 8;
					elseif (strcmpi(value, 'wide_flat'))
						width = 16.2;
						height = 5.4;
					elseif (strcmpi(value, 'wide_flat_2'))
						width = 19.8;
						height = 5.4;
                    elseif (strcmpi(value, 'acm_wide'))
                        width = 20.75;
                        height = 8.5;
					elseif (strcmpi(value, 'wide'))
						width = 19.8;
						height = 7.2;
                    elseif (strcmpi(value, 'features'))
                        width = 14;
                        height = 4.5;
                        linewidth = 10;
                        fontsize = 9;
                    elseif(strcmpi(value, 'consumption_overview'))
                        width = 10;
                        height = 6.5;
                        linewidth = 1;
                        fontsize = 8;
                    elseif isvector(value) && length(value) == 2
						width = value(1);
						height = value(2);
                    elseif isvector(value) && length(value) == 4
                        width = value(1);
                        height = value(2);
                        linewidth = value(3);
                        fontsize = value(4);
                    elseif isvector(value) && length(value) == 5
                        width = value(1);
                        height = value(2);
                        linewidth = value(3);
                        fontsize = value(4);
                        if value(5) == 2
                            fontname = 'Arial';
                        end
                    else
						error(['Size ', value, ' not supported.']);
					end
				elseif (strcmpi(property, 'type'))
					if (strcmpi(value, 'colorbar'))
						cb_flag = true;
						cb_continuous = true;
					elseif (strcmpi(value, 'clustermap'))
						width = 8.6;
						height = 6.4;
						fontsize = 10;
					else
						error(['Type ', value, ' not supported.']);
					end
				elseif (strcmpi(property, 'continuous'))
					if (islogical(value))
						cb_continuous = value;
					else
						error('Continuous only accepts boolean values.');
					end
				elseif (strcmpi(property, 'fontsize'))
					if (isnumeric(value))
						fontsize = value;
					else
						error('Fontsize only accepts numeric values.');
					end
				elseif (strcmpi(property, 'putlabel'))
					if (islogical(value))
						put_label = true;
					else
						error('Continuous only accepts boolean values.');
					end
				else
					error(['The property ''', property, ''' is not supported!']);
				end
			end
		end
	end
	
	%% If Colorbar Flag is set
	if (exist('cb_flag', 'var') && cb_flag)
		cb_h = findobj(fig_h, 'Tag', 'Colorbar');
		fig_cb = figure;
		cb_copy = copyobj(cb_h,fig_cb);
		if (not(cb_continuous))
			colormap(jet(length(get(cb_copy, 'YTickLabel'))));
			set(fig_cb, 'Renderer', 'zbuffer');
			set(cb_copy, 'YTick', []);
		end
		fig_cb = make_report_ready(fig_cb, 'size', size);
		pos = get(cb_copy, 'Position');
		pos(3) = 0.027477;
		pos(4) = 0.815;
		set(cb_copy, 'Position', pos);
		set(cb_h, 'Visible', 'off');
    end
	 
	%% Make Plot Report Ready
	set(fig_h, 'PaperUnits', 'centimeters');
	set(fig_h, 'PaperSize', [width height]);
	set(fig_h, 'PaperPosition', [0 0 width height]);
	set(fig_h, 'PaperPositionMode', 'manual');
	set(fig_h, 'Units', 'centimeters');
	set(fig_h, 'Position', get(fig_h, 'PaperPosition'));
	
	fig_children = get(fig_h, 'Children');
	% For each Axis do...
	for i = 1:length(fig_children)
		ax_h = fig_children(i);
		if (not(strcmpi(get(ax_h, 'Type'), 'axes')))
			continue;
		end
		% Default Axis
		if (isempty(get(ax_h, 'Tag')))
			% Adjust Axis fontsize
            set(ax_h, 'FontName', fontname);
            set(ax_h, 'FontSize', fontsize);
			set(get(ax_h, 'XLabel'), 'FontSize', fontsize);
			set(get(ax_h, 'YLabel'), 'FontSize', fontsize);
			set(get(ax_h, 'XLabel'), 'FontName', fontname);
            set(get(ax_h, 'YLabel'), 'FontName', fontname);
            set(findobj(ax_h,'Type','text'), 'FontSize', fontsize, 'FontName', fontname);
            
            % Add x an y label for psfrag
			if (exist('put_label', 'var') && put_label)
				set(get(ax_h, 'XLabel'), 'String', 'x');
				set(get(ax_h, 'YLabel'), 'String', 'y');
			end
		end
		% Legend
		if (strcmpi(get(ax_h, 'Tag'), 'legend'))
			% Adjust Axis fontsize
            set(ax_h, 'FontName', fontname);
            set(ax_h, 'FontSize', fontsize);
		end
		% Colorbar
		if (strcmpi(get(ax_h, 'Tag'), 'colorbar'))
			% Remove labels and set later by tikz
			if (not(strcmpi(get(fig_h, 'Renderer'), 'painters')))
				set(ax_h, 'YTickLabel', []);
			end
			set(ax_h, 'FontSize', fontsize);
            set(ax_h, 'FontName', fontname);
		end
		% Title
        h = get(gca, 'title');
        set(h, 'FontSize', fontsize);
        set(h, 'FontName', fontname);       
        
        ax_children = get(ax_h, 'Children');
		% For each Axis Element do...
		for j = 1:length(ax_children)
			graph_h = ax_children(j);
			% If it is a line
			if strcmpi(get(graph_h, 'Type'), 'line')
				% Exclude custom grid
				if (not(strcmpi(get(graph_h, 'Tag'), 'grid')))
                    set(graph_h, 'LineWidth', linewidth);
                end
			end
			% If it is a text object
            if (strcmpi(get(graph_h, 'Type'), 'text'))
				set(graph_h, 'FontSize', fontsize);
                set(graph_h, 'FontName', fontname);
            end
		end
    end

	%% Return Elements
	if (nargout >= 1)
		varargout{1} = fig_h;
	end
	if (nargout >= 2)
		varargout{2} = fig_cb;
	end
end