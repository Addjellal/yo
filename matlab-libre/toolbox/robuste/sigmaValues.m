function [valeurs, w] = sigmaValues(sys, w)
%SIGMAVALUES Valeurs singulières en fonction de la pulsation.
    if nargin < 2
        w = logspace(-2, 3, 200).';
    end
    m = bode(sys, w);
    valeurs = 20 * log10(m);
end
