function [prix, prixCaplets] = capbyblk(courbe, exercice, reglement, echeance, volatilite, frequence, base, nominal)
%CAPBYBLK Prix d'un plafond de taux, modèle de Black.
%   P = CAPBYBLK(COURBE,EXERCICE,REGLEMENT,ECHEANCE,VOLATILITE) rend le
%   prix d'un contrat qui rembourse, à chaque période, ce que le taux
%   variable dépasse le taux d'exercice.
%
%   [P,CAPLETS] = CAPBYBLK(...) rend aussi le prix de chaque période.
%
%   Un plafond est une somme d'options d'achat sur le taux à terme, une
%   par période : chacune se valorise par la formule de Black, et le
%   plafond est leur somme. La première période, dont le taux est déjà
%   fixé, ne compte pas.
%
%   Exemple :
%      capbyblk(courbe, 0.04, '01-Jan-2024', '01-Jan-2029', 0.2, 4)
%
%   Voir aussi FLOORBYBLK, SWAPTIONBYBLK, BLKPRICE.
    if nargin < 6 || isempty(frequence), frequence = 1;    end
    if nargin < 7 || isempty(base),      base = courbe.Basis; end
    if nargin < 8 || isempty(nominal),   nominal = 100;    end
    [prix, prixCaplets] = matlibre_plafond(courbe, exercice, reglement, echeance, ...
                                           volatilite, frequence, base, nominal, 'cap');
end
