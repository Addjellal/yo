function [vitesseAngulaire, indiceCible] = purePursuit(pose, chemin, distanceVisee, vitesse)
%PUREPURSUIT Loi de poursuite pure pour suivre un chemin.
%   POSE vaut [x y theta]. Rend la vitesse angulaire à appliquer.
    if nargin < 4
        vitesse = 1;
    end
    distances = sqrt((chemin(:,1) - pose(1)) .^ 2 + (chemin(:,2) - pose(2)) .^ 2);
    candidats = find(distances >= distanceVisee);
    if isempty(candidats)
        indiceCible = numel(distances);
    else
        indiceCible = candidats(1);
    end
    cible = chemin(indiceCible, :);
    dx = cible(1) - pose(1);
    dy = cible(2) - pose(2);
    angle = atan2(dy, dx) - pose(3);
    L = sqrt(dx^2 + dy^2);
    if L < 1e-9
        vitesseAngulaire = 0;
    else
        vitesseAngulaire = 2 * vitesse * sin(angle) / L;
    end
end
