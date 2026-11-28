function e = wgs84Ellipsoid(unite)
%WGS84ELLIPSOID L'ellipsoïde du World Geodetic System 1984.
%   E = WGS84ELLIPSOID rend l'ellipsoïde WGS84 en mètres ;
%   WGS84ELLIPSOID(UNITE) dans une autre unité : 'kilometer', 'km'...
%   C'est l'ellipsoïde du GPS : a = 6378137 m, 1/f = 298,257223563.
%
%   Exemple :
%      e = wgs84Ellipsoid('km');
%      e.SemimajorAxis          % 6378.137
%
%   Voir aussi REFERENCEELLIPSOID, DISTANCE.
    if nargin < 1
        unite = 'meter';
    end
    e = referenceEllipsoid('wgs84', unite);
end
