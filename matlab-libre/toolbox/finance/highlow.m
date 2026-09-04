function [hautes, basses] = highlow(haut, bas, cloture, ouverture)
%HIGHLOW Barres de cotation, sous forme de segments.
%   [H,B] = HIGHLOW(HAUT,BAS,CLOTURE,OUVERTURE) rend, pour chaque
%   séance, les deux extrémités du segment vertical de la barre. Là où
%   MATLAB trace, MatLibre rend les valeurs : le tracé se fait ensuite
%   avec PLOT.
%
%   Exemple :
%      [h, b] = highlow(hauts, bas, clotures, ouvertures);
%      plot([1:numel(h); 1:numel(h)], [h.'; b.']);
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
