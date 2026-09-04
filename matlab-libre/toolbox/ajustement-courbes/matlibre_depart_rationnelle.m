function depart = matlibre_depart_rationnelle(x, y, haut, bas)
%MATLIBRE_DEPART_RATIONNELLE Point de départ d'une fraction rationnelle.
%   D = MATLIBRE_DEPART_RATIONNELLE(X,Y,HAUT,BAS) résout d'abord le
%   problème linéarisé : multiplier par le dénominateur donne une
%   équation linéaire en tous les coefficients, dont la solution sert de
%   départ à l'ajustement véritable.
%
%   Exemple :
%      x = (1:10)'; y = (2*x + 1) ./ (x + 3);
%      matlibre_depart_rationnelle(x, y, 1, 1)
%
%   Voir aussi FIT, MATLIBRE_EVALUER_RATIONNELLE.
    x = x(:);
    y = y(:);
    A = matlibre_base_polynome(x, haut);
    for k = 1:bas
        A = [A, -y .* x .^ (bas - k)];      %#ok<AGROW>
    end
    b = y .* x .^ bas;
    depart = (A \ b).';
end
