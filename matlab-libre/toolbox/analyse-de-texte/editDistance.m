function d = editDistance(a, b)
%EDITDISTANCE Distance de Levenshtein entre deux chaînes.
    a = char(a);
    b = char(b);
    n = numel(a);
    m = numel(b);
    D = zeros(n + 1, m + 1);
    D(:, 1) = (0:n).';
    D(1, :) = 0:m;
    for i = 1:n
        for j = 1:m
            cout = double(a(i) ~= b(j));
            D(i+1, j+1) = min([D(i, j+1) + 1, D(i+1, j) + 1, D(i, j) + cout]);
        end
    end
    d = D(n+1, m+1);
end
