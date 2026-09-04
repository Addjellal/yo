function [coefficients, deviance, statistiques] = glmfit(X, y, loi, varargin)
%GLMFIT Ajustement d'un modèle linéaire généralisé.
%   B = GLMFIT(X,Y,LOI) rend les coefficients, l'ordonnée à l'origine en
%   première position. LOI vaut 'normal', 'binomial', 'poisson', 'gamma'
%   ou 'inverse gaussian'.
%
%   [B,DEV,STATS] = GLMFIT(...) rend la déviance et une structure portant
%   les écarts types, les statistiques t et les valeurs p.
%
%   GLMFIT(...,'link',L) change la fonction de lien, 'constant','off'
%   retire l'ordonnée à l'origine, 'weights',W pondère les observations.
%
%   C'est l'interface historique ; FITGLM rend un modèle complet.
%
%   Exemple :
%      b = glmfit(X, y, 'binomial');
%      p = glmval(b, X, 'logit');
%
%   Voir aussi GLMVAL, FITGLM, FITLM, MNRFIT.
    if nargin < 3 || isempty(loi)
        loi = 'normal';
    end
    options = {'Distribution', char(loi)};
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'link',     options = [options, {'Link', varargin{k+1}}];   %#ok<AGROW>
            case 'weights',  options = [options, {'Weights', varargin{k+1}}]; %#ok<AGROW>
            case 'constant'
                options = [options, {'Intercept', ...
                    ~strcmpi(char(varargin{k+1}), 'off')}];                   %#ok<AGROW>
            otherwise
                error('stats:glmfit:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    modele = fitglm(X, y, options{:});
    coefficients = modele.Coefficients(:);
    deviance = modele.Deviance;
    statistiques = struct('beta', coefficients, 'se', modele.SE(:), ...
                          't', modele.tStat(:), 'p', modele.pValue(:), ...
                          'dfe', numel(y) - numel(coefficients), ...
                          'resid', modele.Residuals(:), ...
                          'deviance', deviance);
end
