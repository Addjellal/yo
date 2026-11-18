function portee = radareqrng(lambda, SNR, Pt, tau, varargin)
%RADAREQRNG Portée maximale théorique, par l'équation du radar.
%   R = RADAREQRNG(LAMBDA,SNR,PT,TAU) rend la portée (m) à laquelle une
%   cible donne le rapport signal sur bruit SNR (dB), pour une longueur
%   d'onde LAMBDA (m), une puissance crête PT (W) et une durée d'impulsion
%   TAU (s) — la signature de MATLAB :
%
%      R = (Pt tau Gt Gr lambda^2 sigma / ((4 pi)^3 k Ts L SNR))^(1/4)
%
%   Options : 'RCS' (m^2, 1), 'Ts' (K, 290), 'Gain' (dB, 20, ou [Gt Gr]),
%   'Loss' (dB, 0), 'CustomFactor' (dB, 0), 'unitstr' ('m', 'km', 'mi',
%   'nmi') pour l'unité de la portée rendue.
%
%   La portée varie comme la racine quatrième de la puissance : doubler la
%   portée demande seize fois plus de puissance.
%
%   Exemple :
%      % Documentation de MATLAB.
%      lambda = physconst('LightSpeed') / 10e9;
%      radareqrng(lambda, 6, 1e6, 10e-6)              % 4.1057e+04 m
%
%   Voir aussi RADAREQPOW, RADAREQSNR, PHYSCONST.
    o = matlibre_radar_options(varargin, 'radareqrng', ...
        {'RCS', 'Ts', 'Gain', 'Loss', 'CustomFactor', 'unitstr'});
    matlibre_radar_cibles('radareqrng', o, SNR(:));
    portee = (Pt .* tau .* 10 .^ ((o.Gain(1) + o.Gain(2)) / 10) .* lambda .^ 2 .* o.RCS(:) ./ ...
              ((4 * pi) ^ 3 * physconst('Boltzmann') .* o.Ts .* ...
               10 .^ ((SNR(:) + o.Loss - o.CustomFactor(:)) / 10))) .^ 0.25;
    switch o.unitstr
        case 'km', portee = portee / 1000;
        case 'mi', portee = portee / 1609.344;
        case 'nmi', portee = portee / 1852;
    end
end
