function x = idct(y, n)
%IDCT Transformée en cosinus discrète inverse.
    y = y(:);
    if nargin > 1 && ~isempty(n)
        if numel(y) > n
            y = y(1:n);
        else
            y = [y; zeros(n - numel(y), 1)];
        end
    end
    N = numel(y);
    x = zeros(N, 1);
    for m = 1:N
        s = y(1) / sqrt(N);
        for k = 2:N
            s = s + sqrt(2/N) * y(k) * cos(pi * (2*m - 1) * (k - 1) / (2 * N));
        end
        x(m) = s;
    end
end
