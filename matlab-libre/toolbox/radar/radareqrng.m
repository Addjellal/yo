function R = radareqrng(lambda, Pt, G, sigma, Pmin)
%RADAREQRNG Portée maximale d'un radar, en mètres.
%   R = RADAREQRNG(LAMBDA,PT,G,SIGMA,PMIN) applique l'équation du radar :
%
%      R = ((Pt G^2 lambda^2 sigma) / ((4 pi)^3 Pmin))^(1/4)
%
%      LAMBDA  la longueur d'onde, en mètres
%      PT      la puissance émise, en watts
%      G       le gain de l'antenne, linéaire
%      SIGMA   la surface équivalente radar de la cible, en mètres carrés
%      PMIN    la plus petite puissance détectable, en watts
%
%   La racine quatrième est ce qu'il faut retenir : l'onde s'étale à
%   l'aller et au retour, si bien que doubler la portée demande seize fois
%   plus de puissance. C'est pourquoi on gagne davantage sur l'antenne —
%   dont le gain intervient au carré — que sur l'émetteur.
%
%   Exemple :
%      radareqrng(0.03, 1e3, 1e4, 1, 1e-12)
%      radareqrng(0.03, 16e3, 1e4, 1, 1e-12)   % seize fois la puissance,
%                                              % deux fois la portee
%
%   Voir aussi RADAREQPOW, TIME2RANGE, RANGE2TIME.
    R = ((Pt .* G .^ 2 .* lambda .^ 2 .* sigma) ./ ((4 * pi) ^ 3 .* Pmin)) .^ 0.25;
end
