function poids = matlibre_poids_binaire(valeur)
%MATLIBRE_POIDS_BINAIRE Nombre de bits à un d'un entier.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    valeur = round(double(valeur));
    poids = 0;
    while valeur > 0
        poids = poids + mod(valeur, 2);
        valeur = floor(valeur / 2);
    end
end
