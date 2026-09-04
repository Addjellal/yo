function y = matlibre_evaluer_gauss(coefficients, x, ordre)
%MATLIBRE_EVALUER_GAUSS Somme de gaussiennes.
%   Y = MATLIBRE_EVALUER_GAUSS(C,X,ORDRE) évalue la somme des ORDRE
%   cloches dont C donne, par groupes de trois, l'amplitude, le centre et
%   la largeur.
%
%   Exemple :
%      matlibre_evaluer_gauss([1 0 1], 0, 1)      % 1
%
%   Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
    x = x(:);
    y = zeros(size(x));
    for k = 1:ordre
        a = coefficients(3 * k - 2);
        b = coefficients(3 * k - 1);
        c = coefficients(3 * k);
        y = y + a * exp(-((x - b) / c) .^ 2);
    end
end
