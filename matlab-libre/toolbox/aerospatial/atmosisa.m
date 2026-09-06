function [T, a, P, rho] = atmosisa(altitude)
%ATMOSISA Atmosphère type internationale (troposphère et stratosphère).
%   [T,A,P,RHO] = ATMOSISA(H) rend la température (K), la vitesse du son
%   (m/s), la pression (Pa) et la masse volumique (kg/m^3) à l'altitude H,
%   en mètres.
%
%   L'atmosphère type est une convention, non une mesure : elle fixe au
%   niveau de la mer 288,15 K et 101325 Pa, puis une décroissance de
%   6,5 K par kilomètre jusqu'à 11 km — la tropopause —, et une
%   température constante au-dessus. C'est ce modèle qui sert à étalonner
%   les altimètres et à comparer des performances d'avions.
%
%   La vitesse du son ne dépend que de la température : elle tombe à
%   295 m/s à la tropopause, contre 340 au sol, et n'y bouge plus. C'est
%   pourquoi un avion de ligne y vole à Mach constant.
%
%   Le modèle s'arrête à 20 km ; au-delà, la valeur rendue est celle de la
%   tropopause prolongée.
%
%   Exemple :
%      [T, a, P, rho] = atmosisa(0);       % 288.15 K, 340 m/s
%      [T, a] = atmosisa(11000);           % 216.65 K, 295 m/s
%      atmosisa(11000) - atmosisa(15000)   % 0 : isotherme au-dessus
%
%   Voir aussi MACHNUMBER, DPRESSURE.
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
