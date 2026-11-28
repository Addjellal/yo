function [phi2, lam2, az2] = matlibre_geodesique_directe(phi1, lam1, s, az1, a, e)
%MATLIBRE_GEODESIQUE_DIRECTE Point atteint en suivant une géodésique.
%   [PHI2,LAM2,AZ2] = MATLIBRE_GEODESIQUE_DIRECTE(PHI1,LAM1,S,AZ1,A,E),
%   angles en radians, rend le point atteint depuis (PHI1,LAM1) en partant
%   à l'azimut AZ1 sur la longueur S (unité de A), et l'azimut d'arrivée.
%   Sur la sphère, les formules du grand cercle ; sur l'ellipsoïde, la
%   méthode directe de Vincenty (1975), qui converge toujours.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [p, l] = matlibre_geodesique_directe(0, 0, pi/2, 0, 1, 0)   % le pôle
%
%   Voir aussi RECKON, MATLIBRE_GEODESIQUE_INVERSE.
    phi2 = zeros(size(phi1));
    lam2 = zeros(size(phi1));
    az2 = zeros(size(phi1));
    for k = 1:numel(phi1)
        if e == 0
            delta = s(k) / a;
            p1 = phi1(k);
            t = az1(k);
            p2 = asin(sin(p1) * cos(delta) + cos(p1) * sin(delta) * cos(t));
            l2 = lam1(k) + atan2(sin(t) * sin(delta) * cos(p1), cos(delta) - sin(p1) * sin(p2));
            phi2(k) = p2;
            lam2(k) = l2;
            az2(k) = atan2(sin(t) * cos(p1), cos(p1) * cos(delta) * cos(t) - sin(p1) * sin(delta));
        else
            [phi2(k), lam2(k), az2(k)] = vincenty(phi1(k), lam1(k), s(k), az1(k), a, e);
        end
    end
    lam2 = mod(lam2 + pi, 2 * pi) - pi;
    az2 = mod(az2, 2 * pi);
end

function [p2, l2, az2] = vincenty(p1, l1, s, a1, a, e)
    f = 1 - sqrt(1 - e ^ 2);
    b = a * (1 - f);
    U1 = atan((1 - f) * tan(p1));
    sU1 = sin(U1); cU1 = cos(U1);
    sigma1 = atan2(tan(U1), cos(a1));
    sinAlpha = cU1 * sin(a1);
    cos2Alpha = 1 - sinAlpha ^ 2;
    u2 = cos2Alpha * (a ^ 2 - b ^ 2) / b ^ 2;
    A = 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)));
    B = u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)));
    sigma = s / (b * A);
    for iteration = 1:200
        cos2SigmaM = cos(2 * sigma1 + sigma);
        deltaSigma = B * sin(sigma) * (cos2SigmaM + B / 4 * (cos(sigma) * ...
                     (-1 + 2 * cos2SigmaM ^ 2) - B / 6 * cos2SigmaM * ...
                     (-3 + 4 * sin(sigma) ^ 2) * (-3 + 4 * cos2SigmaM ^ 2)));
        precedent = sigma;
        sigma = s / (b * A) + deltaSigma;
        if abs(sigma - precedent) < 1e-13
            break
        end
    end
    cos2SigmaM = cos(2 * sigma1 + sigma);
    tmp = sU1 * sin(sigma) - cU1 * cos(sigma) * cos(a1);
    p2 = atan2(sU1 * cos(sigma) + cU1 * sin(sigma) * cos(a1), ...
               (1 - f) * sqrt(sinAlpha ^ 2 + tmp ^ 2));
    lambda = atan2(sin(sigma) * sin(a1), cU1 * cos(sigma) - sU1 * sin(sigma) * cos(a1));
    C = f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));
    L = lambda - (1 - C) * f * sinAlpha * (sigma + C * sin(sigma) * ...
        (cos2SigmaM + C * cos(sigma) * (-1 + 2 * cos2SigmaM ^ 2)));
    l2 = l1 + L;
    az2 = atan2(sinAlpha, -tmp);
end
