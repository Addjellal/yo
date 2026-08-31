function y = matlibre_regression_isotone(x)
%MATLIBRE_REGRESSION_ISOTONE La suite croissante la plus proche.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Y = MATLIBRE_REGRESSION_ISOTONE(X) rend la suite croissante qui
%   minimise la somme des carrés des écarts à X. C'est l'algorithme dit
%   « pool adjacent violators » : tant qu'un terme est plus petit que
%   son prédécesseur, on fond les deux blocs en un seul, dont la valeur
%   est leur moyenne pondérée.
%
%   Le positionnement multidimensionnel non métrique s'en sert : il ne
%   demande aux distances que de respecter l'ordre des dissemblances, et
%   cette régression donne la suite croissante que les distances doivent
%   approcher.
    x = x(:)';
    n = numel(x);
    if n == 0
        y = x;
        return;
    end
    valeurs = zeros(1, n);
    poids = zeros(1, n);
    blocs = 0;
    for i = 1:n
        blocs = blocs + 1;
        valeurs(blocs) = x(i);
        poids(blocs) = 1;
        while blocs > 1 && valeurs(blocs - 1) > valeurs(blocs)
            total = poids(blocs - 1) + poids(blocs);
            valeurs(blocs - 1) = (poids(blocs - 1) * valeurs(blocs - 1) + ...
                                  poids(blocs) * valeurs(blocs)) / total;
            poids(blocs - 1) = total;
            blocs = blocs - 1;
        end
    end
    y = zeros(1, n);
    place = 1;
    for b = 1:blocs
        for r = 1:poids(b)
            y(place) = valeurs(b);
            place = place + 1;
        end
    end
end
