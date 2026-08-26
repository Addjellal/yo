function y = interp(x, r, l, alpha)
%INTERP Augmente la fréquence d'échantillonnage d'un facteur entier.
%   Y = INTERP(X,R) insère R-1 zéros entre les échantillons puis filtre
%   passe-bas ; le résultat a R fois plus de points, et le gain est
%   compensé pour que l'amplitude soit conservée.
    if nargin < 3 || isempty(l), l = 4; end
    if nargin < 4 || isempty(alpha), alpha = 0.5; end
    ligne = isrow(x);
    x = x(:);
    n = numel(x);
    etendu = zeros(n * r, 1);
    etendu(1:r:end) = x;
    ordre = min(2 * l * r, max(2, 2 * floor((numel(etendu) - 1) / 3 / 2)));
    b = fir1(ordre, alpha / r) * r;
    y = filtfilt(b, 1, etendu);
    if ligne, y = y.'; end
end
