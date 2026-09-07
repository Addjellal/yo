function seuil = matlibre_seuil_alpha(x, y, s)
%MATLIBRE_SEUIL_ALPHA Rayon au-delà duquel un triangle est retiré.
%   Le serrage S va de zéro — aucun triangle retiré, donc l'enveloppe
%   convexe — à un — le contour le plus serré qui enferme encore tous les
%   points. Entre les deux, le seuil descend depuis l'infini jusqu'au
%   plus grand rayon circonscrit qu'on peut retirer sans perdre un point.
%
%   Le seuil est pris sur les quantiles des rayons circonscrits : c'est ce
%   qui rend le réglage indépendant de l'échelle du nuage.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      x = [0 1 1 0]'; y = [0 0 1 1]';
%      isinf(matlibre_seuil_alpha(x, y, 0))     % 1 : a zero, rien ne part
%
%   Voir aussi BOUNDARY, ALPHASHAPE.
    if s <= 0
        seuil = inf;
        return
    end
    T = delaunay(x, y);
    if isempty(T)
        seuil = inf;
        return
    end
    rayons = zeros(size(T, 1), 1);
    for e = 1:size(T, 1)
        rayons(e) = matlibre_rayon_circonscrit([x(T(e, :)), y(T(e, :))]);
    end
    rayons = sort(rayons);
    % S = 1 doit encore laisser passer le plus petit triangle : sans cela
    % la forme se viderait entierement.
    position = max(1, ceil((1 - s) * numel(rayons)));
    seuil = rayons(position);
    if s >= 1
        seuil = rayons(1);
    end
end
