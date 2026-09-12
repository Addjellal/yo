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
%   Le contournement sert aussi quand la cible n'est pas devant la
%   source, retour ou non : un bloc déplacé à la souris peut se retrouver
%   derrière celui qui l'alimente, et une liaison directe reviendrait
%   alors sur ses pas, la pointe de flèche pointant à l'envers.
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
    marge = 0.45;
    % Un fil sort toujours par la droite et entre toujours par la gauche :
    % c'est ce qui donne son sens à la pointe de flèche. Il faut donc de
    % la place devant la source ; s'il n'y en a pas — parce que la cible
    % est derrière elle, ce qu'un bloc déplacé à la souris rend courant —,
    % le fil contourne par un couloir plutôt que de revenir sur ses pas.
    devant = arrivee(1) - marge >= depart(1) + marge;
    if retour || ~devant
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
