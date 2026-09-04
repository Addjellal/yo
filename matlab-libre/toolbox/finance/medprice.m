function prix = medprice(haut, bas)
%MEDPRICE Prix médian d'une séance.
%   P = MEDPRICE(HAUT,BAS) rend la moyenne du plus haut et du plus bas.
%   MEDPRICE(COTATIONS) lit une matrice dont les colonnes sont
%   l'ouverture, le plus haut, le plus bas et la clôture.
%
%   Exemple :
%      medprice([12 10; 14 11])       % [11; 12.5]
%
%   Voir aussi TYPPRICE, WCLOSE, HHIGH, LLOW.
    if nargin < 2, reste = {}; else, reste = {bas}; end
    series = matlibre_colonnes_marche(haut, reste, {'haut', 'bas'});
    prix = (series{1} + series{2}) / 2;
end
