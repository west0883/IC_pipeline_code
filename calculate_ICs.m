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
    
    % Tell user where data is being saved. 
    disp(['data saved in ' parameters.dir_out{1}]); 
    
    % Check if a GPU is available. If gpuDeviceCount is 0, tell the user.
    if isfield(parameters, 'use_gpu') && parameters.use_gpu && gpuDeviceCount < 1 
        disp("No GPU available, using CPU instead.");
    end
    
    % For each mouse
    for mousei=1:size(mice_all,2)  
        
        % Get the mouse name and display to user.
        mouse=mice_all(mousei).name;
        disp(['mouse #' mouse]); 
        
        % Create name of files to load 
        [file_string]=CreateFileStrings(compressed_data_name, mouse, [], [], false);
        
        % Load in the compressed data-- only the spatial component and the
        % S. 
        load(file_string, 'S', spatial_component);
        
        % Depending on which component is the spatial component, calculate 
        % the sources accordingly. See if user wants to use a gpu.
        switch spatial_component
            case 'V'
                if parameters.use_gpu
                    V = gpuArray(V);
                    B = jader_lsp_gpu([S*V'],num_sources);
                else
                    B = jader_lsp([S*V'],num_sources);
                end
                sources=B*[S*V'];
                
            case 'U'
                 if parameters.use_gpu
                    U = gpuArray(U);
                    B=jader_lsp_gpu([U*S],num_sources);
                 else 
                     B = jader_lsp([U*S],num_sources);
                 end
                sources=B*[U*S];
        end
      
        % Create output file path & filename
        dir_out =CreateFileStrings(parameters.dir_out, mouse, [], [], [], false);
        filename = CreateFileStrings(parameters.output_filename, mouse, [], [], [], false);
        mkdir(dir_out); 

        % Save sources and B.
        save([dir_out filename], 'sources', 'B', '-v7.3');  
    end
end