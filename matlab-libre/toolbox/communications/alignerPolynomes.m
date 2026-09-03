function [a, b] = alignerPolynomes(a, b)
%ALIGNERPOLYNOMES Complète de zéros le plus court de deux polynômes.
%   Les coefficients étant rangés par puissances croissantes, compléter
%   se fait à droite : on ajoute des termes de plus haut degré, nuls.
%
%   Un scalaire est ici le polynôme constant, non un terme à répandre sur
%   tous les autres : sans cela l'identité de la division euclidienne ne
%   tiendrait pas, le reste étant souvent de degré zéro.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    a = double(a);
    b = double(b);
    if isequal(size(a), size(b))
        return
    end
    if isvector(a) && isvector(b)
        n = max(numel(a), numel(b));
        colonne = iscolumn(a) && iscolumn(b) && (numel(a) > 1 || numel(b) > 1);
        a = [a(:).', zeros(1, n - numel(a))];
        b = [b(:).', zeros(1, n - numel(b))];
        if colonne
            a = a.';
            b = b.';
        end
        return
    end
    % Une matrice contre un scalaire : là, le scalaire se répand.
    if isscalar(a)
        a = repmat(a, size(b));
        return
    end
    if isscalar(b)
        b = repmat(b, size(a));
        return
    end
    lignes = max(size(a, 1), size(b, 1));
    colonnes = max(size(a, 2), size(b, 2));
    a = completerMatrice(a, lignes, colonnes);
    b = completerMatrice(b, lignes, colonnes);
end

function m = completerMatrice(m, lignes, colonnes)
    m = [m, zeros(size(m, 1), colonnes - size(m, 2))];
    m = [m; zeros(lignes - size(m, 1), colonnes)];
end
