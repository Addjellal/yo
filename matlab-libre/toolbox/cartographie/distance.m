function [longueur, az] = distance(varargin)
%DISTANCE Distance entre deux points de la sphère ou de l'ellipsoïde.
%   [ARCLEN,AZ] = DISTANCE(LAT1,LON1,LAT2,LON2) rend la longueur de l'arc
%   de grand cercle entre les points, en degrés d'arc de la sphère, et
%   l'azimut au départ, en degrés depuis le nord vers l'est.
%   DISTANCE(PT1,PT2) prend deux matrices de points [lat lon].
%   DISTANCE(...,ELLIPSOIDE) calcule sur l'ellipsoïde — un objet
%   REFERENCEELLIPSOID, comme wgs84Ellipsoid, ou le vecteur [a e] — : la
%   longueur de la géodésique est alors dans l'unité du demi-grand axe.
%   DISTANCE(...,'radians') lit et rend les angles en radians.
%   DISTANCE('rh',...) suit la loxodromie, à cap constant, au lieu du grand
%   cercle — sur la sphère seulement.
%
%   Sur l'ellipsoïde, la géodésique est calculée par la méthode inverse de
%   Vincenty (1975), au dixième de millimètre ; pour deux points presque
%   antipodaux, où elle ne converge pas, DISTANCE le dit par une erreur.
%
%   Exemple :
%      d = distance(0, 0, 0, 90)                       % 90 degrés d'arc
%      % Vincenty (1975) et Geoscience Australia : de Flinders Peak à
%      % Buninyong, sur l'ellipsoïde GRS80, 54972.271 m.
%      s = distance(-(37 + 57/60 + 3.72030/3600), 144 + 25/60 + 29.52440/3600, ...
%                   -(37 + 39/60 + 10.15610/3600), 143 + 55/60 + 35.38390/3600, ...
%                   referenceEllipsoid('grs80'))
%
%   Voir aussi AZIMUTH, RECKON, REFERENCEELLIPSOID, DISTANCEGC.
    [piste, v, a, e, radians, donne] = matlibre_geodesie_arguments(varargin, 4, 'distance');
    vers = 1;
    if ~radians
        vers = pi / 180;
    end
    phi1 = v{1} * vers; lam1 = v{2} * vers; phi2 = v{3} * vers; lam2 = v{4} * vers;
    if strcmp(piste, 'rh')
        [s, azr] = matlibre_loxodromie(phi1, lam1, phi2, lam2, a, e);
    else
        [s, azr] = matlibre_geodesique_inverse(phi1, lam1, phi2, lam2, a, e);
    end
    if donne
        longueur = s;
    else
        longueur = s / vers;            % un angle : l'arc de la sphère unité
    end
    az = azr / vers;
end
