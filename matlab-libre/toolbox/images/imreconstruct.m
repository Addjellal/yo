function sortie = imreconstruct(marqueur, masque, connexite)
%IMRECONSTRUCT Reconstruction morphologique par dilatation géodésique.
%   J = IMRECONSTRUCT(MARQUEUR,MASQUE) dilate le marqueur sous le masque
%   jusqu'à stabilité : chaque pixel prend le maximum de son voisinage,
%   sans jamais dépasser le masque. C'est la brique de toutes les
%   opérations qui suivent — extrema régionaux, remplissage de trous,
%   suppression des objets touchant le bord.
%
%   L'implémentation fait deux balayages par tour, l'un en avant, l'autre
%   en arrière : la propagation traverse alors l'image en un tour au lieu
%   d'un par pixel de distance.
%
%   Exemple :
%      m = zeros(5); m(3,3) = 1;
%      imreconstruct(m, ones(5))   % tout à 1 : le masque est connexe
    if nargin < 3 || isempty(connexite), connexite = 8; end
    marqueur = double(marqueur);
    masque = double(masque);
    if ~isequal(size(marqueur), size(masque))
        error('images:imreconstruct:SizeMismatch', ...
              'Le marqueur et le masque doivent avoir la même taille.');
    end
    sortie = min(marqueur, masque);
    [h, l] = size(sortie);
    decalages = voisinageConnexite(connexite);
    avant = decalages(decalages(:, 1) < 0 | (decalages(:, 1) == 0 & decalages(:, 2) < 0), :);
    arriere = decalages(decalages(:, 1) > 0 | (decalages(:, 1) == 0 & decalages(:, 2) > 0), :);
    for tour = 1:h * l
        change = false;
        for i = 1:h
            for j = 1:l
                v = sortie(i, j);
                for k = 1:size(avant, 1)
                    ii = i + avant(k, 1);
                    jj = j + avant(k, 2);
                    if ii >= 1 && ii <= h && jj >= 1 && jj <= l
                        v = max(v, sortie(ii, jj));
                    end
                end
                v = min(v, masque(i, j));
                if v > sortie(i, j)
                    sortie(i, j) = v;
                    change = true;
                end
            end
        end
        for i = h:-1:1
            for j = l:-1:1
                v = sortie(i, j);
                for k = 1:size(arriere, 1)
                    ii = i + arriere(k, 1);
                    jj = j + arriere(k, 2);
                    if ii >= 1 && ii <= h && jj >= 1 && jj <= l
                        v = max(v, sortie(ii, jj));
                    end
                end
                v = min(v, masque(i, j));
                if v > sortie(i, j)
                    sortie(i, j) = v;
                    change = true;
                end
            end
        end
        if ~change
            break
        end
    end
end
