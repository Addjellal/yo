function sortie = colfilt(image, voisinage, genre, fonction)
%COLFILT Filtre par colonnes : la fonction voit tous les blocs à la fois.
%   B = COLFILT(A,[M N],'sliding',FUN) passe à FUN une matrice dont
%   chaque colonne est un voisinage, et attend une ligne de résultats.
%   C'est la version rapide de NLFILTER.
%
%   Exemple :
%      colfilt(magic(4), [3 3], 'sliding', @max)
    image = double(image);
    [h, l] = size(image);
    m = voisinage(1);
    n = voisinage(2);
    di = floor(m / 2);
    dj = floor(n / 2);
    if strncmpi(char(genre), 'dist', 4)
        colonnes = im2col(image, voisinage, 'distinct');
        resultats = fonction(colonnes);
        sortie = col2im(resultats, voisinage, [h l], 'distinct');
        return
    end
    etendue = padarray(image, [di dj], 0, 'both');
    colonnes = im2col(etendue, voisinage, 'sliding');
    resultats = fonction(colonnes);
    sortie = reshape(resultats, h, l);
end
