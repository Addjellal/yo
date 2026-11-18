function [s, az] = matlibre_loxodromie(phi1, lam1, phi2, lam2, a, e)
%MATLIBRE_LOXODROMIE Longueur et cap de la loxodromie entre deux points.
%   [S,AZ] = MATLIBRE_LOXODROMIE(PHI1,LAM1,PHI2,LAM2,A,E), en radians : la
%   route à cap constant, droite sur la carte de Mercator. Sur la sphère
%   seulement ; un ellipsoïde est refusé.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [s, az] = matlibre_loxodromie(0, 0, 0, pi/2, 1, 0)   % pi/2, pi/2
%
%   Voir aussi DISTANCE, RECKON.
    if e ~= 0
        error('map:loxodromie:Ellipsoide', ...
              'La loxodromie n''est calculée que sur la sphère (excentricité nulle).');
    end
    dphi = phi2 - phi1;
    dpsi = log(tan(pi / 4 + phi2 / 2) ./ tan(pi / 4 + phi1 / 2));
    q = cos(phi1);
    grand = abs(dpsi) > 1e-12;
    q(grand) = dphi(grand) ./ dpsi(grand);
    dlam = mod(lam2 - lam1 + pi, 2 * pi) - pi;
    s = a * sqrt(dphi .^ 2 + q .^ 2 .* dlam .^ 2);
    az = mod(atan2(dlam, dpsi), 2 * pi);
end
