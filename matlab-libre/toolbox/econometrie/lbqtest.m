function [rejet, pValeur, statistique, valeurCritique] = lbqtest(residus, varargin)
%LBQTEST Test de Ljung et Box sur l'autocorrélation.
%   H = LBQTEST(R) teste si la série R est du bruit blanc. H vaut un
%   quand l'hypothèse est rejetée : il reste de l'autocorrélation.
%
%   LBQTEST(...,'Lags',L) choisit le nombre de retards examinés (le
%   minimum de vingt et de N-1 par défaut), 'Alpha',A le seuil (0,05),
%   'DOF',D les degrés de liberté — à réduire du nombre de paramètres
%   qu'un ajustement a déjà consommés.
%
%   [H,P,STAT,CRIT] = LBQTEST(...) rend la valeur p, la statistique et la
%   valeur critique.
%
%   La statistique est
%
%      Q = N (N+2) somme_{k=1..L} rho(k)^2 / (N-k),
%
%   qui suit une loi du khi-deux à DOF degrés de liberté sous
%   l'hypothèse de bruit blanc. Le facteur (N+2)/(N-k) corrige le biais
%   de l'autocorrélation empirique aux grands retards, ce que le test de
%   Box et Pierce ne fait pas.
%
%   Exemple :
%      lbqtest(randn(1, 200))         % 0 : du bruit reste du bruit
%      lbqtest(cumsum(randn(1, 200))) % 1 : une marche ne l'est pas
%
%   Voir aussi ARCHTEST, AUTOCORR, ADFTEST, KPSSTEST.
    residus = double(residus(:));
    n = numel(residus);
    retards = min(20, n - 1);
    alpha = 0.05;
    libertes = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'lags',  retards = round(varargin{k+1});
            case 'alpha', alpha = varargin{k+1};
            case 'dof',   libertes = round(varargin{k+1});
            otherwise
                error('econ:lbqtest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(libertes), libertes = retards; end
    if retards < 1 || retards >= n
        error('econ:lbqtest:Retards', ...
              'Le nombre de retards doit rester entre un et %d.', n - 1);
    end
    centre = residus - mean(residus);
    denominateur = sum(centre .^ 2);
    statistique = 0;
    for j = 1:retards
        rho = sum(centre(1:(n - j)) .* centre((1 + j):n)) / denominateur;
        statistique = statistique + rho ^ 2 / (n - j);
    end
    statistique = n * (n + 2) * statistique;
    pValeur = 1 - chi2cdf(statistique, libertes);
    valeurCritique = chi2inv(1 - alpha, libertes);
    rejet = pValeur < alpha;
end
