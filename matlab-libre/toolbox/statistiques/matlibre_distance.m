function d = matlibre_distance(u, v, nom, parametre, echelle)
%MATLIBRE_DISTANCE Distance entre deux observations, selon la métrique nommée.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   PDIST et PDIST2 s'en servent pour n'écrire qu'une fois chacune des
%   distances qu'ils proposent.
    switch nom
        case 'euclidean'
            d = sqrt(sum((u - v) .^ 2));
        case 'squaredeuclidean'
            d = sum((u - v) .^ 2);
        case 'seuclidean'
            d = sqrt(sum(((u - v) ./ echelle) .^ 2));
        case 'cityblock'
            d = sum(abs(u - v));
        case 'chebychev'
            d = max(abs(u - v));
        case 'minkowski'
            if isinf(parametre)
                d = max(abs(u - v));
            else
                d = sum(abs(u - v) .^ parametre) ^ (1 / parametre);
            end
        case 'cosine'
            nu = sqrt(sum(u .^ 2));
            nv = sqrt(sum(v .^ 2));
            if nu == 0 || nv == 0
                d = NaN;
            else
                d = 1 - sum(u .* v) / (nu * nv);
            end
        case 'correlation'
            a = u - mean(u);
            b = v - mean(v);
            na = sqrt(sum(a .^ 2));
            nb = sqrt(sum(b .^ 2));
            if na == 0 || nb == 0
                d = NaN;
            else
                d = 1 - sum(a .* b) / (na * nb);
            end
        case 'hamming'
            d = sum(u ~= v) / numel(u);
        case 'jaccard'
            interessantes = (u ~= 0) | (v ~= 0);
            if ~any(interessantes)
                d = 0;
            else
                d = sum((u ~= v) & interessantes) / sum(interessantes);
            end
        otherwise
            error('stats:pdist:UnknownDistance', 'Unknown distance ''%s''.', nom);
    end
end
