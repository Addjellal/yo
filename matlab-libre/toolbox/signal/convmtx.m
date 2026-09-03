function A = convmtx(h, n)
%CONVMTX Matrice de convolution.
%   A = CONVMTX(H,N) rend la matrice qui transforme une convolution en
%   produit matriciel : pour un vecteur X de N éléments, CONVMTX(H,N)*X
%   vaut CONV(H,X) — en colonne si H est une colonne, en ligne si H est
%   une ligne, auquel cas c'est X*CONVMTX(H,N) qu'il faut écrire.
%
%   Exemple :
%      h = [1 2 3];
%      isequal(convmtx(h, 4) * (1:4)', conv(h, 1:4)')   % vrai... en colonne
%
%   Voir aussi CONV, CORRMTX, TOEPLITZ, FILTER.
    colonne = iscolumn(h);
    h = double(h(:));
    m = numel(h);
    n = round(n);
    if n < 1
        error('signal:convmtx:BadLength', 'N doit être au moins 1.');
    end
    A = zeros(m + n - 1, n);
    for k = 1:n
        A(k:(k + m - 1), k) = h;
    end
    if ~colonne
        A = A.';
    end
end
