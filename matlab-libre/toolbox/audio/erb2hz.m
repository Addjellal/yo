function hz = erb2hz(erb)
%ERB2HZ Échelle ERB vers les hertz, inverse de HZ2ERB (Glasberg et Moore, 1990).
%   HZ = (10^(ERB/A) - 1) / 0.00437, A = 1000 ln(10) / (24.7 x 4.37).
%
%   Exemple :
%      erb2hz(hz2erb(440))        % 440
%
%   Voir aussi HZ2ERB, MEL2HZ, BARK2HZ.
    A = 1000 * log(10) / (24.7 * 4.37);
    hz = (10 .^ (erb / A) - 1) / 0.00437;
end
