function resultat = matlibre_var_test(modele, nom, varargin)
%MATLIBRE_VAR_TEST Un test de contrôle a posteriori de la valeur en risque.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    niveauTest = 0.95;
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'testlevel')
            niveauTest = varargin{k+1};
        end
        k = k + 2;
    end
    [echecs, N, x, attendu] = matlibre_var_echecs(modele);
    p = 1 - modele.VaRLevel;
    resultat = struct('PortfolioID', modele.PortfolioID, 'VaRID', modele.VaRID, ...
                      'VaRLevel', modele.VaRLevel, 'ObservedLevel', 1 - x / N, ...
                      'N', N, 'Failures', x, 'Expected', attendu, ...
                      'TestLevel', niveauTest);
    switch nom
        case 'tl'
            % Feu de Bâle : la couleur suit la répartition binomiale du
            % nombre de dépassements.
            probabilite = matlibre_binomiale_cumulee(x, N, p);
            if probabilite < 0.95
                zone = 'green';
            elseif probabilite < 0.9999
                zone = 'yellow';
            else
                zone = 'red';
            end
            resultat.TL = zone;
            resultat.Probability = probabilite;
            % Facteur de majoration du capital, tel que le prescrit Bâle.
            resultat.Increase = matlibre_majoration_bale(x, N, p);
            return
        case 'bin'
            ecart = sqrt(N * p * (1 - p));
            statistique = (x - N * p) / ecart;
            valeurP = 2 * (1 - normcdf(abs(statistique)));
            critique = norminv(1 - (1 - niveauTest) / 2);
            resultat.TestStatistic = statistique;
            resultat.PValue = valeurP;
            resultat.CriticalValue = critique;
            resultat.TestResult = matlibre_verdict(valeurP < 1 - niveauTest);
            return
        case 'pof'
            statistique = matlibre_rapport_proportion(x, N, p);
            ddl = 1;
        case 'tuff'
            premier = find(echecs, 1);
            if isempty(premier)
                statistique = 0;
            else
                statistique = matlibre_rapport_attente(premier, p);
            end
            ddl = 1;
        case 'cci'
            statistique = matlibre_rapport_independance(echecs);
            ddl = 1;
        case 'cc'
            statistique = matlibre_rapport_proportion(x, N, p) + ...
                          matlibre_rapport_independance(echecs);
            ddl = 2;
        case 'tbfi'
            statistique = matlibre_rapport_intervalles(echecs, p);
            ddl = max(x, 1);
        case 'tbf'
            statistique = matlibre_rapport_proportion(x, N, p) + ...
                          matlibre_rapport_intervalles(echecs, p);
            ddl = max(x, 1) + 1;
        otherwise
            error('risque:varbacktest:Test', 'Test inconnu : %s.', nom);
    end
    valeurP = 1 - chi2cdf(statistique, ddl);
    critique = chi2inv(niveauTest, ddl);
    resultat.LRatio = statistique;
    resultat.PValue = valeurP;
    resultat.CriticalValue = critique;
    resultat.TestResult = matlibre_verdict(statistique > critique);
end
