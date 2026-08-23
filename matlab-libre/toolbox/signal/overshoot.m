function [pourcentage, valeur, instant] = overshoot(x, fs)
%OVERSHOOT Dépassement après chaque transition, en pourcentage.
%   Le dépassement est mesuré entre le niveau d'état atteint et
%   l'extremum observé après la transition, rapporté à l'écart entre les
%   deux états. Il vaut zéro si le signal ne dépasse pas.
%
%   Exemple :
%      overshoot([0 0 1.2 1 1 1], 1)   % 20 %
    if nargin < 2 || isempty(fs), fs = 1; end
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    [bas, haut] = signalNiveaux(x, 50);
    transitions = signalTransitions(x, t, 10, 90);
    pourcentage = zeros(size(transitions, 1), 1);
    valeur = zeros(size(transitions, 1), 1);
    instant = zeros(size(transitions, 1), 1);
    for k = 1:size(transitions, 1)
        [debutRegion, finRegion] = regionApres(transitions, k, t);
        plage = t >= debutRegion & t <= finRegion;
        if ~any(plage)
            continue
        end
        segment = x(plage);
        temps = t(plage);
        if transitions(k, 4) > 0
            [extremum, indice] = max(segment);
            pourcentage(k) = 100 * (extremum - haut) / (haut - bas);
        else
            [extremum, indice] = min(segment);
            pourcentage(k) = 100 * (bas - extremum) / (haut - bas);
        end
        valeur(k) = extremum;
        instant(k) = temps(indice);
    end
    pourcentage = max(pourcentage, 0);
end

function [debut, fin] = regionApres(transitions, k, t)
    debut = transitions(k, 2);
    if k < size(transitions, 1)
        fin = transitions(k + 1, 1);
    else
        fin = t(end);
    end
end
