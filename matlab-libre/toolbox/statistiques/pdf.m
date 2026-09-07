function y = pdf(nom, x, varargin)
%PDF Densité ou probabilité d'une loi nommée.
%   Y = PDF('name', X, A, B, C) appelle la fonction de densité de la loi
%   nommée. Les noms suivent MATLAB : 'Normal', 'Poisson', 'Weibull',
%   'Chisquare', 'Discrete Uniform'…, avec leurs abréviations.
%
%   Y = PDF(PD,X) rend la densité d'une loi ajustée par FITDIST : l'objet
%   porte déjà son nom et ses paramètres, qu'il serait inutile — et
%   risqué — de répéter.
%
%   Y = PDF(GM,X) rend la densité d'un mélange gaussien ajusté par
%   FITGMDIST ou décrit par GMDISTRIBUTION.
%
%   Exemples :
%      pdf('Normal', 0, 0, 1)                  % 0.3989
%      pd = fitdist(normrnd(5, 2, 500, 1), 'Normal');
%      abs(pdf(pd, pd.mu) - normpdf(pd.mu, pd.mu, pd.sigma)) < 1e-12
    if isstruct(nom) && isfield(nom, 'type') && strcmp(nom.type, 'melange-gaussien')
        [~, ~, y] = clusterMelange(nom, x);
        return
    end
    [ajustee, nomLoi, parametres] = matlibre_stat_loi_ajustee(nom);
    if ajustee
        y = feval([statPrefixeLoi(nomLoi) 'pdf'], x, parametres{:});
        return
    end
    y = feval([statPrefixeLoi(nom) 'pdf'], x, varargin{:});
end
