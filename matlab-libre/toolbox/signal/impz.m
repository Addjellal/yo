function [h, t] = impz(b, a, n, fs)
%IMPZ Réponse impulsionnelle d'un filtre numérique.
%   [H,T] = IMPZ(B,A,N) rend les N premiers points de la réponse à une
%   impulsion unité. Sans N, la longueur est choisie assez grande pour que
%   la réponse soit retombée.
%
%   Exemple :
%      impz(1, [1 -0.5], 4)'   % [1 0.5 0.25 0.125]
    if nargin < 2 || isempty(a), a = 1; end
    if nargin < 3 || isempty(n)
        if numel(a) > 1
            racines = roots(a);
            rayon = max(abs(racines));
            if rayon >= 1 || isempty(rayon)
                n = 100;
            else
                n = max(numel(b), ceil(log(1e-6) / log(max(rayon, 1e-12))) + numel(b));
            end
        else
            n = numel(b);
        end
        n = min(max(n, 1), 10000);
    end
    impulsion = zeros(n, 1);
    impulsion(1) = 1;
    h = filter(b, a, impulsion);
    t = (0:n-1)';
    if nargin >= 4 && ~isempty(fs)
        t = t / fs;
    end
end
