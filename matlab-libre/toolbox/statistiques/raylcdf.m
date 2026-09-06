function p = raylcdf(x, b)
%RAYLCDF Répartition de la loi de Rayleigh.
%   P = RAYLCDF(X,B) rend 1 - exp(-X^2/(2 B^2)).
%
%   C'est la loi du module d'un vecteur gaussien à deux dimensions
%   centré : d'où son omniprésence en radio, où l'amplitude d'un signal
%   somme de nombreux trajets la suit exactement.
%
%   Sa médiane vaut B racine de 2 ln 2, et sa moyenne B racine de pi/2.
%
%   Exemple :
%      raylcdf(1, 1)                   % 1 - exp(-0.5)
%
%   Voir aussi RAYLPDF, RAYLINV, RAYLRND, RAYLEIGHCHANNEL.
    if nargin < 2, b = 1; end
    p = zeros(size(x));
    positif = x >= 0;
    p(positif) = 1 - exp(-x(positif).^2 ./ (2 * b.^2));
end
