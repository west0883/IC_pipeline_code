% RemoveArtifacts.m
% Sarah West
% 3/14/22

% Function that helps remove artifacts from images (intended for IC
% artifacts). Is the first function I'm writing that's called with
% RemoveArtifacts.m

% Needs to use:
% parameters.sources
% parameters.indices_of_mask
% parameters.reference_image

function [parameters] = RemoveArtifacts(parameters)

    % Grab sources and list of original/raw source numbers based on if user
    % wants to use the split domains or not. Default is to split. 
    if isfield(parameters, 'splitDomains') && ~parameters.splitDomains
        
        % If they don't want to split.
        
        % Grab sources
        sources = parameters.sources.color_mask_domainsTogether;

        % Define source_iterator & source_number based on location in keywords/values, use it for rest of analysis.
        source_iterator = parameters.values{find(contains(parameters.keywords,'source_iterator'))};
        source_number = str2num(parameters.values{find(contains(parameters.keywords,'source'))});

        % Find the original source numbers of the ICs
        originalSourceNumbers = parameters.sources.originalICNumber_domainsTogether';
        
    else

        % If they want to split

        % Grab sources
        sources = parameters.sources.color_mask_domainsSplit;
        
        % Define source_iterator based on location in keywords/values, use it for rest of analysis.
        source_iterator = parameters.values{find(strcmp(parameters.keywords,'source_iterator'))};
        source_number = str2num(parameters.values{find(strcmp(parameters.keywords,'source'))});

        % Find the original source numbers of the ICs
        originalSourceNumbers = parameters.sources.originalICNumber_domainsSplit';

    end
   
    % If no sources dimension defined, default to last dimension. Make
    % number of sources equal to 1. 
    if ~isfield(parameters, 'sourcesDim')
        parameters.sourcesDim = ndims(sources);
        number_of_sources = 1;
    else
        number_of_sources = size(sources, parameters.sourcesDim);
    end
    
    % Check if the current source iterator is greater than the number of
    % sources (can happen when you put an estimated maximum for source
    % ranges.) Go back to RunAnalysis if so. 
    if source_number > number_of_sources
        return
    end

    % Check if number of sources is greater than the max iterator for the
    % source iterator, give warning if so. 
    max_iteration = getfield(parameters.maxIterations, 'source_iterator'); 
    if max_iteration < number_of_sources
        disp('There are more sources than maximum iterations. You may need to increase your source iteration range.');
    end

    % Get the original source number for THIS source   
    original_source_iterator =originalSourceNumbers(source_number);

    % Set up a holder for a variable number of dimensions
    S = repmat({':'},1, ndims(sources));

    % Check to see if there was an existing artifacts removed structure. If
    % not, establish all fields.
    % This still works with looping through sources at RunAnalysis level b/c this is only called
    % before first source. 
    if ~isfield(parameters, 'sources_artifacts_removed')
    
       % Initialize list of indices to remove.
       parameters.sources_artifacts_removed.indices_to_remove = cell(number_of_sources,1);
       
       % Initialize empty list of sources to remove
       parameters.sources_artifacts_removed.sources_removed = [];
       
       % Initialize empty list of artifact masks. 
       parameters.sources_artifacts_removed.artifact_masks = cell(number_of_sources,1);
    end
    
    % Check if source was thrown out before, skip it.
    if ismember(source_number, parameters.sources_artifacts_removed.sources_removed)
        
        % Return to RunAnalysis loop, which will go to next source
        % iteration
        return
    end

    % Initialize matrix of artifact-removed sources. (Do each time so you
    % don't lose track of source_iterator and original_source_iterator).
    parameters.sources_artifacts_removed.sources = sources; 
    
    % Get the source out from the variable dimensions
    S{parameters.sourcesDim} = source_number;  
    source = sources(S{:});

    % Apply any existing masks to source. 
    existing_masks = parameters.sources_artifacts_removed.artifact_masks{source_number};
    % If there are pre-existing masks, apply them
    existing_mask_indices = [];
    for i=1:size(existing_masks,3)
        mask_flat=existing_masks(:,:,i);
        existing_mask_indices=[existing_mask_indices; find(mask_flat)]; 
    end
    source(existing_mask_indices)=0;
    
    % Grab original source.
    S2 = repmat({':'},1, ndims(parameters.original_sources));
    S2{parameters.originalSourcesDim} = original_source_iterator; 
    original_source = abs(parameters.original_sources(S2{:})); 

    % Put pixels of original IC into first dimension
    original_source = permute(original_source,[parameters.originalSourcesPixelsDim setxor(parameters.originalSourcesPixelsDim, 1:ndims(original_source))]);

    % Fill the mask of the original source. 
    original_source = FillMasks(original_source, parameters.indices_of_mask, size(source,1), size(source,2));

    % Make find indices where the source is.
    indices = find(source > 0);

    % Apply the mask to the reference image
    holder = NaN(size(parameters.reference_image));
    holder(parameters.indices_of_mask) = parameters.reference_image(parameters.indices_of_mask);
    reference_image = holder; 

    % For the contex image, put the source in the reference image. 
    reference_image_context = reference_image;
    reference_image_context(indices) = source(indices);
    
    % For image of brain behind the source, keep pixels of reference
    % image that are only the source.
    reference_image_brain = reference_image; 
    indices = find(source == 0); 
    reference_image_brain(indices) = 0; 

    % ****Arrange figure****;
    
    % Count number of small subplots needed. Count reference image 2x for
    % context & brain under IC images.
    small_subplots = 0;
    small_subplot_counter = 0;
    small_subplots_fields = {'reference_image'; 'reference_image'; 'overlay'; 'original_sources'};
    for i = 1:numel(small_subplots_fields)
        if isfield(parameters, small_subplots_fields{i})
            small_subplots = small_subplots + 1; 
        end
    end

    % Based on number of small subplots, get the arrangement of plots
    % (maximizes useable figure size)
    
    fig = figure; 

    % Make full-screen
    fig.WindowState = 'maximized';
    
    % Make figure title with all iterator values in it.
    sgtitle([strjoin(parameters.values(1:end/2), ', ' ) ]);
    
    % ** Context image **
    if isfield(parameters, 'reference_image')

        % Increase counter of what small subplot you're on;
        small_subplot_counter = small_subplot_counter + 1; 
        [subplots, ~, ~] = calculate_subplots(small_subplots, small_subplot_counter);

        % Plot 
        subplot(subplots(1), subplots(2),subplots(3));
        img = image(reference_image_context, 'CDataMapping', 'scaled');
        set(img, 'AlphaData', ~isnan(source)); % Make nans "transparent"
        title('Context');
    
        % Get the color range you'll use for the contex image.
        top1 = max(max(source));
        top2 = max(max(reference_image_context)); 
        cmap = [parula(top1 * 20); gray((top2)*20)];
        colormap(cmap);
        axis square; xticks([]); yticks([]); 

    end

    % ** Draw a figure showing the brain underneath the source.**
    if isfield(parameters, 'reference_image')

        % Increase counter of what small subplot you're on;
        small_subplot_counter = small_subplot_counter + 1; 
        
        [subplots, ~, ~] = calculate_subplots(small_subplots, small_subplot_counter);

        % Plot 
        subplot(subplots(1), subplots(2),subplots(3));
        img3 = imagesc(reference_image_brain);
        set(img3, 'AlphaData', ~isnan(source)); % Make nans "transparent"
        colormap(gca,[0.5 0.5 0.5; gray(256)]);
        reference_image_brain(find(reference_image_brain == 0)) = NaN;
        caxis([min(min(reference_image_brain)) max(max(reference_image_brain))]);
        title('brain beneath source');
        xticks([]); yticks([]); axis square; axis square; 
    end 

    % ** Draw a figure showing all sources together in an overlay.**
    if isfield(parameters, 'overlay')

        % Increase counter of what small subplot you're on;
        small_subplot_counter = small_subplot_counter + 1; 
        
        % Pull overlay out so you aren't changing it every time.
        overlay = parameters.overlay;

        % Make mask of current source 1+ the highest number, so it will be
        % plotted a set color every time. 
        indices = overlay == source_number; 
        overlay(indices) = number_of_sources + 1; 

        % Make a color map for the overlay, with the current source as red.
        cmap1 = [1 1 1; 0.50 0.50 0.50; parula(number_of_sources); 1 0 0];
        
        [subplots, ~, ~] = calculate_subplots(small_subplots, small_subplot_counter);

        % Plot 
        subplot(subplots(1), subplots(2),subplots(3));
        img1 = imagesc(overlay);    
        colormap(gca, cmap1); 
        title('(in red) with other sources');
        xticks([]); yticks([]); axis square;
    end
   
    % ** Draw a figure showing the original, un-thresholded source. ** 
    if isfield(parameters, 'original_sources')

        % Increase counter of what small subplot you're on;
        small_subplot_counter = small_subplot_counter + 1; 

        [subplots, ~, ~] = calculate_subplots(small_subplots, small_subplot_counter);

        % Plot 
        subplot(subplots(1), subplots(2),subplots(3));
        img1 = imagesc(original_source);    
        colormap(gca, parula(256)); caxis([0 10]); 
        title('corresponding raw source');
        xticks([]); yticks([]); axis square;
    end

    % Draw the source, where you're going to draw masks.
    [~, subplot_column, subplot_large_column] = calculate_subplots(small_subplots, small_subplot_counter);
    subplot(1,subplot_column, subplot_large_column); 
    img2 = imagesc(source);
    cmap2 = [0.5 0.5 0.5; parula(512)];
    colormap(gca, cmap2); colorbar; 
    xticks([]); yticks([]);  axis square;

    % Grab axis handle for drawing on with ManualMasking
    axis_for_drawing = gca; 

    % Arrange input dialogue options-- allowing for interaction with
    % figures
    opts.WindowStyle = 'normal';

    % *** Ask if the whole IC should be thrown out.***
    user_answer1= inputdlg(['Do you want to throw out this entire source as an artifact? y=yes, n=no'], 'User input', 1,{'n'}, opts); 
   
    %Convert the user's answer into a value
    answer1=user_answer1{1};
    
    % If the user's answer is y (being strict/difficult with this so
    % accidents are hard), mark it & move on to next source. Do nothing otherwise.
    if strcmp('y', answer1)
         
        % Note source for removal. 
        parameters.sources_artifacts_removed.indices_to_remove{source_number} = 'all'; 
        parameters.sources_artifacts_removed.sources_removed = [parameters.sources_artifacts_removed.sources_removed; source_number]; 

    else
        % Grab any existing masks
        existing_masks = parameters.sources_artifacts_removed.artifact_masks{source_number};
        
        % Set a "don't flip" value -- don't flip up-down for this sort of
        % masking.
        flip = false;

        % Run fine-tune removal of artifacts within ICs.
        [masks, indices_of_mask]=ManualMasking(source, existing_masks, axis_for_drawing, flip);
        
        % Take note of masks (need these for deleting individual masks later).
        parameters.sources_artifacts_removed.artifact_masks{source_number} = masks; 

        % Remove indices from source.  
        parameters.sources_artifacts_removed.indices_to_remove{source_number} = indices_of_mask;
        source(indices_of_mask) = 0; 
        parameters.sources_artifacts_removed.sources(S{:}) = source;
    end

    close all; 
   
    % Remove sources that should be removed. (Do this every time, is okay
    % because sources_artifacts_removed.sources is re-created each time.)
    S{parameters.sourcesDim} = parameters.sources_artifacts_removed.sources_removed;
    parameters.sources_artifacts_removed.sources(S{:}) = []; 

    % Update original (raw) source ID list with removed sources.
    originalSourceNumbers(parameters.sources_artifacts_removed.sources_removed) = [];
    parameters.sources_artifacts_removed.originalICNumbers =originalSourceNumbers;

    % Make an overlay (from scratch every time?)
    parameters.sources_artifacts_removed.overlay = zeros(size(source,1), size(source,2));
    S = repmat({':'},1, ndims(parameters.sources_artifacts_removed.sources));
    for i = 1: size(parameters.sources_artifacts_removed.sources, parameters.sourcesDim)
        S{parameters.sourcesDim} = i; 
        source_for_overlay = parameters.sources_artifacts_removed.sources(S{:});
        parameters.sources_artifacts_removed.overlay(source_for_overlay > 0) = i;
        
    end 

    % Ask if the user wants to work on next source.
    user_answer1= inputdlg(['Do you want to work on the next source? y = yes, n = no'], 'User input', 1,{'n'}, opts); 

    % Convert the user's answer into a value
    answer1=user_answer1{1};

    % If user didn't want to continue to next source, set continue flag to
    % false (need to assume sources is the lowest level of iteration for now)
    if strcmp(answer1, 'y')
        parameters.continue_flag{end} = true;
    else    
        parameters.continue_flag{end} = false;

        % Tell RunAnalysis to save this iteration
        parameters.save_now = true;
    end
    
    % If this was the max source number or user said they didn't want to 
    % work on next source, ask user if they want to work on next dataset; 
    if source_number == number_of_sources || ~strcmp(answer1, 'y')
       
        %  Don't ask if there aren't multiple levels of iterators,
        if numel(parameters.continue_flag) > 1
            
            % Don't ask if you're already on the last data set, (need to
            % assume sources is the lowest level of iteration for now)
            next_iterator_up = parameters.values{end-1};
            next_max_iteration = parameters.maxIterations.numbers_only(end-1);
    
            if next_iterator_up < next_max_iteration

                user_answer1= inputdlg(['Do you want to work on the next data set? y = yes, n = no'], 'User input', 1,{'n'}, opts); 
            
                % Convert the user's answer into a value
                answer1=user_answer1{1};
                
                % If user didn't want to continue to next dataset, set continue flag one level up to false
                if strcmp(answer1, 'y')
                    parameters.continue_flag{end-1} = true;
                else    
                    parameters.continue_flag {end-1}= false;
        
                    % Tell RunAnalysis to save this iteration-- will include all
                    % recursive edits to parameters structure
                    parameters.save_now = true;
                end
            end 
        end
    end
end 

function [subplots, subplot_column, subplot_large_column] = calculate_subplots(small_subplots, small_subplot_counter)
    switch small_subplots
        case {1, 2}
            subplot_row = 2;
            subplot_column = 3; 
            subplot_large_column = 2:3;
            subplots = [subplot_row, subplot_column,(small_subplot_counter -1)*subplot_column +1];

        case 3 
            subplot_row = 3;
            subplot_column = 3; 
            subplot_large_column = 2:3;
            subplots = [subplot_row, subplot_column,((small_subplot_counter -1)*subplot_column +1)];
        
        case 4
            subplot_row = 2;
            subplot_column = 4; 
            subplot_large_column = 3:4;
            if small_subplot_counter < 3
                subplots = [subplot_row, subplot_column,((small_subplot_counter-1).*subplot_column +1)];
            else
                subplots = [subplot_row, subplot_column,((small_subplot_counter -1).*subplot_column +2 - subplot_row .*subplot_column)];
            end

        case 0
            subplots = [ 1 1 1];
            subplot_column = 1; 
            subplot_large_column = 1;
    end
end 