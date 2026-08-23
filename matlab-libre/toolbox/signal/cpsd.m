function [pxy, f] = cpsd(x, y, fenetre, recouvrement, nfft, fs)
%CPSD Densité interspectrale de puissance, par la méthode de Welch.
%   [PXY,F] = CPSD(X,Y,...) : même découpage que PWELCH, mais le produit
%   croisé X conjugué par Y.
    if nargin < 3, fenetre = []; end
    if nargin < 4, recouvrement = []; end
    if nargin < 5, nfft = []; end
    if nargin < 6, fs = 1; end
    [sx, f] = spectrogram(x, fenetre, recouvrement, nfft, fs);
    sy = spectrogram(y, fenetre, recouvrement, nfft, fs);
    if isempty(fenetre), fenetre = hamming(min(256, numel(x))); end
    if isscalar(fenetre), fenetre = hamming(fenetre); end
    normalisation = fs * sum(fenetre(:).^2);
    pxy = mean(conj(sx) .* sy, 2) / normalisation;
    % Les fréquences autres que 0 et Nyquist portent aussi l'image négative.
    milieu = 2:size(sx, 1) - 1;
    pxy(milieu) = 2 * pxy(milieu);
end
