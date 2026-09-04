function [Q, R] = matlibre_operateurs_spline(h)
%MATLIBRE_OPERATEURS_SPLINE Opérateurs de la spline de lissage.
%   [Q,R] = MATLIBRE_OPERATEURS_SPLINE(H) rend les deux matrices creuses
%   qui lient les valeurs d'une spline naturelle à ses courbures : Q est
%   la différence seconde divisée par les pas, R la matrice de la forme
%   quadratique qui donne l'intégrale du carré de la dérivée seconde.
%
%   Ce sont ces deux matrices qui ramènent le problème de lissage, posé
%   sur un espace de fonctions, à un système linéaire de taille le nombre
%   de points intérieurs.
%
%   Exemple :
%      [Q, R] = matlibre_operateurs_spline([1; 1; 1]);
%      size(Q)     % 4 2
%
%   Voir aussi CSAPS, SPAPS.
    h = h(:);
    m = numel(h);
    n = m + 1;
    interieurs = m - 1;
    lignes = zeros(3 * interieurs, 1);
    colonnes = zeros(3 * interieurs, 1);
    valeurs = zeros(3 * interieurs, 1);
    for j = 1:interieurs
        base = 3 * (j - 1);
        lignes(base + (1:3)) = [j; j + 1; j + 2];
        colonnes(base + (1:3)) = j;
        valeurs(base + (1:3)) = [1 / h(j); -1 / h(j) - 1 / h(j + 1); 1 / h(j + 1)];
    end
    Q = sparse(lignes, colonnes, valeurs, n, interieurs);
    principale = (h(1:interieurs) + h(2:(interieurs + 1))) / 3;
    hors = h(2:interieurs) / 6;
    R = sparse(1:interieurs, 1:interieurs, principale, interieurs, interieurs);
    if interieurs > 1
        R = R + sparse(1:(interieurs - 1), 2:interieurs, hors, interieurs, interieurs) + ...
                sparse(2:interieurs, 1:(interieurs - 1), hors, interieurs, interieurs);
    end
end
