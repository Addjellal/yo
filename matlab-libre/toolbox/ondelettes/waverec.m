function x = waverec(C, L, nom)
%WAVEREC Reconstruction d'une décomposition multiniveaux.
%   X = WAVEREC(C,L) reconstruit le signal à partir de la décomposition
%   multiniveaux rendue par WAVEDEC, avec l'ondelette de Haar.
%   X = WAVEREC(C,L,NOM) emploie l'ondelette NOM, qui doit être celle de
%   la décomposition — reconstruire avec une autre ne rend pas le signal.
%
%   La remontée est symétrique de la descente : on part de l'approximation
%   la plus grossière, on lui adjoint le détail du niveau le plus profond
%   par IDWT, et le résultat sert d'approximation au niveau suivant.
%
%   La reconstruction est exacte à l'arrondi près pour un banc de filtres
%   à reconstruction parfaite, ce qui est la propriété qui définit une
%   ondelette orthogonale ou biorthogonale : les erreurs de repliement
%   introduites par la décimation d'un demi-canal sont exactement annulées
%   par celles de l'autre. Une longueur impaire fait produire à IDWT un
%   point de trop, retiré grâce à L(end) qui garde la longueur d'origine.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 3, 'db2');
%      max(abs(waverec(c, l, 'db2') - x)) < 1e-10
%
%   Voir aussi WAVEDEC, IDWT, DWT, WENERGY.
    if nargin < 3
        nom = 'haar';
    end
    niveaux = numel(L) - 2;
    debut = 1;
    a = C(debut:L(1));
    debut = L(1) + 1;
    for k = 1:niveaux
        longueur = L(k + 1);
        d = C(debut:debut + longueur - 1);
        debut = debut + longueur;
        a = idwt(a, d, nom);
        if numel(a) > L(end) && k == niveaux
            a = a(1:L(end));
        end
    end
    x = a;
end
