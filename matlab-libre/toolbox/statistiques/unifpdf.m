function y = unifpdf(x, a, b)
%UNIFPDF Densité de la loi uniforme continue sur [A,B].
%   Y = UNIFPDF(X,A,B) vaut 1/(B-A) dans l'intervalle, zéro dehors.
%
%   La densité peut dépasser un : c'est une densité, non une probabilité.
%   Sur [0, 0.1] elle vaut dix, et son intégrale vaut bien un.
%
%   Exemple :
%      unifpdf(0.5, 0, 0.1)            % 0 : hors de l'intervalle
%
%   Voir aussi UNIFCDF, UNIFINV, RAND.
    if nargin < 2, a = 0; end
    if nargin < 3, b = 1; end
    y = zeros(size(x));
    y(x >= a & x <= b) = 1 / (b - a);
end
