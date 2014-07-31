% % This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% % Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% % Copyright: ETH Zurich, 2014
% % Author: Romano Cicchetti
% 
% function create_configuration()
% 
%     algorithm = 'weiss';
%     configuration = 'initial';
%     
%     % create a new default configuration
%     
%     % load default values in yaml file
%     yaml_file = strcat('input/default_values/', algorithm, '.yaml');
%     default = ReadYaml(yaml_file);
%     
%     % set default values
%     field_names = fieldnames(default);
%     for field_name = field_names'
%         default.(field_name{1}) = cell2mat(default.(field_name{1}));
%     end
%     
%     % save default values in matlab file and a new yaml file
%     path_to_configuration = strcat('input/autogen/configurations/', algorithm, '_', configuration);
%     if ~exist(path_to_configuration, 'dir')
%         mkdir(path_to_configuration); 
%     end
%     save(strcat(path_to_configuration, '/default_values.mat'), 'default');
%     copyfile(yaml_file, strcat(path_to_configuration, '/default_values.yaml'));
% 
% end
