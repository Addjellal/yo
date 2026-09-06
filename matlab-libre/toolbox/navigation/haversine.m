function d = haversine(lat1, lon1, lat2, lon2, rayon)
%HAVERSINE Distance orthodromique entre deux points, en mètres.
%   D = HAVERSINE(LAT1,LON1,LAT2,LON2) rend la distance sur la sphère
%   entre deux points donnés en degrés ; HAVERSINE(...,RAYON) impose le
%   rayon, celui de la Terre par défaut.
%
%   La formule de l'haversine est préférée à la loi des cosinus
%   sphériques parce qu'elle reste précise pour les points proches, là où
%   celle-ci perd ses chiffres significatifs en soustrayant deux cosinus
%   presque égaux.
%
%   Elle mesure sur une sphère, non sur l'ellipsoïde : l'écart avec la
%   géodésique vraie atteint quelques dixièmes de pour cent, ce qui est
%   sans importance pour une navigation mais pas pour une géodésie.
%
%   Un degré de latitude vaut environ 111 km, partout ; un degré de
%   longitude vaut cela multiplié par le cosinus de la latitude, donc rien
%   au pôle.
%
%   Exemple :
%      haversine(0, 0, 0, 1)           % environ 111 km, a l'equateur
%      haversine(60, 0, 60, 1)         % la moitie, a 60 degres
%      haversine(0, 0, 90, 0)          % le quart d'un meridien
%
%   Voir aussi AZIMUTHTO, DISTANCEGC, RECKON.
    if nargin < 5
        rayon = 6371000;
    end
    p1 = lat1 * pi / 180;
    p2 = lat2 * pi / 180;
    dp = (lat2 - lat1) * pi / 180;
    dl = (lon2 - lon1) * pi / 180;
    a = sin(dp/2) .^ 2 + cos(p1) .* cos(p2) .* sin(dl/2) .^ 2;
    d = 2 * rayon * atan2(sqrt(a), sqrt(1 - a));
end
