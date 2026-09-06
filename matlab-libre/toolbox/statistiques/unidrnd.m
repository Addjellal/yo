function r = unidrnd(n, varargin)
%UNIDRND Tirages d'une loi uniforme discrète sur 1..N.
%   R = UNIDRND(N) tire un entier au hasard, uniformément dans 1..N.
%   R = UNIDRND(N,M) rend une matrice M par M de tirages, et
%   R = UNIDRND(N,M,K) une matrice M par K ; N peut aussi être un tableau,
%   auquel cas chaque tirage suit sa propre borne.
%
%   Le tirage se fait par CEIL(N.*RAND) : RAND vivant dans [0,1[, le
%   produit couvre [0,N[ et le plafond donne 1..N avec des probabilités
%   égales. La borne inférieure est ramenée à un pour le cas, de
%   probabilité nulle mais non impossible, où RAND rend exactement zéro.
%
%   Un N non entier ou inférieur à un rend NaN : la loi n'est pas définie
%   sur un support vide ou fractionnaire.
%
%   C'est la loi du dé, et la brique du tirage avec remise : RANDSAMPLE
%   avec remise et RANDPERM en dérivent, le second en tirant sans remise.
%
%   Exemple :
%      rng(1);
%      r = unidrnd(6, 1, 5);
%
%   Voir aussi UNIDCDF, UNIDINV, RANDI, RANDPERM, RANDSAMPLE.
    forme = statForme(size(n), varargin);
    n = statEtendre(n, forme);
    r = ceil(n .* rand(forme));
    r(r < 1) = 1;
    r(n < 1 | n ~= round(n)) = NaN;
end
