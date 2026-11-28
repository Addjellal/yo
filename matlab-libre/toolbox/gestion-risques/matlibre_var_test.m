function resultat = matlibre_var_test(modele, nom, varargin)
%MATLIBRE_VAR_TEST Un test de contrôle a posteriori de la valeur en risque.
%   T = MATLIBRE_VAR_TEST(MODELE,NOM,'TestLevel',NIVEAU) fait le test NOM —
%   'tl', 'bin', 'pof', 'tuff', 'cci', 'cc', 'tbfi' ou 'tbf' — et rend une
%   table d'une ligne aux colonnes de MATLAB : PortfolioID, VaRID,
%   VaRLevel, puis le verdict (accept/reject, ou green/yellow/red pour
%   TL), la statistique et sa valeur p, et les comptes.
%
%   Le feu tricolore suit la documentation de MathWorks : F la loi
%   binomiale des dépassements, vert si F(x) <= 0,95, jaune jusqu'à
%   0,9999, rouge au-delà ; Increase vaut 0 au vert, 1 au rouge, et au
%   jaune 3*(z(niveau annoncé)/z(niveau observé) - 1), borné à [0, 1].
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      r = [-ones(17, 1); zeros(1026, 1)];
%      v = varbacktest(r, 0.5 * ones(1043, 1), 'VaRLevel', 0.99);
%      t = matlibre_var_test(v, 'tl');
%      t.Increase              % 0.26582, l'exemple de MathWorks
%
%   Voir aussi VARBACKTEST, RUNTESTS.
    niveauTest = 0.95;
    for k = 1:2:numel(varargin)
        if k < numel(varargin) && strcmpi(char(varargin{k}), 'testlevel')
            niveauTest = varargin{k + 1};
        end
    end
    [echecs, N, x] = matlibre_var_echecs(modele);
    p = 1 - modele.VaRLevel;
    tete = {string(modele.PortfolioID), string(modele.VaRID), modele.VaRLevel};
    nomsTete = {'PortfolioID', 'VaRID', 'VaRLevel'};
    switch nom
        case 'tl'
            probabilite = binocdf(x, N, p);
            typeI = 1 - binocdf(x - 1, N, p);
            if probabilite <= 0.95
                zone = 'green';
                hausse = 0;
            elseif probabilite <= 0.9999
                zone = 'yellow';
                hausse = 3 * (norminv(modele.VaRLevel) / norminv(1 - x / N) - 1);
                hausse = min(max(hausse, 0), 1);
            else
                zone = 'red';
                hausse = 1;
            end
            feu = categorical({zone}, {'green', 'yellow', 'red'}, 'Ordinal', true);
            resultat = table(tete{:}, feu, probabilite, typeI, hausse, N, x, ...
                'VariableNames', [nomsTete, {'TL', 'Probability', 'TypeI', 'Increase', ...
                                             'Observations', 'Failures'}]);
            return
        case 'bin'
            z = (x - N * p) / sqrt(N * p * (1 - p));
            valeurP = 2 * (1 - normcdf(abs(z)));
            resultat = table(tete{:}, verdict(valeurP < 1 - niveauTest), z, valeurP, N, x, ...
                niveauTest, 'VariableNames', [nomsTete, {'Bin', 'ZScoreBin', 'PValueBin', ...
                'Observations', 'Failures', 'TestLevel'}]);
            return
        case 'pof'
            [lr, pv] = rapport(matlibre_rapport_proportion(x, N, p), 1);
            resultat = table(tete{:}, verdict(pv < 1 - niveauTest), lr, pv, N, x, niveauTest, ...
                'VariableNames', [nomsTete, {'POF', 'LRatioPOF', 'PValuePOF', ...
                'Observations', 'Failures', 'TestLevel'}]);
        case 'tuff'
            premier = find(echecs, 1);
            if isempty(premier)
                statistique = 0;
                premier = NaN;
            else
                statistique = matlibre_rapport_attente(premier, p);
            end
            [lr, pv] = rapport(statistique, 1);
            resultat = table(tete{:}, verdict(pv < 1 - niveauTest), lr, pv, premier, N, x, ...
                niveauTest, 'VariableNames', [nomsTete, {'TUFF', 'LRatioTUFF', 'PValueTUFF', ...
                'TimeToFirstFailure', 'Observations', 'Failures', 'TestLevel'}]);
        case 'cci'
            [statistique, n] = matlibre_rapport_independance(echecs);
            [lr, pv] = rapport(statistique, 1);
            resultat = table(tete{:}, verdict(pv < 1 - niveauTest), lr, pv, N, x, ...
                n(1), n(2), n(3), n(4), niveauTest, 'VariableNames', [nomsTete, {'CCI', ...
                'LRatioCCI', 'PValueCCI', 'Observations', 'Failures', 'N00', 'N10', 'N01', ...
                'N11', 'TestLevel'}]);
        case 'cc'
            [lrPof, pvPof] = rapport(matlibre_rapport_proportion(x, N, p), 1);
            [sCci, n] = matlibre_rapport_independance(echecs);
            [lrCci, pvCci] = rapport(sCci, 1);
            [lr, pv] = rapport(lrPof + lrCci, 2);
            resultat = table(tete{:}, verdict(pv < 1 - niveauTest), lr, pv, ...
                verdict(pvPof < 1 - niveauTest), lrPof, pvPof, ...
                verdict(pvCci < 1 - niveauTest), lrCci, pvCci, N, x, ...
                n(1), n(2), n(3), n(4), niveauTest, 'VariableNames', [nomsTete, {'CC', ...
                'LRatioCC', 'PValueCC', 'POF', 'LRatioPOF', 'PValuePOF', 'CCI', ...
                'LRatioCCI', 'PValueCCI', 'Observations', 'Failures', 'N00', 'N10', ...
                'N01', 'N11', 'TestLevel'}]);
        case 'tbfi'
            [statistique, intervalles] = matlibre_rapport_intervalles(echecs, p);
            [lr, pv] = rapport(statistique, max(x, 1));
            q = quartiles(intervalles);
            resultat = table(tete{:}, verdict(pv < 1 - niveauTest), lr, pv, ...
                q(1), q(2), q(3), q(4), q(5), N, x, niveauTest, 'VariableNames', ...
                [nomsTete, {'TBFI', 'LRatioTBFI', 'PValueTBFI', 'TBFMin', 'TBFQ1', ...
                'TBFQ2', 'TBFQ3', 'TBFMax', 'Observations', 'Failures', 'TestLevel'}]);
        case 'tbf'
            [lrPof, pvPof] = rapport(matlibre_rapport_proportion(x, N, p), 1);
            [sTbfi, intervalles] = matlibre_rapport_intervalles(echecs, p);
            [lrTbfi, pvTbfi] = rapport(sTbfi, max(x, 1));
            [lr, pv] = rapport(lrPof + lrTbfi, max(x, 1) + 1);
            q = quartiles(intervalles);
            resultat = table(tete{:}, verdict(pv < 1 - niveauTest), lr, pv, ...
                verdict(pvPof < 1 - niveauTest), lrPof, pvPof, ...
                verdict(pvTbfi < 1 - niveauTest), lrTbfi, pvTbfi, ...
                q(1), q(2), q(3), q(4), q(5), N, x, niveauTest, 'VariableNames', ...
                [nomsTete, {'TBF', 'LRatioTBF', 'PValueTBF', 'POF', 'LRatioPOF', ...
                'PValuePOF', 'TBFI', 'LRatioTBFI', 'PValueTBFI', 'TBFMin', 'TBFQ1', ...
                'TBFQ2', 'TBFQ3', 'TBFMax', 'Observations', 'Failures', 'TestLevel'}]);
        otherwise
            error('risque:varbacktest:Test', 'Test inconnu : %s.', nom);
    end
end

function [lr, pv] = rapport(statistique, ddl)
%RAPPORT Un rapport de vraisemblance et sa valeur p, loi du khi deux.
    lr = statistique;
    pv = 1 - chi2cdf(statistique, ddl);
end

function v = verdict(rejet)
    if rejet
        v = categorical({'reject'}, {'accept', 'reject'});
    else
        v = categorical({'accept'}, {'accept', 'reject'});
    end
end

function q = quartiles(intervalles)
%QUARTILES Minimum, quartiles et maximum des temps entre dépassements.
    if isempty(intervalles)
        q = nan(1, 5);
        return
    end
    q = [min(intervalles), quantile(intervalles, [0.25 0.5 0.75]), max(intervalles)];
end
