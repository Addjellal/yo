function [separation, debut, fin] = pulsesep(x, fs, varargin)
%PULSESEP Séparation entre impulsions.
%   S = PULSESEP(X,FS) rend l'écart entre la fin d'une impulsion et le
%   début de la suivante, mesuré au niveau médian.
    if nargin < 2 || isempty(fs), fs = 1; end
    positive = true;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'Polarity')
            positive = ~strcmpi(char(varargin{k + 1}), 'negative');
        end
    end
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    [~, ~, milieu] = signalNiveaux(x, 50);
    [instants, montantes] = signalTraverses(x, t, milieu);
    debut = [];
    fin = [];
    for k = 1:numel(instants) - 1
        if montantes(k) ~= positive && montantes(k + 1) == positive
            debut(end + 1, 1) = instants(k);      %#ok<AGROW>
            fin(end + 1, 1) = instants(k + 1);    %#ok<AGROW>
        end
    end
    separation = fin - debut;
end
