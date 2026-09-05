function [y, X] = matlibre_id_parcourir_etat(modele, u, x0)
%MATLIBRE_ID_PARCOURIR_ETAT Sortie et états d'un modèle d'état.
%   [Y,X] = MATLIBRE_ID_PARCOURIR_ETAT(MODELE,U,X0) fait avancer la
%   récurrence x(t+1) = A x(t) + B u(t) et rend la sortie C x + D u ainsi
%   que la suite des états.
%
%   Exemple :
%      [y, X] = matlibre_id_parcourir_etat(m, ones(10, 1), zeros(2, 1));
%
%   Voir aussi IDSS, SIM.
    n = size(u, 1);
    ordre = size(modele.A, 1);
    sorties = size(modele.C, 1);
    X = zeros(n, ordre);
    y = zeros(n, sorties);
    x = x0(:);
    for t = 1:n
        X(t, :) = x.';
        y(t, :) = (modele.C * x + modele.D * u(t, :).').';
        x = modele.A * x + modele.B * u(t, :).';
    end
end
