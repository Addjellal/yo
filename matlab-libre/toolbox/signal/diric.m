function y = diric(x, n)
%DIRIC Fonction de Dirichlet, ou sinus cardinal périodique.
%   Y = DIRIC(X,N) vaut sin(N X/2)/(N sin(X/2)), prolongée par
%   (-1)^(k(N-1)) aux multiples de 2 pi.
%
%   C'est la transformée de Fourier de la fenêtre rectangulaire de N
%   points, normalisée.
%
%   Exemple :  diric(0, 5)   % 1
    if n <= 0 || n ~= round(n)
        error('signal:diric:BadOrder', 'N doit être un entier positif.');
    end
    x = double(x);
    y = zeros(size(x));
    % Aux multiples de 2 pi le quotient est indéterminé ; la limite vaut
    % +1 ou -1 selon la parité de N et le multiple.
    k = round(x / (2 * pi));
    singulier = abs(x - 2 * pi * k) < 1e-12;
    y(singulier) = (-1) .^ (k(singulier) * (n - 1));
    ordinaire = ~singulier;
    y(ordinaire) = sin(n * x(ordinaire) / 2) ./ (n * sin(x(ordinaire) / 2));
end
