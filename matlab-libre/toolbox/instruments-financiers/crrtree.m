function arbre = crrtree(actif, courbe, temps)
%CRRTREE Arbre binomial de Cox, Ross et Rubinstein.
%   A = CRRTREE(ACTIF,COURBE,TEMPS) construit l'arbre des cours à partir
%   du descripteur d'actif, de la courbe de taux et du découpage du
%   temps.
%
%   Chaque nœud a deux successeurs, dont l'un est le successeur bas de
%   l'autre : l'arbre se recombine, et son nombre de nœuds ne croît que
%   comme le carré du nombre de pas.
%
%   Exemple :
%      s = stockspec(0.2, 100);
%      c = intenvset('Rates', 0.05, 'StartDates', '01-Jan-2024', ...
%                    'EndDates', '01-Jan-2025', 'Compounding', -1);
%      a = crrtree(s, c, crrtimespec('01-Jan-2024', '01-Jan-2025', 50));
%
%   Voir aussi CRRTIMESPEC, CRRPRICE, CRRSENS, BINPRICE.
    n = temps.NumPeriods;
    duree = temps.tObs(end);
    dt = duree / n;
    sigma = actif.Sigma(1);
    hausse = exp(sigma * sqrt(dt));
    baisse = 1 / hausse;
    [~, taux, ~, ~, dividende] = matlibre_bls_parametres(courbe, actif, ...
        temps.ValuationDate, temps.Maturity);
    probabilite = (exp((taux - dividende) * dt) - baisse) / (hausse - baisse);
    cours = actif.AssetPrice(1);
    niveaux = cell(1, n + 1);
    for k = 0:n
        rangs = (0:k).';
        niveaux{k + 1} = cours * hausse .^ (k - 2 * rangs);
    end
    arbre = struct('FinObj', 'BinStockTree', 'Method', 'CRR', ...
                   'StockSpec', actif, 'TimeSpec', temps, 'RateSpec', courbe, ...
                   'tObs', temps.tObs, 'dObs', temps.dObs, ...
                   'STree', {niveaux}, 'UpProbs', repmat(probabilite, 1, n), ...
                   'Rate', taux, 'Dividend', dividende, 'Step', dt, ...
                   'Up', hausse, 'Down', baisse);
end
