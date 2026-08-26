function [h, v, d] = detcoef2(genre, C, S, niveau)
%DETCOEF2 Coefficients de détail d'une image décomposée.
%   D = DETCOEF2('h',C,S,N) rend le détail horizontal du niveau N ;
%   'v' le vertical, 'd' le diagonal, 'compact' ou 'all' les trois.
    niveauMax = size(S, 1) - 2;
    if niveau > niveauMax || niveau < 1
        error('wavelet:detcoef2:BadLevel', 'Niveau hors de la décomposition.');
    end
    position = prod(S(1, :));
    for k = 1:niveauMax - niveau
        position = position + 3 * prod(S(k + 1, :));
    end
    taille = S(niveauMax - niveau + 2, :);
    n = prod(taille);
    ch = reshape(C(position + (1:n)), taille);
    cv = reshape(C(position + n + (1:n)), taille);
    cd = reshape(C(position + 2 * n + (1:n)), taille);
    switch lower(char(genre))
        case 'h', h = ch;
        case 'v', h = cv;
        case 'd', h = cd;
        otherwise
            h = ch;
            v = cv;
            d = cd;
            return
    end
    v = [];
    d = [];
end
