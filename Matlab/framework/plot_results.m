function [] = plot_results(setup_file)

    width = 24;
    height = 12;
    fontsize = 9;
    
    setup = ReadYaml(setup_file)
    
    algorithm = setup.algorithm;
    configuration_name = setup.configuration_name;
    experiment_name = setup.experiment_name;
    granularity = setup.granularity;
    dataset = setup.dataset;
    household = setup.household;
    setup_name = setup.setup_name;
    
    source_folder = ['results/details/', algorithm, '/', configuration_name, '/', experiment_name, '/', setup_name];
    plot_folder = ['results/plots/', algorithm, '/', configuration_name, '/', experiment_name, '/', setup_name, '/'];
    
    load([source_folder, '/result1.mat']);

    if ~exist(plot_folder)
        mkdir(plot_folder)
    end
    
    evaluation_days = result.evaluation_and_training_days{1};
    first_day = evaluation_days(1,:);
    num_days = size(evaluation_days, 1);
    
    total_consumption = read_smartmeter_data(dataset, household, evaluation_days, granularity, 'powerallphases');
    
    %%%%%%%%%%%%%%
    %% Plot events
    %%%%%%%%%%%%%%
    if isfield(result, 'events')
        i = 1;
        for appliance_name_cell = result.appliance_names
            appliance_name = cell2mat(appliance_name_cell);
            appliance_id = getApplianceID(appliance_name);
            fprintf(appliance_name);
            plug_consumption = read_plug_data(dataset, household, appliance_id, evaluation_days, granularity);
            
            classified_events = struct;
            
            % events inferred from algorithm
            % col1: event time
            % col2: appliance id
            % col3: delta
            events_inferred = result.events(result.events(:,2) == i,:);
            
            % get ground truth from plug-level data
            filter = struct;
            filter.p_edgeThreshold = setup.p_edgeThreshold;
            filter.p_filtering = setup.p_filtering;
            filter.p_filtLength = setup.p_filtLength;    
            % col1: time start
            % col2: time stop
            % col3: consumption delta
            events_from_plug_data = getEventsFromPlugData(dataset, household, appliance_id, evaluation_days, granularity, filter);
            
            % class one events: correctly inferred
            % class two events: missed events
            plug_events_detected = arrayfun(@(idx) any(events_inferred(:,1) > events_from_plug_data(idx,1) - 20 & ...
                    events_inferred(:,1) < events_from_plug_data(idx,1) + 20), [1:size(events_from_plug_data, 1)]');
            avg_deviation_of_plug_data_event = mean(events_from_plug_data(:,1) - events_from_plug_data(:,2));
            classified_events.tp_events = [events_from_plug_data(plug_events_detected,1) + avg_deviation_of_plug_data_event, events_from_plug_data(plug_events_detected,3)];
            classified_events.fn_events = [events_from_plug_data(~plug_events_detected,1) + avg_deviation_of_plug_data_event, events_from_plug_data(~plug_events_detected,3)];

            % class three events: incorrectly inferred
            which_detected_events_have_ground_truth_events = arrayfun(@(t) any(events_from_plug_data(:,1) - 20 < t & t < events_from_plug_data(:,2) + 20), ...
                    events_inferred(:, 1));
            plug_data_exists = arrayfun(@(t) ~any(plug_consumption(max(1,t-5):min(t+5,length(plug_consumption))) == -1), events_inferred(:, 1));
            tmp_idx = ~which_detected_events_have_ground_truth_events & plug_data_exists;
            classified_events.fp_events = events_inferred(tmp_idx, [1,3]);

            for d = 1:num_days
                day = evaluation_days(d,:);
                idx_start = 86400 / granularity * (d-1) + 1;
                idx_stop = 86400 / granularity * d;
                date_range = datenum(day)+granularity/86400 : granularity/86400 : datenum(day)+1;

                % plot smart meter consumption
                fig = figure;
                hold on;
                plot(date_range, total_consumption(idx_start:idx_stop));
                max_cons = max(total_consumption(idx_start:idx_stop));

                % get events for current day
                tp_events = classified_events.tp_events(:,1) >= idx_start & classified_events.tp_events(:,1) <= idx_stop;
                tp_events_on = classified_events.tp_events(classified_events.tp_events(:,2) > 0 & tp_events, 1);
                tp_events_off = classified_events.tp_events(classified_events.tp_events(:,2) < 0 & tp_events, 1);
                fn_events = classified_events.fn_events(:,1) >= idx_start & classified_events.fn_events(:,1) <= idx_stop;
                fn_events_on = classified_events.fn_events(classified_events.fn_events(:,2) > 0 & fn_events, 1);
                fn_events_off = classified_events.fn_events(classified_events.fn_events(:,2) < 0 & fn_events, 1);
                fp_events = classified_events.fp_events(:,1) >= idx_start & classified_events.fp_events(:,1) <= idx_stop;
                fp_events_on = classified_events.fp_events(classified_events.fp_events(:,2) > 0 & fp_events, 1);
                fp_events_off = classified_events.fp_events(classified_events.fp_events(:,2) < 0 & fp_events, 1);
                
                for ev = 1:size(tp_events_on, 1)
                    time = tp_events_on(ev, 1);
                    xval = datenum(day) + time/86400*granularity - d + 1;
                    plot([xval,xval],[0,max_cons], 'g-');
                end
                
                for ev = 1:size(tp_events_off, 1)
                    time = tp_events_off(ev, 1);
                    xval = datenum(day) + time/86400*granularity - d + 1;
                    plot([xval,xval],[0,max_cons], 'g--');
                end
                
                for ev = 1:size(fn_events_on, 1)
                    time = fn_events_on(ev, 1);
                    xval = datenum(day) + time/86400*granularity - d + 1;
                    plot([xval,xval],[0,max_cons], '-', 'Color', [0.5 0.5 0.5]);
                end
                
                for ev = 1:size(fn_events_off, 1)
                    time = fn_events_off(ev, 1);
                    xval = datenum(day) + time/86400*granularity - d + 1;
                    plot([xval,xval],[0,max_cons], '--', 'Color', [0.5 0.5 0.5]);
                end
                
                for ev = 1:size(fp_events_on, 1)
                    time = fp_events_on(ev, 1);
                    xval = datenum(day) + time/86400*granularity - d + 1;
                    plot([xval,xval],[0,max_cons], 'r-');
                end
                
                for ev = 1:size(fp_events_off, 1)
                    time = fp_events_off(ev, 1);
                    xval = datenum(day) + time/86400*granularity - d + 1;
                    plot([xval,xval],[0,max_cons], 'r--');
                end
                
                ylim([0 max_cons]);
                datetick('x','HHPM')
                % legend('Actual', 'Inferred'); % does not work
                title([appliance_name, ' - ', evaluation_days(d,:)])
                fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);
                filename = ['Events_', appliance_name, '_', evaluation_days(d,:)];
                % print('-depsc2', '-cmyk', '-r600', [plot_folder, filename, '.eps']); % if eps is needed
                saveas(fig, [plot_folder, filename, '.png'], 'png');
                close(fig);
            end
            i = i+1;
        end
    end

    %%%%%%%%%%%%%
    %% Plot inferred consumption and pie chart
    %%%%%%%%%%%%%
    if isfield(result, 'consumption')
        %% plot inferred plug data vs ground truth plug data
        i = 1;
        for appliance_name_cell = result.appliance_names
            appliance_name = cell2mat(appliance_name_cell);
            appliance_id = getApplianceID(appliance_name);
            plug_consumption = read_plug_data(dataset, household, appliance_id, evaluation_days, granularity);
            inferred_consumption = result.consumption(i,:);
            for d = 1:num_days
                day = evaluation_days(d,:);
                idx_start = 86400 / granularity * (d-1) + 1;
                idx_stop = 86400 / granularity * d;
                date_range = datenum(day)+granularity/86400 : granularity/86400 : datenum(day)+1;

                fig = figure;
                hold on;
                plot(date_range, plug_consumption(idx_start:idx_stop));
                plot(date_range, inferred_consumption(idx_start:idx_stop), 'r');
                if strcmp(appliance_name, 'Fridge') == 1 || strcmp(appliance_name, 'Freezer') == 1
                    ylim([0 500]);
                end
                datetick('x','HHPM')
                % legend('Actual', 'Inferred'); % does not work
                title([appliance_name, ' - ', evaluation_days(d,:)])
                fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);
                filename = ['Consumption_', appliance_name, '_', evaluation_days(d,:)];
                % print('-depsc2', '-cmyk', '-r600', [plot_folder, filename, '.eps']); % if eps is needed
                saveas(fig, [plot_folder, filename, '.png'], 'png');
                close(fig);
            end
            i = i+1;
        end

        %% plot ground truth smart meter data vs ground truth plug data and vs. ground truth inferred consumption
        i = 1;
        plug_consumption = {};
        inferred_consumption = {};
        for appliance_name_cell = result.appliance_names
            appliance_name = cell2mat(appliance_name_cell);
            appliance_id = getApplianceID(appliance_name);
            plug_consumption{i} = read_plug_data(dataset, household, appliance_id, evaluation_days, granularity);
            inferred_consumption{i} = result.consumption(i,:);
            i = i+1;
        end
        for d = 1:num_days
            day = evaluation_days(d,:);
            idx_start = 86400 / granularity * (d-1) + 1;
            idx_stop = 86400 / granularity * d;
            date_range = datenum(day)+granularity/86400 : granularity/86400 : datenum(day)+1;

            fig = figure;
            hold on;
            plot(date_range, total_consumption(idx_start:idx_stop));
            for j = 1:length(plug_consumption)
                 plot(date_range, plug_consumption{j}(idx_start:idx_stop));
            end
            datetick('x','HHPM')
            % legend('Actual', 'Inferred'); % does not work
            title(['Plug and Smart Meter - ', evaluation_days(d,:)])
            fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);
            filename = ['plug-and-smartmeter_', evaluation_days(d,:)];
            % print('-depsc2', '-cmyk', '-r600', [plot_folder, filename, '.eps']); % if eps is needed
            saveas(fig, [plot_folder, filename, '.png'], 'png');
            close(fig);
            fig = figure;
            hold on;
            plot(date_range, total_consumption(idx_start:idx_stop));
            for j = 1:length(plug_consumption)
                plot(date_range, inferred_consumption{j}(idx_start:idx_stop));
            end
            datetick('x','HHPM')
            % legend('Actual', 'Inferred'); % does not work
            title(['Inferred and Smart Meter -  - ', evaluation_days(d,:)])
            fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);
            filename = ['Smartmeter_', evaluation_days(d,:)];
            % print('-depsc2', '-cmyk', '-r600', [plot_folder, filename, '.eps']); % if eps is needed
            saveas(fig, [plot_folder, filename, '.png'], 'png');
            close(fig);
        end

        %% plot pie charts
        i = 1;
        plug_consumption = {};
        inferred_consumption = {};
        for appliance_name_cell = result.appliance_names
            appliance_name = cell2mat(appliance_name_cell);
            appliance_id = getApplianceID(appliance_name);
            tmp = read_plug_data(dataset, household, appliance_id, evaluation_days, granularity);
            valid_time = tmp ~= -1;
            plug_consumption{i} = mean(tmp(valid_time)) * num_days * 24;
            cons = result.consumption(i,:);
            inferred_consumption{i} = mean(cons(valid_time)) * num_days * 24;
            i = i+1; 
        end
        other_plugs = mean(total_consumption) * num_days * 24 - sum(cell2mat(plug_consumption));
        other_inferred = mean(total_consumption) * num_days * 24 - sum(cell2mat(inferred_consumption));
        fig = figure;
        hold on;
        subplot(1,2,1);
        pie([cell2mat(plug_consumption), other_plugs]);
        title('Ground truth');
        subplot(1,2,2);
        pie([cell2mat(inferred_consumption), other_inferred]);
        title('Inferred');
        fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);    
        filename = 'Pie_Chart';
        % print('-depsc2', '-cmyk', '-r600', [plot_folder, filename, '.eps']); % if eps is needed
        saveas(fig, [plot_folder, filename, '.png'], 'png');
        close(fig);
    end
end