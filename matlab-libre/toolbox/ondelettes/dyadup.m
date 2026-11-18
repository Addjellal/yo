function y = dyadup(x, varargin)
%DYADUP Suréchantillonnage dyadique : un zéro entre deux échantillons.
%   Y = DYADUP(X,EVENODD) insère des zéros dans le vecteur X :
%      EVENODD pair   Y(2k-1) = X(k), Y(2k) = 0 — les zéros aux rangs
%                     pairs, et Y compte 2*numel(X)-1 valeurs ;
%      EVENODD impair Y(2k-1) = 0, Y(2k) = X(k) — les zéros aux rangs
%                     impairs, et Y compte 2*numel(X)+1 valeurs.
%   Y = DYADUP(X) vaut DYADUP(X,1), comme dans MATLAB.
%   Y = DYADUP(X,EVENODD,'c') suréchantillonne les colonnes d'une
%   matrice (des lignes de zéros), 'r' ses lignes (des colonnes de
%   zéros), 'm' les deux ; l'ordre des deux options est libre.
%
%   Exemple :
%      dyadup(1:3)        % 0 1 0 2 0 3 0
%      dyadup(1:3, 0)     % 1 0 2 0 3
%
%   Voir aussi DYADDOWN, IDWT, UPCOEF.
    parite = 1;
    genre = '';
    for k = 1:numel(varargin)
        a = varargin{k};
        if ischar(a) || (isstring(a) && isscalar(a))
            genre = lower(char(a));
        elseif ~isempty(a)
            parite = double(a);
        end
    end
    pair = mod(parite, 2) == 0;
    x = double(x);
    if isvector(x) && isempty(genre)
        ligne = size(x, 1) == 1;
        y = surVecteur(x(:).', pair);
        if ~ligne
            y = y(:);
        end
        return
    end
    if isempty(genre)
        genre = 'c';
    end
    y = x;
    if any(genre == 'c') || any(genre == 'm')
        y = surLignes(y, pair);
    end
    if any(genre == 'r') || any(genre == 'm')
        y = surLignes(y.', pair).';
    end
end

function y = surVecteur(v, pair)
    n = numel(v);
    if pair
        y = zeros(1, max(2 * n - 1, 0));
        y(1:2:end) = v;
    else
        y = zeros(1, 2 * n + 1);
        y(2:2:end) = v;
    end
end

% Insère des lignes de zéros entre les lignes de X.
function y = surLignes(x, pair)
    [m, n] = size(x);
    if pair
        y = zeros(max(2 * m - 1, 0), n);
        y(1:2:end, :) = x;
    else
        y = zeros(2 * m + 1, n);
        y(2:2:end, :) = x;
    end
end
