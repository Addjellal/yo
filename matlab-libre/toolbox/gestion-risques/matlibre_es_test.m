function resultat = matlibre_es_test(modele, loi, degres, varargin)
%MATLIBRE_ES_TEST Test d'Acerbi et Székely sur la perte moyenne au-delà.
%   La statistique compare la somme des pertes dépassantes à ce que le
%   modèle annonçait ; elle vaut zéro en moyenne sous l'hypothèse nulle,
%   et devient négative quand les dépassements coûtent plus cher que
%   prévu.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    niveauTest = 0.95;
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'testlevel')
            niveauTest = varargin{k+1};
        end
        k = k + 2;
    end
    X = modele.PortfolioData;
    N = numel(X);
    p = 1 - modele.VaRLevel;
    depassements = X < -modele.VaRData;
    statistique = sum(X .* depassements ./ (N * p * modele.ESData)) + 1;
    critique = matlibre_es_critique(N, p, loi, degres, 1 - niveauTest);
    resultat = struct('PortfolioID', modele.PortfolioID, 'VaRID', modele.VaRID, ...
                      'VaRLevel', modele.VaRLevel, 'TestLevel', niveauTest, ...
                      'N', N, 'Failures', sum(depassements), ...
                      'Expected', p * N, 'Distribution', loi, ...
                      'ZScore', statistique, 'CriticalValue', critique, ...
                      'TestResult', matlibre_verdict(statistique < critique));
end
