function valeur = matlibre_interp_disperse(F, point)
%MATLIBRE_INTERP_DISPERSE Valeur interpolée en un point, données dispersées.
%   En linéaire, on cherche le triangle de Delaunay qui contient le point
%   et l'on y prend la combinaison barycentrique des trois valeurs. En
%   'nearest', la valeur du point de donnée le plus proche.
%
%   Hors de l'enveloppe convexe, aucun triangle ne contient le point : la
%   valeur est NaN, sauf si le prolongement demandé est 'nearest'.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      F = scatteredInterpolant([0;1;0], [0;0;1], [1;2;3]);
%      abs(matlibre_interp_disperse(F, [0.5 0]) - 1.5) < 1e-12
%
%   Voir aussi SCATTEREDINTERPOLANT.
    P = F.Points;
    v = F.Values;
    if strcmp(F.Method, 'nearest')
        [~, k] = min(sum((P - point) .^ 2, 2));
        valeur = v(k);
        return
    end
    T = F.Triangulation;
    for e = 1:size(T, 1)
        poids = matlibre_bary_poids(P(T(e, :), :), point);
        if all(poids >= -1e-12)
            valeur = poids * v(T(e, :));
            return
        end
    end
    if strcmp(F.ExtrapolationMethod, 'nearest')
        [~, k] = min(sum((P - point) .^ 2, 2));
        valeur = v(k);
    else
        valeur = NaN;
    end
end
