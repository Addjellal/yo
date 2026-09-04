function [a, b] = matlibre_diffuser_dates(a, b)
%MATLIBRE_DIFFUSER_DATES Met deux séries de dates à la même taille.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isscalar(a) && ~isscalar(b)
        a = repmat(a, size(b));
    elseif isscalar(b) && ~isscalar(a)
        b = repmat(b, size(a));
    elseif ~isequal(size(a), size(b))
        error('finance:dates:Tailles', ...
              'Les deux séries de dates n''ont pas la même taille.');
    end
end
