function t = istall(x)
%ISTALL Dit si une valeur est un tableau différé.
%   T = ISTALL(X) rend vrai si X est un tableau dont le calcul est
%   différé, celui que rend TALL.
%
%   Exemple :
%      istall(tall([1 2 3]))           % 1
%      istall([1 2 3])                 % 0
%      istall(gather(tall(7)))         % 0 : rassemblé, il est ordinaire
%
%   Voir aussi TALL, GATHER.
    if nargin < 1
        error('MATLAB:minrhs', 'ISTALL attend une valeur.');
    end
    t = isa(x, 'tall');
end
