function [q, qd, qdd, pp] = cubicpolytraj(points, instants, echantillons, varargin)
%CUBICPOLYTRAJ Trajectoire polynomiale cubique passant par des points.
%   [Q,QD,QDD] = CUBICPOLYTRAJ(POINTS,INSTANTS,ECHANTILLONS) fait passer
%   une cubique par chaque segment entre points successifs, et l'évalue
%   aux instants demandés. POINTS a une ligne par degré de liberté et une
%   colonne par point de passage.
%
%   [...] = CUBICPOLYTRAJ(...,'VelocityBoundaryCondition',V) impose les
%   vitesses aux points de passage ; elles sont nulles par défaut.
%
%   [Q,QD,QDD,PP] = CUBICPOLYTRAJ(...) rend aussi la forme par morceaux.
%
%   Une cubique est le polynôme de plus bas degré qui satisfasse quatre
%   conditions : position et vitesse à chaque bout. C'est exactement ce
%   qu'il faut pour raccorder deux points sans saut de vitesse — mais
%   l'accélération, elle, saute encore aux points de passage. Quand cela
%   gêne, QUINTICPOLYTRAJ ajoute les deux conditions qui manquent.
%
%   Exemple :
%      [q, qd] = cubicpolytraj([0 1 2; 0 2 0], [0 1 2], linspace(0, 2, 50));
%      qd(:, 1)                        % nulle au depart
%
%   Voir aussi QUINTICPOLYTRAJ, TRAPVELTRAJ, BSPLINEPOLYTRAJ.
    [q, qd, qdd, pp] = matlibre_rob_polytraj(points, instants, echantillons, ...
                                             3, varargin);
end
