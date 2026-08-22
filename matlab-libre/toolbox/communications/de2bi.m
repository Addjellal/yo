function b = de2bi(d, n, base)
%DE2BI Entiers vers vecteurs de chiffres, poids faible en tête.
    if nargin < 3
        base = 2;
    end
    d = d(:);
    if nargin < 2 || isempty(n)
        n = 1;
        m = max(d);
        while base ^ n <= m
            n = n + 1;
        end
    end
    b = zeros(numel(d), n);
    for k = 1:numel(d)
        v = d(k);
        for j = 1:n
            b(k, j) = mod(v, base);
            v = floor(v / base);
        end
    end
end
