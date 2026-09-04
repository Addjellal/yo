function [modele, covariance, logL, information] = estimate(specification, y, varargin)
%ESTIMATE Ajuste un modèle de série temporelle à des données.
%   ESTMDL = ESTIMATE(MDL,Y) remplace par leurs estimations les
%   paramètres laissés à NaN dans MDL, et rend le modèle complété. Les
%   paramètres déjà fixés le restent : c'est ainsi qu'on impose une
%   contrainte.
%
%   [ESTMDL,COV,LOGL,INFO] = ESTIMATE(...) rend la covariance des
%   estimations, la log-vraisemblance atteinte et une structure décrivant
%   l'ajustement.
%
%   ESTIMATE(...,'Display','off') n'écrit rien.
%
%   L'ajustement maximise la vraisemblance conditionnelle : les valeurs
%   antérieures au début de l'échantillon sont prises à la moyenne du
%   modèle, et les innovations correspondantes à zéro. La variance du
%   bruit est concentrée hors du critère.
%
%   Exemple :
%      vrai = arima('Constant', 0.5, 'AR', {0.7}, 'Variance', 1);
%      y = simulate(vrai, 800);
%      ajuste = estimate(arima(1, 0, 0), y);
%
%   Voir aussi ARIMA, GARCH, SIMULATE, FORECAST, INFER, SUMMARIZE.
    if isa(specification, 'arima')
        [modele, covariance, logL, information] = ...
            matlibre_arima_estimer(specification, y, varargin{:});
    elseif isa(specification, 'garch')
        [modele, covariance, logL, information] = ...
            matlibre_garch_estimer(specification, y, varargin{:});
    else
        error('econ:estimate:Modele', ...
              'ESTIMATE attend un modèle ARIMA ou GARCH.');
    end
end
