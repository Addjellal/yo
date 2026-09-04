function [noeuds, ordre, coefs] = matlibre_bspline_deriver(noeuds, ordre, coefs)
%MATLIBRE_BSPLINE_DERIVER Dérivée d'une spline en B-forme.
%   [N,O,C] = MATLIBRE_BSPLINE_DERIVER(NOEUDS,ORDRE,COEFS) rend la
%   B-forme de la dérivée : l'ordre baisse d'un, les nœuds extrêmes
%   tombent, et les coefficients sont les différences divisées des
%   anciens.
%
%   Exemple :
%      [n, o, c] = matlibre_bspline_deriver([0 0 0 1 2 2 2], 3, [0 1 2 3]);
%
%   Voir aussi MATLIBRE_BSPLINE_VERS_PP, FNDER.
    coefs = double(coefs(:)).';
    nombre = numel(coefs);
    if ordre <= 1 || nombre <= 1
        noeuds = noeuds(2:(end - 1));
        ordre = 1;
        coefs = zeros(1, max(numel(noeuds) - 1, 1));
        return
    end
    nouveaux = zeros(1, nombre - 1);
    for i = 1:(nombre - 1)
        largeur = noeuds(i + ordre) - noeuds(i + 1);
        if largeur > 0
            nouveaux(i) = (ordre - 1) * (coefs(i + 1) - coefs(i)) / largeur;
        end
    end
    noeuds = noeuds(2:(end - 1));
    ordre = ordre - 1;
    coefs = nouveaux;
end
