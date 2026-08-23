function [duree, debut, fin] = falltime(x, fs, varargin)
%FALLTIME Temps de descente d'un signal à deux états.
%   Symétrique de RISETIME : de 90 % à 10 % sur chaque front descendant.
    if nargin < 2 || isempty(fs), fs = 1; end
    pourcentages = [10 90];
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'PercentReferenceLevels')
            pourcentages = double(varargin{k + 1});
        end
    end
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    transitions = signalTransitions(x, t, pourcentages(1), pourcentages(2));
    descendantes = transitions(transitions(:, 4) < 0, :);
    debut = descendantes(:, 1);
    fin = descendantes(:, 2);
    duree = fin - debut;
end
