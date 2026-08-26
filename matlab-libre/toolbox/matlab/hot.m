function carte = hot(m)
%HOT Carte de couleurs noir - rouge - jaune - blanc.
%   Les trois tiers de la rampe montent tour à tour le rouge, le vert
%   puis le bleu : c'est la couleur d'un corps chauffé.
    if nargin < 1 || isempty(m), m = 256; end
    m = round(m);
    n = fix(3 * m / 8);
    if n < 1, n = 1; end
    r = [(1:n)' / n; ones(max(0, m - n), 1)];
    v = [zeros(n, 1); (1:n)' / n; ones(max(0, m - 2 * n), 1)];
    reste = max(0, m - 2 * n);
    if reste > 0
        b = [zeros(2 * n, 1); (1:reste)' / reste];
    else
        b = zeros(m, 1);
    end
    carte = [ajuster(r, m) ajuster(v, m) ajuster(b, m)];
end

function v = ajuster(v, m)
    if numel(v) > m
        v = v(1:m);
    elseif numel(v) < m
        v(end+1:m, 1) = v(end);
    end
end
