function w = bohmanwin(n)
%BOHMANWIN Fenêtre de Bohman.
%   W = BOHMANWIN(N) rend la fenêtre de N points, en colonne.
%
%   C'est la convolution de deux demi-cosinusoïdes, ce qui lui donne une
%   propriété que les fenêtres polynomiales n'ont pas : la fenêtre et sa
%   dérivée s'annulent aux deux bords. Le raccord avec le silence se fait
%   sans rupture de pente, et les lobes secondaires décroissent d'autant
%   plus vite — en 1/f^4, soit 24 dB par octave, contre 6 dB pour une
%   fenêtre rectangulaire dont le raccord est brutal.
%
%   Premier lobe secondaire à -46 dB environ, pour un lobe principal deux
%   fois plus large que celui de Hann. Elle sert quand il faut voir une
%   composante très faible loin d'une composante forte.
%
%   Exemple :
%      w = bohmanwin(64);
%      [w(1) w(end)]
%
%   Voir aussi PARZENWIN, BARTHANNWIN, BLACKMAN, HANN.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' - (n - 1) / 2;
    r = abs(k) / ((n - 1) / 2);
    w = (1 - r) .* cos(pi * r) + sin(pi * r) / pi;
    w(1) = 0;
    w(end) = 0;
end
