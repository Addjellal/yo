function [y, moyenne, variance] = matlibre_dl_normaliser(x, dimensions, decalage, echelle, epsilon)
%MATLIBRE_DL_NORMALISER Centre et réduit sur les dimensions données.
%   [Y,M,V] = MATLIBRE_DL_NORMALISER(X,DIMENSIONS,DECALAGE,ECHELLE,EPSILON)
%   retranche la moyenne, divise par l'écart type, puis applique l'échelle
%   et le décalage appris. C'est le calcul commun à la normalisation par
%   lot, par couche et par groupe : seules changent les dimensions sur
%   lesquelles la moyenne est prise.
%
%   La variance est la variance de population — divisée par l'effectif, non
%   par l'effectif moins un : c'est celle qui rend la sortie exactement
%   centrée réduite sur les données vues.
%
%   Tout est écrit avec des opérations dérivables : la dérivée du
%   normaliseur, qui est fastidieuse à écrire à la main, s'obtient d'elle-même.
%
%   Exemple :
%      y = matlibre_dl_normaliser([1 2 3], 2, 0, 1, 0);
%      mean(y)      % 0
%
%   Voir aussi BATCHNORM, LAYERNORM, GROUPNORM.
    moyenne = matlibre_dl_moyenne_sur(x, dimensions);
    centre = x - moyenne;
    variance = matlibre_dl_moyenne_sur(centre .^ 2, dimensions);
    y = echelle .* centre ./ sqrt(variance + epsilon) + decalage;
end
