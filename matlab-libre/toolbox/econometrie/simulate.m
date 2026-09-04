function [Y, E, V] = simulate(modele, nombre, varargin)
%SIMULATE Tire des trajectoires d'un modèle de série temporelle.
%   Y = SIMULATE(MDL,N) rend une trajectoire de N observations.
%   SIMULATE(...,'NumPaths',K) en rend K, une par colonne.
%   [Y,E,V] = SIMULATE(...) rend aussi les innovations et, pour un modèle
%   GARCH, les variances conditionnelles.
%
%   La trajectoire commence après une période de rodage, assez longue
%   pour que l'effet du départ ait disparu : la série rendue suit la loi
%   stationnaire du modèle.
%
%   Exemple :
%      m = arima('Constant', 0, 'AR', {0.8}, 'Variance', 1);
%      y = simulate(m, 1000);
%      abs(var(y) - 1 / (1 - 0.64)) < 0.5      % variance theorique
%
%   SIMULATE d'un modèle de portefeuille de crédit rend l'objet enrichi
%   de ses scénarios de pertes, que PORTFOLIORISK et RISKCONTRIBUTION
%   exploitent ensuite.
%
%   Voir aussi ARIMA, GARCH, ESTIMATE, FORECAST, INFER,
%   CREDITDEFAULTCOPULA.
    if nargin < 2
        error('econ:simulate:Arguments', ...
              'Il faut dire combien d''observations simuler.');
    end
    if isa(modele, 'creditDefaultCopula') || isa(modele, 'creditMigrationCopula')
        % Un modèle de crédit rend l'objet enrichi de ses scénarios, non
        % une série : c'est lui qui porte ensuite les mesures de risque.
        Y = matlibre_copule_simuler(modele, nombre, varargin{:});
        E = [];
        V = [];
        return
    end
    if isa(modele, 'arima')
        [Y, E] = matlibre_arima_simuler(modele, nombre, varargin{:});
        V = modele.Variance * ones(size(Y));
    elseif isa(modele, 'garch')
        [Y, E, V] = matlibre_garch_simuler(modele, nombre, varargin{:});
    else
        error('econ:simulate:Modele', ...
              ['SIMULATE attend un modèle ARIMA, GARCH ou de portefeuille ' ...
               'de crédit.']);
    end
end
