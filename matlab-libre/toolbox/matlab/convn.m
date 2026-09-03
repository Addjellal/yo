function c = convn(a, b, forme)
%CONVN Convolution à N dimensions.
%   C = CONVN(A,B) rend la convolution complète de A par B : sa taille
%   est size(A)+size(B)-1 suivant chaque dimension.
%   C = CONVN(A,B,'same') rend la partie centrale, de la taille de A.
%   C = CONVN(A,B,'valid') ne rend que la part calculée sans dépassement.
%
%   Exemple :
%      a = ones(3,3,3);
%      c = convn(a, ones(2,2,2), 'valid');   % 2x2x2 de valeur 8
%
%   Voir aussi CONV, CONV2, FILTER.
    if nargin < 3
        forme = 'full';
    end
    forme = lower(char(forme));
    a = double(a);
    b = double(b);
    if isempty(a) || isempty(b)
        c = [];
        return;
    end
    d = max(max(ndims(a), ndims(b)), 2);
    sa = tailleEtendue(a, d);
    sb = tailleEtendue(b, d);
    if d == 2
        % Une matrice, ou un vecteur : conv2 fait déjà le travail, et
        % plus vite que la boucle générale.
        c = conv2(a, b, 'full');
    else
        sc = sa + sb - 1;
        c = zeros(sc);
        indice = cell(1, d);
        cible = cell(1, d);
        for j = 1:numel(b)
            if b(j) == 0
                continue;
            end
            [indice{1:d}] = ind2sub(sb, j);
            for k = 1:d
                cible{k} = indice{k} - 1 + (1:sa(k));
            end
            c(cible{:}) = c(cible{:}) + b(j) * a;
        end
    end
    switch forme
        case 'full'
            % Rien à couper.
        case 'same'
            c = couper(c, floor((sb - 1) / 2) + 1, sa, d);
        case 'valid'
            taille = max(sa - sb + 1, 0);
            if any(taille == 0)
                c = zeros(taille);
            else
                c = couper(c, min(sa, sb), taille, d);
            end
        otherwise
            error('convn:Forme', 'Forme inconnue : %s.', forme);
    end
end

function t = tailleEtendue(x, d)
    t = size(x);
    t = [t, ones(1, d - numel(t))];
end

function c = couper(c, debut, taille, d)
    tranche = cell(1, d);
    for k = 1:d
        tranche{k} = debut(k) - 1 + (1:taille(k));
    end
    c = c(tranche{:});
end
