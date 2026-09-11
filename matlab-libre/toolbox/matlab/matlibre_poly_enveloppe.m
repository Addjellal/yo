function k = matlibre_poly_enveloppe(V)
%MATLIBRE_POLY_ENVELOPPE Indices de l'enveloppe convexe d'un nuage.
%   Un simple relais vers CONVHULL. Il existe parce que POLYSHAPE porte
%   une méthode du même nom : à l'intérieur de la classe, écrire
%   « convhull(x, y) » appellerait la méthode, non la fonction. Passer
%   par un nom que la classe ne porte pas lève l'ambiguïté.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      k = matlibre_poly_enveloppe([0 0; 1 0; 1 1; 0 1; 0.5 0.5]);
%      numel(k)                        % 5 : quatre coins et le retour
%
%   Voir aussi CONVHULL, POLYSHAPE.
    k = convhull(V(:, 1), V(:, 2));
end
