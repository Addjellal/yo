function [a, e] = levinson(r, p)
%LEVINSON Récursion de Levinson-Durbin.
%   [A,E] = LEVINSON(R,P) résout les équations de Yule-Walker pour la
%   suite d'autocorrélation R et l'ordre P. A(1) vaut toujours 1 et E est
%   la puissance de l'erreur de prédiction.
    r = r(:).';
    if nargin < 2
        p = numel(r) - 1;
    end
    a = zeros(1, p + 1);
    a(1) = 1;
    e = r(1);
    if e == 0
        return;
    end
    for m = 1:p
        acc = r(m + 1);
        for k = 2:m
            acc = acc + a(k) * r(m - k + 2);
        end
        reflexion = -acc / e;
        precedent = a;
        for k = 2:m
            a(k) = precedent(k) + reflexion * precedent(m - k + 2);
        end
        a(m + 1) = reflexion;
        e = e * (1 - reflexion ^ 2);
        if e <= 0
            e = eps;
            break;
        end
    end
end
