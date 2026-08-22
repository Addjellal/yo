function d = bi2de(b, base)
%BI2DE Vecteurs de chiffres vers entiers, poids faible en tête.
    if nargin < 2
        base = 2;
    end
    d = zeros(size(b, 1), 1);
    for k = 1:size(b, 1)
        v = 0;
        for j = size(b, 2):-1:1
            v = v * base + b(k, j);
        end
        d(k) = v;
    end
end
