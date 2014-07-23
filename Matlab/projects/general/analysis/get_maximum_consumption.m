base_folder_plugs = 'data/eco/plugs/';
end_date = '2013-01-31';
start_date = '2012-06-01';
num_days = datenum(end_date) - datenum(start_date) + 1;

household = 6;
plug = 8;

houseStr = num2str(household, '%02d');
plugStr = num2str(plug, '%02d');
source_folder = [ base_folder_plugs, houseStr, '/', plugStr, '/'];
for day = 1:num_days
    date = datestr(datenum(start_date) + day - 1, 'yyyy-mm-dd');
    source_file = [source_folder, date, '.mat'];
    if ~exist(source_file, 'file')
        continue;
    end
    vars = whos('-file',source_file);
    load(source_file);
    eval(['plug_data=' vars.name ';']);
    eval(['clear ' vars.name ';']);
    fprintf('Date: %s - Maximum: %.2f\n', date, max(plug_data.consumption));
end