function [Rt, Rr] = matlibre_radar_portees(portee, fonction)
%MATLIBRE_RADAR_PORTEES Portées d'émission et de réception d'un radar.
%   Une portée (monostatique), [Rt Rr] (bistatique), une colonne de J
%   portées ou une matrice J x 2.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [Rt, Rr] = matlibre_radar_portees([50e3 75e3], 'radareqpow')
%
%   Voir aussi RADAREQPOW, RADAREQSNR.
    portee = double(portee);
    if any(portee(:) <= 0)
        error(['phased:' fonction ':Portee'], 'Ranges must be positive.');
    end
    if size(portee, 2) == 2
        Rt = portee(:, 1);
        Rr = portee(:, 2);
    elseif isvector(portee)
        Rt = portee(:);
        Rr = portee(:);
    else
        error(['phased:' fonction ':Portee'], ...
              'Range must be a scalar, [Rt Rr], a column or a J-by-2 matrix.');
    end
end
