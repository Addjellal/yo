function y = medfilt1(x, n)
%MEDFILT1 Filtre médian glissant d'ordre N.
%   Y = MEDFILT1(X,N) remplace chaque échantillon par la médiane de la
%   fenêtre de N points centrée dessus. N vaut 3 par défaut.
    if nargin < 2
        n = 3;
    end
    x = x(:).';
    m = numel(x);
    y = zeros(1, m);
    demi = floor(n / 2);
    for k = 1:m
        a = max(1, k - demi);
        b = min(m, k + demi);
        y(k) = median(x(a:b));
    end
end
