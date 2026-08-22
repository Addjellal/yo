function M = tfidf(effectifs)
%TFIDF Pondération terme-fréquence / fréquence inverse de document.
%   M = TFIDF(C) où C est la matrice rendue par BAGOFWORDS.
    [n, v] = size(effectifs);
    df = sum(effectifs > 0, 1);
    idf = log(n ./ max(df, 1));
    M = zeros(n, v);
    for i = 1:n
        total = sum(effectifs(i, :));
        if total == 0
            continue;
        end
        M(i, :) = (effectifs(i, :) / total) .* idf;
    end
end
