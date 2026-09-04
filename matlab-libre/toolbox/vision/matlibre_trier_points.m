function [positions, a, b, c] = matlibre_trier_points(positions, a, b, c)
%MATLIBRE_TRIER_POINTS Range des points d'intérêt du plus fort au plus faible.
%   [P,A,B,C] = MATLIBRE_TRIER_POINTS(P,A,B,C) trie les lignes par valeur
%   décroissante de A — la métrique — et réordonne les autres colonnes de
%   la même façon.
%
%   Exemple :
%      [p, m] = matlibre_trier_points([1 1; 2 2], [3; 7], [], []);
%      m(1)    % 7
%
%   Voir aussi DETECTSURFFEATURES, DETECTBRISKFEATURES, SELECTSTRONGEST.
    if isempty(positions)
        return
    end
    [a, ordre] = sort(a, 'descend');
    positions = positions(ordre, :);
    if ~isempty(b)
        b = b(ordre);
    end
    if nargin > 3 && ~isempty(c)
        c = c(ordre);
    end
end
