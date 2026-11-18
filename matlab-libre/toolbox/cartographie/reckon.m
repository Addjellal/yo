function [lat2, lon2] = reckon(varargin)
%RECKON Point atteint en suivant un azimut sur une distance donnée.
%   [LAT2,LON2] = RECKON(LAT,LON,ARCLEN,AZ) rend le point atteint depuis
%   (LAT,LON) en partant à l'azimut AZ sur le grand cercle, après un arc
%   ARCLEN — en degrés d'arc de la sphère, comme dans MATLAB.
%   RECKON(LAT,LON,ARCLEN,AZ,ELLIPSOIDE) suit la géodésique de
%   l'ellipsoïde — un objet REFERENCEELLIPSOID ou le vecteur [a e] — et
%   ARCLEN est alors une longueur, dans l'unité du demi-grand axe. Un
%   rayon seul, ou [R 0], fait une sphère de rayon R : RECKON(LAT,LON,D,AZ,
%   6371000) avance de D mètres.
%   RECKON(...,'radians') lit et rend les angles en radians ;
%   RECKON('rh',...) suit la loxodromie, à cap constant.
%
%   C'est la réciproque de DISTANCE : partir d'un point, suivre l'azimut et
%   la longueur qu'elle donne, et retomber sur l'autre point. Sur
%   l'ellipsoïde, la méthode directe de Vincenty (1975).
%
%   Suivre l'azimut initial ne veut pas dire garder ce cap : le grand cercle
%   le fait varier. Le point rendu est bien celui d'un grand cercle, non
%   d'une route à cap constant — sauf avec 'rh'.
%
%   Exemple :
%      [lat, lon] = reckon(0, 0, 90, 0)              % le pôle Nord
%      [lat, lon] = reckon(0, 0, 111195, 0, 6371000) % un degré vers le nord
%      [s, az] = distance(48.86, 2.35, 40.71, -74.01, wgs84Ellipsoid);
%      [lat, lon] = reckon(48.86, 2.35, s, az, wgs84Ellipsoid) % New York
%
%   Voir aussi DISTANCE, AZIMUTH, AREAINT.
    [piste, v, a, e, radians, donne] = matlibre_geodesie_arguments(varargin, 4, 'reckon');
    vers = 1;
    if ~radians
        vers = pi / 180;
    end
    phi1 = v{1} * vers;
    lam1 = v{2} * vers;
    az = v{4} * vers;
    if donne
        s = v{3};                       % une longueur, dans l'unité de a
    else
        s = v{3} * vers;                % un arc de la sphère unité
    end
    if strcmp(piste, 'rh')
        if e ~= 0
            error('map:reckon:Ellipsoide', ...
                  'La loxodromie n''est calculée que sur la sphère (excentricité nulle).');
        end
        delta = s / a;
        dphi = delta .* cos(az);
        phi2 = phi1 + dphi;
        dpsi = log(tan(pi / 4 + phi2 / 2) ./ tan(pi / 4 + phi1 / 2));
        q = cos(phi1);
        grand = abs(dpsi) > 1e-12;
        q(grand) = dphi(grand) ./ dpsi(grand);
        lam2 = lam1 + delta .* sin(az) ./ q;
        lam2 = mod(lam2 + pi, 2 * pi) - pi;
    else
        [phi2, lam2] = matlibre_geodesique_directe(phi1, lam1, s, az, a, e);
    end
    lat2 = phi2 / vers;
    lon2 = lam2 / vers;
end
