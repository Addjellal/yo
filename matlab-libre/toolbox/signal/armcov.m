function [a, e] = armcov(x, p)
%ARMCOV Modèle autorégressif par la covariance modifiée.
%   Moindres carrés sur les erreurs de prédiction avant et arrière à la
%   fois : c'est la méthode qui résout le mieux deux sinusoïdes proches.
    x = double(x(:));
    n = numel(x);
    if p >= n
        error('signal:armcov:OrderTooLarge', 'L''ordre dépasse la longueur.');
    end
    lignes = n - p;
    M = zeros(2 * lignes, p);
    b = zeros(2 * lignes, 1);
    for i = 1:lignes
        M(i, :) = x(p + i - 1:-1:i).';
        b(i) = x(p + i);
        % Prédiction arrière : le même bloc, retourné et conjugué.
        M(lignes + i, :) = conj(x(i + 1:i + p)).';
        b(lignes + i) = conj(x(i));
    end
    coefficients = -(M \ b);
    a = [1 coefficients.'];
    residu = b + M * coefficients;
    e = sum(abs(residu) .^ 2) / (2 * lignes);
end
