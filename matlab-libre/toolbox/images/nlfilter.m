function sortie = nlfilter(image, voisinage, fonction)
%NLFILTER Filtre défini par une fonction du voisinage.
%   B = NLFILTER(A,[M N],FUN) applique FUN à chaque voisinage glissant de
%   M x N pixels ; le résultat prend la valeur rendue par FUN.
%
%   Exemple :
%      nlfilter(magic(4), [3 3], @(x) max(x(:)))
    image = double(image);
    [h, l] = size(image);
    m = voisinage(1);
    n = voisinage(2);
    di = floor(m / 2);
    dj = floor(n / 2);
    etendue = padarray(image, [di dj], 0, 'both');
    sortie = zeros(h, l);
    for i = 1:h
        for j = 1:l
            bloc = etendue(i:i+m-1, j:j+n-1);
            sortie(i, j) = fonction(bloc);
        end
    end
end
