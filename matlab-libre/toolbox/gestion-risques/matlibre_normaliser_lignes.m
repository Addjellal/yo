function P = matlibre_normaliser_lignes(comptes)
%MATLIBRE_NORMALISER_LIGNES Matrice stochastique tirée de comptages.
%   Une ligne sans observation devient la ligne d'un état absorbant :
%   faute de transition observée, on ne suppose rien de plus qu'un
%   maintien sur place.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    P = zeros(size(comptes));
    for i = 1:size(comptes, 1)
        total = sum(comptes(i, :));
        if total > 0
            P(i, :) = comptes(i, :) / total;
        else
            P(i, i) = 1;
        end
    end
end
