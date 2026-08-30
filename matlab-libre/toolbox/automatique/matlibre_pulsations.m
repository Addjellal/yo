function w = matlibre_pulsations(sys, points)
%MATLIBRE_PULSATIONS Grille de pulsations automatique d'un modèle.
%   W = MATLIBRE_PULSATIONS(SYS) rend deux cents pulsations
%   logarithmiquement espacées, centrées sur la moyenne géométrique des
%   pôles et des zéros non nuls du modèle et couvrant deux décades de
%   part et d'autre. C'est la grille que choisissent BODE, SIGMA et
%   NYQUIST quand l'appelant n'en donne pas.
%
%   W = MATLIBRE_PULSATIONS(SYS,N) en rend N.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi BODE, LOGSPACE.
    if nargin < 2 || isempty(points)
        points = 200;
    end
    g = tf(sys);
    p = [roots(g.den); roots(g.num)];
    p = p(abs(p) > 1e-9);
    if isempty(p)
        centre = 1;
    else
        centre = exp(mean(log(abs(p))));
    end
    w = logspace(log10(centre / 100), log10(centre * 100), points).';
end
