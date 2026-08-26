function sortie = appliquerMatriceCouleur(entree, M)
%APPLIQUERMATRICECOULEUR Combine linéairement les trois plans d'une image.
%   Accepte une image H x L x 3 ou une liste N x 3 de couleurs, et rend
%   la même forme.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    entree = double(entree);
    d = size(entree);
    if numel(d) == 2 && d(2) == 3
        sortie = entree * M';
        return
    end
    if numel(d) < 3 || d(3) ~= 3
        error('images:appliquerMatriceCouleur:BadInput', ...
              'L''entrée doit être une image à trois plans ou une liste N x 3.');
    end
    liste = reshape(entree, [], 3) * M';
    sortie = reshape(liste, d);
end
