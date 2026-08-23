function [c, f] = mscohere(x, y, fenetre, recouvrement, nfft, fs)
%MSCOHERE Cohérence quadratique moyenne entre deux signaux.
%   C = MSCOHERE(X,Y,...) vaut |Pxy|^2 / (Pxx*Pyy) : entre 0 et 1, elle
%   dit quelle part de Y s'explique linéairement par X, fréquence par
%   fréquence.
    if nargin < 3, fenetre = []; end
    if nargin < 4, recouvrement = []; end
    if nargin < 5, nfft = []; end
    if nargin < 6, fs = 1; end
    [pxy, f] = cpsd(x, y, fenetre, recouvrement, nfft, fs);
    pxx = cpsd(x, x, fenetre, recouvrement, nfft, fs);
    pyy = cpsd(y, y, fenetre, recouvrement, nfft, fs);
    denominateur = real(pxx) .* real(pyy);
    c = zeros(size(pxy));
    utile = denominateur > 0;
    c(utile) = abs(pxy(utile)).^2 ./ denominateur(utile);
    c = min(max(real(c), 0), 1);
end
