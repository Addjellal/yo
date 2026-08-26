function y = rectpuls(t, w)
%RECTPULS Impulsion rectangulaire de largeur W centrée en zéro.
%   L'impulsion vaut 1 sur [-W/2, W/2[ et 0 ailleurs ; W vaut 1 par défaut.
%
%   Exemple :  rectpuls([-1 -0.4 0 0.4 1])   % [0 1 1 1 0]
    if nargin < 2, w = 1; end
    t = double(t);
    y = double(t >= -w / 2 & t < w / 2);
end
