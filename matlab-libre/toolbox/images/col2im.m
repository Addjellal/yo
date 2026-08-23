function image = col2im(colonnes, blocs, taille, genre)
%COL2IM Réassemble une image à partir de colonnes de blocs.
%   Réciproque d'IM2COL pour le découpage disjoint ; pour le découpage
%   glissant, chaque colonne fournit un pixel, comme dans MATLAB.
    if nargin < 4 || isempty(genre), genre = 'sliding'; end
    colonnes = double(colonnes);
    m = blocs(1);
    n = blocs(2);
    h = taille(1);
    l = taille(2);
    if strncmpi(char(genre), 'dist', 4)
        lignesBlocs = ceil(h / m);
        colonnesBlocs = ceil(l / n);
        etendue = zeros(lignesBlocs * m, colonnesBlocs * n);
        compteur = 0;
        for b = 1:colonnesBlocs
            for a = 1:lignesBlocs
                compteur = compteur + 1;
                etendue((a-1)*m + (1:m), (b-1)*n + (1:n)) = ...
                    reshape(colonnes(:, compteur), m, n);
            end
        end
        image = etendue(1:h, 1:l);
    else
        image = reshape(colonnes(1, :), h - m + 1, l - n + 1);
    end
end
