function [Y, variances] = forecast(modele, horizon, varargin)
%FORECAST Prolonge une série observée par le modèle.
%   [Y,YMSE] = FORECAST(MDL,H,DONNEES) rend la prévision à H pas et la
%   variance de l'erreur de prévision, pas par pas. La série observée
%   peut aussi se donner par le couple 'Y0',DONNEES.
%
%   La prévision optimale au sens de l'erreur quadratique est
%   l'espérance conditionnelle : on prolonge la récurrence du modèle en
%   posant les innovations à venir à zéro. La variance de l'erreur se lit
%   sur les poids de la représentation en moyenne mobile infinie ; elle
%   croît avec l'horizon et tend, pour un modèle stationnaire, vers la
%   variance de la série.
%
%   Exemple :
%      m = arima('Constant', 0, 'AR', {0.8}, 'Variance', 1);
%      y = simulate(m, 200);
%      [p, e] = forecast(m, 10, y);
%      [p, e] = forecast(m, 10, 'Y0', y);      % la meme chose
%
%   Voir aussi ARIMA, GARCH, ESTIMATE, SIMULATE, INFER.
    % La série peut venir en troisième argument, comme dans MATLAB, ou
    % par le couple 'Y0',DONNEES : les deux formes se rencontrent.
    if ~isempty(varargin) && isnumeric(varargin{1})
        varargin = [{'Y0'}, varargin];
    end
    if isa(modele, 'arima')
        [Y, variances] = matlibre_arima_prevoir(modele, horizon, varargin{:});
    elseif isa(modele, 'garch')
        [Y, variances] = matlibre_garch_prevoir(modele, horizon, varargin{:});
    else
        error('econ:forecast:Modele', ...
              'FORECAST attend un modèle ARIMA ou GARCH.');
    end
end
