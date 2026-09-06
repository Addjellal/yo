function [x, y, z] = geodetic2ecef(latitude, longitude, altitude)
%GEODETIC2ECEF Coordonnées géodésiques (degrés) vers repère terrestre WGS84.
%   [X,Y,Z] = GEODETIC2ECEF(LAT,LON,ALT) convertit latitude et longitude,
%   en degrés, et altitude au-dessus de l'ellipsoïde, en mètres, vers le
%   repère cartésien lié à la Terre : origine au centre, X vers le méridien
%   de Greenwich à l'équateur, Z vers le pôle nord.
%
%   C'est le repère dans lequel travaille un récepteur GPS : les positions
%   des satellites y sont données, et c'est là que se résout la
%   trilatération. Les coordonnées géodésiques n'en sont qu'une lecture
%   commode.
%
%   L'ellipsoïde WGS84 est aplati d'environ un trois-centième : la
%   distance du centre au pôle est plus courte de 21 km que celle à
%   l'équateur. Traiter la Terre comme une sphère fausse donc les
%   altitudes de plusieurs kilomètres selon la latitude.
%
%   Exemple :
%      [x, y, z] = geodetic2ecef(0, 0, 0);      % x = 6378137, le rayon
%      [x, y, z] = geodetic2ecef(90, 0, 0);     % z = 6356752, plus court
%      norm([x y z])
%
%   Voir aussi ATMOSISA, DEG2UTM.
    a = 6378137.0;
    f = 1 / 298.257223563;
    e2 = f * (2 - f);
    lat = latitude * pi / 180;
    lon = longitude * pi / 180;
    N = a ./ sqrt(1 - e2 * sin(lat) .^ 2);
    x = (N + altitude) .* cos(lat) .* cos(lon);
    y = (N + altitude) .* cos(lat) .* sin(lon);
    z = (N * (1 - e2) + altitude) .* sin(lat);
end
