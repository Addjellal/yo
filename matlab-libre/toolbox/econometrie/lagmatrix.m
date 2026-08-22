function M = lagmatrix(y, retards)
%LAGMATRIX Matrice des versions retardées d'une série.
    y = y(:);
    n = numel(y);
    M = NaN(n, numel(retards));
    for k = 1:numel(retards)
        d = retards(k);
        if d >= 0
            M(d+1:n, k) = y(1:n-d);
        else
            M(1:n+d, k) = y(1-d:n);
        end
    end
end
