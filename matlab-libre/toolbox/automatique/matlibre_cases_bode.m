function [haut, bas] = matlibre_cases_bode()
%MATLIBRE_CASES_BODE Coupe la case courante en deux, pour un Bode.
%   [HAUT,BAS] = MATLIBRE_CASES_BODE() remplace l'axe courant par deux
%   axes qui se partagent sa place : le gain en haut, la phase en bas.
%   C'est ainsi que MATLAB dessine un diagramme de Bode dans une case de
%   SUBPLOT sans déranger les autres.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi BODE, MARGIN, SUBPLOT, AXES.
    place = get(gca, 'Position');
    haut = axes('Position', [place(1), place(2) + place(4) / 2, ...
                             place(3), place(4) / 2]);
    bas = axes('Position', [place(1), place(2), place(3), place(4) / 2]);
end
