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

    % For each source to clean, 
    for sourcei = 1:size(sources, parameters.sourcesDim) 
        
       
        % Get the source out from the variable dimensions
        S{parameters.sourcesDim} = sourcei;  
        source = sources(S{:});

        % Find the original source number of the IC you want. 
        original_sourcei = parameters.sources.originalICNumber_domainsSplit(sourcei);

        % Fill the mask of the original source. 
        original_source = abs(parameters.original_ICs(:, sourcei)); 
        original_source = FillMasks(original_source, parameters.indices_of_mask, size(source,1), size(source,2));

        
        indices = find(source > 0);
        reference_image_old = reference_image;
        reference_image(indices) = source(indices);
        
        indices = find(source == 0); 
        reference_image_old(indices) = 0; 

        % Arrange figure;
        figure; sgtitle([strjoin(parameters.values, ', ' ) ', source ' num2str(sourcei)]);
        subplot(3,3,1);
        img = image(reference_image, 'CDataMapping', 'scaled');
        set(img, 'AlphaData', ~isnan(source)); 
        
        % Get the color range you'll use. 
        top1 = max(max(source));
        top2 = max(max(reference_image)); 
        cmap = [parula(top1 * 10); gray((top2)*20)];
        colormap(cmap);
        axis square; xticks([]); yticks([]); 
        
        subplot(3, 3, 4);
        img3 = imagesc(reference_image_old);
        set(img3, 'AlphaData', ~isnan(source)); 
        colormap(gca,[0.5 0.5 0.5; gray(256)]);
        reference_image_old(find(reference_image_old == 0)) = NaN;
        caxis([min(min(reference_image_old)) max(max(reference_image_old))]);
         xticks([]); yticks([]); axis square; axis square; 
        
        subplot(3,3,7); 
        img1 = imagesc(original_source);   
        set(img1, 'AlphaData', ~isnan(source)); 
        colormap(gca, parula(256)); caxis([0 10]); 
        xticks([]); yticks([]); axis square;
        
        subplot(1,3, 2:3); 
        img2 = imagesc(source); caxis([0 10]);
        set(img2, 'AlphaData', ~isnan(source)); 
        cmap2 = [0.5 0.5 0.5; parula(256)];
        colormap(gca, cmap2); caxis([parameters.amplitude_threshold max(max(source))]); colorbar; 
        xticks([]); yticks([]);  axis square;
    end

    % Ask user if they want to work on next dataset 
    user_answer1= inputdlg(['Do you want to work on the next data set? 1=Y, 0=N']); 

    %Convert the user's answer into a value
    answer1=str2num(user_answer1{1});
    
    % If user didn't want to continue to next mouse, set continue flag to false
    if answer1
        parameters.continue_flag = true;
    else    
        parameters.continue_flag = false;
    end

end 