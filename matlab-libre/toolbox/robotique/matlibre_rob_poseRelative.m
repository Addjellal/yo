function T = matlibre_rob_poseRelative(robot, config, corps, reference)
%MATLIBRE_ROB_POSERELATIVE Pose d'un corps dans un repère de référence.
%   Une référence vide vaut le repère de base : c'est la convention des
%   objets de contrainte, dont la propriété ReferenceBody est vide par
%   défaut.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 4 || isempty(reference)
        reference = robot.BaseName;
    end
    T = getTransform(robot, config, char(corps), char(reference));
end
