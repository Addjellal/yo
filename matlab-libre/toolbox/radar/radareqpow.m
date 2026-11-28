function Pt = radareqpow(lambda, portee, SNR, tau, varargin)
%RADAREQPOW Puissance crête nécessaire, par l'équation du radar.
%   PT = RADAREQPOW(LAMBDA,TGTRNG,SNR,TAU) rend la puissance crête (W) qui
%   donne le rapport signal sur bruit SNR (dB) sur une cible à la portée
%   TGTRNG (m), pour une longueur d'onde LAMBDA (m) et une durée
%   d'impulsion TAU (s) — la signature de MATLAB :
%
%      Pt = SNR (4 pi)^3 k Ts Rt^2 Rr^2 L / (tau Gt Gr lambda^2 sigma)
%
%   TGTRNG est une portée, ou [Rt Rr] pour un radar bistatique ; une
%   colonne de J portées, ou une matrice J x 2, décrit J cibles, et SNR,
%   'RCS', 'CustomFactor', 'AtmosphericLoss' et 'PropagationFactor'
%   peuvent alors avoir une valeur par cible : PT est une colonne de J
%   puissances.
%   Options : 'RCS' (m^2, 1), 'Ts' (K, 290), 'Gain' (dB, 20, ou [Gt Gr]),
%   'Loss' (dB, 0), 'CustomFactor' (dB, 0), 'AtmosphericLoss' et
%   'PropagationFactor' (dB, 0 ; une valeur vaut pour un trajet aller, et
%   compte à l'aller et au retour ; [aller retour] les distingue).
%
%   Exemple :
%      % Documentation de MATLAB.
%      lambda = physconst('LightSpeed') / 1e9;
%      radareqpow(lambda, 50e3, 6, 1e-6)              % 2.1996e+05 W
%
%   Voir aussi RADAREQRNG, RADAREQSNR, PHYSCONST.
    o = matlibre_radar_options(varargin, 'radareqpow', ...
        {'RCS', 'Ts', 'Gain', 'Loss', 'CustomFactor', 'AtmosphericLoss', 'PropagationFactor'});
    [Rt, Rr] = matlibre_radar_portees(portee, 'radareqpow');
    [~, pertes] = matlibre_radar_cibles('radareqpow', o, Rt, SNR(:));
    Pt = 10 .^ ((SNR(:) + o.Loss - o.CustomFactor(:) + pertes) / 10) .* (4 * pi) ^ 3 .* ...
         physconst('Boltzmann') .* o.Ts .* Rt .^ 2 .* Rr .^ 2 ./ ...
         (tau .* 10 .^ ((o.Gain(1) + o.Gain(2)) / 10) .* lambda .^ 2 .* o.RCS(:));
end
