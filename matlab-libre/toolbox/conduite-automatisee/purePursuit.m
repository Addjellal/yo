function [vitesseAngulaire, indiceCible] = purePursuit(pose, chemin, distanceVisee, vitesse)
%PUREPURSUIT Loi de poursuite pure pour suivre un chemin.
%   OMEGA = PUREPURSUIT(POSE,CHEMIN,DISTANCEVISEE,VITESSE) rend la vitesse
%   angulaire à appliquer. POSE vaut [X Y THETA], CHEMIN une liste de
%   points en lignes, DISTANCEVISEE la distance à laquelle regarder
%   devant, VITESSE la vitesse d'avance — un par défaut.
%
%   [OMEGA,INDICE] = PUREPURSUIT(...) rend aussi l'indice du point visé.
%
%   Le principe tient en une phrase : viser un point du chemin situé à
%   DISTANCEVISEE devant soi, et décrire l'arc de cercle qui y mène. Cet
%   arc a pour courbure 2 sin(alpha) / L, où alpha est l'angle entre le
%   cap et la direction du point visé, d'où
%
%      omega = 2 V sin(alpha) / L
%
%   Le point visé se cherche en avançant depuis le point du chemin le plus
%   proche, jamais depuis le début : passé la distance de visée, le début
%   du chemin est lui aussi assez loin, et le viser ferait faire demi-tour
%   au véhicule.
%
%   DISTANCEVISEE est le seul réglage. Court, le suivi est nerveux et
%   oscille ; long, il coupe les virages. Il se choisit en général
%   proportionnel à la vitesse.
%
%   Exemple :
%      chemin = [linspace(0, 50, 501).', zeros(501, 1)];
%      purePursuit([0 1 0], chemin, 5, 5)   % decale a gauche : omega < 0
%      purePursuit([0 0 0], chemin, 5, 5)   % sur le chemin : omega = 0
%
%   Voir aussi SMOOTHPATH, LANEOFFSET, BICYCLEMODEL.
    if nargin < 4
        vitesse = 1;
    end
    distances = sqrt((chemin(:,1) - pose(1)) .^ 2 + (chemin(:,2) - pose(2)) .^ 2);
    % Le point le plus proche fixe l'avancement le long du chemin ; la
    % recherche du point visé part de là et ne remonte jamais en arrière.
    [~, plusProche] = min(distances);
    candidats = find(distances(plusProche:end) >= distanceVisee, 1);
    if isempty(candidats)
        indiceCible = numel(distances);
    else
        indiceCible = plusProche + candidats - 1;
    end
    cible = chemin(indiceCible, :);
    dx = cible(1) - pose(1);
    dy = cible(2) - pose(2);
    alpha = atan2(dy, dx) - pose(3);
    L = sqrt(dx^2 + dy^2);
    if L < 1e-9
        vitesseAngulaire = 0;
    else
        vitesseAngulaire = 2 * vitesse * sin(alpha) / L;
    end
end
