function k = kurtosis(x)
%KURTOSIS Coefficient d'aplatissement (3 pour une loi normale).
%   K = KURTOSIS(X) rend le moment centré d'ordre quatre divisé par le
%   carré de la variance.
%
%   Il vaut trois pour une loi normale : c'est la référence. Au-dessus, la
%   loi a des queues plus lourdes — les valeurs extrêmes y sont plus
%   fréquentes qu'une normale ne le prévoit, ce qui est le cas de presque
%   tous les rendements financiers. Au-dessous, elle est plus plate ;
%   l'uniforme vaut 1,8.
%
%   Sur un signal, il mesure l'impulsivité : un sinus vaut 1,5, un signal
%   à chocs bien davantage. C'est le descripteur de l'écaillage de
%   roulement.
%
%   Exemple :
%      abs(kurtosis(randn(100000,1)) - 3) < 0.1        % true
%      kurtosis(sin(linspace(0, 20*pi, 10000)))        % 1.5
%
%   Voir aussi SKEWNESS, STD, FAULTFEATURES.
    x = x(:);
    n = numel(x);
    m = mean(x);
    ecart = std(x, 1);
    if ecart == 0
        k = NaN;
    else
        k = sum((x - m) .^ 4) / (n * ecart ^ 4);
    end
end
