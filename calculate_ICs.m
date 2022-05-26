% calculate_ICs.m
% Sarah West
% 9/1/21

% Calculates ICs from SVD compressed data. Assumes one compressed dataset
% per mouse.

function []= calculate_ICs(parameters) 
    
    % Return parameters to individual names.
    mice_all = parameters.mice_all;
    dir_dataset = parameters.dir_dataset;
    compressed_data_name = parameters.compressed_data_name; 
    dir_exper = parameters.dir_exper;
    spatial_component = parameters.spatial_component;
    num_sources = parameters.num_sources;

    % Set up input and output directories 
    dir_in=dir_dataset; 
    dir_out=[dir_exper 'ICs raw\'];
    mkdir(dir_out); 
    
    % Tell user where data is being saved. 
    disp(['data saved in ' dir_out]); 
    
    % For each mouse
    for mousei=1:size(mice_all,2)  
        
        % Get the mouse name and display to user.
        mouse=mice_all(mousei).mouse;
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
    end
end