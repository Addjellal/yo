function Pt = radareqpow(lambda, R, G, sigma, Pmin)
%RADAREQPOW Puissance d'émission nécessaire pour une portée donnée.
%   PT = RADAREQPOW(LAMBDA,R,G,SIGMA,PMIN) résout l'équation du radar en
%   puissance :
%
%      Pt = Pmin (4 pi)^3 R^4 / (G^2 lambda^2 sigma)
%
%   C'est l'exacte réciproque de RADAREQRNG : ce que l'une rend en portée,
%   l'autre le rend en puissance, et les deux se recomposent.
%
%   La puissance croît comme la puissance quatrième de la portée : c'est
%   ce qui rend les radars longue portée si gourmands, et c'est aussi ce
%   qui rend une cible furtive — un SIGMA divisé par cent — si difficile,
%   puisqu'il faut alors cent fois plus de puissance à portée égale.
%
%   Exemple :
%      Pt = radareqpow(0.03, 50e3, 1e4, 1, 1e-12);
%      radareqrng(0.03, Pt, 1e4, 1, 1e-12)     % 50000, la portee voulue
%
%   Voir aussi RADAREQRNG, DOPPLERSHIFT.
    Pt = Pmin .* (4 * pi) ^ 3 .* R .^ 4 ./ (G .^ 2 .* lambda .^ 2 .* sigma);
end
