function [s, az1, az2] = matlibre_geodesique_inverse(phi1, lam1, phi2, lam2, a, e)
%MATLIBRE_GEODESIQUE_INVERSE Distance et azimuts entre deux points.
%   [S,AZ1,AZ2] = MATLIBRE_GEODESIQUE_INVERSE(PHI1,LAM1,PHI2,LAM2,A,E),
%   angles en radians, rend la longueur S de la géodésique (dans l'unité
%   de A) et les azimuts au départ et à l'arrivée.
%
%   Sur la sphère (E = 0), la formule des haversines. Sur l'ellipsoïde, la
%   méthode de Vincenty (1975, « Direct and inverse solutions of geodesics
%   on the ellipsoid with application of nested equations », Survey Review
%   23(176)), précise au dixième de millimètre. Elle ne converge pas pour
%   des points presque antipodaux : la fonction le dit au lieu de rendre
%   un nombre faux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      s = matlibre_geodesique_inverse(0, 0, 0, pi/2, 1, 0)   % pi/2
%
%   Voir aussi DISTANCE, AZIMUTH, MATLIBRE_GEODESIQUE_DIRECTE.
    s = zeros(size(phi1));
    az1 = zeros(size(phi1));
    az2 = zeros(size(phi1));
    for k = 1:numel(phi1)
        if e == 0
            [s(k), az1(k), az2(k)] = surSphere(phi1(k), lam1(k), phi2(k), lam2(k), a);
        else
            [s(k), az1(k), az2(k)] = vincenty(phi1(k), lam1(k), phi2(k), lam2(k), a, e);
        end
    end
end

function [s, az1, az2] = surSphere(p1, l1, p2, l2, R)
    dl = l2 - l1;
    h = sin((p2 - p1) / 2) ^ 2 + cos(p1) * cos(p2) * sin(dl / 2) ^ 2;
    s = 2 * R * atan2(sqrt(h), sqrt(max(1 - h, 0)));
    az1 = atan2(sin(dl) * cos(p2), cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl));
    az2 = atan2(sin(dl) * cos(p1), -sin(p1) * cos(p2) + cos(p1) * sin(p2) * cos(dl));
    az1 = mod(az1, 2 * pi);
    az2 = mod(az2, 2 * pi);
end

function [s, az1, az2] = vincenty(p1, l1, p2, l2, a, e)
    f = 1 - sqrt(1 - e ^ 2);
    b = a * (1 - f);
    L = mod(l2 - l1 + pi, 2 * pi) - pi;
    U1 = atan((1 - f) * tan(p1));
    U2 = atan((1 - f) * tan(p2));
    sU1 = sin(U1); cU1 = cos(U1);
    sU2 = sin(U2); cU2 = cos(U2);
    lambda = L;
    converge = false;
    for iteration = 1:200
        sl = sin(lambda);
        cl = cos(lambda);
        sinSigma = sqrt((cU2 * sl) ^ 2 + (cU1 * sU2 - sU1 * cU2 * cl) ^ 2);
        if sinSigma == 0
            s = 0;
            az1 = 0;
            az2 = 0;
            return
        end
        cosSigma = sU1 * sU2 + cU1 * cU2 * cl;
        sigma = atan2(sinSigma, cosSigma);
        sinAlpha = cU1 * cU2 * sl / sinSigma;
        cos2Alpha = 1 - sinAlpha ^ 2;
        if cos2Alpha ~= 0
            cos2SigmaM = cosSigma - 2 * sU1 * sU2 / cos2Alpha;
        else
            cos2SigmaM = 0;                 % ligne équatoriale
        end
        C = f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));
        precedent = lambda;
        lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * ...
                 (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM ^ 2)));
        if abs(lambda - precedent) < 1e-13
            converge = true;
            break
        end
    end
    if ~converge
        error('map:geodesique:Convergence', ...
              ['La méthode de Vincenty ne converge pas : les deux points sont presque ', ...
               'antipodaux sur l''ellipsoïde.']);
    end
    u2 = cos2Alpha * (a ^ 2 - b ^ 2) / b ^ 2;
    A = 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)));
    B = u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)));
    deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM ^ 2) ...
                 - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma ^ 2) * (-3 + 4 * cos2SigmaM ^ 2)));
    s = b * A * (sigma - deltaSigma);
    az1 = mod(atan2(cU2 * sin(lambda), cU1 * sU2 - sU1 * cU2 * cos(lambda)), 2 * pi);
    az2 = mod(atan2(cU1 * sin(lambda), -sU1 * cU2 + cU1 * sU2 * cos(lambda)), 2 * pi);
end
