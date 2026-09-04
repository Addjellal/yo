function y = matlibre_evaluer_sinus(coefficients, x, ordre)
%MATLIBRE_EVALUER_SINUS Somme de sinusoïdes.
%   Y = MATLIBRE_EVALUER_SINUS(C,X,ORDRE) évalue la somme des ORDRE
%   sinusoïdes dont C donne, par groupes de trois, l'amplitude, la
%   pulsation et la phase.
%
%   Exemple :
%      matlibre_evaluer_sinus([1 1 0], pi/2, 1)      % 1
%
%   Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
    x = x(:);
    y = zeros(size(x));
    for k = 1:ordre
        y = y + coefficients(3 * k - 2) * ...
                sin(coefficients(3 * k - 1) * x + coefficients(3 * k));
    end
end
