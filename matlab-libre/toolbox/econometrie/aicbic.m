function [aic, bic] = aicbic(logVraisemblance, nombreParametres, nombreObservations)
%AICBIC Critères d'information d'Akaike et de Schwarz.
%   [AIC,BIC] = AICBIC(LOGL,NUMPARAM,NUMOBS) rend
%
%      AIC = -2 LOGL + 2 NUMPARAM,
%      BIC = -2 LOGL + NUMPARAM log(NUMOBS).
%
%   Les deux pèsent l'ajustement contre le nombre de paramètres : entre
%   deux modèles, on garde celui dont le critère est le plus petit. Le
%   critère de Schwarz punit plus durement, et choisit donc des modèles
%   plus simples dès que les observations se comptent par centaines.
%
%   LOGL et NUMPARAM peuvent être des vecteurs : on compare alors
%   plusieurs modèles d'un coup.
%
%   Exemple :
%      [aic, bic] = aicbic([-100 -95], [2 5], 100);
%      % le second ajuste mieux, mais coûte trois paramètres
%
%   Voir aussi ARFIT, OLS, LRATIOTEST, FITLM.
    logVraisemblance = double(logVraisemblance(:)).';
    nombreParametres = double(nombreParametres(:)).';
    if numel(nombreParametres) == 1
        nombreParametres = repmat(nombreParametres, size(logVraisemblance));
    end
    if numel(logVraisemblance) ~= numel(nombreParametres)
        error('econ:aicbic:Tailles', ...
              'Il faut autant de comptes de paramètres que de vraisemblances.');
    end
    aic = -2 * logVraisemblance + 2 * nombreParametres;
    if nargout > 1
        if nargin < 3 || isempty(nombreObservations)
            error('econ:aicbic:Observations', ...
                  'Le critère de Schwarz demande le nombre d''observations.');
        end
        bic = -2 * logVraisemblance + nombreParametres * log(nombreObservations);
    end
end
