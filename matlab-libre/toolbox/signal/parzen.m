function w = parzen(n)
%PARZEN Fenêtre de Parzen.
%   W = PARZEN(N) rend la fenêtre de Parzen de N points, aussi appelée
%   fenêtre de de La Vallée Poussin : c'est la convolution de deux
%   fenêtres triangulaires, donc un B-spline cubique. Son spectre décroît
%   en 1/f^4, plus vite que celui de toute autre fenêtre polynomiale de
%   même largeur, au prix d'un lobe principal plus large.
%
%   C'est la même fenêtre que rend PARZENWIN.
%
%   Exemple :
%      w = parzen(64);
%      sum(w) / 64          % environ 0,375
%
%   Voir aussi PARZENWIN, BARTHANNWIN, TRIANG, WINDOW.
    w = parzenwin(n);
end
