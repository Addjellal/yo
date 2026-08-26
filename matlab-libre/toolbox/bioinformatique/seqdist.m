function d = seqdist(a, b)
%SEQDIST Distance de Hamming normalisée entre deux séquences.
    a = upper(char(a));
    b = upper(char(b));
    n = min(numel(a), numel(b));
    d = sum(a(1:n) ~= b(1:n)) / max(n, 1);
end
