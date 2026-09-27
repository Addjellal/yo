function t = matlibre_fixe_chiffres(Q, T, base)
%MATLIBRE_FIXE_CHIFFRES Les entiers stockés écrits en base 2, 8, 16 ou 10.
%   T = MATLIBRE_FIXE_CHIFFRES(Q,TYPE,BASE) : en base 2, 8 et 16, sur la
%   taille du mot, un négatif en complément à deux ; en base 10, l'entier
%   avec son signe. Les éléments d'une ligne sont séparés de trois
%   espaces ; chaque ligne du tableau est une ligne du texte.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi BIN, HEX, DEC, OCT.
    w = T.WordLength;
    if base ~= 10
        Q(Q < 0) = Q(Q < 0) + 2 ^ w;
    end
    lignes = cell(size(Q, 1), 1);
    for i = 1:size(Q, 1)
        morceaux = cell(1, size(Q, 2));
        for j = 1:size(Q, 2)
            switch base
                case 2
                    morceaux{j} = dec2bin(Q(i, j), w);
                case 8
                    morceaux{j} = dec2base(Q(i, j), 8, ceil(w / 3));
                case 16
                    morceaux{j} = lower(dec2hex(Q(i, j), ceil(w / 4)));
                otherwise
                    morceaux{j} = sprintf('%d', Q(i, j));
            end
        end
        lignes{i} = strjoin(morceaux, '   ');
    end
    if isempty(lignes)
        t = '';
    else
        t = char(lignes);
    end
end
