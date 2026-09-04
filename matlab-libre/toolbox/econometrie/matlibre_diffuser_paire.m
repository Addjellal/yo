function [a, b] = matlibre_diffuser_paire(a, b)
%MATLIBRE_DIFFUSER_PAIRE Met deux tableaux à la même taille par diffusion.
%   Un scalaire prend la taille de l'autre ; deux tableaux de même taille
%   sont rendus tels quels ; toute autre combinaison est une erreur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isscalar(a) && ~isscalar(b)
        a = repmat(a, size(b));
    elseif isscalar(b) && ~isscalar(a)
        b = repmat(b, size(a));
    elseif ~isequal(size(a), size(b))
        error('econ:diffuser:Tailles', ...
              'Les tableaux ne se diffusent pas : %s contre %s.', ...
              mat2str(size(a)), mat2str(size(b)));
    end
end
