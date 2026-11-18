function az = azimuth(varargin)
%AZIMUTH Azimut d'un point vers un autre, sur la sphère ou l'ellipsoïde.
%   AZ = AZIMUTH(LAT1,LON1,LAT2,LON2) rend l'azimut au départ du grand
%   cercle qui va du premier point au second, en degrés, compté du nord
%   vers l'est, dans [0, 360).
%   AZIMUTH(PT1,PT2), AZIMUTH(...,ELLIPSOIDE), AZIMUTH(...,'radians') et
%   AZIMUTH('rh',...) se lisent comme pour DISTANCE.
%
%   Exemple :
%      azimuth(0, 0, 10, 0)          % 0 : plein nord
%      azimuth(0, 0, 0, 10)          % 90 : plein est
%
%   Voir aussi DISTANCE, RECKON.
    [~, az] = distance(varargin{:});
end
