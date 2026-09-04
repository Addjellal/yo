function bornes = matlibre_intervalle_coefficients(ajustement, niveau)
%MATLIBRE_INTERVALLE_COEFFICIENTS Intervalle de confiance des coefficients.
%   B = MATLIBRE_INTERVALLE_COEFFICIENTS(FO,NIVEAU) rend deux lignes : la
%   borne basse et la borne haute de chaque coefficient.
%
%   La demi-largeur est le quantile de Student aux degrés de liberté du
%   résidu, multiplié par l'écart type du coefficient. C'est la loi de
%   Student et non la normale parce que la variance du bruit est estimée
%   sur les mêmes données.
%
%   Exemple :
%      matlibre_intervalle_coefficients(fit((1:10)', (1:10)', 'poly1'), 0.95)
%
%   Voir aussi CONFINT, PREDINT.
    [covariance, ~] = matlibre_covariance_ajustement(ajustement);
    coefficients = ajustement.Coefficients(:).';
    if isempty(covariance)
        bornes = [coefficients; coefficients];
        bornes(1, :) = -inf;
        bornes(2, :) = inf;
        return
    end
    ecarts = sqrt(max(diag(covariance), 0)).';
    quantile = tinv(1 - (1 - niveau) / 2, ajustement.DDL);
    bornes = [coefficients - quantile * ecarts; coefficients + quantile * ecarts];
end
