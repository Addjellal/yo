function A = matlibre_base_polynome(x, ordre)
%MATLIBRE_BASE_POLYNOME Matrice des puissances de x.
%   A = MATLIBRE_BASE_POLYNOME(X,ORDRE) rend la matrice dont la colonne k
%   porte x à la puissance ORDRE+1-k. Le modèle polynomial étant linéaire
%   en ses coefficients, l'ajustement se ramène à résoudre A*c = y au sens
%   des moindres carrés.
%
%   Exemple :
%      matlibre_base_polynome([1; 2], 1)      % [1 1; 2 1]
%
%   Voir aussi FIT, POLYFIT.
    x = x(:);
    A = zeros(numel(x), ordre + 1);
    for k = 1:(ordre + 1)
        A(:, k) = x .^ (ordre + 1 - k);
    end
end
