function rul = rulSimilarity(trajectoire, historiques, dureesVie)
%RULSIMILARITY Durée de vie restante par similarité de trajectoires.
%   Les trajectoires historiques les plus proches, au sens de l'écart
%   quadratique sur la partie commune, votent au prorata de l'inverse de
%   leur distance.
    n = numel(trajectoire);
    poids = zeros(numel(historiques), 1);
    restes = zeros(numel(historiques), 1);
    for k = 1:numel(historiques)
        h = historiques{k};
        m = min(n, numel(h));
        d = sqrt(mean((trajectoire(1:m) - h(1:m)) .^ 2));
        poids(k) = 1 / max(d, 1e-6);
        restes(k) = dureesVie(k) - m;
    end
    rul = sum(poids .* restes) / sum(poids);
end
