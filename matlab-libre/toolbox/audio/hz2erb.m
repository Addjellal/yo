function erb = hz2erb(hz)
%HZ2ERB Fréquences en hertz vers l'échelle ERB (Glasberg et Moore, 1990).
%   ERB = HZ2ERB(HZ) = A log10(1 + 0.00437 HZ), A = 1000 ln(10) / (24.7
%   x 4.37) : le nombre de bandes rectangulaires équivalentes sous HZ, la
%   bande à F valant 24.7 (4.37 F/1000 + 1) hertz. 1000 Hz valent 15.57.
%
%   Exemple :
%      hz2erb(1000)               % 15.572
%
%   Voir aussi ERB2HZ, HZ2MEL, HZ2BARK.
    A = 1000 * log(10) / (24.7 * 4.37);
    erb = A * log10(1 + hz * 0.00437);
end
