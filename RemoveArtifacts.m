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

    % Convert to an easier-to-use parameter name
    sources = parameters.sources.color_mask_domainssplit;

    % Set up a holder for a variable number of dimensions
    S = repmat({':'},1, ndims(sources));
   
    % If no sources dimension defined, default to last dimension. Make
    % number of sources equal to 1. 
    if ~isfield(parameters, 'sourcesDim')
        parameters.sourcesDim = ndims(sources);
        number_of_sources = 1;
    else
        number_of_sources = size(sources, parameters.sourcesDim);
    end
    
    % Define source_iterator based on location in keywords/values, use it for rest of analysis.
    source_iterator = parameters.values{find(contains(parameters.keywords,'source_iterator'))};
    
    % Check if the current source iterator is greater than the number of
    % sources (can happen when you put an estimated maximum for source
    % ranges.) Go back to RunAnalysis if so. 
    if source_iterator > number_of_sources
        return
    end

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
    if ismember(source_iterator, parameters.sources_artifacts_removed.sources_removed)
        
        % Return to RunAnalysis loop, which will go to next source
        % iteration
        return
    end

    % Initialize matrix of artifact-removed sources. (Do each time so you
    % don't lose track of source_iterator and original_source_iterator).
    parameters.sources_artifacts_removed.sources = sources; 
    
    % Get the source out from the variable dimensions
    S{parameters.sourcesDim} = source_iterator;  
    source = sources(S{:});

    % Find the original source number of the IC you want. 
    original_source_iterator = parameters.sources.originalICNumber_domainsSplit(source_iterator);
    
    % Grab original source.
    S2 = repmat({':'},1, ndims(parameters.original_ICs));
    S2{parameters.originalSourcesDim} = original_source_iterator; 
    original_source = abs(parameters.original_ICs(S2{:})); 

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
    fig = figure; 

    % Make full-screen
    fig.WindowState = 'maximized';
    
    % Make figure title with all iterator values in it.
    sgtitle([strjoin(parameters.values(1:end/2), ', ' ) ]);
    
    % ** Context image **
    subplot(3,3,1);
    img = image(reference_image_context, 'CDataMapping', 'scaled');
    set(img, 'AlphaData', ~isnan(source)); % Make nans "transparent"
    title('Context');
    
    % Get the color range you'll use for the contex image.
    top1 = max(max(source));
    top2 = max(max(reference_image_context)); 
    cmap = [parula(top1 * 10); gray((top2)*20)];
    colormap(cmap);
    axis square; xticks([]); yticks([]); 
    
    % ** Draw a figure showing the brain underneath the source.**
    subplot(3, 3, 4);
    img3 = imagesc(reference_image_brain);
    set(img3, 'AlphaData', ~isnan(source)); % Make nans "transparent"
    colormap(gca,[0.5 0.5 0.5; gray(256)]);
    reference_image_brain(find(reference_image_brain == 0)) = NaN;
    caxis([min(min(reference_image_brain)) max(max(reference_image_brain))]);
    title('brain beneath source');
    xticks([]); yticks([]); axis square; axis square; 
    
    % ** Draw a figure showing the original, un-thresholded source. ** 
    subplot(3,3,7); 
    img1 = imagesc(original_source);   
    set(img1, 'AlphaData', ~isnan(source)); 
    colormap(gca, parula(256)); caxis([0 10]); 
    title('corresponding raw source');
    xticks([]); yticks([]); axis square;
    
    % Draw the source, where you're going to draw masks.
    subplot(1,3, 2:3); 
    img2 = imagesc(source);
    cmap2 = [0.5 0.5 0.5; parula(512)];
    colormap(gca, cmap2); colorbar; 
    xticks([]); yticks([]);  axis square;
   
    % Grab axis handle for drawing on with ManualMasking
    axis_for_drawing = gca; 

    % *** Ask if the whole IC should be thrown out.***
    user_answer1= inputdlg(['Do you want to throw out this entire source as an artifact? y=yes, n=no']); 
   
    %Convert the user's answer into a value
    answer1=user_answer1{1};
    
    % If the user's answer is y (being strict/difficult with this so
    % accidents are hard), mark it & move on to next source. Do nothing otherwise.
    if strcmp('y', answer1)
         
        % Note source for removal. 
        parameters.sources_artifacts_removed.indices_to_remove{source_iterator} = 'all'; 
        parameters.sources_artifacts_removed.sources_removed = [parameters.sources_artifacts_removed.sources_removed; source_iterator]; 

    else
        % Grab any existing masks
        existing_masks = parameters.sources_artifacts_removed.artifact_masks{source_iterator};

        % Run fine-tune removal of artifacts within ICs.
        [masks, indices_of_mask]=ManualMasking(source, existing_masks, axis_for_drawing);
        
        % Take note of masks (need these for deleting individual masks later).
        parameters.sources_artifacts_removed.artifact_masks{source_iterator} = masks; 

        % Remove indices from source.  
        parameters.sources_artifacts_removed.indices_to_remove{source_iterator} = indices_of_mask;
        source(indices_of_mask) = 0; 
        parameters.sources_artifacts_removed.sources(S{:}) = source;
    end

    close all; 

    % Ask if the user wants to work on next source.
    user_answer1= inputdlg(['Do you want to work on the next source? y = yes, n = no']); 

    % Convert the user's answer into a value
    answer1=user_answer1{1};

    % If user didn't want to continue to next mouse, set continue flag to false
    if strcmp(answer1, 'y')
        parameters.continue_flag{end} = true;
    else    
        parameters.continue_flag{end} = false;

        % Tell RunAnalysis to save this iteration
        parameters.save_now = true;
    end
   
    % Remove sources that should be removed. (Do this every time, is okay
    % because sources_artifacts_removed.sources is re-created each time.)
    S{parameters.sourcesDim} = parameters.sources_artifacts_removed.sources_removed;
    parameters.sources_artifacts_removed.sources(S{:}) = []; 

    % Update original (raw) source ID list with removed sources. 
    parameters.sources_artifacts_removed.originalICNumber = parameters.sources.originalICNumber_domainsSplit';
    parameters.sources_artifacts_removed.originalICNumber(parameters.sources_artifacts_removed.sources_removed) = [];

    % If this was the max source number & there ask user if they want to work on next dataset; Don't ask if there aren't multiple levels of iterators. 
    if source_iterator == number_of_sources && numel(parameters.continue_flag) > 1
        user_answer1= inputdlg(['Do you want to work on the next data set? y = yes, n = no']); 
    
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