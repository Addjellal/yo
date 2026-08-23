function [rapport, debut, fin] = dutycycle(x, fs, varargin)
%DUTYCYCLE Rapport cyclique des impulsions.
%   D = DUTYCYCLE(X,FS) rend, pour chaque période, la largeur de
%   l'impulsion divisée par la période.
%
%   Exemple :
%      dutycycle([0 1 1 0 0 1 1 0 0 1], 1)   % environ 0.5
    if nargin < 2 || isempty(fs), fs = 1; end
    largeurs = pulsewidth(x, fs, varargin{:});
    [periodes, debut, fin] = pulseperiod(x, fs, varargin{:});
    n = min(numel(largeurs), numel(periodes));
    rapport = largeurs(1:n) ./ periodes(1:n);
    debut = debut(1:n);
    fin = fin(1:n);
end
