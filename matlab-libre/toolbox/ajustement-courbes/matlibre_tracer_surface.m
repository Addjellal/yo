function h = matlibre_tracer_surface(ajustement, arguments)
%MATLIBRE_TRACER_SURFACE Trace une surface ajustée et ses données.
%   H = MATLIBRE_TRACER_SURFACE(SO,ARGUMENTS) trace la surface sur
%   l'étendue des points quand ils sont donnés, et les superpose.
%
%   Exemple :
%      plot(so, [x y], z);
%
%   Voir aussi SFIT, FIT.
    xy = [];
    z = [];
    if numel(arguments) >= 2 && isnumeric(arguments{1}) && isnumeric(arguments{2})
        xy = double(arguments{1});
        z = double(arguments{2}(:));
    end
    if isempty(xy)
        bornesX = [0 1];
        bornesY = [0 1];
    else
        bornesX = [min(xy(:, 1)), max(xy(:, 1))];
        bornesY = [min(xy(:, 2)), max(xy(:, 2))];
    end
    [X, Y] = meshgrid(linspace(bornesX(1), bornesX(2), 40), ...
                      linspace(bornesY(1), bornesY(2), 40));
    Z = feval(ajustement, X, Y);
    h = surf(X, Y, Z);
    if ~isempty(xy)
        etat = ishold();
        hold('on');
        plot3(xy(:, 1), xy(:, 2), z, 'k.');
        if ~etat
            hold('off');
        end
    end
end
