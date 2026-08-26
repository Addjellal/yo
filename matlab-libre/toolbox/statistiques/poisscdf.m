function p = poisscdf(x, lambda)
%POISSCDF Répartition de la loi de Poisson.
%   P(X <= k) est la gamma incomplète supérieure d'ordre k+1 en lambda.
%
%   Exemple :  poisscdf(2, 1)   % 0.919698602928
    [x, lambda] = statAjuster(x, lambda);
    k = floor(x);
    p = zeros(size(x));
    dedans = k >= 0 & lambda > 0;
    if any(dedans(:))
        p(dedans) = gammainc(lambda(dedans), k(dedans) + 1, 'upper');
    end
    p(k >= 0 & lambda == 0) = 1;
    p(k < 0) = 0;
    p(lambda < 0) = NaN;
end
