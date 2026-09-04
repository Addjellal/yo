function [a, b] = matlibre_diffuser_deux(a, b, nom)
%MATLIBRE_DIFFUSER_DEUX Met deux arguments à la même taille par diffusion.
%   Un scalaire prend la taille de l'autre ; deux tableaux de même taille
%   passent tels quels ; toute autre combinaison est refusée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isscalar(a) && ~isscalar(b)
        a = repmat(a, size(b));
    elseif isscalar(b) && ~isscalar(a)
        b = repmat(b, size(a));
    elseif ~isequal(size(a), size(b))
        error('stats:diffuser:Tailles', ...
              '%s : les arguments ne se diffusent pas, %s contre %s.', ...
              nom, mat2str(size(a)), mat2str(size(b)));
    end
end
