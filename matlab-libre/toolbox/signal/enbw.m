function b = enbw(fenetre, fs)
%ENBW Largeur de bande de bruit équivalente d'une fenêtre.
%   B = ENBW(W) rend N*sum(w.^2)/sum(w)^2, en bacs de la transformée.
%   ENBW(W,FS) la donne en hertz.
%
%   Exemple :  enbw(rectwin(10))   % 1
    w = fenetre(:);
    n = numel(w);
    b = n * sum(w.^2) / sum(w)^2;
    if nargin > 1, b = b * fs / n; end
end
