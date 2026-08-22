function [T, a, P, rho] = atmosisa(altitude)
%ATMOSISA Atmosphère type internationale (troposphère et stratosphère).
%   [T,A,P,RHO] = ATMOSISA(H) rend la température (K), la vitesse du son
%   (m/s), la pression (Pa) et la masse volumique (kg/m^3).
    T0 = 288.15; P0 = 101325; g = 9.80665; R = 287.0531; L = 0.0065;
    T = zeros(size(altitude));
    P = zeros(size(altitude));
    for k = 1:numel(altitude)
        h = altitude(k);
        if h <= 11000
            T(k) = T0 - L * h;
            P(k) = P0 * (T(k) / T0) ^ (g / (R * L));
        else
            T11 = T0 - L * 11000;
            P11 = P0 * (T11 / T0) ^ (g / (R * L));
            T(k) = T11;
            P(k) = P11 * exp(-g * (h - 11000) / (R * T11));
        end
    end
    rho = P ./ (R * T);
    a = sqrt(1.4 * R * T);
end
