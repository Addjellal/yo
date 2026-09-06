function r = raylrnd(b, varargin)
%RAYLRND Tirages d'une loi de Rayleigh.
%   R = RAYLRND(B,M,N) rend le module d'un vecteur gaussien à deux
%   dimensions d'écart type B.
%
%   Sa moyenne vaut B racine de pi/2, sa médiane B racine de 2 ln 2 : deux
%   repères qui vérifient un tirage en deux lignes.
%
%   Exemple :
%      r = raylrnd(1, 20000, 1);
%      abs(mean(r) - sqrt(pi/2)) < 0.02        % true
%
%   Voir aussi RAYLCDF, RAYLINV, RANDN.
    if nargin < 1, b = 1; end
    forme = statForme(size(b), varargin);
    b = statEtendre(b, forme);
    r = b .* sqrt(-2 * log(rand(forme)));
    r(b <= 0) = NaN;
end
