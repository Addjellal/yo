function c = spectralCentroid(x, fs)
%SPECTRALCENTROID Centre de gravité du spectre, en hertz.
%   C = SPECTRALCENTROID(X,FS) rend la moyenne des fréquences pondérée par
%   l'amplitude du spectre. FS vaut un par défaut, auquel cas le résultat
%   est une fréquence réduite.
%
%   C'est le descripteur qui correspond le mieux à la « brillance »
%   perçue d'un son : un son grave a un centroïde bas, un son clair un
%   centroïde haut. Il sert dans presque toute classification de timbre.
%
%   Les repères : le centroïde d'un sinus pur est sa fréquence ; celui
%   d'un bruit blanc tombe au quart de la fréquence d'échantillonnage,
%   c'est-à-dire au milieu de la bande utile.
%
%   Exemple :
%      fs = 8000; t = (0:fs-1) / fs;
%      spectralCentroid(sin(2*pi*1000*t), fs)      % 1000
%      spectralCentroid(randn(1, fs), fs)          % environ fs/4
%
%   Voir aussi DBFS, MFCCSIMPLE, MELFILTERBANK.
    if nargin < 2
        fs = 1;
    end
    x = x(:);
    n = numel(x);
    X = abs(fft(x));
    moitie = floor(n / 2) + 1;
    X = X(1:moitie);
    f = (0:moitie-1).' * fs / n;
    d = sum(X);
    if d == 0
        c = 0;
    else
        c = sum(f .* X) / d;
    end
end
