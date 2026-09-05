function modele = arx(donnees, ordres, varargin)
%ARX Estimation d'un modèle ARX par moindres carrés.
%   M = ARX(Z,[na nb nk]) ajuste le modèle
%
%      y(t) + a1 y(t-1) + ... + ana y(t-na)
%          = b1 u(t-nk) + ... + bnb u(t-nk-nb+1) + e(t)
%
%   où Z est un IDDATA. Le modèle est linéaire en ses coefficients : la
%   solution est directe, c'est le minimum global, et il n'y a ni point de
%   départ ni itération. C'est pourquoi ARX sert de départ aux autres
%   estimateurs, dont aucun n'a cette propriété.
%
%   Le prix de cette simplicité est que le bruit est supposé entrer par le
%   même dénominateur que l'entrée : quand ce n'est pas le cas, ARX rend
%   des coefficients biaisés, que ARMAX, OE ou BJ corrigent.
%
%   M = ARX(Z,ORDRES,'na',...) accepte les réglages de POLYEST.
%
%   Exemple :
%      z = iddata(filter([0 0.5], [1 -0.8], ones(200, 1)), ones(200, 1));
%      m = arx(z, [1 1 1]);
%      m.A      % 1 -0.8
%
%   Voir aussi ARMAX, OE, BJ, POLYEST, IV4, AR, COMPARE.
    ordres = matlibre_id_ordres(ordres, [1 1 0 0 0 1]);
    ordres(3:5) = 0;
    modele = matlibre_id_moindres_carres(donnees, ordres, 'arx');
end
