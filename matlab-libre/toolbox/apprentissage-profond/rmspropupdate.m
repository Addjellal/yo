function [parametres, moyenneCarres] = rmspropupdate(parametres, gradients, ...
        moyenneCarres, pas, inertieCarres, epsilon)
%RMSPROPUPDATE Un pas de descente à pas normalisé par le gradient récent.
%   [P,V] = RMSPROPUPDATE(P,G,V) divise chaque composante du gradient par
%   la racine de sa moyenne quadratique récente. Chaque paramètre avance
%   ainsi d'un pas comparable, quelle que soit l'échelle de son gradient —
%   ce qui évite d'avoir à régler un pas par couche.
%
%   [P,V] = RMSPROPUPDATE(P,G,V,PAS,INERTIE,EPSILON) impose les réglages ;
%   par défaut, 0,001, 0,9 et 1e-8.
%
%   Exemple :
%      [p, v] = rmspropupdate(dlarray(1), dlarray(0.5), []);
%
%   Voir aussi ADAMUPDATE, SGDMUPDATE.
    if nargin < 4 || isempty(pas), pas = 0.001; end
    if nargin < 5 || isempty(inertieCarres), inertieCarres = 0.9; end
    if nargin < 6 || isempty(epsilon), epsilon = 1e-8; end
    if isempty(moyenneCarres)
        moyenneCarres = matlibre_dl_zeros_comme(parametres);
    end
    [parametres, moyenneCarres] = matlibre_dl_combiner( ...
        @(p, g, v) pasNormalise(p, g, v, pas, inertieCarres, epsilon), ...
        parametres, gradients, moyenneCarres);
end

function [p, v] = pasNormalise(p, g, v, pas, inertieCarres, epsilon)
    vg = matlibre_dl_valeur(g);
    v = inertieCarres * matlibre_dl_valeur(v) + (1 - inertieCarres) * vg .^ 2;
    p = matlibre_dl_soustraire(p, pas * vg ./ (sqrt(v) + epsilon));
end
