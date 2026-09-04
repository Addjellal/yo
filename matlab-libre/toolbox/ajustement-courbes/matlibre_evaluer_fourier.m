function y = matlibre_evaluer_fourier(coefficients, x, ordre)
%MATLIBRE_EVALUER_FOURIER Série de Fourier tronquée.
%   Y = MATLIBRE_EVALUER_FOURIER(C,X,ORDRE) évalue la constante suivie
%   des ORDRE harmoniques ; le dernier coefficient est la pulsation
%   fondamentale.
%
%   Exemple :
%      matlibre_evaluer_fourier([0 1 0 1], 0, 1)      % 1
%
%   Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
    x = x(:);
    w = coefficients(end);
    y = coefficients(1) * ones(size(x));
    for k = 1:ordre
        y = y + coefficients(2 * k) * cos(k * w * x) + ...
                coefficients(2 * k + 1) * sin(k * w * x);
    end
end
