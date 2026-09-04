function bornes = matlibre_intervalle_prediction(ajustement, x, niveau, genre, simultane)
%MATLIBRE_INTERVALLE_PREDICTION Bornes de confiance de la courbe ajustée.
%   B = MATLIBRE_INTERVALLE_PREDICTION(FO,X,NIVEAU,GENRE,SIMULTANE) rend
%   deux colonnes : la borne basse et la borne haute en chaque X.
%
%   L'incertitude sur la courbe vient de celle des coefficients,
%   propagée par la jacobienne. L'intervalle d'observation y ajoute la
%   variance du bruit de mesure : il dit où tombera un point à venir, non
%   où passe la courbe.
%
%   L'intervalle simultané est plus large : il vaut d'un coup pour toutes
%   les abscisses, alors que l'intervalle ponctuel ne garantit son niveau
%   qu'en une abscisse fixée d'avance.
%
%   Exemple :
%      fo = fit((1:10)', (1:10)' + 0.1, 'poly1');
%      matlibre_intervalle_prediction(fo, 5, 0.95, 'functional', 'off')
%
%   Voir aussi PREDINT, CONFINT.
    x = double(x(:));
    [covariance, ecartType] = matlibre_covariance_ajustement(ajustement);
    valeurs = feval(ajustement, x);
    if isempty(covariance)
        bornes = [valeurs(:) - inf, valeurs(:) + inf];
        return
    end
    xa = (x - ajustement.Normalisation(1)) / ajustement.Normalisation(2);
    J = matlibre_jacobienne_modele(ajustement.Modele, ajustement.Coefficients, ...
                                   ajustement.Imposees, xa);
    variance = sum((J * covariance) .* J, 2);
    if strcmpi(genre, 'observation')
        variance = variance + ecartType ^ 2;
    end
    nombre = numel(ajustement.Coefficients);
    if strcmpi(simultane, 'on')
        % Borne de Working et Hotelling : elle vaut pour toutes les
        % abscisses a la fois, d'ou le quantile de Fisher a la place de
        % celui de Student.
        facteur = sqrt(nombre * finv(niveau, nombre, ajustement.DDL));
    else
        facteur = tinv(1 - (1 - niveau) / 2, ajustement.DDL);
    end
    demi = facteur * sqrt(max(variance, 0));
    bornes = [valeurs(:) - demi, valeurs(:) + demi];
end
