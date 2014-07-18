% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Christian Beckel;

figure_path = 'projects/buildsys/images/pie_chart/';
fontsize = 9;
% width = 4.8;
% height = 4.8;
households = [ 5, 6 ];
if ~exist(figure_path, 'dir')
    mkdir(figure_path);
end

for household = households
    %params
    dataset = 'thun';
    % evalDays_type = 'completeSM_first90';
    evalDays_type = 'all';
    granularity = 1;

    path_to_evalDays = strcat(pwd, '/input/evalDays/', dataset, '/', evalDays_type, '/', num2str(household, '%02d'), '.mat');
    load(path_to_evalDays); % evalDays

    % total consumption
    fprintf('Processing household %d, smart meter\n', household);
    smartmeter_consumption = read_smartmeter_data(dataset, household, evalDays, granularity, 'powerallphases');
    missing_values_idx_sm = smartmeter_consumption == -1; 
    total_consumption = sum(smartmeter_consumption(~missing_values_idx_sm));

    % consumption of each appliance
    appliances = findAppliances(household);
    % power_pct = zeros(length(appliances)+1, 1);
    avg_cons = zeros(length(appliances)+1, 1);
    for i = 1:length(appliances)
       fprintf('Processing household %d, plug %d/%d\n', household, i, length(appliances));
       plug_consumption = read_plug_data(dataset, household, appliances(i), evalDays, granularity);
       missing_values_idx_plug = plug_consumption == -1;
       sum_plug_consumption = sum(plug_consumption(~missing_values_idx_plug));
    %    ratio = nnz(~missing_values_idx_sm) / nnz(~missing_values_idx_plug);
    %    extrapolated_plug_consumption = ratio*sum_plug_consumption;
    %    power_pct(i) = extrapolated_plug_consumption / total_consumption;
        avg_cons(i) = sum_plug_consumption / nnz(~missing_values_idx_plug);
    end

    % power_pct(end) = 1 - sum(power_pct(~isnan(power_pct)));
    avg_cons(end) = (total_consumption / nnz(~missing_values_idx_sm)) - sum(avg_cons);

%     % plot pie chart
%     if household == 5
%         names{end+1} = '';
%         avg_cons(end+1) = avg_cons(end);
%         avg_cons(end-1) = 0;
%     end
%     
    names = getApplianceNames(appliances);
    names{end+1} = 'Other';
    fig = figure();
    %title(strcat('Household: ', num2str(household)));
    % pie_handle = pie(power_pct);
    pie_handle = pie(avg_cons);
    % set(pie_handle(2:2:end));
    handle_array = findobj(pie_handle, 'Type', 'text');
%     percentages = get(handle_array, 'String');
%     new_labels = strcat(names',{': '}, percentages);
    new_labels = strcat(names', {': '}, num2str(avg_cons * 24/1000*30, 3));
    set(handle_array, {'String'}, new_labels);
    
%     fig = make_report_ready(fig, 'size', [width height], 'fontsize', fontsize);
    fig = make_report_ready(fig, 'fontsize', fontsize);
    
    filename = ['household_', num2str(household)];
    print('-depsc2', '-cmyk', '-r600', [figure_path, filename, '.eps']);
  	% saveas(fig_h, [figure_path, filename, '.png'], 'png');
    pause(1);
  	close(fig);
    
end
