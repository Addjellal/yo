function aire = areaint(latitudes, longitudes, varargin)
%AREAINT Aire d'un polygone tracé sur la sphère ou l'ellipsoïde.
%   A = AREAINT(LAT,LON) rend l'aire du polygone de sommets (LAT,LON), en
%   degrés, comme la fraction de la sphère qu'il couvre — la convention de
%   MATLAB. Le polygone se referme tout seul ; des NaN séparent plusieurs
%   polygones, et A a alors un élément par polygone. L'aire est positive
%   quel que soit le sens de parcours ; c'est celle de la plus petite des
%   deux régions que le contour sépare.
%   AREAINT(LAT,LON,ELLIPSOIDE) la rend en unités carrées de l'ellipsoïde
%   — un objet REFERENCEELLIPSOID, [a e], ou un rayon seul —, par les
%   latitudes authaliques, qui portent l'ellipsoïde sur la sphère de même
%   aire.
%   AREAINT(...,'radians') lit les angles en radians.
%
%   Les côtés sont des arcs de grand cercle, et l'aire est exacte : la
%   somme des excès sphériques des triangles qu'ils forment avec un point
%   de référence (formule de Van Oosterom et Strackee, 1983). MATLAB, lui,
%   intègre par trapèzes une intégrale de Green : sa documentation rend
%   0.0792 puis 0.0829 pour un fuseau de trente degrés décrit avec des
%   sommets espacés de 30 puis de 10 degrés, dont l'aire exacte est 1/12,
%   0.0833 — la valeur que rend AREAINT dans les deux cas.
%
%   Exemple :
%      areaint([0 0 90], [0 90 0])          % un octant : 0.125
%      lat = [-90:30:90 60:-30:-60]; lon = [zeros(1,7) 30*ones(1,5)];
%      areaint(lat, lon)                    % fuseau de 30 degrés : 1/12
%      areaint([0 0 10 10], [0 10 10 0], 6371000)   % en mètres carrés
%
%   Voir aussi AREAQUAD, DISTANCE, RECKON, REFERENCEELLIPSOID.
    [~, v, a, e, radians, donne] = matlibre_geodesie_arguments( ...
        [{latitudes, longitudes}, varargin], 2, 'areaint');
    vers = 1;
    if ~radians
        vers = pi / 180;
    end
    phi = v{1}(:) * vers;
    lam = v{2}(:) * vers;
    if ~isequal(isnan(phi), isnan(lam))
        error('map:areaint:NaN', 'The NaNs of LAT and LON must match.');
    end
    if e > 0
        phi = matlibre_latitude_authalique(phi, e);
    end
    % Les polygones, séparés par des NaN.
    coupures = [0; find(isnan(phi)); numel(phi) + 1];
    aire = [];
    for k = 1:numel(coupures) - 1
        indices = coupures(k) + 1:coupures(k + 1) - 1;
        if isempty(indices)
            continue
        end
        aire(end + 1, 1) = fraction(phi(indices), lam(indices)); %#ok<AGROW>
    end
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

function f = fraction(phi, lam)
%FRACTION La part de la sphère qu'occupe un polygone à côtés géodésiques.
    n = numel(phi);
    if n < 3
        f = 0;
        return
    end
    P = [cos(phi) .* cos(lam), cos(phi) .* sin(lam), sin(phi)];
    % Le point de référence : une direction quelconque, ni sommet ni
    % antipode d'un sommet.
    R = [0.4083, 0.5774, 0.7071];
    R = R / norm(R);
    while any(abs(P * R') > 1 - 1e-9)
        R = R + [0.0123 -0.0321 0.0217];
        R = R / norm(R);
    end
    somme = 0;
    for i = 1:n
        A = P(i, :);
        B = P(mod(i, n) + 1, :);
        numerateur = dot(R, cross(A, B));
        denominateur = 1 + dot(R, A) + dot(A, B) + dot(B, R);
        somme = somme + 2 * atan2(numerateur, denominateur);
    end
    aire = mod(abs(somme), 4 * pi);
    aire = min(aire, 4 * pi - aire);
    f = aire / (4 * pi);
end
