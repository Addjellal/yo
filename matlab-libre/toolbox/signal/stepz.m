function [h, t] = stepz(b, a, n, fs)
%STEPZ Réponse indicielle d'un filtre numérique.
%   [H,T] = STEPZ(B,A,N) : la réponse à un échelon unité.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      [h, t] = stepz(b, a, 100);
%      abs(h(end) - 1) < 0.01      % la reponse indicielle tend vers le gain continu
    if nargin < 2 || isempty(a), a = 1; end
    if nargin < 3 || isempty(n)
        [~, ti] = impz(b, a);
        n = numel(ti);
    end
    h = filter(b, a, ones(n, 1));
    t = (0:n-1)';
    if nargin >= 4 && ~isempty(fs), t = t / fs; end
end
