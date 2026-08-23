function [a, e] = ac2poly(r)
%AC2POLY Polynôme de prédiction d'une suite d'autocorrélation.
%   [A,E] = AC2POLY(R) résout les équations de Yule-Walker par
%   Levinson-Durbin. E est la puissance de l'erreur de prédiction.
%
%   Exemple :
%      [a, e] = ac2poly([1 0.5 0.25]);   % a = [1 -0.5 0]
    r = double(r(:));
    p = numel(r) - 1;
    a = 1;
    e = r(1);
    for m = 1:p
        acc = r(m + 1);
        for i = 1:m-1
            acc = acc + a(i + 1) * r(m - i + 1);
        end
        if e == 0
            k = 0;
        else
            k = -acc / e;
        end
        a = [a 0] + k * [0 conj(fliplr(a))];
        e = e * (1 - abs(k) ^ 2);
    end
end
