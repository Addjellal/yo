function k = signalSommet(S, autour, rayon)
%SIGNALSOMMET Indice du maximum local le plus proche de AUTOUR.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = numel(S);
    debut = max(1, autour - rayon);
    fin = min(n, autour + rayon);
    if debut > fin
        k = min(n, max(1, autour));
        return
    end
    [~, decalage] = max(S(debut:fin));
    k = debut + decalage - 1;
end
