function r = matlibre_poly_booleen(pg, autre, operation)
%MATLIBRE_POLY_BOOLEEN Opération booléenne entre deux régions.
%   Réunit les deux listes de contours, passe au découpage, et rassemble
%   le résultat en une région dont les orientations sont refaites.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      a = polyshape([0 2 2 0], [0 0 2 2]);
%      b = polyshape([1 3 3 1], [1 1 3 3]);
%      abs(area(matlibre_poly_booleen(a, b, 'intersection')) - 1) < 1e-9
%
%   Voir aussi POLYSHAPE, UNION, INTERSECT, SUBTRACT, XOR.
    contoursP = matlibre_poly_separer(pg.Vertices);
    contoursQ = matlibre_poly_separer(autre.Vertices);
    if isempty(contoursP)
        if strcmp(operation, 'intersection') || strcmp(operation, 'difference')
            r = polyshape();
        else
            r = autre;
        end
        return
    end
    if isempty(contoursQ)
        if strcmp(operation, 'intersection')
            r = polyshape();
        else
            r = pg;
        end
        return
    end
    contours = matlibre_clip_booleen(contoursP, contoursQ, operation);
    r = polyshape();
    r.Vertices = matlibre_poly_assembler(contours);
end
