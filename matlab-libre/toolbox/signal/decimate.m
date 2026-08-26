function y = decimate(x, r, n)
%DECIMATE Réduit la fréquence d'échantillonnage d'un facteur entier.
%   Y = DECIMATE(X,R) filtre X passe-bas puis garde un échantillon sur R.
%   Le filtre est un RIF d'ordre 30 par défaut, appliqué en phase nulle
%   pour ne pas décaler le signal ; DECIMATE(X,R,N) choisit l'ordre.
%
%   Exemple :
%      numel(decimate(1:100, 4))   % 25
    if nargin < 3 || isempty(n), n = 30; end
    ligne = isrow(x);
    x = x(:);
    n = min(n, max(2, 2 * floor((numel(x) - 1) / 3 / 2)));
    b = fir1(n, 1 / r);
    filtre = filtfilt(b, 1, x);
    y = filtre(1:r:end);
    if ligne, y = y.'; end
end
