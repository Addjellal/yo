function aire = areaquad(lat1, lon1, lat2, lon2, varargin)
%AREAQUAD Aire d'un quadrangle délimité par deux parallèles et deux méridiens.
%   A = AREAQUAD(LAT1,LON1,LAT2,LON2) rend l'aire de la région comprise
%   entre les latitudes LAT1 et LAT2 et les longitudes LON1 et LON2, en
%   degrés, comme fraction de la sphère :
%      A = |LON2 - LON1|/360 * |sin(LAT2) - sin(LAT1)|/2.
%   AREAQUAD(...,ELLIPSOIDE) la rend en unités carrées de l'ellipsoïde, par
%   les latitudes authaliques ; AREAQUAD(...,'radians') lit des radians.
%
%   Exemple :
%      areaquad(90, 0, -90, 30)     % 1/12 : le fuseau de trente degrés
%      areaquad(0, 0, 90, 360)      % 0.5 : l'hémisphère nord
%
%   Voir aussi AREAINT, REFERENCEELLIPSOID.
    [~, v, a, e, radians, donne] = matlibre_geodesie_arguments( ...
        [{lat1, lon1, lat2, lon2}, varargin], 4, 'areaquad');
    vers = 1;
    if ~radians
        vers = pi / 180;
    end
    phi1 = v{1} * vers;
    phi2 = v{3} * vers;
    largeur = abs(v{4} - v{2}) * vers;
    largeur = min(largeur, 2 * pi);
    if e > 0
        phi1 = matlibre_latitude_authalique(phi1, e);
        phi2 = matlibre_latitude_authalique(phi2, e);
    end
    aire = largeur / (2 * pi) .* abs(sin(phi2) - sin(phi1)) / 2;
    if donne
        if e > 0
            ellipsoide = referenceEllipsoid([a e]);
            surface = ellipsoide.SurfaceArea;
        else
            surface = 4 * pi * a ^ 2;
        end
        aire = aire * surface;
    end
end
