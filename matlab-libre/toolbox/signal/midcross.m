function [instants, niveauMilieu] = midcross(x, fs)
%MIDCROSS Instants de traversée du niveau médian.
%   [C,NIVEAU] = MIDCROSS(X,FS) rend les instants où le signal coupe le
%   niveau à mi-chemin entre ses deux états, et ce niveau.
%
%   Exemple :
%      midcross([0 0 1 1], 1)   % 1.5 : la moitié est franchie là
    if nargin < 2 || isempty(fs), fs = 1; end
    x = double(x(:));
    t = (0:numel(x) - 1)' / fs;
    [~, ~, niveauMilieu] = signalNiveaux(x, 50);
    instants = signalTraverses(x, t, niveauMilieu);
end
