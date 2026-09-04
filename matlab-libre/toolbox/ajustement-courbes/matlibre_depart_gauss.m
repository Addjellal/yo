function depart = matlibre_depart_gauss(x, y, ordre)
%MATLIBRE_DEPART_GAUSS Point de départ d'un ajustement de gaussiennes.
%   D = MATLIBRE_DEPART_GAUSS(X,Y,ORDRE) place une cloche par tranche de
%   l'intervalle : son amplitude est le maximum local, son centre
%   l'abscisse de ce maximum, sa largeur le quart de la tranche.
%
%   Un ajustement non linéaire ne converge que depuis un départ
%   raisonnable ; celui-ci est déduit des données plutôt que tiré au sort,
%   ce qui rend l'ajustement reproductible.
%
%   Exemple :
%      matlibre_depart_gauss((-3:0.1:3)', exp(-(-3:0.1:3)'.^2), 1)
%
%   Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
    x = x(:);
    y = y(:);
    depart = zeros(1, 3 * ordre);
    bornes = linspace(min(x), max(x), ordre + 1);
    etendue = max(x) - min(x);
    for k = 1:ordre
        dedans = x >= bornes(k) & x <= bornes(k + 1);
        if ~any(dedans)
            dedans = true(size(x));
        end
        [amplitude, position] = max(y(dedans));
        abscisses = x(dedans);
        depart(3 * k - 2) = amplitude;
        depart(3 * k - 1) = abscisses(position);
        depart(3 * k) = max(etendue / (4 * ordre), eps);
    end
end
