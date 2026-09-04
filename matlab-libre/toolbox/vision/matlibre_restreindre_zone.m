function [positions, a, b, c] = matlibre_restreindre_zone(zone, positions, a, b, c)
%MATLIBRE_RESTREINDRE_ZONE Ne garde que les points d'un rectangle.
%   [P,A,B,C] = MATLIBRE_RESTREINDRE_ZONE(ZONE,P,A,B,C) où ZONE vaut
%   [x y largeur hauteur]. Une zone vide laisse tout passer.
%
%   Exemple :
%      p = matlibre_restreindre_zone([1 1 5 5], [3 3; 9 9], [1; 2], [], []);
%      size(p, 1)    % 1
%
%   Voir aussi DETECTSURFFEATURES, DETECTBRISKFEATURES, DETECTORBFEATURES.
    if isempty(zone) || isempty(positions)
        return
    end
    dedans = positions(:, 1) >= zone(1) & ...
             positions(:, 1) <= zone(1) + zone(3) - 1 & ...
             positions(:, 2) >= zone(2) & ...
             positions(:, 2) <= zone(2) + zone(4) - 1;
    positions = positions(dedans, :);
    a = a(dedans);
    if ~isempty(b)
        b = b(dedans);
    end
    if nargin > 4 && ~isempty(c)
        c = c(dedans);
    end
end
