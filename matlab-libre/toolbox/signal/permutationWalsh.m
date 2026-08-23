function ordreLignes = permutationWalsh(N, ordre)
%PERMUTATIONWALSH Rangement des fonctions de Walsh.
%   Rend le vecteur d'indices qui fait passer de l'ordre naturel de
%   Sylvester à l'ordre demandé : 'hadamard' (identité), 'dyadic'
%   (renversement des bits, ordre de Paley) ou 'sequency' (renversement
%   puis code de Gray, rangement par nombre de changements de signe).
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    bits = round(log2(N));
    switch lower(char(ordre))
        case 'hadamard'
            ordreLignes = 1:N;
        case {'dyadic', 'paley'}
            ordreLignes = zeros(1, N);
            for k = 0:N-1
                ordreLignes(k + 1) = renverserBits(k, bits) + 1;
            end
        case {'sequency', 'walsh'}
            ordreLignes = zeros(1, N);
            for k = 0:N-1
                gris = bitxor(k, floor(k / 2));
                ordreLignes(k + 1) = renverserBits(gris, bits) + 1;
            end
        otherwise
            error('signal:fwht:UnknownOrdering', 'Ordre inconnu : %s.', char(ordre));
    end
end

function r = renverserBits(v, bits)
    r = 0;
    for b = 0:bits-1
        if bitand(v, 2^b) ~= 0
            r = r + 2^(bits - 1 - b);
        end
    end
end
