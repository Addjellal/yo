function [puissance, plage] = signalLobe(S, k)
%SIGNALLOBE Puissance d'un lobe spectral autour de la raie K.
%   On somme de part et d'autre du sommet tant que le spectre décroît :
%   la fuite de la fenêtre est ainsi ramassée avec la raie.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = numel(S);
    k = max(1, min(n, k));
    gauche = k;
    while gauche > 1 && S(gauche - 1) < S(gauche)
        gauche = gauche - 1;
    end
    droite = k;
    while droite < n && S(droite + 1) < S(droite)
        droite = droite + 1;
    end
    plage = gauche:droite;
    puissance = sum(S(plage));
end
