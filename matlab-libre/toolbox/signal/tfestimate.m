function [h, f] = tfestimate(x, y, fenetre, recouvrement, nfft, fs)
%TFESTIMATE Estimation de la fonction de transfert entre deux signaux.
%   H = TFESTIMATE(X,Y,...) vaut Pxy/Pxx : la réponse du système qui mène
%   de X à Y, au sens des moindres carrés.
    if nargin < 3, fenetre = []; end
    if nargin < 4, recouvrement = []; end
    if nargin < 5, nfft = []; end
    if nargin < 6, fs = 1; end
    [pxy, f] = cpsd(x, y, fenetre, recouvrement, nfft, fs);
    pxx = cpsd(x, x, fenetre, recouvrement, nfft, fs);
    h = zeros(size(pxy));
    utile = abs(pxx) > 0;
    h(utile) = pxy(utile) ./ pxx(utile);
end
