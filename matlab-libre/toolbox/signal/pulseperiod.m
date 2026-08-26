function [periode, debut, fin] = pulseperiod(x, fs, varargin)
%PULSEPERIOD Période des impulsions.
%   P = PULSEPERIOD(X,FS) rend l'écart entre deux fronts montants
%   consécutifs, mesuré au niveau médian.
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
    retenus = instants(montantes == positive);
    debut = retenus(1:end-1);
    fin = retenus(2:end);
    periode = fin - debut;
end
