% regularize_ICs.m
% Sarah West
% 9/1/21
% Takes calculated ICs, thresholds them, and regularizes them into
% contiguous areas 

function []=regularize_ICs(parameters)
    
    % Return parameters to individual names.
    mice_all = parameters.mice_all;
    dir_exper = parameters.dir_exper;
    num_sources = parameters.num_sources;
    amplitude_threshold = parameters.amplitude_threshold;
    area_threshold = parameters.area_threshold;
    yDim = parameters.yDim;
    xDim = parameters.xDim;
    masked_flag = parameters.masked_flag; 
    plot_sizes = parameters.plot_sizes;
    %masks_name = parameters.masks_name;
    zscore_flag = parameters.zscore_flag;
    
    % Establish input and output directories 
    dir_in=[dir_exper 'ICs raw\']; 
    dir_out_base=[dir_exper 'ICs cleaned']; 
    disp(['output saved in ' dir_out_base]);  
    
    % For each mouse
    for mousei=1:size(mice_all,2)   
       
        % Find mouse and display to user
        mouse=mice_all(mousei).name;
        disp(['mouse ' mouse]); 
        
        % Make an output folder for this mouse 
        dir_out=[dir_out_base '\' mouse '\']; 
        mkdir(dir_out);
        
        % Get the names of the ICA-calculated sources of mouse
        filename = CreateFileStrings([parameters.dir_input_base parameters.input_filename], mouse, [], [], [], false);
        input_variable = CreateFileStrings(parameters.input_variable, mouse, [], [], [], false);
        
        % Load the raw sources, convert variable to something generic.
        sources = load(filename, input_variable); 
        sources = sources.(input_variable);

        % Check which dimension the pixels vs sources are in. Flip the sources so each IC is its own column. (pixels x source
        % number). 
        source_dimension = find(size(sources = parameters.num_sources));
        if source_dimension == 1
            sources = permute(sources, [2 source_dimension setxor([2 source_dimension], 1:ndims(sources))]);
        end
        
        % If the user wants to use zscoring (if zscore_flag is true)
        if zscore_flag 
            
            % Perform zscoring (built-in "zscore" function works on each
            % column independently).
            sources=zscore(sources); 
        end
        
        % If masked, (if mask_flag is "true")
        if masked_flag 
            % Find file name of mask
            file_string_mask=CreateFileStrings([parameters.dir_input_mask parameters.mask_filename], mouse, [], [], false);
            
            % Get variable name of mask
            mask_variable =CreateFileStrings(parameters.mask_variable, mouse, [], [], false);

            % Load mask indices, convert to generic name
            indices_of_mask = load(file_string_mask, mask_variable);
            indices_of_mask = indices_of_mask.(mask_variable);

            % Convert mask variable to something generic
            %eval(['indices_of_mask = ' mask_variable ';']);
            
            % Run the FillMasks.m function
            sources_reshaped=FillMasks(sources, indices_of_mask, yDim, xDim);
        
        % If not masked,
        else     
            % Reshape sources into images, 
            sources_reshaped=reshape(sources, yDim, xDim, size(sources,2));
        end 
        
        % Make holding variables for thresholded ICs-- with domains in same
        % image.
        output_sources.color_mask_domainstogether=NaN(size(sources_reshaped));
        output_sources.domain_mask_domainstogether=NaN(size(sources_reshaped));
        
        % Make holding variables for thresholded ICs-- with domains split
        % into different images. Will change sizes on each iteration.
        output_sources.color_mask_domainssplit=[];
        output_sources.domain_mask_domainssplit=[];
        
        % Initialize the "position" counters at 0, for
        % keeping the domains together in same image.
        position_domainstogether=0;
        
        % Initialize holders for original IC numbers.
        output_sources.originalICNumber_domainsSplit = [];
        output_sources.originalICNumber_domainsTogether = [];

        % For each source (IC)
        for ici=1:size(sources_reshaped,3)
            
            % Take the relevant source (IC), call it "map"
            map=sources_reshaped(:,:,ici); 
            
            % Take the absolute value of the map, so all relevant pixels of
            % the IC are positive (sometimes ICs are calculated as negative
            % compared to the rest of the image, but it's all relative.
            % With our high-quality ICs, the rest of the image should be
            % close to 0, while everything relevant will be either very
            % positve or very negative). 
            map=abs(map); 
            
            % Threshold the IC into a mask, with everything below the amplitude
            % threshold set to 0. 
            map(map<amplitude_threshold)=0;
            
            % Run the ClustReg function to keep only ICs that have at least
            % the area threshold number of contiguous pixels. (Code by
            % Laurentiu Popa, from 2018 ish.)
            [Reg,FinSize,DomId] = ClustReg(map,area_threshold);
            
            % If there was at least one domain that passed the area
            % threshold,
            if ~isempty(DomId)
                
                %%%%%%%%%%%%%%%%%%%%%%55
                
                % Increase the position of domains in same image counter
                position_domainstogether=position_domainstogether+1;
                
                % Make a holding variable for Reg_id, which holds the imagess
                % of each IC with each domain given a different number. 
                Reg_id=zeros(yDim,xDim);
                
                % For each domain,
                for domaini=1:length(DomId)
                    
                    % Take the map of all the passing domains,
                    Reg0=Reg;
                    
                    % Find the value of the domain
                    id0=DomId(domaini);
                    
                    % Set everything that doesn't belong to that domain 
                    % (value of image doesn't equal that domain value) to
                    % 0.
                    Reg0(Reg0~=id0)=0;
                     
                    % Set everything remaining to the domain iterator. (I 
                    % guess potentially the domain ID could be different from 
                    % the domain iterator).
                    Reg0(Reg0>0)=domaini;
                    
                    % Add the maps from the two domains together, for
                    % keeping 
                    Reg_id=Reg_id+Reg0;
                    
                    % Calculate color mask of single domain
                    color_mask_single=map.*(Reg0./domaini);
                    
                    % Concatenate
                    output_sources.color_mask_domainssplit=cat(3, output_sources.color_mask_domainssplit, color_mask_single); 
                    output_sources.originalICNumber_domainsSplit = [output_sources.originalICNumber_domainsSplit, ici];
                    output_sources.domain_mask_domainssplit=cat(3, output_sources.domain_mask_domainssplit, Reg0./domaini); 
                
                end
                
                % Hold flat masks of the IC with the
                % domain ID preserved.
                output_sources.domain_mask_domainstogether(:,:,position_domainstogether)=Reg_id;
                output_sources.originalICNumber_domainsTogether =  [output_sources.originalICNumber_domainsTogether, ici];
            end
        end

        % Get output names of regularized ICs, convert variable to specific
        % name.
        dir_out = CreateFileStrings(parameters.dir_output_base, mouse, [], [], [], false);
        mkdir(dir_out);
        output_filename = CreateFileStrings(parameters.output_filename, mouse, [], [], [], false);
        output_variable = CreateFileStrings(parameters.output_variable, mouse, [], [], [], false);
        
        eval([output_variable ' = output_sources;']);

        % Save the regularized ICs 
        save([dir_out output_filename], output_variable, '-v7.3'); 
 
        % Draw an overlay image of all domains masks together. 
        
        % Initialize a blank overlay image. 
        overlay=zeros(yDim, xDim);
        
        % For each IC
        for ici=1:size(output_sources.domain_mask_domainssplit,3)
           % Find the IC indices
           ind2=find(output_sources.domain_mask_domainssplit(:,:,ici)==1); 
           
           % Apply the IC number as the value at the IC indices
           overlay(ind2)=ici;
        end

        % Plot the overlay. 
        figure;hold on; 
        imagesc(flipud(overlay)); colorbar;
        title(['mouse ' mouse]); axis tight; axis square;    

        % Get overlay figure output name.
        if strcmp(output_filename(numel(output_filename)-3:end), '.mat')
            filename_overlay = [output_filename(1:numel(output_filename)-4) '_overlay'];
        else 
            filename_overlay = [output_filename '_overlay'];
        end
        % Save overlay
        savefig([dir_out filename_overlay]); 
  

        % Plot individual color maps 
        
        % Get the number of subplots to use.
        subplot_rows=plot_sizes(1);
        subplot_columns=plot_sizes(2); 
        figure; 
        for i=1:size(output_sources.color_mask_domainssplit,3)
            subplot(subplot_rows,subplot_columns,i); 
            imagesc(output_sources.color_mask_domainssplit(:,:,i)); 
            axis square; xticks([]); yticks([]);
            title([num2str(i) ', ' num2str(output_sources.originalICNumber_domainsSplit(i))]);
        end
        sgtitle(['mouse ' mouse ', component nums: new, original']);

        % Get colormasks figure output name.
        if strcmp(output_filename((end-3):end), '.mat')
            filename_colormasks = [output_filename([1:end-4]) '_colormasks'];
        else 
            filename_colormasks = [output_filename '_colormasks'];
        end

        % Save colormasks figure
        savefig([dir_out filename_colormasks]); 
       
    end 
end