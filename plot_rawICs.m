% plot_rawICs.m
% Sarah West
% 9/16/21
% Plots raw ICs from calculate_ICs.m for looking at/inspection.

function []=plot_rawICs(days_all, masks_name, dir_exper, num_sources, masked_flag, yDim, xDim, plot_sizes)
    % Establish folder name you're working with. 
    dir_out=[dir_exper 'ICs raw\'];
    
    % Tell user where data is being saved. 
    disp(['data saved in ' dir_out]); 
    
    % For each mouse
    for mousei=1:size(days_all,2)  
        
        % Get the mouse name and display to user.
        mouse=days_all(mousei).mouse;

        % Load the raw sources. 
        load([dir_out 'm' mouse '_' num2str(num_sources) 'sources.mat']); 
        
        % Reshape and permute for plotting 
        
        % If the data was masked, load mask and reshape specially
        if masked_flag==1
            % Find file name of masks
            file_string_mask=CreateFileStrings(masks_name, mouse, [], []);
            
            % Load mask indices 
            load(file_string_mask, 'indices_of_mask'); 
            
            % flip sources for inputting into FillMasks
            sources=sources';
            
            % Fill in masks with FillMasks.m function
            sources_permute=FillMasks(sources, indices_of_mask, yDim, xDim);
        
        % If no masks, just reshape and permute sources    
        else
            sources_permute=permute(reshape(sources, num_sources, yDim, xDim),[2 3 1]);
        end 
        
        % Plot and save figures of sources. 
        figure; for i=1:num_sources; subplot(plot_sizes(1), plot_sizes(2),i); imagesc(sources_permute(:,:,i)); end
       
        suptitle(['m' mouse ', ' num2str(num_sources) ' sources']); 
        savefig([dir_out 'm' mouse '_' num2str(num_sources) 'sources.fig']); 
    
    end 
end 