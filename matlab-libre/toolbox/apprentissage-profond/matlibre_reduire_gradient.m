function g = matlibre_reduire_gradient(g, taille)
%MATLIBRE_REDUIRE_GRADIENT Ramène un gradient à la taille de l'opérande.
%   G = MATLIBRE_REDUIRE_GRADIENT(G,TAILLE) somme le gradient sur les
%   dimensions que la diffusion implicite avait étirées. Quand une
%   opération répète un opérande pour l'apparier à l'autre, chaque copie
%   reçoit sa part de dérivée, et la dérivée de l'opérande d'origine est
%   la somme de ces parts.
%
%   Exemple :
%      matlibre_reduire_gradient(ones(3, 4), [3 1])     % des 4, en 3 par 1
%
%   Voir aussi DLGRADIENT, DLARRAY.
    tailleG = size(g);
    if isequal(tailleG, taille)
        return
    end
    cible = [taille, ones(1, max(0, numel(tailleG) - numel(taille)))];
    for d = 1:numel(tailleG)
        if cible(d) == 1 && tailleG(d) > 1
            g = sum(g, d);
        end
    end
    g = reshape(g, taille);
end
