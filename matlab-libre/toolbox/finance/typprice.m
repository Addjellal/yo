function prix = typprice(haut, bas, cloture)
%TYPPRICE Prix typique d'une séance.
%   P = TYPPRICE(HAUT,BAS,CLOTURE) rend la moyenne des trois. Il sert de
%   cours de référence là où la clôture seule serait trop sensible aux
%   derniers échanges.
%
%   Exemple :
%      typprice([12 10 11], [14 11 13])
%
%   Voir aussi MEDPRICE, WCLOSE, STOCHOSC.
    if nargin < 2, reste = {}; else, reste = {bas, cloture}; end
    if nargin == 2, reste = {bas}; end
    series = matlibre_colonnes_marche(haut, reste, {'haut', 'bas', 'cloture'});
    prix = (series{1} + series{2} + series{3}) / 3;
end
