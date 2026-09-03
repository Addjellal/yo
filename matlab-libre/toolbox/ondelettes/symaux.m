function w = symaux(N, sumf)
%SYMAUX Filtre d'échelle d'un symlet d'ordre N.
%   W = SYMAUX(N) rend le filtre d'échelle de l'ondelette symN, de
%   longueur 2N et de somme un.
%   W = SYMAUX(N,SOMME) le normalise à la somme donnée ; SOMME nulle
%   demande la normalisation en norme deux.
%
%   Le symlet a les mêmes moments nuls que dbN : c'est l'autre
%   factorisation spectrale du même polynôme, celle dont la phase
%   s'écarte le moins de la linéarité — d'où un filtre presque
%   symétrique.
%
%   Exemple :
%      w = symaux(4);
%      sum(w)                         % 1
%      numel(w)                       % 8
%
%   Voir aussi SYMWAVF, DBAUX, WFILTERS, ORTHFILT.
    if nargin < 1 || isempty(N), N = 2; end
    if nargin < 2 || isempty(sumf), sumf = 1; end
    N = round(N);
    if N < 1
        error('wavelet:symaux:BadOrder', 'L''ordre doit valoir au moins un.');
    end
    w = daubechiesFiltre(N, 'symetrique');
    w = normaliserSomme(w, sumf);
end
