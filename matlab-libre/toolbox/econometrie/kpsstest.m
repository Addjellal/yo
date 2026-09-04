function [rejet, pValeur, statistique, valeurCritique] = kpsstest(serie, varargin)
%KPSSTEST Test de stationnarité de Kwiatkowski, Phillips, Schmidt et Shin.
%   H = KPSSTEST(Y) teste si Y est stationnaire. H vaut un quand
%   l'hypothèse de stationnarité est rejetée : la série a une racine
%   unitaire.
%
%   L'hypothèse nulle est ici la stationnarité, à l'inverse d'ADFTEST où
%   c'est la racine unitaire. Les deux se complètent : conclure demande
%   souvent de les faire tous les deux.
%
%   KPSSTEST(...,'Lags',L) choisit la fenêtre de la variance de long
%   terme, 'Trend',false enlève la tendance du modèle, 'Alpha',A règle le
%   seuil (0,05).
%   [H,P,STAT,CRIT] = KPSSTEST(...) rend la valeur p, la statistique et
%   la valeur critique.
%
%   La statistique est la somme des carrés des résidus cumulés, divisée
%   par le carré du nombre d'observations et par la variance de long
%   terme estimée à la Newey-West.
%
%   Exemple :
%      kpsstest(randn(1, 200))        % 0 : stationnaire
%      kpsstest(cumsum(randn(1, 200)))  % 1 : ne l'est pas
%
%   Voir aussi ADFTEST, PPTEST, LMCTEST, VRATIOTEST.
    serie = double(serie(:));
    n = numel(serie);
    retards = max(1, floor(4 * (n / 100) ^ 0.25));
    avecTendance = true;
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'lags',  retards = round(varargin{k+1});
            case 'trend', avecTendance = logical(varargin{k+1});
            case 'alpha', alpha = varargin{k+1};
            otherwise
                error('econ:kpsstest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    % Résidus de la régression sur une constante, plus une tendance si
    % on la demande.
    if avecTendance
        X = [ones(n, 1), (1:n).'];
    else
        X = ones(n, 1);
    end
    residus = serie - X * (X \ serie);
    cumules = cumsum(residus);
    varianceLongTerme = matlibre_newey_west(residus, retards);
    if varianceLongTerme <= 0
        varianceLongTerme = eps;
    end
    statistique = sum(cumules .^ 2) / (n ^ 2 * varianceLongTerme);
    [pValeur, valeurCritique] = matlibre_kpss_table(statistique, avecTendance, alpha);
    rejet = statistique > valeurCritique;
end
