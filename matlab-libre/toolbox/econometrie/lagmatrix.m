function M = lagmatrix(y, retards)
%LAGMATRIX Matrice des versions retardées d'une série.
%   M = LAGMATRIX(Y,RETARDS) rend une matrice dont la colonne k est Y
%   décalé de RETARDS(k) : un retard positif descend la série, un retard
%   négatif l'avance. Les cases sans valeur reçoivent NaN, si bien que la
%   matrice garde la longueur de Y.
%
%   C'est la matrice de régresseurs d'un modèle autorégressif : régresser
%   Y sur LAGMATRIX(Y,1:p) ajuste un AR(p), à ceci près qu'il faut écarter
%   les p premières lignes, incomplètes. Les NaN ne sont pas un
%   remplissage arbitraire mais un signalement : ils rendent impossible de
%   régresser par mégarde sur des valeurs inventées.
%
%   Un retard négatif donne une avance, ce qui sert aux tests de causalité
%   et aux corrélations croisées — mais un modèle prédictif qui en
%   contient regarde l'avenir, et son pouvoir de prédiction est illusoire.
%
%   Exemple :
%      lagmatrix((1:5)', [1 -1])
%
%   Voir aussi ARSIM, AUTOCORR, OLS, FILTER.
    y = y(:);
    n = numel(y);
    M = NaN(n, numel(retards));
    for k = 1:numel(retards)
        d = retards(k);
        if d >= 0
            M(d+1:n, k) = y(1:n-d);
        else
            M(1:n+d, k) = y(1-d:n);
        end
    end
end
