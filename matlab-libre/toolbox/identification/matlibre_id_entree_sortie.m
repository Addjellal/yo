function [B, D, x0] = matlibre_id_entree_sortie(A, C, y, u)
%MATLIBRE_ID_ENTREE_SORTIE Matrices B et D, et état initial, par moindres carrés.
%   [B,D,X0] = MATLIBRE_ID_ENTREE_SORTIE(A,C,Y,U) résout le problème
%   linéaire qui reste une fois A et C connus : la sortie s'écrit
%
%      y(t) = C A^t x0 + somme des C A^(t-k-1) B u(k) + D u(t)
%
%   ce qui est linéaire en x0, en B et en D. La solution est donc directe,
%   et c'est le minimum global.
%
%   Exemple :
%      [B, D, x0] = matlibre_id_entree_sortie(A, C, y, u);
%
%   Voir aussi N4SID, SSEST.
    N = size(y, 1);
    ordre = size(A, 1);
    entrees = size(u, 2);
    sorties = size(C, 1);
    inconnues = ordre + ordre * entrees + sorties * entrees;
    Phi = zeros(N * sorties, inconnues);
    for k = 1:inconnues
        base = zeros(inconnues, 1);
        base(k) = 1;
        [x0Essai, BEssai, DEssai] = matlibre_id_decouper_inconnues(base, ordre, entrees, sorties);
        modele = idss(A, BEssai, C, DEssai, [], x0Essai, 1);
        reponse = matlibre_id_parcourir_etat(modele, u, x0Essai);
        Phi(:, k) = reponse(:);
    end
    solution = Phi \ y(:);
    [x0, B, D] = matlibre_id_decouper_inconnues(solution, ordre, entrees, sorties);
end
