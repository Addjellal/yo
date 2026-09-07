function y = appliquerBande(x, b, a)
%APPLIQUERBANDE Filtrage à phase nulle des fonctions lowpass et voisines.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      rng(1);
%      t = (0:255)' / 256;
%      y = appliquerBande(sin(2*pi*5*t) + 0.5*sin(2*pi*90*t), b, a);
%      rms(y - sin(2*pi*5*t)) < 0.3
%
%   Voir aussi LOWPASS, CONCEVOIRBANDE.
    if numel(a) == 1 && a == 1
        y = filtfilt(b, 1, x);
    else
        y = filtfilt(b, a, x);
    end
end
