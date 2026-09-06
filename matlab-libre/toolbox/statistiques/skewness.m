function s = skewness(x)
%SKEWNESS Coefficient d'asymétrie (moment d'ordre trois normalisé).
%   S = SKEWNESS(X) rend le moment centré d'ordre trois divisé par le cube
%   de l'écart type.
%
%   Il vaut zéro pour toute loi symétrique. Positif, la queue s'étire vers
%   la droite — c'est le cas des revenus et des durées ; négatif, vers la
%   gauche.
%
%   Une asymétrie non nulle interdit de résumer les données par leur
%   moyenne : la médiane dit alors bien mieux ce qui est typique.
%
%   Exemple :
%      abs(skewness(randn(100000,1))) < 0.05           % true
%      skewness(exprnd(1, 100000, 1))                  % proche de 2
%
%   Voir aussi KURTOSIS, MEDIAN, MEAN.
    x = x(:);
    n = numel(x);
    m = mean(x);
    ecart = std(x, 1);
    if ecart == 0
        s = NaN;
    else
        s = sum((x - m) .^ 3) / (n * ecart ^ 3);
    end
end
