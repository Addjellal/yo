function cap = azimuthTo(lat1, lon1, lat2, lon2)
%AZIMUTHTO Cap initial, en degrés depuis le nord.
%   CAP = AZIMUTHTO(LAT1,LON1,LAT2,LON2) rend le cap à prendre au départ
%   pour suivre l'orthodromie, en degrés depuis le nord, dans le sens des
%   aiguilles d'une montre.
%
%   C'est le cap *initial* : sur une orthodromie, il change tout au long
%   du trajet, sauf le long d'un méridien ou de l'équateur. C'est ce qui
%   distingue l'orthodromie de la loxodromie, où le cap est constant mais
%   le chemin plus long.
%
%   Aller et revenir ne donne donc pas deux caps opposés à 180 degrés
%   près, sauf sur ces deux exceptions.
%
%   Exemple :
%      azimuthTo(0, 0, 10, 0)          % 0 : plein nord
%      azimuthTo(0, 0, 0, 10)          % 90 : plein est
%      azimuthTo(45, 0, 45, 90)        % bien moins que 90 : on passe
%                                      % par le nord
%
%   Voir aussi HAVERSINE, RECKON, DISTANCEGC.
    p1 = lat1 * pi / 180;
    p2 = lat2 * pi / 180;
    dl = (lon2 - lon1) * pi / 180;
    y = sin(dl) .* cos(p2);
    x = cos(p1) .* sin(p2) - sin(p1) .* cos(p2) .* cos(dl);
    cap = mod(atan2(y, x) * 180 / pi + 360, 360);
end
