% goes through all matlab files in the folder
% loads file
% saves as CSV file

base_folder_smartmeter = 'data/eco/smartmeter/';
base_folder_plugs = 'data/eco/plugs/';
target_folder_smartmeter = 'data/eco/smartmeter_csv/';
target_folder_plugs = 'data/eco/plugs_csv/';
process_smart_meter = 1;
process_plugs = 0;

% household = [ 2:6 ];
% plugs = [ 1:12 ];
household = [ 4 ];
plugs = [ 3, 8 ];

for h = household

    houseStr = num2str(h, '%02d');
    
	%% smart meter
    if process_smart_meter == 1
        source_folder = [base_folder_smartmeter, houseStr, '/'];
        target_folder = [target_folder_smartmeter, houseStr, '/'];
        if ~exist(target_folder, 'dir')
            mkdir(target_folder);
        end
        files = dir([source_folder, '*.mat']);
        for day = 1:size(files,1)
            fprintf('Processing smart meter household %s, day %d of %d\n', houseStr, day, size(files,1));
            filename = files(day,1).name;
            source_file = [source_folder, filename];
            vars = whos('-file',source_file);
            load(source_file);
            eval(['smartmeter_data=' vars.name ';']);
            eval(['clear ' vars.name ';']);
            data_to_write = [ ... 
                smartmeter_data.powerallphases ... 
                smartmeter_data.powerl1 ... 
                smartmeter_data.powerl2 ... 
                smartmeter_data.powerl3 ... 
                smartmeter_data.currentneutral ... 
                smartmeter_data.currentl1 ... 
                smartmeter_data.currentl2 ... 
                smartmeter_data.currentl3 ... 
                smartmeter_data.voltagel1 ... 
                smartmeter_data.voltagel2 ... 
                smartmeter_data.voltagel3 ... 
                smartmeter_data.phaseanglevoltagel2l1 ... 
                smartmeter_data.phaseanglevoltagel3l1 ... 
                smartmeter_data.phaseanglecurrentvoltagel1 ... 
                smartmeter_data.phaseanglecurrentvoltagel2 ... 
                smartmeter_data.phaseanglecurrentvoltagel3 ... 
            ];
            dlmwrite([target_folder, filename(1:end-4), '.csv'], data_to_write, 'precision', 9);
        end
    end
    
    if process_plugs == 1
        for plug = plugs
            plugStr = num2str(plug, '%02d');
            plug_dir = [ base_folder_plugs, houseStr, '/', plugStr, '/'];
            if ~exist(plug_dir, 'dir')
                continue;
            end
            target_folder = [target_folder_plugs, houseStr, '/', plugStr, '/'];
            if ~exist(target_folder, 'dir')
                mkdir(target_folder)
            end
            files = dir([plug_dir, '*.mat']);
            for day = 1:size(files,1)
                fprintf('Processing plug %s for household %s, day %d of %d\n', plugStr, houseStr, day, size(files,1));
                filename = files(day,1).name;
                source_file = [plug_dir, filename];
                vars = whos('-file',source_file);
                load(source_file);
                eval(['plug_data=' vars.name ';']);
                eval(['clear ' vars.name ';']);
                data_to_write = plug_data.consumption;
                dlmwrite([target_folder, filename(1:end-4), '.csv'], data_to_write, 'precision', 9);		
            end			
        end
    end
end
