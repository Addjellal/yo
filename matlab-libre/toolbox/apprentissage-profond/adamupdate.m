function [parametres, moyenne, moyenneCarres] = adamupdate(parametres, gradients, ...
        moyenne, moyenneCarres, iteration, pas, inertie, inertieCarres, epsilon)
%ADAMUPDATE Un pas de descente par estimation adaptative des moments.
%   [P,M,V] = ADAMUPDATE(P,G,M,V,K) met à jour les paramètres P d'après
%   les gradients G, en tenant deux moyennes glissantes : celle du
%   gradient, qui lisse la direction, et celle de son carré, qui donne à
%   chaque paramètre son propre pas. Un paramètre dont le gradient est
%   régulièrement grand avance à petits pas, un paramètre au gradient rare
%   avance à grands pas.
%
%   K est le numéro de l'itération, à partir de un. Il sert à corriger le
%   biais des deux moyennes, qui partent de zéro et sous-estiment donc au
%   début.
%
%   [P,M,V] = ADAMUPDATE(P,G,M,V,K,PAS,INERTIE,INERTIECARRES,EPSILON)
%   impose les réglages, dont les valeurs par défaut sont 0,001, 0,9,
%   0,999 et 1e-8.
%
%   P, G, M et V peuvent être un DLARRAY, un tableau de cellules, une
%   structure ou une table de paramètres : la mise à jour parcourt la même
%   forme. Un état vide démarre à zéro.
%
%   Exemple :
%      [p, m, v] = adamupdate(dlarray(1), dlarray(0.5), [], [], 1);
%      extractdata(p)     % 0.999
%
%   Voir aussi SGDMUPDATE, RMSPROPUPDATE, DLGRADIENT, DLFEVAL.
    if nargin < 6 || isempty(pas), pas = 0.001; end
    if nargin < 7 || isempty(inertie), inertie = 0.9; end
    if nargin < 8 || isempty(inertieCarres), inertieCarres = 0.999; end
    if nargin < 9 || isempty(epsilon), epsilon = 1e-8; end
    if isempty(moyenne)
        moyenne = matlibre_dl_zeros_comme(parametres);
    end
    if isempty(moyenneCarres)
        moyenneCarres = matlibre_dl_zeros_comme(parametres);
    end
    correctionMoyenne = 1 - inertie ^ iteration;
    correctionCarres = 1 - inertieCarres ^ iteration;
    [parametres, moyenne, moyenneCarres] = matlibre_dl_combiner( ...
        @(p, g, m, v) pasAdam(p, g, m, v, pas, inertie, inertieCarres, ...
                              epsilon, correctionMoyenne, correctionCarres), ...
        parametres, gradients, moyenne, moyenneCarres);
end

function [p, m, v] = pasAdam(p, g, m, v, pas, inertie, inertieCarres, ...
                             epsilon, correctionMoyenne, correctionCarres)
    vg = matlibre_dl_valeur(g);
    m = inertie * matlibre_dl_valeur(m) + (1 - inertie) * vg;
    v = inertieCarres * matlibre_dl_valeur(v) + (1 - inertieCarres) * vg .^ 2;
    avance = pas * (m / correctionMoyenne) ./ (sqrt(v / correctionCarres) + epsilon);
    p = matlibre_dl_soustraire(p, avance);
end
