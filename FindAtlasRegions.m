% FindAtlasRegions.m
% Sarah West
% 4/1/22

% Uses center-of-mass and percent area to find the best atlas region for
% each spatial source.

function [parameters] = FindAtlasRegions(parameters)
    
    % If there's a mask for this mouse & the atlas hasn't been masked yet,
    % do that now. 
    if isfield(parameters, 'indices_of_mask') && ~isfield(parameters, 'atlas_masked')
        
        % Set up atlas_masked as a matrix of zeroes the size of atlas.
        parameters.atlas_masked = zeros(size(parameters.atlas));

        % Set values inside mask to corresponding values of the atlas.
        parameters.atlas_masked(parameters.indices_of_mask) = parameters.atlas(parameters.indices_of_mask);
    
    % If no masking needed, make the atlas_masked the atlas 
    elseif ~isfield(parameters, 'indices_of_mask') && ~isfield(parameters, 'atlas_masked')
        parameters.atlas_masked = parameters.atlas;

    end
    
    % If atlas metrics haven't been calculated yet, do that now.
    if ~isfield(parameters, 'atlas_metrics')
           
        % Calculate metrics for each region name. Get list of all the
        % regions
        all_regions = fieldnames(parameters.region_names);
        
        % Get number of atlas region
        number_of_regions = numel(all_regions);

        % Make a holder of calulations. Make it a normal numeric array, 
        % because trying to do calculations on cells or structures is a nightmare.
        % This will just be center of mass x and y.
        parameters.atlas_metrics = NaN(number_of_regions, 2);

        % For each region, 
        for regioni = 1:number_of_regions

            % Get the value at of region so you can isolate the atlas
            % region
            region_value = getfield(parameters.region_names, all_regions{regioni}); 

            % Grab the atlas region. 
            region = parameters.atlas_masked == region_value;
            
            % Calculated center of mass (will be empty if mouse doesn't
            % have that region)>
            COM = centerOfMass(double(region));

            % Put it into atlas metrics 
            if ~isempty(COM)
                parameters.atlas_metrics(regioni, :) = COM; 
            end 
        end 

    end 
    
    % Begin comparisons

    % Get number of sources.
    number_of_sources = size(parameters.sources_artifacts_removed.sources, parameters.sourcesDim); 

    % Make a holder for each source's center of mass. 
    sources_center_of_mass = NaN(number_of_sources, 2); 

    % Make a holder for the comparison matrix (n regions x n sources x 2).
    % Third dimension is distance between center-of-mass, weighted area
    % overlap. 
    parameters.metrics.comparison_matrix = NaN(number_of_regions, number_of_sources, 2);

    % Get list of what the sources would've been called in regularized ICs
    IC_old_list = 1:size(parameters.sources.color_mask_domainsSplit, 3);
    IC_old_list(parameters.sources_artifacts_removed.sources_removed) = [];

    % For each source, 
    for sourcei = 1:number_of_sources

        % Convert to nubmer that it would've been in the regularized ICs
        source_index = IC_old_list(sourcei);
        
   
        % Pull out source
            % Set up abstractable dimensions
            S = repmat({':'},1, ndims(parameters.sources.color_mask_domainsSplit));
            S{parameters.sourcesDim} = source_index; 

            % Get out source
            source = parameters.sources.color_mask_domainsSplit(S{:});

            % Make any NaNs in source (usually outside the mask) into 0 to
            % avoid match issues.
            source(isnan(source)) = 0; 

        % Calculate center of mass. 
        region_COM = centerOfMass(source);

        % Put into storage matrix
        sources_center_of_mass(sourcei, :) = region_COM;

        % Compare to each atlas region. 
        for regioni = 1:number_of_regions

            % *** Calculate distances between centers of mass***
            % Compare distance from center of mass to each atlas region 
            atlas_COM = parameters.atlas_metrics(regioni, :);

            % Calculate Euclidean distance
            parameters.metrics.comparison_matrix(regioni, sourcei, 1) = pdist([region_COM; atlas_COM], 'euclidean');
           
            % *** Calculate weighted overlap***
            % Get the value at of region so you can isolate the atlas
            % region
            region_value = getfield(parameters.region_names, all_regions{regioni}); 

            % Grab the atlas region. 
            region = parameters.atlas_masked == region_value;
           
            % Compare area overlapping with each atlas region (weighted);
            overlap = sum(sum(region .* source ))./(sum(sum(source))); 

            % Put into storage matrix.
            parameters.metrics.comparison_matrix(regioni, sourcei, 2) = overlap; 

        end
    end 

    % Find best region fit.

    % For each source,
    for sourcei = 1:number_of_sources
        
        % Find best COM distance (smallest), note the index 
        holder_COM = parameters.metrics.comparison_matrix(:, sourcei,1);
        index_COM = find(holder_COM == min(holder_COM, [], 'all', 'omitnan'));
        parameters.metrics.best_fit.indices(sourcei).COM = index_COM; 
        parameters.metrics.best_fit.names(sourcei).COM = all_regions{index_COM}; 

        % Find best overlap (largest), note the index & name 
        holder_overlap = parameters.metrics.comparison_matrix(:, sourcei,2);
        index_overlap = find(holder_overlap == max(holder_overlap, [], 'all', 'omitnan'));
        parameters.metrics.best_fit.indices(sourcei).overlap = index_overlap; 
        parameters.metrics.best_fit.names(sourcei).overlap = all_regions{index_overlap} ; 
        
       % If those indices match, assign to a best match field
       if index_COM == index_overlap 
          parameters.metrics.best_fit.indices(sourcei).best = index_COM; 
          parameters.metrics.best_fit.names(sourcei).best = all_regions{index_COM};

       else 
          parameters.metrics.best_fit.indices(sourcei).best = NaN; 
          parameters.metrics.best_fit.names(sourcei).best = [];
       end 
    end

end 

