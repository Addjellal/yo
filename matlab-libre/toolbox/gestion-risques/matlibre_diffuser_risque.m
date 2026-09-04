function [a, b] = matlibre_diffuser_risque(a, b)
%MATLIBRE_DIFFUSER_RISQUE Met deux vecteurs à la même longueur par diffusion.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isscalar(a) && ~isscalar(b)
        a = repmat(a, size(b));
    elseif isscalar(b) && ~isscalar(a)
        b = repmat(b, size(a));
    elseif ~isequal(size(a), size(b))
        error('risque:diffuser:Tailles', ...
              'Les tableaux ne se diffusent pas : %s contre %s.', ...
              mat2str(size(a)), mat2str(size(b)));
    end
end
