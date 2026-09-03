function w = dbaux(N, sumf)
%DBAUX Filtre d'échelle de Daubechies d'ordre N.
%   W = DBAUX(N) rend le filtre d'échelle de l'ondelette dbN, de longueur
%   2N et de somme un.
%   W = DBAUX(N,SOMME) le normalise à la somme donnée ; SOMME nulle
%   demande la normalisation en norme deux, c'est-à-dire une somme de
%   racine de deux — celle du banc orthonormé.
%
%   Le filtre n'est pas lu dans une table : il vient de la factorisation
%   spectrale du polynôme de Daubechies, et existe donc à tout ordre.
%
%   Exemple :
%      w = dbaux(2);
%      sum(w)                         % 1
%      norme = dbaux(2, 0);
%      sum(norme .^ 2)                % 1 : le filtre orthonormé
%
%   Voir aussi DBWAVF, SYMAUX, WFILTERS, ORTHFILT.
    if nargin < 1 || isempty(N), N = 2; end
    if nargin < 2 || isempty(sumf), sumf = 1; end
    N = round(N);
    if N < 1
        error('wavelet:dbaux:BadOrder', 'L''ordre doit valoir au moins un.');
    end
    w = daubechiesFiltre(N);
    w = normaliserSomme(w, sumf);
end
