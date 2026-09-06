function x = unifinv(p, a, b)
%UNIFINV Quantile de la loi uniforme continue sur [A,B].
%   X = UNIFINV(P,A,B) rend A + P (B - A).
%
%   C'est la réciproque exacte d'UNIFCDF, et la plus simple illustration de
%   la méthode d'inversion : appliquer la fonction quantile à un tirage
%   uniforme donne la loi voulue.
%
%   Exemple :
%      unifinv(0.25, 0, 4)             % 1
%
%   Voir aussi UNIFCDF, UNIFPDF, RAND.
    if nargin < 2, a = 0; end
    if nargin < 3, b = 1; end
    [p, a, b] = statAjuster(p, a, b);
    x = a + p .* (b - a);
    x(p < 0 | p > 1 | a > b) = NaN;
end
