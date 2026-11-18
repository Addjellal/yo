function [J, pertes] = matlibre_radar_cibles(fonction, o, varargin)
%MATLIBRE_RADAR_CIBLES Nombre de cibles J et pertes de trajet aller et retour.
%   [J,PERTES] = MATLIBRE_RADAR_CIBLES(FONCTION,O,A,B,...) vérifie que les
%   grandeurs par cible (A, B... et les options RCS, CustomFactor,
%   AtmosphericLoss, PropagationFactor de O) ont une valeur, ou J. PERTES
%   est la somme, en dB, des pertes atmosphériques moins les facteurs de
%   propagation, sur les deux trajets : une valeur scalaire ou une colonne
%   vaut pour un trajet aller, et compte donc à l'aller et au retour ; deux
%   colonnes donnent l'aller puis le retour, comme MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = matlibre_radar_options({'AtmosphericLoss', 1}, 'radareqsnr', {'AtmosphericLoss'});
%      [J, pertes] = matlibre_radar_cibles('radareqsnr', o, 50e3)   % 1, 2 dB
%
%   Voir aussi RADAREQPOW, RADAREQSNR, RADAREQRNG.
    atmosphere = deuxTrajets(o.AtmosphericLoss, fonction, 'AtmosphericLoss');
    propagation = deuxTrajets(o.PropagationFactor, fonction, 'PropagationFactor');
    tailles = [cellfun(@numel, varargin), numel(o.RCS), numel(o.CustomFactor), ...
               size(atmosphere, 1), size(propagation, 1)];
    J = max(tailles);
    if any(tailles ~= 1 & tailles ~= J)
        error(['phased:' fonction ':Cibles'], ...
              'Les grandeurs par cible ont une valeur, ou une par cible (%d).', J);
    end
    pertes = sum(atmosphere, 2) - sum(propagation, 2);
end

function v = deuxTrajets(v, fonction, nom)
    if size(v, 2) == 1
        v = [v(:), v(:)];
    elseif size(v, 2) ~= 2
        error(['phased:' fonction ':' nom], ...
              '%s est un scalaire, une colonne, [aller retour] ou une matrice J x 2, en dB.', nom);
    end
end
