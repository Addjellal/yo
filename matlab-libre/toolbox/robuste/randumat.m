function M = randumat(lignes, colonnes, nombreAtomes)
%RANDUMAT Matrice incertaine tirée au hasard.
%   M = RANDUMAT(N) crée une matrice incertaine N x N.
%   M = RANDUMAT(N,M) la crée N x M.
%   M = RANDUMAT(N,M,P) emploie P paramètres incertains ; deux par
%   défaut.
%
%   Chaque entrée est une combinaison affine des paramètres, à
%   coefficients tirés au hasard. C'est de quoi éprouver WCNORM ou MUSSV
%   sur des objets qu'on n'a pas choisis.
%
%   Exemples :
%      M = randumat(2)
%      wcnorm(M)
%      usample(M)
%
%   Voir aussi RANDATOM, RANDUSS, UMAT, WCNORM, UREAL.
    if nargin < 1 || isempty(lignes)
        lignes = 2;
    end
    if nargin < 2 || isempty(colonnes)
        colonnes = lignes;
    end
    if nargin < 3 || isempty(nombreAtomes)
        nombreAtomes = 2;
    end
    M = umat(randn(lignes, colonnes));
    for k = 1:nombreAtomes
        atome = randatom('ureal');
        M = M + atome * randn(lignes, colonnes);
    end
end
