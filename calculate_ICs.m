% calculate_ICs.m
% Sarah West
% 9/1/21

% Calculates ICs from SVD compressed data. Assumes one compressed dataset
% per mouse.

function []= calculate_ICs(days_all, dir_dataset, compressed_data_name, masks_name, dir_exper, spatial_component, num_sources, masked_flag, yDim, xDim) 
    
    % Set up input and output directories 
    dir_in=dir_dataset; 
    dir_out=[dir_exper 'ICs raw\'];
    mkdir(dir_out); 
    
    % Tell user where data is being saved. 
    disp(['data saved in ' dir_out]); 
    
    % For each mouse
    for mousei=1:size(days_all,2)  
        
        % Get the mouse name and display to user.
        mouse=days_all(mousei).mouse;
        disp(['mouse #' mouse]); 
        
        % Create name of files to load 
        [file_string]=CreateFileStrings(compressed_data_name, mouse, [], []);
        
        % Load in the compressed data-- only the spatial component and the
        % S. 
        load(file_string, 'S', spatial_component);
        
        % Depending on which component is the spatial component, calculate 
        % the sources accordingly. 
        switch spatial_component
            case 'V'
                B=jader_lsp([S*V'],num_sources);
                sources=B*[S*V'];
            case 'U'
                B=jader_lsp([U*S],num_sources);
                sources=B*[U*S];
        end
        
        % Save sources and B.
        save([dir_out 'm' mouse '_' num2str(num_sources) 'sources.mat'], 'sources', 'B');  
        
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
            sources_filled=FillMasks(sources, indices_of_mask, yDim, xDim, pixel_dim);
            
            % Permute. 
            sources_permute=permute(reshape(sources_filled, num_sources, yDim, xDim),[2 3 1]);
        
        % If no masks, just reshape and permute sources    
        else
            sources_permute=permute(reshape(sources, num_sources, yDim, xDim),[2 3 1]);
        end 
        
        % Plot and save figures of sources. 
        figure; for i=1:num_sources; subplot(7,8,i); imagesc(sources_permute(:,:,i)); end
        savefig([dir_out 'm' mouse '_' num2str(num_sources) 'sources.fig']); 
    end
end