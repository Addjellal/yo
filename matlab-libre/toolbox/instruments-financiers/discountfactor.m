function d = discountfactor(taux, echeances)
%DISCOUNTFACTOR Facteurs d'actualisation d'une courbe de taux.
    d = 1 ./ (1 + taux(:)) .^ echeances(:);
end
