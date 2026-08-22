function [x, y, coude] = fkine2R(q, l1, l2)
%FKINE2R Cinématique directe d'un bras plan à deux segments.
%   [X,Y] = FKINE2R([Q1 Q2],L1,L2) rend la position de l'effecteur.
    if nargin < 2, l1 = 1; end
    if nargin < 3, l2 = 1; end
    coude = [l1 * cos(q(1)), l1 * sin(q(1))];
    x = coude(1) + l2 * cos(q(1) + q(2));
    y = coude(2) + l2 * sin(q(1) + q(2));
end
