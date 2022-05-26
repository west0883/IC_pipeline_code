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
   
    % Apply the mask to the reference image
    holder = NaN(size(parameters.reference_image));
    holder(parameters.indices_of_mask) = parameters.reference_image(parameters.indices_of_mask);
    reference_image = holder; 

    % Convert to an easier-to-use parameter name
    sources = parameters.sources.color_mask_domainssplit;

    % Set up a holder for a variable number of dimensions
    S = repmat({':'},1, ndims(sources));
   
    % Reshape original sources. 
    
    % Put pixels into first dimension
    parameters.original_ICs = permute(parameters.original_ICs,[parameters.originalSourcesPixelsDim setxor(parameters.originalSourcesPixelsDim, 1:ndims(parameters.original_ICs))]);
   
    % Check to see if there was an existing artifacts removed structure. If
    % not, establish all fields.
    if ~isfield(parameters, 'sources_artifacts_removed')
    
       % Initialize list of indices to remove.
       parameters.sources_artifacts_removed.indices_to_remove = cell(size(sources, parameters.sourcesDim),1);
       
       % Initialize empty list of sources to remove
       parameters.sources_artifacts_removed.sources_removed = [];
       
       % Initialize empty list of artifact masks. 
       parameters.sources_artifacts_removed.artifact_masks = cell(size(sources, parameters.sourcesDim),1);
    end

    % Initialize matrix of artifact-removed sources. (Do each time so you
    % don't lose track of sourcei and original_sourcei).
    parameters.sources_artifacts_removed.sources = sources; 

    % For each source to clean, 
    for sourcei = 1:size(sources, parameters.sourcesDim) 
        
        % Check if source was thrown out before, skip it.
        if ismember(sourcei, parameters.sources_artifacts_removed.sources_removed)
            continue
        end

        % Get the source out from the variable dimensions
        S{parameters.sourcesDim} = sourcei;  
        source = sources(S{:});

        % Find the original source number of the IC you want. 
        original_sourcei = parameters.sources.originalICNumber_domainsSplit(sourcei);

        % Fill the mask of the original source. 
        original_source = abs(parameters.original_ICs(:, original_sourcei)); 
        original_source = FillMasks(original_source, parameters.indices_of_mask, size(source,1), size(source,2));

        % Make find indices where the source is.
        indices = find(source > 0);

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
        sgtitle([strjoin(parameters.values, ', ' ) ', source ' num2str(sourcei)]);
        
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
            parameters.sources_artifacts_removed.indices_to_remove{sourcei} = 'all'; 
            parameters.sources_artifacts_removed.sources_removed = [parameters.sources_artifacts_removed.sources_removed; sourcei]; 

        else
            % Grab any existing masks
            existing_masks = parameters.sources_artifacts_removed.artifact_masks{sourcei};

            % Run fine-tune removal of artifacts within ICs.
            [masks, indices_of_mask]=ManualMasking(source, existing_masks, axis_for_drawing);
            
            % Take note of masks (need these for deleting individual masks later).
            parameters.sources_artifacts_removed.artifact_masks{sourcei} = masks; 

            % Remove indices from source.  
            parameters.sources_artifacts_removed.indices_to_remove{sourcei} = indices_of_mask;
            source(indices_of_mask) = 0; 
            parameters.sources_artifacts_removed.sources(S{:}) = source;
        end

        close all; 

        % Ask user if they want to work on next source.
        user_answer1= inputdlg(['Do you want to work on the next source? y = yes, n = no']); 

        % Convert the user's answer into a value
        answer1=user_answer1{1};
    
        % If user didn't want to continue to next source, break for loop
        if strcmp(answer1, 'n')
            break
        end
    end
   
    % Remove sources that should be removed. 
    S{parameters.sourcesDim} = parameters.sources_artifacts_removed.sources_removed;
    parameters.sources_artifacts_removed.sources(S{:}) = []; 

    % Upadate original (raw) source ID list. 
    parameters.sources_artifacts_removed.originalICNumber = parameters.sources.originalICNumber_domainsSplit';
    parameters.sources_artifacts_removed.originalICNumber(parameters.sources_artifacts_removed.sources_removed) = [];

    % Ask user if they want to work on next dataset 
    user_answer1= inputdlg(['Do you want to work on the next data set? y = yes, n = no']); 

    % Convert the user's answer into a value
    answer1=user_answer1{1};
    
    % If user didn't want to continue to next mouse, set continue flag to false
    if strcmp(answer1, 'y')
        parameters.continue_flag = true;
    else    
        parameters.continue_flag = false;
    end
end 