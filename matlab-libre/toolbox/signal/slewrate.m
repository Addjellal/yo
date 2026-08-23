function [pente, debut, fin] = slewrate(x, fs, varargin)
%SLEWRATE Vitesse de balayage d'un signal à deux états.
%   S = SLEWRATE(X,FS) rend, pour chaque transition, la pente moyenne
%   entre les seuils bas et haut : l'écart d'amplitude divisé par la
%   durée. La pente est négative sur un front descendant.
%
%   Exemple :
%      slewrate([0 0 1 1], 1)   % 0.8/0.8 = 1 par seconde
    if nargin < 2 || isempty(fs), fs = 1; end
    pourcentages = [10 90];
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'PercentReferenceLevels')
            pourcentages = double(varargin{k + 1});
        end
    end
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    [bas, haut] = signalNiveaux(x, [pourcentages 50]);
    ecart = (haut - bas) * (pourcentages(2) - pourcentages(1)) / 100;
    transitions = signalTransitions(x, t, pourcentages(1), pourcentages(2));
    debut = transitions(:, 1);
    fin = transitions(:, 2);
    pente = transitions(:, 4) .* ecart ./ (fin - debut);
end
