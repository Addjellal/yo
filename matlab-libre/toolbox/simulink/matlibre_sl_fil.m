function matlibre_sl_fil(depart, arrivee, retour, bas)
%MATLIBRE_SL_FIL Trace une liaison entre deux blocs, à angles droits.
%   MATLIBRE_SL_FIL(DEPART,ARRIVEE) relie le point DEPART au point
%   ARRIVEE par des segments horizontaux et verticaux, et pose une
%   pointe de flèche à l'arrivée.
%
%   MATLIBRE_SL_FIL(DEPART,ARRIVEE,true,BAS) trace un retour de boucle :
%   la liaison descend sous le schéma, à la hauteur BAS, revient vers la
%   gauche, puis remonte. Tracée en ligne droite, elle passerait au
%   travers des blocs qu'elle enjambe.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure;
%      matlibre_sl_fil([0 0], [3 1]);
%
%   Voir aussi OPEN_SYSTEM, MATLIBRE_SL_FORME.
    if nargin < 3, retour = false; end
    if nargin < 4, bas = min(depart(2), arrivee(2)) - 1.5; end
    couleur = [0.15 0.15 0.15];
    if retour
        marge = 0.45;
        xs = [depart(1), depart(1) + marge, depart(1) + marge, ...
              arrivee(1) - marge, arrivee(1) - marge, arrivee(1)];
        ys = [depart(2), depart(2), bas, bas, arrivee(2), arrivee(2)];
    elseif abs(depart(2) - arrivee(2)) < 1e-9
        xs = [depart(1), arrivee(1)];
        ys = [depart(2), arrivee(2)];
    else
        milieu = (depart(1) + arrivee(1)) / 2;
        xs = [depart(1), milieu, milieu, arrivee(1)];
        ys = [depart(2), depart(2), arrivee(2), arrivee(2)];
    end
    line(xs, ys, 'Color', couleur);
    matlibre_sl_pointe(arrivee, couleur);
end
