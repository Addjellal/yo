function [a, e] = arcov(x, p)
%ARCOV Modèle autorégressif par la méthode de la covariance.
%   Moindres carrés sur l'erreur de prédiction avant, sans fenêtrage : on
%   n'utilise que les échantillons pour lesquels toute la fenêtre de
%   prédiction existe.
    x = double(x(:));
    n = numel(x);
    if p >= n
        error('signal:arcov:OrderTooLarge', 'L''ordre dépasse la longueur.');
    end
    lignes = n - p;
    M = zeros(lignes, p);
    b = zeros(lignes, 1);
    for i = 1:lignes
        M(i, :) = x(p + i - 1:-1:i).';
        b(i) = x(p + i);
    end
    coefficients = -(M \ b);
    a = [1 coefficients.'];
    residu = b + M * coefficients;
    e = sum(abs(residu) .^ 2) / lignes;
end
