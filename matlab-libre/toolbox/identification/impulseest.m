function h = impulseest(donnees, n)
%IMPULSEEST Réponse impulsionnelle estimée par moindres carrés.
    if nargin < 2
        n = 20;
    end
    y = donnees.y;
    u = donnees.u;
    N = numel(y);
    Phi = zeros(N - n, n);
    for t = n+1:N
        for k = 1:n
            Phi(t - n, k) = u(t - k + 1);
        end
    end
    h = Phi \ y(n+1:N);
end
