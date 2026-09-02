function M = genmat(x)
%GENMAT Matrice généralisée : une matrice à paramètres.
%   M = GENMAT(X) fait d'une matrice ordinaire une matrice généralisée.
%
%   Dans MATLAB, une matrice généralisée est celle qui dépend de blocs
%   réglables — des REALP — plutôt que de blocs incertains. La différence
%   est d'intention : un paramètre incertain est ce qu'on subit, un
%   paramètre réglable est ce qu'on choisit. La représentation est la
%   même.
%
%   MatLibre n'a qu'une représentation, celle d'UMAT : GENMAT rend donc
%   un UMAT, et l'arithmétique est celle d'UMAT. Ce qui manque est la
%   synthèse structurée — HINFSTRUCT —, qui réglerait ces paramètres.
%
%   Exemples :
%      k = ureal('k', 1, 'Range', [0 10]);
%      M = genmat([1 k; 0 1]);
%      getNominal(M)
%      usubs(M, 'k', 5)
%
%   Voir aussi UMAT, UREAL, GENSS, HINFSTRUCT, USUBS.
    M = umat(x);
end
