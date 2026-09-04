function [innovations, variances, logL] = infer(modele, y, varargin)
%INFER Retrouve les innovations d'une série sous un modèle donné.
%   E = INFER(MDL,Y) rend les innovations, [E,V,LOGL] rend en plus les
%   variances conditionnelles et la log-vraisemblance.
%
%   C'est l'opération inverse de SIMULATE : là où celui-ci part d'un
%   bruit et construit une série, celui-ci part d'une série et retrouve
%   le bruit qui l'aurait produite. Les résidus obtenus servent aux
%   diagnostics — LBQTEST sur les innovations, ARCHTEST sur leurs carrés.
%
%   Exemple :
%      m = arima('Constant', 0, 'AR', {0.8}, 'Variance', 1);
%      y = simulate(m, 500);
%      e = infer(m, y);
%      lbqtest(e)                     % 0 : les innovations sont blanches
%
%   Voir aussi ARIMA, GARCH, ESTIMATE, SIMULATE, FORECAST, LBQTEST.
    if isa(modele, 'arima')
        [innovations, variances, logL] = matlibre_arima_inferer(modele, y, varargin{:});
    elseif isa(modele, 'garch')
        [innovations, variances, logL] = matlibre_garch_inferer(modele, y, varargin{:});
    else
        error('econ:infer:Modele', ...
              'INFER attend un modèle ARIMA ou GARCH.');
    end
end
