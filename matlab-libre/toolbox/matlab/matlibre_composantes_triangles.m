function n = matlibre_composantes_triangles(T)
%MATLIBRE_COMPOSANTES_TRIANGLES Nombre de morceaux d'un ensemble de triangles.
%   Deux triangles sont du même morceau s'ils partagent au moins un
%   sommet, et de proche en proche. On parcourt en largeur depuis chaque
%   triangle non encore visité, et l'on compte les départs.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_composantes_triangles([1 2 3; 2 3 4])   % 1 : ils se touchent
%      matlibre_composantes_triangles([1 2 3; 4 5 6])   % 2 : separes
%
%   Voir aussi ALPHASHAPE, BOUNDARY.
    if isempty(T)
        n = 0;
        return
    end
    nT = size(T, 1);
    vus = false(nT, 1);
    n = 0;
    while ~all(vus)
        n = n + 1;
        pile = find(~vus, 1);
        vus(pile) = true;
        while ~isempty(pile)
            courant = pile(end);
            pile(end) = [];
            for t = find(~vus)'
                if ~isempty(intersect(T(courant, :), T(t, :)))
                    vus(t) = true;
                    pile(end + 1) = t;   %#ok<AGROW>
                end
            end
        end
    end
end
