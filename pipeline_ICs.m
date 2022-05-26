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
parameters.dir_dataset=['Y:\Sarah\Analysis\Experiments\' parameters.experiment_name '\spatial segmentation\500 SVD components\SVD compressions\'];

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

% Number of digits you want in your stack number names (default is 3).
parameters.digitNumber = 2; 

% Use split domain ICs?
parameters.splitDomains = true;

%% Calculate ICs
% Calculates ICs from SVD compressed data. Assumes one compressed dataset
% per mouse.

% output directory & filename
parameters.dir_out = {[parameters.dir_exper 'spatial segmentation\1000 SVD components\raw ICs\'], 'mouse number', '\'};
parameters.output_filename = {['sources' num2str(parameters.num_sources) '.mat']};

% Use a gpu for this calculation? (t/f)
parameters.use_gpu = true;

% (DON'T EDIT). Run code. 
calculate_ICs(parameters); 


%% Plot raw ICs

% Input directory 
parameters.dir_input_base = {[parameters.dir_exper 'spatial segmentation\200 SVD components\raw ICs\'], 'mouse number', '\'};
parameters.input_filename = {['sources' num2str(parameters.num_sources) '.mat']};
parameters.input_variable = {'sources'};

% output directory
parameters.dir_output_base = {[parameters.dir_exper 'spatial segmentation\200 SVD components\raw ICs\'], 'mouse number', '\'};
parameters.output_filename = {['sources' num2str(parameters.num_sources)]};

% Run code
plot_rawICs(parameters); 

%% Regularize ICs 

% Input directory 
parameters.dir_input_base = {[parameters.dir_exper 'spatial segmentation\200 SVD components\raw ICs\'], 'mouse number', '\'};
parameters.input_filename = {['sources' num2str(parameters.num_sources) '.mat']};
parameters.input_variable = {'sources'};

% output directory
parameters.dir_output_base = {[parameters.dir_exper 'spatial segmentation\200 SVD components\regularized ICs_' num2str(parameters.area_threshold) 'pixels\'], 'mouse number', '\'};
parameters.output_filename = {['sources' num2str(parameters.num_sources) '.mat']};
parameters.output_variable = {'sources'};

% (DON'T EDIT). Run code. 
regularize_ICs(parameters);

%% Remove IC artifacts (interactive)

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Dimension different sources are in.
parameters.sourcesDim = 3;

% Dimension the pixels dimension, different sources dimension of original data.
parameters.originalSourcesPixelsDim = 2; 
parameters.originalSourcesDim = 1; 

% Loop variables
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
                                  'source', {'7:50'}, 'source_iterator'};
parameters.loop_variables.mice_all = parameters.mice_all;

% Input values
parameters.loop_list.things_to_load.sources.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\regularized ICs_' num2str(parameters.area_threshold) 'pixels\'], 'mouse', '\'};
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

% [Right now, code assumes raw sources are in same file, I think it still
% works if it's each source separate.]
parameters.loop_list.things_to_load.original_sources.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\raw ICs\'], 'mouse', '\'};
parameters.loop_list.things_to_load.original_sources.filename= {['sources' num2str(parameters.num_sources) '.mat']};
parameters.loop_list.things_to_load.original_sources.variable= {'sources'};
parameters.loop_list.things_to_load.original_sources.level = 'mouse';

% (for any existing artifact removals)
parameters.loop_list.things_to_load.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\artifacts_removed\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources_artifacts_removed.filename = {'sources.mat'};
parameters.loop_list.things_to_load.sources_artifacts_removed.variable= {'sources'};
parameters.loop_list.things_to_load.sources_artifacts_removed.level = 'mouse';

% Output values
parameters.loop_list.things_to_save.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\artifacts_removed\'], 'mouse', '\'};
parameters.loop_list.things_to_save.sources_artifacts_removed.filename = {'sources.mat'};
parameters.loop_list.things_to_save.sources_artifacts_removed.variable= {'sources'};
parameters.loop_list.things_to_save.sources_artifacts_removed.level = 'mouse';

RunAnalysis({@RemoveArtifacts}, parameters);

%% Return any deleted ICs you deleted by accident.
% % Loop variables
% parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'};
% parameters.loop_variables.mice_all = parameters.mice_all;
% 
% % Inputs 
% % Sources
% parameters.loop_list.things_to_load.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\artifacts_removed\'], 'mouse', '\'};
% parameters.loop_list.things_to_load.sources_artifacts_removed.filename = {'sources.mat'};
% parameters.loop_list.things_to_load.sources_artifacts_removed.variable= {'sources'};
% parameters.loop_list.things_to_load.sources_artifacts_removed.level = 'mouse';
% 
% % Masks
% parameters.loop_list.things_to_load.indices_of_mask.dir = {[parameters.dir_exper 'masks/']};
% parameters.loop_list.things_to_load.indices_of_mask.filename= {'masks_m', 'mouse', '.mat'};
% parameters.loop_list.things_to_load.indices_of_mask.variable= {'indices_of_mask'}; 
% parameters.loop_list.things_to_load.indices_of_mask.level = 'mouse';


% Outputs (editing the same file)
% parameters.loop_list.things_to_load.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\artifacts_removed\'], 'mouse', '\'};
% parameters.loop_list.things_to_load.sources_artifacts_removed.filename = {'sources.mat'};
% parameters.loop_list.things_to_load.sources_artifacts_removed.variable= {'sources'};
% parameters.loop_list.things_to_load.sources_artifacts_removed.level = 'mouse';
% 
% RunAnalysis({@RestoreSources}, parameters);


%% Plot resulting cleaned ICs
% Always clear loop list first. 
% if isfield(parameters, 'loop_list')
% parameters = rmfield(parameters,'loop_list');
% end
% 
% % Dimension different sources are in.
% parameters.sourcesDim = 3;
% 
% % Loop variables
% parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'};
% parameters.loop_variables.mice_all = parameters.mice_all;
% 
% % Input variables
% parameters.loop_list.things_to_load.sources_overlay.dir = {[parameters.dir_exper 'spatial segmentation\artifacts_removed\'], 'mouse', '\'};
% parameters.loop_list.things_to_load.sources_overlay.filename = {'sources.mat'};
% parameters.loop_list.things_to_load.sources_overlay.variable= {'sources.overlay'};
% parameters.loop_list.things_to_load.sources_overlay.level = 'mouse';
% 
% % Output variables
% parameters.loop_list.things_to_save.sources_overlay.dir = {[parameters.dir_exper 'spatial segmentation\artifacts_removed\'], 'mouse', '\'};
% parameters.loop_list.things_to_save.sources_overlay.filename = {'sources_overlay.fig'};
% parameters.loop_list.things_to_save.sources_overlay.level = 'mouse';
% 
% parameters.loop_list.things_to_save.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\artifacts_removed\'], 'mouse', '\'};
% parameters.loop_list.things_to_save.sources_artifacts_removed.filename = {'sources_overlay.fig'};
% parameters.loop_list.things_to_save.sources_artifacts_removed.level = 'mouse';
% 
% % For now, assume everything was saved as structures from RemoveArtifacts.m
% RunAnalysis({@PlotSourceOverlays}, parameters);

%% Align atlases 
% (Get from the LocaNMF preprocessing pipeline folder you made)

%% Find best atlas locations. 
% (from locomotion paper):
% IC_groups_eachmouse.m
% make_official_catalogue_permouse.m
% find_coordinates_official_mousecatalogues.m

% Always clear loop list first. 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Dimension different sources are in.
parameters.sourcesDim = 3;

% Loop variables; iterate through mice, sources
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'};
parameters.loop_variables.mice_all = parameters.mice_all;

% Load aligned atlas. 
parameters.loop_list.things_to_load.atlas.dir = {[parameters.dir_exper 'spatial segmentation\aligned atlases\'], 'mouse'};
parameters.loop_list.things_to_load.atlas.filename= {'atlas.mat'};
parameters.loop_list.things_to_load.atlas.variable= {'atlas'}; 
parameters.loop_list.things_to_load.atlas.level = 'mouse';

% Load corresponding atlas region names
parameters.loop_list.things_to_load.region_names.dir = {[parameters.dir_exper 'spatial segmentation\aligned atlases\'], 'mouse'};
parameters.loop_list.things_to_load.region_names.filename= {'atlas.mat'};
parameters.loop_list.things_to_load.region_names.variable= {'regions'}; 
parameters.loop_list.things_to_load.region_names.level = 'mouse';

% Load mouse's mask, if necessary.
parameters.loop_list.things_to_load.indices_of_mask.dir = {[parameters.dir_exper 'preprocessing\masks\']};
parameters.loop_list.things_to_load.indices_of_mask.filename= {'masks_m', 'mouse', '.mat'};
parameters.loop_list.things_to_load.indices_of_mask.variable= {'indices_of_mask'}; 
parameters.loop_list.things_to_load.indices_of_mask.level = 'mouse';

% Load sources with artifacts removed
parameters.loop_list.things_to_load.sources_artifacts_removed.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\artifacts_removed\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources_artifacts_removed.filename = {'sources.mat'};
parameters.loop_list.things_to_load.sources_artifacts_removed.variable= {'sources.sources'};
parameters.loop_list.things_to_load.sources_artifacts_removed.level = 'mouse';

% Also load sources WITHOUT artifacts removed (regularized only,to get the original center
% of mass and area). 
parameters.loop_list.things_to_load.sources.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\regularized ICs_' num2str(parameters.area_threshold) 'pixels\'], 'mouse', '\'};
parameters.loop_list.things_to_load.sources.filename= {['sources' num2str(parameters.num_sources) '.mat']};
parameters.loop_list.things_to_load.sources.variable= {'sources'};
parameters.loop_list.things_to_load.sources.level = 'mouse';

% Save metrics 
parameters.loop_list.things_to_save.metrics.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\best region fit\'], 'mouse', '\'};
parameters.loop_list.things_to_save.metrics.filename= {'best_region_fit_metrics.mat'};
parameters.loop_list.things_to_save.metrics.variable= {'metrics'};
parameters.loop_list.things_to_save.metrics.level = 'mouse';

% Save figure of sources over atlas that meet a single best region
parameters.loop_list.things_to_save.figure_best_fit.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\best region fit\'], 'mouse', '\'};
parameters.loop_list.things_to_save.figure_best_fit.filename= {'best_region_fit.fig'};
parameters.loop_list.things_to_save.figure_best_fit.variable= {};
parameters.loop_list.things_to_save.figure_best_fit.level = 'mouse';

% Save figure of sources of atlas that have multiple potential best regions 
parameters.loop_list.things_to_save.figure_multiple_best_fit.dir = {[parameters.dir_exper 'spatial segmentation\500 SVD components\best region fit\'], 'mouse', '\'};
parameters.loop_list.things_to_save.figure_multiple_best_fit.filename= {'multiple_best_region_fit.fig'};
parameters.loop_list.things_to_save.figure_multiple_best_fit.variable= {};
parameters.loop_list.things_to_save.figure_multiple_best_fit.level = 'mouse';

% Run code
RunAnalysis({@FindAtlasRegions}, parameters);

%% Apply IC masks to data & extract
% (from locomotion paper):
% GraphAnalysis_Sarah_finalcatalogues.m
