function carte = copper(m)
%COPPER Carte de couleurs noir - cuivre.
%   CARTE = COPPER() rend une carte de 256 couleurs allant du noir au
%   cuivre. CARTE = COPPER(M) en rend M.
%
%   Les trois canaux montent proportionnellement à la même rampe, dans le
%   rapport 1,25 / 0,7812 / 0,4975 : la teinte ne change jamais, seule la
%   clarté augmente. Le rouge sature à un aux quatre cinquièmes du
%   parcours, ce qui donne le reflet métallique du haut de l'échelle.
%
%   Une carte à teinte fixe et clarté monotone est celle qui trahit le
%   moins : elle ne crée aucune frontière là où les données varient
%   régulièrement, contrairement aux cartes arc-en-ciel dont les brusques
%   changements de teinte font croire à des paliers.
%
%   Exemple :
%      carte = copper(8);
%      carte(end, :)
%
%   Voir aussi BONE, PINK, GRAY, HOT, COLORMAP.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [min(1, g * 1.25), g * 0.7812, g * 0.4975];
end
