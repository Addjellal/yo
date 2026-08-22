function y = resample(x, p, q)
%RESAMPLE Rééchantillonnage d'un facteur rationnel P/Q.
%   Y = RESAMPLE(X,P,Q) interpole linéairement le signal sur la nouvelle
%   grille temporelle.
    x = x(:).';
    n = numel(x);
    m = floor(n * p / q);
    ancien = 1:n;
    nouveau = linspace(1, n, m);
    y = interp1(ancien, x, nouveau);
    y = y(:);
end
