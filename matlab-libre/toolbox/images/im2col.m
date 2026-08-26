function colonnes = im2col(image, blocs, genre)
%IM2COL Réarrange les blocs d'une image en colonnes.
%   IM2COL(A,[M N],'distinct') découpe l'image en blocs disjoints ;
%   'sliding' (par défaut) prend tous les blocs glissants.
%
%   Exemple :
%      im2col(magic(4), [2 2], 'distinct')   % quatre colonnes de quatre
    if nargin < 3 || isempty(genre), genre = 'sliding'; end
    image = double(image);
    [h, l] = size(image);
    m = blocs(1);
    n = blocs(2);
    if strncmpi(char(genre), 'dist', 4)
        lignesBlocs = ceil(h / m);
        colonnesBlocs = ceil(l / n);
        etendue = zeros(lignesBlocs * m, colonnesBlocs * n);
        etendue(1:h, 1:l) = image;
        colonnes = zeros(m * n, lignesBlocs * colonnesBlocs);
        compteur = 0;
        for b = 1:colonnesBlocs
            for a = 1:lignesBlocs
                compteur = compteur + 1;
                bloc = etendue((a-1)*m + (1:m), (b-1)*n + (1:n));
                colonnes(:, compteur) = bloc(:);
            end
        end
    else
        hs = h - m + 1;
        ls = l - n + 1;
        if hs < 1 || ls < 1
            colonnes = zeros(m * n, 0);
            return
        end
        colonnes = zeros(m * n, hs * ls);
        compteur = 0;
        for b = 1:ls
            for a = 1:hs
                compteur = compteur + 1;
                bloc = image(a:a+m-1, b:b+n-1);
                colonnes(:, compteur) = bloc(:);
            end
        end
    end
end
