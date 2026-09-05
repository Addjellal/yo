function [q, qd, qdd, pp] = quinticpolytraj(points, instants, echantillons, varargin)
%QUINTICPOLYTRAJ Trajectoire polynomiale de degré cinq.
%   [Q,QD,QDD] = QUINTICPOLYTRAJ(POINTS,INSTANTS,ECHANTILLONS) fait
%   passer une quintique par chaque segment, en imposant position,
%   vitesse et accélération à chaque bout.
%
%   [...] = QUINTICPOLYTRAJ(...,'VelocityBoundaryCondition',V) et
%   'AccelerationBoundaryCondition',A imposent ces conditions ; elles
%   sont nulles par défaut.
%
%   Six conditions par segment demandent six coefficients, donc le degré
%   cinq. Ce que cela achète sur la cubique : une accélération continue
%   d'un segment à l'autre, donc un effort continu sur les actionneurs.
%
%   Exemple :
%      [q, qd, qdd] = quinticpolytraj([0 1; 0 1], [0 1], linspace(0, 1, 30));
%      qdd(:, 1)                       % nulle au depart, contrairement a la cubique
%
%   Voir aussi CUBICPOLYTRAJ, TRAPVELTRAJ, BSPLINEPOLYTRAJ.
    [q, qd, qdd, pp] = matlibre_rob_polytraj(points, instants, echantillons, ...
                                             5, varargin);
end
