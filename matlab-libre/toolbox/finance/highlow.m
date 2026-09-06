function [hautes, basses] = highlow(haut, bas, cloture, ouverture)
%HIGHLOW Barres de cotation, sous forme de segments.
%   [H,B] = HIGHLOW(HAUT,BAS,CLOTURE,OUVERTURE) rend, pour chaque
%   séance, les deux extrémités du segment vertical de la barre. Là où
%   MATLAB trace, MatLibre rend les valeurs : le tracé se fait ensuite
%   avec PLOT.
%
%   Exemple :
%      rng(1);
%      clotures = 100 + cumsum(randn(20, 1));
%      [h, b] = highlow(clotures + 1, clotures - 1, clotures, clotures + 0.2);
%
%   Voir aussi CANDLE, POINTFIG, MEDPRICE.
    if nargin < 2
        series = matlibre_colonnes_marche(haut, {}, {'haut', 'bas'});
    else
        series = matlibre_colonnes_marche(haut, {bas}, {'haut', 'bas'});
    end
    hautes = series{1};
    basses = series{2};
end
