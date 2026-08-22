function [x, y, fuseau] = deg2utm(latitude, longitude)
%DEG2UTM Projection transverse universelle de Mercator (WGS84).
    a = 6378137.0;
    f = 1/298.257223563;
    e2 = f*(2-f);
    k0 = 0.9996;
    fuseau = floor((longitude + 180) / 6) + 1;
    lon0 = (fuseau - 1) * 6 - 180 + 3;
    p = latitude * pi/180;
    dl = (longitude - lon0) * pi/180;
    N = a ./ sqrt(1 - e2 * sin(p).^2);
    T = tan(p).^2;
    C = e2/(1-e2) * cos(p).^2;
    A = cos(p) .* dl;
    M = a * ((1 - e2/4 - 3*e2^2/64) * p - (3*e2/8 + 3*e2^2/32) .* sin(2*p) ...
             + (15*e2^2/256) .* sin(4*p));
    x = k0 * N .* (A + (1-T+C).*A.^3/6 + (5-18*T+T.^2).*A.^5/120) + 500000;
    y = k0 * (M + N .* tan(p) .* (A.^2/2 + (5-T+9*C+4*C.^2).*A.^4/24));
    y(latitude < 0) = y(latitude < 0) + 10000000;
end
