function y = appliquerBande(x, b, a)
%APPLIQUERBANDE Filtrage à phase nulle des fonctions lowpass et voisines.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if numel(a) == 1 && a == 1
        y = filtfilt(b, 1, x);
    else
        y = filtfilt(b, a, x);
    end
end
