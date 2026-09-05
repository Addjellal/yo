function y = fftfilt(b, x, nfft)
%FFTFILT Filtrage RIF par recouvrement-addition dans le domaine fréquentiel.
%   Y = FFTFILT(B,X) donne le même résultat que FILTER(B,1,X), mais en
%   passant par la transformée de Fourier : c'est plus rapide dès que le
%   filtre est long.
%   Y = FFTFILT(B,X,NFFT) impose la taille des blocs.
%
%   La méthode est celle du recouvrement et de l'addition : le signal est
%   découpé, chaque bloc est convolué par transformée, et les morceaux se
%   recouvrent de la longueur du filtre moins un. C'est ce recouvrement
%   qui rend le résultat exactement égal à celui de FILTER, et non
%   seulement voisin.
%
%   L'orientation de X est préservée, comme dans MATLAB : un vecteur
%   colonne rend un vecteur colonne.
%
%   Exemple :
%      x = randn(4096, 1);
%      b = fir1(64, 0.3);
%      max(abs(fftfilt(b, x) - filter(b, 1, x)))     % de l'ordre de 1e-15
%
%   Voir aussi FILTER, CONV, UPFIRDN, FIR1.
    colonne = iscolumn(x) && numel(x) > 1;
    b = b(:).';
    x = x(:).';
    nb = numel(b);
    nx = numel(x);
    if nargin < 3 || isempty(nfft)
        nfft = 2 ^ nextpow2(max(4 * nb, 64));
    end
    L = nfft - nb + 1;
    B = fft(b, nfft);
    y = zeros(1, nx + nb - 1);
    debut = 1;
    while debut <= nx
        fin = min(nx, debut + L - 1);
        bloc = x(debut:fin);
        Y = ifft(fft(bloc, nfft) .* B);
        n = numel(bloc) + nb - 1;
        y(debut:debut + n - 1) = y(debut:debut + n - 1) + real(Y(1:n));
        debut = fin + 1;
    end
    y = y(1:nx);
    if colonne
        y = y.';
    end
end
