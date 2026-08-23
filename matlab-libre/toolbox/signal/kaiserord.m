function [n, Wn, beta, genre] = kaiserord(f, a, ondulation, fs)
%KAISERORD Ordre et paramètre d'un filtre RIF fenêtré par Kaiser.
%   [N,WN,BETA,GENRE] = KAISERORD(F,A,DEV,FS) applique les formules de
%   Kaiser : BETA dépend de l'atténuation demandée, et N de la largeur de
%   la bande de transition.
%
%   Exemple :
%      [n, Wn, beta] = kaiserord([1000 1200], [1 0], [0.05 0.01], 8000);
    if nargin < 4 || isempty(fs), fs = 2; end
    f = f(:).';
    a = a(:).';
    ondulation = ondulation(:).';
    dev = min(ondulation);
    attenuation = -20 * log10(dev);
    if attenuation > 50
        beta = 0.1102 * (attenuation - 8.7);
    elseif attenuation >= 21
        beta = 0.5842 * (attenuation - 21)^0.4 + 0.07886 * (attenuation - 21);
    else
        beta = 0;
    end
    largeur = 2 * pi * (f(2) - f(1)) / fs;
    n = ceil((attenuation - 8) / (2.285 * largeur));
    Wn = (f(1) + f(2)) / fs;
    if a(1) > a(end)
        genre = 'low';
    else
        genre = 'high';
    end
end
