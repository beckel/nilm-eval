import os
from os import listdir
from os.path import isfile, join

# generates runfile to be used on brutus
# first version by Christian Beckel

algorithm = "parsonAppliance"   # set by user
configuration = "microwaveInitial"      # set by user
experiment = "house5_meanOn_varOn_filt_phaseIndv_transOff"

path_to_experiment = algorithm + "_" + configuration + "/" + experiment
path_to_setup_files = "input/autogen/experiments/setups/" + path_to_experiment

path_to_results = "results/brutus/" + path_to_experiment 
if not os.path.exists(path_to_results):
	os.makedirs(path_to_results)
	
text = '#/bin/bash\n\n'
files = [ f for f in listdir(path_to_setup_files) if isfile(join(path_to_setup_files,f)) ]
for i in range(len(files)):
    filename = str(files[i])
    filename_split = filename.split('.')
    text += "bsub -W 1:00 -o results/brutus/" + path_to_experiment + "/lsf." + filename_split[0] + " matlab -nodisplay -singleCompThread -r \'eval_system" + " " + path_to_setup_files + "/" + str(files[i]) + "\'\n"
	
d = "input/autogen/runfiles/" + algorithm + "_" + configuration
if not os.path.exists(d):
	os.makedirs(d)
f_out = open(d + "/" + experiment, 'w')
f_out.write(text)
f_out.close()
