function y = arsim(phi, n, sigma, constante)
%ARSIM Simulation d'un processus autorégressif.
    if nargin < 3, sigma = 1; end
    if nargin < 4, constante = 0; end
    p = numel(phi);
    y = zeros(n, 1);
    bruit = sigma * randn(n, 1);
    for k = 1:n
        acc = constante + bruit(k);
        for j = 1:p
            if k - j >= 1
                acc = acc + phi(j) * y(k - j);
            end
        end
        y(k) = acc;
    end
end
