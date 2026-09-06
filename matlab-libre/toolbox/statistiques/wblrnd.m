function r = wblrnd(a, b, varargin)
%WBLRND Tirages d'une loi de Weibull.
%   R = WBLRND(A,B,M,N) rend A * (-log(U))^(1/B) pour U uniforme : le
%   tirage se fait par inversion, exactement.
%
%   Exemple :
%      r = wblrnd(1, 1, 10000, 1);
%      abs(mean(r) - 1) < 0.05         % true : c'est l'exponentielle
%
%   Voir aussi WBLCDF, WBLINV, EXPRND.
    if nargin < 1, a = 1; end
    if nargin < 2, b = 1; end
    forme = statForme(size(a + b), varargin);
    a = statEtendre(a, forme);
    b = statEtendre(b, forme);
    r = a .* (-log(rand(forme))) .^ (1 ./ b);
    r(a <= 0 | b <= 0) = NaN;
end
