function SNR = radareqsnr(lambda, portee, Pt, tau, varargin)
%RADAREQSNR Rapport signal sur bruit par l'équation du radar, en dB.
%   SNR = RADAREQSNR(LAMBDA,TGTRNG,PT,TAU) rend le rapport signal sur bruit
%   (dB) d'une cible à la portée TGTRNG (m), pour une longueur d'onde LAMBDA
%   (m), une puissance crête PT (W) et une durée d'impulsion TAU (s) :
%
%      SNR = Pt tau Gt Gr lambda^2 sigma / ((4 pi)^3 k Ts Rt^2 Rr^2 L)
%
%   TGTRNG est une portée (radar monostatique) ou [Rt Rr], les portées de
%   l'émetteur et du récepteur (bistatique), ou une colonne / une matrice
%   J x 2 de telles portées.
%   Options : 'RCS' (m^2, 1), 'Ts' (K, 290), 'Gain' (dB, 20, ou [Gt Gr]),
%   'Loss' (dB, 0), 'AtmosphericLoss' et 'PropagationFactor' (dB, 0 ; une
%   valeur vaut pour un trajet aller, et compte donc à l'aller et au
%   retour ; [aller retour] les distingue), 'CustomFactor' (dB, 0).
%   Pour J cibles, 'RCS', 'CustomFactor' et les pertes de trajet peuvent
%   avoir une valeur par cible ; SNR est alors une colonne de J valeurs.
%
%   Exemple :
%      % Documentation de MATLAB.
%      lambda = physconst('LightSpeed') / 1e9;
%      radareqsnr(lambda, 50e3, 1e6, 0.2e-6)        % 5.5868 dB
%
%   Voir aussi RADAREQPOW, RADAREQRNG, PHYSCONST.
    o = matlibre_radar_options(varargin, 'radareqsnr', ...
        {'RCS', 'Ts', 'Gain', 'Loss', 'AtmosphericLoss', 'PropagationFactor', 'CustomFactor'});
    [Rt, Rr] = matlibre_radar_portees(portee, 'radareqsnr');
    [~, pertes] = matlibre_radar_cibles('radareqsnr', o, Rt);
    rapport = Pt .* tau .* 10 .^ ((o.Gain(1) + o.Gain(2)) / 10) .* lambda .^ 2 .* o.RCS(:) ./ ...
              ((4 * pi) ^ 3 * physconst('Boltzmann') .* o.Ts .* Rt .^ 2 .* Rr .^ 2);
    SNR = 10 * log10(rapport) - o.Loss + o.CustomFactor(:) - pertes;
end
