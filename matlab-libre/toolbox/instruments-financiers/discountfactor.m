function d = discountfactor(taux, echeances)
%DISCOUNTFACTOR Facteurs d'actualisation d'une courbe de taux.
%   D = DISCOUNTFACTOR(TAUX,ECHEANCES) rend les facteurs d'actualisation
%   1./(1+TAUX).^ECHEANCES, un par couple taux-échéance. TAUX est le taux
%   zéro-coupon propre à chaque échéance, non un taux unique.
%
%   Un facteur d'actualisation est le prix d'aujourd'hui pour un euro reçu
%   à l'échéance. Une fois cette courbe connue, tout instrument à flux
%   certains s'évalue par un simple produit scalaire entre son échéancier
%   et les facteurs : la valorisation ne demande plus aucune hypothèse.
%
%   Les facteurs décroissent avec l'échéance dès que les taux sont
%   positifs, et valent un à l'instant zéro. Ce sont eux, et non les taux,
%   qui s'interpolent proprement : interpoler des taux peut engendrer des
%   taux à terme négatifs entre deux points de la courbe.
%
%   Exemple :
%      discountfactor([0.02 0.025 0.03], [1 2 3])'
%
%   Voir aussi FORWARDRATE, BONDPRICE, PV.
    d = 1 ./ (1 + taux(:)) .^ echeances(:);
end
