function [h, w] = freqs(b, a, w)
%FREQS Réponse en fréquence d'un filtre analogique.
%   H = FREQS(B,A,W) évalue B(s)/A(s) en s = j*W. Sans W, deux cents
%   points logarithmiques couvrant les pôles et les zéros.
%
%   Exemple :  abs(freqs(1, [1 1], 1))   % 1/sqrt(2), le passe-bas RC
    b = double(b(:)).';
    a = double(a(:)).';
    if nargin < 3 || isempty(w)
        singularites = abs([roots(a); roots(b)]);
        singularites = singularites(singularites > 0);
        if isempty(singularites)
            w = logspace(-1, 1, 200);
        else
            w = logspace(log10(min(singularites) / 10), log10(max(singularites) * 10), 200);
        end
    end
    w = double(w);
    h = polyval(b, 1i * w) ./ polyval(a, 1i * w);
end
