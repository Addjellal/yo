function [prix, prixFloorlets] = floorbyblk(courbe, exercice, reglement, echeance, volatilite, frequence, base, nominal)
%FLOORBYBLK Prix d'un plancher de taux, modèle de Black.
%   P = FLOORBYBLK(COURBE,EXERCICE,REGLEMENT,ECHEANCE,VOLATILITE) rend le
%   prix d'un contrat qui verse, à chaque période, ce qui manque au taux
%   variable pour atteindre le taux d'exercice.
%
%   Un plafond moins un plancher de même exercice vaut un échange payeur
%   de fixe : c'est la parité achat-vente, appliquée période par période.
%
%   Exemple :
%      floorbyblk(courbe, 0.04, '01-Jan-2024', '01-Jan-2029', 0.2, 4)
%
%   Voir aussi CAPBYBLK, SWAPTIONBYBLK, BLKPRICE.
    if nargin < 6 || isempty(frequence), frequence = 1;    end
    if nargin < 7 || isempty(base),      base = courbe.Basis; end
    if nargin < 8 || isempty(nominal),   nominal = 100;    end
    [prix, prixFloorlets] = matlibre_plafond(courbe, exercice, reglement, echeance, ...
                                             volatilite, frequence, base, nominal, 'floor');
end
