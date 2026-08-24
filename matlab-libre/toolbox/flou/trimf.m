function y = trimf(x, p)
%TRIMF Fonction d'appartenance triangulaire.
%   Y = TRIMF(X,[A B C]) monte de zéro en A jusqu'à un en B, puis
%   redescend à zéro en C.
%
%   Les cas dégénérés comptent : quand A vaut B, la fonction saute à un en
%   A et l'appartenance y vaut un, pas zéro — c'est l'épaulement gauche
%   dont on se sert pour la modalité extrême d'une variable. De même quand
%   B vaut C, à droite.
%
%   Exemple :
%      trimf(0:10, [0 5 10])   % [0 .2 .4 .6 .8 1 .8 .6 .4 .2 0]
%      trimf(0:5, [0 0 5])     % [1 .8 .6 .4 .2 0]
%
%   Voir aussi TRAPMF, GAUSSMF, EVALMF.
    a = p(1); b = p(2); c = p(3);
    x = double(x);
    y = zeros(size(x));
    for k = 1:numel(x)
        v = x(k);
        if v == b
            y(k) = 1;
        elseif v <= a || v >= c
            y(k) = 0;
        elseif v < b
            y(k) = (v - a) / (b - a);
        else
            y(k) = (c - v) / (c - b);
        end
    end
end
