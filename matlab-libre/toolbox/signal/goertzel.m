function y = goertzel(x, indices)
%GOERTZEL Composantes choisies de la transformée de Fourier discrète.
%   Y = GOERTZEL(X,K) rend X(k) pour les indices K donnés, calculés par
%   l'algorithme de Goertzel : un filtre du second ordre par indice, ce qui
%   coûte moins qu'une transformée complète quand on ne veut qu'un raie.
%
%   Les indices suivent la convention de MATLAB : 1 correspond à la
%   composante continue.
%
%   Exemple :
%      x = [1 2 3 4]; abs(goertzel(x, 1) - sum(x)) < 1e-12
    x = x(:);
    n = numel(x);
    if nargin < 2 || isempty(indices), indices = 1:n; end
    indices = indices(:);
    y = zeros(numel(indices), 1);
    for j = 1:numel(indices)
        k = indices(j) - 1;
        omega = 2 * pi * k / n;
        coefficient = 2 * cos(omega);
        s0 = 0; s1 = 0; s2 = 0;
        for i = 1:n
            s0 = x(i) + coefficient * s1 - s2;
            s2 = s1;
            s1 = s0;
        end
        y(j) = (s1 - exp(-1i * omega) * s2) * exp(-1i * omega * (n - 1)) * exp(1i * omega * (n - 1));
        y(j) = s1 - exp(-1i * omega) * s2;
    end
end
