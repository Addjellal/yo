function R = matlibre_rf_matrices(M, fonction)
%MATLIBRE_RF_MATRICES Applique une conversion de paramètres à chaque fréquence.
%   R = MATLIBRE_RF_MATRICES(M,FONCTION) : M est N x N, ou N x N x K pour K
%   fréquences ; FONCTION transforme une matrice N x N.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      R = matlibre_rf_matrices(eye(2), @(m) 2 * m)
%
%   Voir aussi S2Z, Z2S, S2Y, Y2S.
    if size(M, 1) ~= size(M, 2) || ndims(M) > 3
        error('rf:parametres:Taille', 'Il faut une matrice N x N, ou N x N x K.');
    end
    R = zeros(size(M));
    for k = 1:size(M, 3)
        R(:, :, k) = fonction(M(:, :, k));
    end
end
