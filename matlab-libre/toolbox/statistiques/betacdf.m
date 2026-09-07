function p = betacdf(x, a, b)
%BETACDF Fonction de répartition de la loi bêta.
%   C'est la fonction bêta incomplète régularisée.
%
%   Exemple :
%      betacdf(0.5, 2, 2)          % 0.5 : la loi est symetrique pour a = b
    x = double(x);
    p = zeros(size(x));
    p(x >= 1) = 1;
    dedans = x > 0 & x < 1;
    p(dedans) = betainc(x(dedans), a, b);
end
