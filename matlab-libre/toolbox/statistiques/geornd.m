function r = geornd(p, varargin)
%GEORND Tirages d'une loi géométrique.
%   R = GEORND(P,M,N) rend le nombre d'échecs avant le premier succès,
%   pour une probabilité de succès P.
%
%   Sa moyenne vaut (1-P)/P : à une chance sur dix, on attend neuf échecs
%   en moyenne. Sa variance est bien plus grande encore, ce qui rend
%   l'attente très irrégulière — c'est la loi sans mémoire.
%
%   Exemple :
%      r = geornd(0.5, 10000, 1);
%      abs(mean(r) - 1) < 0.1          % true : (1-0.5)/0.5 = 1
%
%   Voir aussi GEOCDF, GEOINV, NBINRND.
    forme = statForme(size(p), varargin);
    p = statEtendre(p, forme);
    r = geoinv(rand(forme), p);
    r(p <= 0 | p > 1) = NaN;
end
