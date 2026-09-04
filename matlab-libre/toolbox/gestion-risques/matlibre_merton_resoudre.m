function [actif, volatiliteActif] = matlibre_merton_resoudre(capitaux, volatiliteCapitaux, dette, taux, echeance)
%MATLIBRE_MERTON_RESOUDRE Actif et volatilité implicites du modèle de Merton.
%   Le point fixe alterne les deux équations : à volatilité d'actif
%   donnée, la formule de Black et Scholes s'inverse pour donner l'actif ;
%   l'actif connu, la relation entre les deux volatilités donne la
%   nouvelle volatilité d'actif. La suite converge parce que chaque
%   équation est monotone.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    volatiliteActif = volatiliteCapitaux * capitaux / (capitaux + dette);
    actif = capitaux + dette * exp(-taux * echeance);
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    for iteration = 1:500
        % Inversion de Black et Scholes : quel actif donne ces capitaux ?
        ecart = @(a) matlibre_bls_general(a, dette, taux, taux, echeance, ...
                                          volatiliteActif) - capitaux;
        bas = capitaux;
        haut = capitaux + dette + 1;
        while ecart(haut) < 0 && haut < 1e12
            haut = haut * 2;
        end
        nouvelActif = fzero(ecart, [bas, haut]);
        d1 = (log(nouvelActif / dette) + (taux + volatiliteActif ^ 2 / 2) * echeance) ...
             / (volatiliteActif * sqrt(echeance));
        nouvelleVolatilite = volatiliteCapitaux * capitaux / (nouvelActif * N(d1));
        if abs(nouvelActif - actif) < 1e-10 * max(1, actif) && ...
           abs(nouvelleVolatilite - volatiliteActif) < 1e-12
            actif = nouvelActif;
            volatiliteActif = nouvelleVolatilite;
            return
        end
        actif = nouvelActif;
        volatiliteActif = nouvelleVolatilite;
    end
end
