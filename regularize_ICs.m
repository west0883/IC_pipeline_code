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
    masks_name = parameters.masks_name;
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
        
        % Load ICA-calculated sources of mouse
        load([dir_in 'm' mouse '_' num2str(num_sources) 'sources.mat'], 'sources');
        
        % Flip the sources so each IC is its own column. (pixels x source
        % number). 
        sources=sources'; 
        
        % If the user wants to use zscoring (if zscore_flag is true)
        if zscore_flag 
            
            % Perform zscoring (built-in "zscore" function works on each
            % column independently).
            sources=zscore(sources); 
        end
        
        % If masked, (if mask_flag is "true")
        if masked_flag 
            % Find file name of masks
            file_string_mask=CreateFileStrings(masks_name, mouse, [], [], false);
            
            % Load mask indices 
            load(file_string_mask, 'indices_of_mask'); 
            
            % Run the FillMasks.m function
            sources_reshaped=FillMasks(sources, indices_of_mask, yDim, xDim);
        
        % If not masked,
        else     
            % Reshape sources into images, 
            sources_reshaped=reshape(sources, yDim, xDim, size(sources,2));
        end 
        
        % Make holding variables for thresholded ICs-- with domains in same
        % image.
        color_mask_domainstogether=NaN(size(sources_reshaped));
        domain_mask_domainstogether=NaN(size(sources_reshaped));
        
        % Make holding variables for thresholded ICs-- with domains split
        % into different images. Will change sizes on each iteration.
        color_mask_domainssplit=[];
        domain_mask_domainssplit=[];
        
        % Initialize the "position" counters at 0, for
        % keeping the domains together in same image.
        position_domainstogether=0;
        
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
                    color_mask_domainssplit=cat(3, color_mask_domainssplit, color_mask_single); 
                    domain_mask_domainssplit=cat(3, domain_mask_domainssplit, Reg0./domaini); 
                end
                
                % Hold flat masks of the IC with the
                % domain ID preserved.
                domain_mask_domainstogether(:,:,position_domainstogether)=Reg_id;

            end
        end
        
        % Save the regularized ICs 
        save([dir_out 'regularized ICs_' num2str(num_sources) 'sources.mat'], 'color_mask_domainssplit', 'domain_mask_domainssplit', 'domain_mask_domainstogether', '-v7.3'); 
   
        
        % Draw an overlay image of all domain masks together. 
        
        % Initialize a blank overlay image. 
        overlay=zeros(yDim, xDim);
        
        % For each IC
        for ici=1:size(domain_mask_domainssplit,3)
           % Find the IC indices
           ind2=find(domain_mask_domainssplit(:,:,ici)==1); 
           
           % Apply the IC number as the value at the IC indices
           overlay(ind2)=ici;
        end
        
        % Plot the overlay. 
         figure;hold on; 
         imagesc(flipud(overlay)); colorbar;
         title(['mouse ' mouse]); axis tight; axis square;        
         
         % Save the overlay fig
         savefig([dir_out 'regularized ICs_overlay_' num2str(num_sources) 'sources.fig']); 

        % Plot individual color maps 
        
        % Get the number of subplots to use.
        subplot_rows=plot_sizes(1);
        subplot_columns=plot_sizes(2); 
        figure; 
        for i=1:size(color_mask_domainssplit,3)
            subplot(subplot_rows,subplot_columns,i); 
            imagesc(color_mask_domainssplit(:,:,i)); 
            %axis square;
        end
        suptitle(['mouse ' mouse]);
        % Save figure of individual  color maps.
        savefig([dir_out 'regularized ICs_color masks_' num2str(num_sources) 'sources.fig']); 
    
    end 
end