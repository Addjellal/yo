function [x, y, largeur, style] = matlibre_arguments_barres(entrees, nom)
%MATLIBRE_ARGUMENTS_BARRES Décode les arguments de BARH et de PARETO.
%   Fonction interne : elle n'existe pas dans MATLAB. Elle applique la
%   règle de BAR — Y seul, ou X et Y, puis une largeur, puis un style —
%   pour que les diagrammes en barres de MatLibre s'accordent tous.
    style = 'b';
    largeur = 0.8;
    if ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        style = char(entrees{end});
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) >= 2 && isscalar(entrees{end}) && ~isscalar(entrees{1})
        largeur = entrees{end};
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) == 1
        y = entrees{1}(:);
        x = (1:numel(y))';
    elseif numel(entrees) >= 2
        x = entrees{1}(:);
        y = entrees{2}(:);
    else
        error(['MATLAB:' nom ':NotEnoughInputs'], 'Not enough input arguments.');
    end
    if numel(x) ~= numel(y)
        error(['MATLAB:' nom ':SizeMismatch'], 'X and Y must have the same length.');
    end
end
