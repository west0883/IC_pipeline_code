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
parameters.dir_input_mask=[parameters.dir_exper 'masks\'];
parameters.mask_filename={'masks_m', 'mouse number', '.mat' };
parameters.mask_variable = {'indices_of_mask'};

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
parameters.area_threshold=300;

% Indicate if you want to z-score your ICs before regularizing (true/false)
parameters.zscore_flag = false; 

%% Calculate ICs
% Calculates ICs from SVD compressed data. Assumes one compressed dataset
% per mouse.

% output directory & filename
parameters.dir_out = {[parameters.dir_exper 'spatial segmentation\raw ICs\'], 'mouse number', '\'};
parameters.output_filename = {['sources' num2str(parameters.num_sources) '.mat']};

true_false_vector = [true false];

for i = 1: numel(true_false_vector)%true_false_vector
% Use a gpu for this calculation? (t/f)
parameters.use_gpu = true_false_vector(i);

% (DON'T EDIT). Run code. 
calculate_ICs(parameters); 
end 
%% Plot raw ICs
% Determine how many subplots you want for displaying your individual ICs.
parameters.plot_sizes=[10,10]; 

% Input directory 
parameters.dir_input_base = {[parameters.dir_exper 'spatial segmentation\raw ICs\'], 'mouse number', '\'};
parameters.input_filename = {['sources' num2str(parameters.num_sources) '.mat']};
parameters.input_variable = {'sources'};

% output directory
parameters.dir_output_base = {[parameters.dir_exper 'spatial segmentation\raw ICs\'], 'mouse number', '\'};
parameters.output_filename = {['sources' num2str(parameters.num_sources)]};

% Run code
plot_rawICs(parameters); 

%% Regularize ICs

% Determine how many subplots you want for displaying your individual ICs.
parameters.plot_sizes=[6,8]; 

% Input directory 
parameters.dir_input_base = {[parameters.dir_exper 'spatial segmentation\raw ICs\'], 'mouse number', '\'};
parameters.input_filename = {['sources' num2str(parameters.num_sources) '.mat']};
parameters.input_variable = {'sources'};

% output directory
parameters.dir_output_base = {[parameters.dir_exper 'spatial segmentation\regularized ICs_' num2str(parameters.area_threshold) 'pixels\'], 'mouse number', '\'};
parameters.output_filename = {['sources' num2str(parameters.num_sources) '.mat']};
parameters.output_variable = {'sources'};

% (DON'T EDIT). Run code. 
regularize_ICs(parameters);

%% Remove IC artifacts (interactive)

% Dimension different sources are in.
parameters.sourcesDim = 3;

% Dimension the pixels dimension of original data is in.
parameters.originalSourcesPixelsDim = 2; 

% Loop variables
parameters.loop_list.iterators = {'mouse', {'mice_all(:).name'}, 'mouse_iterator';
                                  'source', {'size(sources.color_mask_domainssplit, parameters.sourcesDim)'}, 'source_iterator'};

parameters.loop_variables.mice_all = parameters.mice_all;

% Input values
parameters.loop_list.things_to_load.sources.dir = {[parameters.dir_exper 'spatial segmentation\regularized ICs_' num2str(parameters.area_threshold) 'pixels\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources.filename= {['sources' num2str(parameters.num_sources) '.mat']};
parameters.loop_list.things_to_load.sources.variable= {'sources'};
parameters.loop_list.things_to_load.sources.level = 'mouse';

parameters.loop_list.things_to_load.indices_of_mask.dir = {[parameters.dir_exper 'masks/']};
parameters.loop_list.things_to_load.indices_of_mask.filename= {'masks_m', 'mouse', '.mat'};
parameters.loop_list.things_to_load.indices_of_mask.variable= {'indices_of_mask'}; 
parameters.loop_list.things_to_load.indices_of_mask.level = 'mouse';

parameters.loop_list.things_to_load.reference_image.dir = {[parameters.dir_exper 'representative images\'], 'mouse', '\'};
parameters.loop_list.things_to_load.reference_image.filename= {'reference_image.mat'};
parameters.loop_list.things_to_load.reference_image.variable= {'reference_image'};
parameters.loop_list.things_to_load.reference_image.level = 'mouse';

parameters.loop_list.things_to_load.original_ICs.dir = {[parameters.dir_exper '\spatial segmentation\raw ICs\'], 'mouse', '\'};
parameters.loop_list.things_to_load.original_ICs.filename= {['sources' num2str(parameters.num_sources) '.mat']};
parameters.loop_list.things_to_load.original_ICs.variable= {'sources'};
parameters.loop_list.things_to_load.original_ICs.level = 'mouse';

% (for any existing artifact removals)
parameters.loop_list.things_to_load.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\artifacts_removed\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources_artifacts_removed.filename = {'sources.mat'};
parameters.loop_list.things_to_load.sources_artifacts_removed.variable= {'sources'};
parameters.loop_list.things_to_load.sources_artifacts_removed.level = 'mouse';

% Output values
parameters.loop_list.things_to_save.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\artifacts_removed\'], 'mouse', '\'};
parameters.loop_list.things_to_save.sources_artifacts_removed.filename = {'sources.mat'};
parameters.loop_list.things_to_save.sources_artifacts_removed.variable= {'sources'};
parameters.loop_list.things_to_save.sources_artifacts_removed.level = 'mouse';

RunAnalysis({@RemoveArtifacts}, parameters);

%% Group ICs into catalogues (interactive)
% (from locomotion paper):
% IC_groups_eachmouse.m
% make_official_catalogue_permouse.m
% find_coordinates_official_mousecatalogues.m

%% Apply IC masks to data & extract
% (from locomotion paper):
% GraphAnalysis_Sarah_finalcatalogues.m
