function prix = wclose(haut, bas, cloture)
%WCLOSE Clôture pondérée d'une séance.
%   P = WCLOSE(HAUT,BAS,CLOTURE) rend la moyenne où la clôture compte
%   double : (H + B + 2C) divisé par quatre.
%
%   Exemple :
%      wclose(14, 10, 13)             % 12.5
%
%   Voir aussi MEDPRICE, TYPPRICE.
    if nargin < 2, reste = {}; else, reste = {bas, cloture}; end
    if nargin == 2, reste = {bas}; end
    series = matlibre_colonnes_marche(haut, reste, {'haut', 'bas', 'cloture'});
    prix = (series{1} + series{2} + 2 * series{3}) / 4;
end
