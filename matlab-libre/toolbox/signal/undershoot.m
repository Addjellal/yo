function [pourcentage, valeur, instant] = undershoot(x, fs)
%UNDERSHOOT Creux avant chaque transition, en pourcentage.
%   Symétrique d'OVERSHOOT : l'extremum est cherché avant la transition,
%   du côté opposé au niveau de départ.
%
%   Exemple :
%      t = (0:0.001:0.2)';
%      [p, v, instant] = undershoot(exp(-30*t) .* sin(2*pi*30*t) + double(t > 0), 1000);
%      p >= 0                      % 1
%
%   Voir aussi OVERSHOOT, SETTLINGTIME, FALLTIME.
    if nargin < 2 || isempty(fs), fs = 1; end
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    [bas, haut] = signalNiveaux(x, 50);
    transitions = signalTransitions(x, t, 10, 90);
    pourcentage = zeros(size(transitions, 1), 1);
    valeur = zeros(size(transitions, 1), 1);
    instant = zeros(size(transitions, 1), 1);
    for k = 1:size(transitions, 1)
        if k == 1
            debut = t(1);
        else
            debut = transitions(k - 1, 2);
        end
        fin = transitions(k, 1);
        plage = t >= debut & t <= fin;
        if ~any(plage)
            continue
        end
        segment = x(plage);
        temps = t(plage);
        if transitions(k, 4) > 0
            [extremum, indice] = min(segment);
            pourcentage(k) = 100 * (bas - extremum) / (haut - bas);
        else
            [extremum, indice] = max(segment);
            pourcentage(k) = 100 * (extremum - haut) / (haut - bas);
        end
        valeur(k) = extremum;
        instant(k) = temps(indice);
    end
    pourcentage = max(pourcentage, 0);
end
