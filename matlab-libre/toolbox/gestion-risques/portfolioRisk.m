function [risqueGlobal, intervalles] = portfolioRisk(modele, niveaux)
%PORTFOLIORISK Résumé des pertes d'un portefeuille de crédit simulé.
%   R = PORTFOLIORISK(C) rend la perte attendue, son écart type, la valeur
%   en risque et la perte moyenne au-delà, aux quantiles demandés.
%
%   [R,I] = PORTFOLIORISK(...) rend aussi les intervalles de confiance à
%   quatre-vingt-quinze pour cent dus au nombre fini de scénarios : ils
%   disent combien on peut se fier au résultat.
%
%   Exemple :
%      c = simulate(creditDefaultCopula(pd, lgd, ead, poids), 20000);
%      portfolioRisk(c)
%
%   Voir aussi CREDITDEFAULTCOPULA, RISKCONTRIBUTION, CONFIDENCEBANDS.
    if ~matlibre_est_copule(modele)
        error('risque:portfolioRisk:Modele', ...
              'PORTFOLIORISK attend un modèle de portefeuille de crédit.');
    end
    if isempty(modele.PortfolioLosses)
        error('risque:portfolioRisk:Simulation', ...
              'Il faut simuler le modèle avant de mesurer son risque.');
    end
    if nargin < 2 || isempty(niveaux)
        niveaux = modele.VaRLevel;
    end
    niveaux = double(niveaux(:));
    pertes = modele.PortfolioLosses;
    n = numel(pertes);
    perteAttendue = mean(pertes);
    ecartType = std(pertes);
    valeurEnRisque = zeros(numel(niveaux), 1);
    perteConditionnelle = zeros(numel(niveaux), 1);
    for k = 1:numel(niveaux)
        valeurEnRisque(k) = quantile(pertes, niveaux(k));
        queue = pertes(pertes >= valeurEnRisque(k));
        if isempty(queue)
            perteConditionnelle(k) = valeurEnRisque(k);
        else
            perteConditionnelle(k) = mean(queue);
        end
    end
    risqueGlobal = struct('EL', perteAttendue, 'Std', ecartType, ...
                          'VaR', valeurEnRisque, 'CVaR', perteConditionnelle, ...
                          'VaRLevel', niveaux);
    if nargout > 1
        marge = 1.96 * ecartType / sqrt(n);
        intervalles = struct('EL', [perteAttendue - marge, perteAttendue + marge], ...
                             'VaR', zeros(numel(niveaux), 2), ...
                             'CVaR', zeros(numel(niveaux), 2));
        for k = 1:numel(niveaux)
            % L'incertitude sur un quantile se lit sur le rang : le rang
            % du quantile est binomial, et son écart type en découle.
            p = niveaux(k);
            ecartRang = sqrt(n * p * (1 - p));
            triees = sort(pertes);
            bas = max(round(n * p - 1.96 * ecartRang), 1);
            haut = min(round(n * p + 1.96 * ecartRang), n);
            intervalles.VaR(k, :) = [triees(bas), triees(haut)];
            queue = pertes(pertes >= valeurEnRisque(k));
            margeQueue = 1.96 * std(queue) / sqrt(max(numel(queue), 1));
            intervalles.CVaR(k, :) = perteConditionnelle(k) + [-margeQueue, margeQueue];
        end
    end
end
