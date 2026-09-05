function [Phi, Y, debut] = matlibre_id_regression(y, u, ordres)
%MATLIBRE_ID_REGRESSION Matrice de régression d'un modèle ARX.
%   [PHI,Y,DEBUT] = MATLIBRE_ID_REGRESSION(Y,U,ORDRES) construit la
%   matrice dont chaque ligne porte les sorties et les entrées passées qui
%   expliquent un échantillon.
%
%   Le modèle ARX est linéaire en ses coefficients : cette matrice suffit
%   à les obtenir par moindres carrés, sans itération et sans point de
%   départ. C'est ce qui en fait le point de départ de tous les autres.
%
%   Exemple :
%      [Phi, Y] = matlibre_id_regression((1:5)', (1:5)', [1 1 0 0 0 1]);
%      size(Phi)      % 4 2
%
%   Voir aussi ARX, POLYEST.
    na = ordres(1);
    nb = ordres(2);
    nk = ordres(6);
    y = y(:);
    u = u(:);
    N = numel(y);
    debut = max(na, nb + nk - 1) + 1;
    lignes = max(N - debut + 1, 0);
    Phi = zeros(lignes, na + nb);
    Y = zeros(lignes, 1);
    for t = debut:N
        i = t - debut + 1;
        for k = 1:na
            Phi(i, k) = -y(t - k);
        end
        for k = 1:nb
            Phi(i, na + k) = u(t - nk - k + 1);
        end
        Y(i) = y(t);
    end
end
