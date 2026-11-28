function beta = matlibre_latitude_authalique(phi, e)
%MATLIBRE_LATITUDE_AUTHALIQUE Latitude de la sphère de même aire que l'ellipsoïde.
%   BETA = MATLIBRE_LATITUDE_AUTHALIQUE(PHI,E), en radians : sin(beta) =
%   q(phi)/q(pi/2), avec q(phi) = (1-e^2) [sin(phi)/(1-e^2 sin^2(phi))
%   - 1/(2e) ln((1-e sin(phi))/(1+e sin(phi)))] (Snyder, Map Projections —
%   A Working Manual, 1987, équation 3-11). La zone entre deux parallèles
%   de l'ellipsoïde a la même aire que celle des parallèles authaliques sur
%   la sphère de même surface.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_latitude_authalique(pi/2, 0.0818)   % pi/2
%
%   Voir aussi AREAINT, AREAQUAD.
    q = @(s) (1 - e ^ 2) * (s ./ (1 - e ^ 2 * s .^ 2) - ...
             1 / (2 * e) * log((1 - e * s) ./ (1 + e * s)));
    beta = asin(max(-1, min(1, q(sin(phi)) / q(1))));
end
