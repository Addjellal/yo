function [haut, bas] = envelope(x)
%ENVELOPE Enveloppes supérieure et inférieure d'un signal.
%   [H,B] = ENVELOPE(X) utilise le module du signal analytique.
    a = abs(hilbert(x));
    m = mean(x(:));
    haut = m + a;
    bas = m - a;
end
