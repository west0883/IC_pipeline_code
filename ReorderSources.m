% ReorderSources.m
% Sarah West
% 4/4/22

function [parameters] = ReorderSources(parameters)

    % Make a holding matrix
    parameters.sources_reordered = NaN(size(parameters.sources.sources));

    % For each source in the manual assignments list
    for sourcei = 1:size(parameters.assigned_region_order,1)
        
        % Get original place
        original_place = parameters.assigned_region_order(sourcei);

        % Put source in new place.
        parameters.sources_reordered(:,:, sourcei) = parameters.sources.sources(:,:, original_place); 
        
    end
end