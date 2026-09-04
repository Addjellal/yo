function [bandes, nombres] = confidenceBands(modele, varargin)
%CONFIDENCEBANDS Convergence d'une mesure de risque avec le nombre de scénarios.
%   [B,N] = CONFIDENCEBANDS(C) rend, pour un nombre croissant de
%   scénarios, l'estimation d'une mesure de risque et son intervalle de
%   confiance. B a trois colonnes : borne basse, estimation, borne haute.
%
%   C'est la façon de savoir combien de scénarios suffisent : quand les
%   bandes se resserrent au-delà de la précision voulue, on peut
%   s'arrêter.
%
%   CONFIDENCEBANDS(...,'RiskMeasure',M) choisit la mesure — 'EL',
%   'Std', 'VaR' ou 'CVaR' —, 'ConfidenceIntervalLevel',A le niveau de
%   l'intervalle (0,95), 'NumPoints',P le nombre de points (100).
%
%   Exemple :
%      [b, n] = confidenceBands(c, 'RiskMeasure', 'VaR');
%      plot(n, b);
%
%   Voir aussi PORTFOLIORISK, RISKCONTRIBUTION, CREDITDEFAULTCOPULA.
    mesure = 'EL';
    niveauIntervalle = 0.95;
    nombrePoints = 100;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'riskmeasure',             mesure = upper(char(varargin{k+1}));
            case 'confidenceintervallevel', niveauIntervalle = varargin{k+1};
            case 'numpoints',               nombrePoints = round(varargin{k+1});
            otherwise
                error('risque:confidenceBands:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if ~matlibre_est_copule(modele) || isempty(modele.PortfolioLosses)
        error('risque:confidenceBands:Modele', ...
              'CONFIDENCEBANDS attend un modèle de crédit déjà simulé.');
    end
    pertes = modele.PortfolioLosses;
    n = numel(pertes);
    nombres = round(linspace(max(round(n / nombrePoints), 30), n, nombrePoints)).';
    bandes = zeros(numel(nombres), 3);
    z = norminv(1 - (1 - niveauIntervalle) / 2);
    for k = 1:numel(nombres)
        m = nombres(k);
        echantillon = pertes(1:m);
        switch mesure
            case 'EL'
                estimation = mean(echantillon);
                marge = z * std(echantillon) / sqrt(m);
            case 'STD'
                estimation = std(echantillon);
                marge = z * estimation / sqrt(2 * (m - 1));
            case 'VAR'
                p = modele.VaRLevel;
                estimation = quantile(echantillon, p);
                triees = sort(echantillon);
                ecartRang = sqrt(m * p * (1 - p));
                bas = max(round(m * p - z * ecartRang), 1);
                haut = min(round(m * p + z * ecartRang), m);
                bandes(k, :) = [triees(bas), estimation, triees(haut)];
                continue
            case 'CVAR'
                seuil = quantile(echantillon, modele.VaRLevel);
                queue = echantillon(echantillon >= seuil);
                estimation = mean(queue);
                marge = z * std(queue) / sqrt(max(numel(queue), 1));
            otherwise
                error('risque:confidenceBands:Mesure', ...
                      'Mesure inconnue : %s.', mesure);
        end
        bandes(k, :) = [estimation - marge, estimation, estimation + marge];
    end
end
