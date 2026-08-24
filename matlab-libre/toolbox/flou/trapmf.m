function y = trapmf(x, p)
%TRAPMF Fonction d'appartenance trapézoïdale.
%   Y = TRAPMF(X,[A B C D]) monte de zéro en A jusqu'à un en B, reste à
%   un jusqu'à C, puis redescend à zéro en D.
%
%   Comme pour TRIMF, les côtés de largeur nulle valent un sur le plateau :
%   TRAPMF(X,[0 0 3 5]) est un épaulement gauche, qui vaut un en zéro.
%
%   Exemple :
%      trapmf(0:6, [1 2 4 5])   % [0 0 1 1 1 0 0]
%      trapmf(0:5, [0 0 2 4])   % [1 1 1 0.5 0 0]
%
%   Voir aussi TRIMF, PIMF, EVALMF.
    a = p(1); b = p(2); c = p(3); d = p(4);
    x = double(x);
    y = zeros(size(x));
    for k = 1:numel(x)
        v = x(k);
        if v >= b && v <= c
            y(k) = 1;
        elseif v <= a || v >= d
            y(k) = 0;
        elseif v < b
            y(k) = (v - a) / (b - a);
        else
            y(k) = (d - v) / (d - c);
        end
    end
end
