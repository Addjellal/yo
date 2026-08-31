function v = matlibre_etendre_blocs(valeurs, tailles)
%MATLIBRE_ETENDRE_BLOCS Répète une valeur par bloc sur toutes ses lignes.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   MUSSV s'en sert : la mise à l'échelle d'une structure d'incertitude
%   est constante sur chaque bloc, et c'est sous cette forme étendue
%   qu'elle devient une matrice diagonale.
    v = zeros(1, sum(tailles));
    place = 1;
    for k = 1:numel(tailles)
        v(place:place + tailles(k) - 1) = valeurs(k);
        place = place + tailles(k);
    end
end
