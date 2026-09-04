function [contributions, total] = matlibre_contribution_credit(modele)
%MATLIBRE_CONTRIBUTION_CREDIT Décomposition des pertes par contrepartie.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(modele.Losses)
        error('risque:contribution:Simulation', ...
              'Il faut simuler le modèle avant de décomposer son risque.');
    end
    pertes = modele.Losses;
    portefeuille = modele.PortfolioLosses;
    n = numel(portefeuille);
    niveau = modele.VaRLevel;
    perteAttendue = mean(pertes, 1).';
    ecartTotal = std(portefeuille);
    if ecartTotal > 0
        centrees = pertes - repmat(mean(pertes, 1), n, 1);
        ecartPart = (centrees.' * (portefeuille - mean(portefeuille))) / ...
                    ((n - 1) * ecartTotal);
    else
        ecartPart = zeros(size(perteAttendue));
    end
    seuil = quantile(portefeuille, niveau);
    % Fenêtre autour du quantile : assez large pour contenir des
    % scénarios, assez étroite pour rester le quantile.
    largeur = max(round(0.01 * n), 1);
    [~, ordre] = sort(portefeuille);
    rang = max(min(round(niveau * n), n), 1);
    fenetre = ordre(max(rang - largeur, 1):min(rang + largeur, n));
    partVaR = mean(pertes(fenetre, :), 1).';
    if sum(partVaR) > 0
        partVaR = partVaR * seuil / sum(partVaR);
    end
    queue = portefeuille >= seuil;
    if any(queue)
        partCVaR = mean(pertes(queue, :), 1).';
    else
        partCVaR = partVaR;
    end
    contributions = struct('EL', perteAttendue, 'Std', ecartPart, ...
                           'VaR', partVaR, 'CVaR', partCVaR);
    total = struct('EL', sum(perteAttendue), 'Std', ecartTotal, ...
                   'VaR', seuil, 'CVaR', sum(partCVaR));
end
