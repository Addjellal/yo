function r = exprnd(mu, varargin)
%EXPRND Tirages d'une loi exponentielle de moyenne MU.
%   EXPRND(MU), EXPRND(MU,M), EXPRND(MU,M,N), EXPRND(MU,[M N]).
    if nargin < 1, mu = 1; end
    forme = statForme(size(mu), varargin);
    mu = statEtendre(mu, forme);
    % La transformation inverse : -mu log(u) suit la loi exponentielle.
    r = -mu .* log(rand(forme));
    r(mu <= 0) = NaN;
end
