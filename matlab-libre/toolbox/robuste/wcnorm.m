function [pire, valeurs] = wcnorm(sys, options)
%WCNORM Pire norme d'une matrice incertaine.
%   [N,V] = WCNORM(M) cherche, dans le domaine des paramètres, la
%   combinaison qui donne à la matrice incertaine M la plus grande norme
%   spectrale. N porte LowerBound et UpperBound ; V est la structure des
%   valeurs qui la donnent.
%
%   Pour un modèle, c'est WCGAIN qu'il faut : il cherche la norme
%   H-infini, non la norme d'une matrice constante.
%
%   La recherche est celle de WCGAIN : sommets, tirages, puis descente
%   locale. Voir WCGAIN pour ce que cela garantit.
%
%   Exemples :
%      a = ureal('a', 1, 'Range', [0 2]);
%      b = ureal('b', 1, 'Range', [-1 1]);
%      M = [a b; 0 a];
%      [n, v] = wcnorm(M);
%      n.LowerBound
%      [v.a, v.b]
%
%   Voir aussi WCGAIN, ROBSTAB, USAMPLE, NORM, UMAT.
    if nargin < 2
        options = struct();
    end
    [parametres, evaluer] = matlibre_incertitudes(sys);
    cout = @(v) max(svd(evaluer(v)));
    [borne, valeurs] = matlibre_balayer_incertitude(parametres, cout, options);
    pire = struct('LowerBound', borne, 'UpperBound', borne);
end
