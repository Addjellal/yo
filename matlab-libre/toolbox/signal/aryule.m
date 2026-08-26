function [a, e, k] = aryule(x, p)
%ARYULE Modèle autorégressif par les équations de Yule-Walker.
%   [A,E,K] = ARYULE(X,P) estime un modèle d'ordre P à partir de
%   l'autocorrélation biaisée du signal, résolue par Levinson-Durbin. E
%   est la variance de l'erreur de prédiction, K les coefficients de
%   réflexion.
%
%   Exemple :
%      a = aryule(filter(1, [1 -0.9], randn(1000,1)), 1);
    x = double(x(:));
    n = numel(x);
    r = zeros(p + 1, 1);
    for m = 0:p
        r(m + 1) = sum(x(1:n-m) .* conj(x(1+m:n))) / n;   % estimation biaisée
    end
    [a, e] = ac2poly(r);
    if nargout > 2
        k = poly2rc(a);
    end
end
