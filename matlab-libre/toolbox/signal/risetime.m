function [duree, debut, fin] = risetime(x, fs, varargin)
%RISETIME Temps de montée d'un signal à deux états.
%   R = RISETIME(X,FS) rend, pour chaque front montant, la durée entre le
%   passage à 10 % et le passage à 90 % de l'écart entre les deux états.
%
%   RISETIME(...,'PercentReferenceLevels',[BAS HAUT]) change les seuils.
%
%   Exemple :
%      risetime([0 0 0.5 1 1], 1)   % 0.8 : de 10 % à 90 %
    if nargin < 2 || isempty(fs), fs = 1; end
    pourcentages = lireSeuils(varargin, [10 90]);
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    transitions = signalTransitions(x, t, pourcentages(1), pourcentages(2));
    montantes = transitions(transitions(:, 4) > 0, :);
    debut = montantes(:, 1);
    fin = montantes(:, 2);
    duree = fin - debut;
end

function p = lireSeuils(arguments, defaut)
    p = defaut;
    for k = 1:2:numel(arguments) - 1
        if strcmpi(char(arguments{k}), 'PercentReferenceLevels')
            p = double(arguments{k + 1});
        end
    end
end
