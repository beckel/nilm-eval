% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

warning off MATLAB:dispatcher:nameConflict

addpath(genpath('algorithms'));
addpath(genpath('config'));
addpath(genpath('data_access'));
addpath(genpath('framework'));
addpath(genpath('lib'));
addpath(genpath('plot'));
addpath('projects/');
addpath('projects/buildsys/');
addpath('projects/buildsys/images/');
addpath(genpath('util'));

set(0,'DefaultTextFontname', 'Times New Roman');
set(0,'DefaultTextFontSize', 9);
set(0,'DefaultAxesFontName', 'Times New Roman');
set(0,'DefaultAxesFontSize', 9);
