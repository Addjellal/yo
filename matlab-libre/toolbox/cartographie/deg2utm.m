function [x, y, fuseau] = deg2utm(latitude, longitude)
%DEG2UTM Projection transverse universelle de Mercator (WGS84).
%   [X,Y,FUSEAU] = DEG2UTM(LAT,LON) projette des coordonnées géodésiques,
%   en degrés, vers des mètres est et nord dans le fuseau UTM qui contient
%   le point.
%
%   L'UTM découpe le monde en soixante fuseaux de six degrés de longitude,
%   chacun avec sa propre projection. C'est ce qui limite la déformation à
%   moins d'un pour mille — mais deux points de fuseaux différents ne se
%   comparent pas : leurs coordonnées ne sont pas dans le même repère.
%
%   La projection est conforme : elle conserve les angles, donc les
%   formes locales, au prix des aires. C'est le choix qui convient à la
%   navigation et au cadastre, non à une carte de densités.
%
%   L'ordonnée est comptée depuis l'équateur ; l'abscisse depuis le
%   méridien central du fuseau, décalée de 500 km pour rester positive.
%
%   Exemple :
%      [x, y, fuseau] = deg2utm(48.8566, 2.3522);   % Paris, fuseau 31
%      fuseau
%
%   Voir aussi DISTANCEGC, RECKON, AREAINT.
    a = 6378137.0;
    f = 1/298.257223563;
    e2 = f*(2-f);
    k0 = 0.9996;
    fuseau = floor((longitude + 180) / 6) + 1;
    lon0 = (fuseau - 1) * 6 - 180 + 3;
    p = latitude * pi/180;
    dl = (longitude - lon0) * pi/180;
    N = a ./ sqrt(1 - e2 * sin(p).^2);
    T = tan(p).^2;
    C = e2/(1-e2) * cos(p).^2;
    A = cos(p) .* dl;
    M = a * ((1 - e2/4 - 3*e2^2/64) * p - (3*e2/8 + 3*e2^2/32) .* sin(2*p) ...
             + (15*e2^2/256) .* sin(4*p));
    x = k0 * N .* (A + (1-T+C).*A.^3/6 + (5-18*T+T.^2).*A.^5/120) + 500000;
    y = k0 * (M + N .* tan(p) .* (A.^2/2 + (5-T+9*C+4*C.^2).*A.^4/24));
    y(latitude < 0) = y(latitude < 0) + 10000000;
end
