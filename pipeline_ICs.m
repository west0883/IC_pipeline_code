%% pipeline_ICs_MotorizedTreadmill.m
% Sarah West
% 9/1/21

% After preprocessing data and SVD compressing all data from a mouse into one compression
% with the supercomputers, use this code to calculate and clean the ICs of each animal. 

% **Use and run create_days_all.m before using this***

%% Initial Setup  

clear all; 

% ***********************************
% Directories

% Create the experiment name. This is used to name the output folder. 
parameters.experiment_name='Random Motorized Treadmill';

% Create the input directory of the SVD compressed datasets for each mouse
parameters.dir_dataset=['Y:\Sarah\Analysis\Experiments\' parameters.experiment_name '\spatial segmentation\SVD compressions\'];

% Establish the format of the file names of compressed data. Each piece
% needs to be a separate entry in a cell array. Put the string 'mouse', 'day',
% or 'stack number' where the mouse, day, or stack number will be. If you 
% concatenated this as a sigle string, it should create a file name, with the 
% correct mouse/day/stack name inserted accordingly. 
parameters.compressed_data_name={parameters.dir_dataset, 'm', 'mouse number', '_SVD_compressed.mat'}; 

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% Was the data masked in preprocessing? (Masking that removed pixels, so
% masks have to be loaded in to reshape the data into proper images).
% If it was masked, the flag = 1; If not masked, the flag = 0.
parameters.masked_flag=1; 

% Directory of where the masks are saved. If not masked, can leave this
% empty. If masked, use the cell array format as above. 
parameters.dir_masked=[parameters.dir_exper 'masks\'];
parameters.masks_name={parameters.dir_masked, 'masks_m', 'mouse number', '.mat' };

% Compressed component that represents [spatial dimension]. Will be 'S' or
% 'V', with the number of (masked) pixels as one of the dimensions. Put in 
% as a character with quotes.
parameters.spatial_component='V'; 

% (DON'T EDIT). Load the "mice_all" variable you've created with "create_mice_all.m"
load([parameters.dir_exper 'mice_all.mat']);

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
parameters.mice_all=mice_all;

parameters.mice_all=parameters.mice_all(1);

% ****************************************
% ***Parameters.*** 

% Set image dimensions.
parameters.yDim=256;
parameters.xDim=256;

% The number of ICs you want to calculate. 
parameters.num_sources=100;

% For cleaning the ICs
% Applies a (raw) threshold to the ICs.
parameters.amplitude_threshold=3.5; 

% Minimim size in pixels of an IC.
parameters.area_threshold=150;

% Indicate if you want to z-score your ICs before regularizing (1 = yes, 0
% = no).
parameters.zscore_flag = 0; 

%% Calculate ICs
% Calculates ICs from SVD compressed data. Assumes one compressed dataset
% per mouse.

% output directory & filename
parameters.dir_out = {parameters.dir_exper, 'spatial segmentation\raw ICs\', 'mouse_number', '\'};
parameteres.ouput_filename = {[num2str(parameters.num_sources) 'sources.mat']};

% (DON'T EDIT). Run code. 
calculate_ICs(parameters); 

%% Plot raw ICs
% Determine how many subplots you want for displaying your individual ICs.
parameters.plot_sizes=[10,10]; 

% output directory
parameters.dir_out = {dir_exper, 'spatial segmentation\raw ICs\', 'mouse_number', '\'};

% Run code
plot_rawICs(parameters); 

%% Regularize ICs

% Determine how many subplots you want for displaying your individual ICs.
parameters.plot_sizes=[5,12]; 

% (DON'T EDIT). Run code. 
regularize_ICs(parameters);

%% Remove IC artifacts (interactive)
% (from locomotion paper):
% remove_artifacts_from_catalogues.m
% remove_artifacts_from_catalogues_finetune.m

%% Group ICs into catalogues (interactive)
% (from locomotion paper):
% IC_groups_eachmouse.m
% make_official_catalogue_permouse.m
% find_coordinates_official_mousecatalogues.m

%% Apply IC masks to data & extract
% (from locomotion paper):
% GraphAnalysis_Sarah_finalcatalogues.m
