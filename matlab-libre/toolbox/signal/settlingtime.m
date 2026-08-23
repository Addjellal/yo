function [duree, debut, fin] = settlingtime(x, fs, d)
%SETTLINGTIME Temps d'établissement après chaque transition.
%   S = SETTLINGTIME(X,FS,D) rend la durée entre la traversée médiane et
%   l'instant à partir duquel le signal reste dans une bande de D pour
%   cent de l'écart entre états autour du niveau atteint. D vaut 2 par
%   défaut.
    if nargin < 2 || isempty(fs), fs = 1; end
    if nargin < 3 || isempty(d), d = 2; end
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    [bas, haut] = signalNiveaux(x, 50);
    tolerance = (haut - bas) * d / 100;
    transitions = signalTransitions(x, t, 10, 90);
    duree = zeros(size(transitions, 1), 1);
    debut = transitions(:, 3);
    fin = zeros(size(transitions, 1), 1);
    for k = 1:size(transitions, 1)
        if transitions(k, 4) > 0
            cible = haut;
        else
            cible = bas;
        end
        if k < size(transitions, 1)
            borne = transitions(k + 1, 1);
        else
            borne = t(end);
        end
        plage = find(t >= transitions(k, 3) & t <= borne);
        etabli = numel(plage);
        for j = numel(plage):-1:1
            if abs(x(plage(j)) - cible) > tolerance
                break
            end
            etabli = j;
        end
        fin(k) = t(plage(etabli));
        duree(k) = fin(k) - debut(k);
    end
end
