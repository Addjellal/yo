function r = poissrnd(lambda, varargin)
%POISSRND Tirages d'une loi de Poisson.
%   Méthode du produit de Knuth pour les petites intensités : on
%   multiplie des uniformes jusqu'à passer sous exp(-lambda). Au-delà,
%   l'inversion de la répartition évite le nombre d'itérations qui
%   croîtrait avec lambda.
    forme = statForme(size(lambda), varargin);
    lambda = statEtendre(lambda, forme);
    r = zeros(forme);
    petit = lambda > 0 & lambda <= 30;
    if any(petit(:))
        seuil = exp(-lambda);
        produit = ones(forme);
        compte = zeros(forme);
        actif = petit;
        while any(actif(:))
            produit(actif) = produit(actif) .* rand(size(produit(actif)));
            encore = actif & produit > seuil;
            compte(encore) = compte(encore) + 1;
            actif = encore;
        end
        r(petit) = compte(petit);
    end
    grand = lambda > 30;
    if any(grand(:))
        r(grand) = poissinv(rand(size(lambda(grand))), lambda(grand));
    end
    r(lambda < 0) = NaN;
end
