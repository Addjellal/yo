function w = triang(n)
%TRIANG Fenêtre triangulaire.
%   W = TRIANG(N). Contrairement à BARTLETT, les extrémités ne sont pas
%   nulles : c'est la différence que documente MathWorks entre les deux.
%
%   Exemple :
%      triang(4)'   % [0.25 0.75 0.75 0.25]
    n = round(n);
    if n <= 0, w = zeros(0, 1); return, end
    k = (1:n)';
    if mod(n, 2)
        w = min(2 * k, 2 * (n + 1 - k)) / (n + 1);
    else
        w = (2 * min(k, n + 1 - k) - 1) / n;
    end
end
