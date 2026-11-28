function [matrice, info] = nuc44()
%NUC44 Matrice de substitution des nucléotides NUC44 (NUC.4.4 du NCBI).
%   M = NUC44 rend la matrice 15 x 15 dans l'ordre ACGTRYKMSWBDHVN : +5
%   pour deux bases identiques, -4 pour deux différentes, et des valeurs
%   intermédiaires pour les codes ambigus (R = A ou G...).
%   [M,INFO] = NUC44 rend aussi sa fiche : Scale = 0.277316, l'échelle
%   qui convertit un score en bits.
%
%   Exemple :
%      M = nuc44();
%      M(1, 1) - M(1, 2)    % 9 : correspondance contre différence
%
%   Voir aussi BLOSUM, PAM, NWALIGN.
    [matrice, info] = matlibre_info_matrice('NUC44', {}, 'nuc44');
end
