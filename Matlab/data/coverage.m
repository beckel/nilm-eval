% goes through all matlab files in the folder
% loads file
% saves as CSV file

base_folder_smartmeter = 'data/eco/smartmeter/';
base_folder_plugs = 'data/eco/plugs/';
process_smart_meter = 0;
process_plugs = 1;

end_date = '2013-01-31';
start_date = '2012-06-01';
num_days = datenum(end_date) - datenum(start_date) + 1;

household = [ 6 ];
plugs = [ 3 ];

for h = household

    houseStr = num2str(h, '%02d');
    
	%% smart meter
    if process_smart_meter == 1
        fprintf('\nProcessing smart meter of household %s\n', houseStr);
        source_folder = [base_folder_smartmeter, houseStr, '/'];
        missing_values = 0;
        existing_days = 0;
        for day = 1:num_days
            date = datestr(datenum(start_date) + day - 1, 'yyyy-mm-dd');
            source_file = [source_folder, date, '.mat'];
            if ~exist(source_file, 'file')
                continue;
            end
            existing_days = existing_days + 1;
            vars = whos('-file',source_file);
            load(source_file);
            eval(['smartmeter_data=' vars.name ';']);
            eval(['clear ' vars.name ';']);
            missing_values = missing_values + sum(smartmeter_data.powerallphases == -1);
        end
        total_values = existing_days*86400;
        cvg = (1 - (missing_values / total_values)) * 100;
        fprintf('Household %s - Smart Meter - No. days: %d, missing values: %d, coverage: %.2f\n', houseStr, existing_days, missing_values, cvg);
    end
    
    if process_plugs == 1
        fprintf('\nProcessing plugs of household %s\n', houseStr);
        for plug = plugs
            plugStr = num2str(plug, '%02d');
            source_folder = [ base_folder_plugs, houseStr, '/', plugStr, '/'];
            if ~exist(source_folder, 'dir')
                continue;
            end
            progress = 0;
            missing_values = 0;
            existing_days = 0;
            for day = 1:num_days
                date = datestr(datenum(start_date) + day - 1, 'yyyy-mm-dd');
                source_file = [source_folder, date, '.mat'];
                if ~exist(source_file, 'file')
                    continue;
                end
                existing_days = existing_days + 1;
                vars = whos('-file',source_file);
                load(source_file);
                eval(['plug_data=' vars.name ';']);
                eval(['clear ' vars.name ';']);
                missing_values = missing_values + sum(plug_data.consumption == -1);
            end
            total_values = existing_days*86400;
            cvg = (1 - (missing_values / total_values)) * 100;
            fprintf('Household %s - Plug %s - No. days: %d, missing values: %d, coverage: %.2f\n', houseStr, plugStr, existing_days, missing_values, cvg);
        end
    end
end
