function r = chi2rnd(v, varargin)
%CHI2RND Tirages d'un khi-deux à V degrés de liberté.
%   Le khi-deux à V degrés est une gamma de forme V/2 et d'échelle 2.
%
%   Exemple :
%      rng(1);
%      mean(chi2rnd(4, 1, 10000))           % proche de 4 : la moyenne est nu
    forme = statForme(size(v), varargin);
    v = statEtendre(v, forme);
    r = gamrnd(v / 2, 2 * ones(forme));
end
