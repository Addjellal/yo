function r = ordfilt2(image, ordre, domaine, remplissage)
%ORDFILT2 Filtre de rang : le ORDRE-ième plus petit du voisinage.
%   R = ORDFILT2(I,N,DOMAINE) où DOMAINE est une matrice logique qui dit
%   quels voisins comptent. Avec N = 1 c'est un minimum, avec N égal au
%   nombre de vrais c'est un maximum, et au milieu c'est la médiane.
%   Les bords sont complétés par des zéros, comme dans MATLAB ;
%   ORDFILT2(...,'symmetric') les complète par symétrie.
%
%   Exemple :
%      ordfilt2(magic(4), 9, ones(3))   % maximum sur 3x3
    x = double(image);
    [m, n] = size(x);
    [dm, dn] = size(domaine);
    decalageLigne = floor(dm / 2);
    decalageColonne = floor(dn / 2);
    if nargin < 4 || isempty(remplissage), remplissage = 0; end
    etendu = padarray(x, [decalageLigne decalageColonne], remplissage);
    [di, dj] = find(logical(domaine));
    compte = numel(di);
    if ordre < 1 || ordre > compte
        error('images:ordfilt2:BadOrder', 'The order must be between 1 and %d.', compte);
    end
    r = zeros(m, n);
    for i = 1:m
        for j = 1:n
            valeurs = zeros(compte, 1);
            for k = 1:compte
                valeurs(k) = etendu(i + di(k) - 1, j + dj(k) - 1);
            end
            triees = sort(valeurs);
            r(i, j) = triees(ordre);
        end
    end
end
