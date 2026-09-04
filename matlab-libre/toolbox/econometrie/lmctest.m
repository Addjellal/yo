function [rejet, pValeur, statistique, valeurCritique] = lmctest(serie, varargin)
%LMCTEST Test de stationnarité de Leybourne et McCabe.
%   H = LMCTEST(Y) teste si Y est stationnaire autour d'une tendance. H
%   vaut un quand cette hypothèse est rejetée : la série a une racine
%   unitaire.
%
%   L'hypothèse nulle est la même que celle de KPSSTEST, et la
%   statistique a la même loi limite ; ce qui change est la manière de
%   corriger l'autocorrélation. KPSS l'estime sans modèle, par une
%   moyenne pondérée des covariances ; Leybourne et McCabe ajustent un
%   ARIMA(p,1,1) et lisent la variance de long terme dans les paramètres
%   estimés. Quand le modèle est juste, la correction paramétrique est
%   plus fine et le test plus puissant.
%
%   LMCTEST(...,'Lags',P) donne l'ordre autorégressif du modèle ajusté
%   (zéro par défaut), 'Trend',false enlève la tendance, 'Alpha',A règle
%   le seuil (0,05).
%   [H,P,STAT,CRIT] = LMCTEST(...) rend la valeur p, la statistique et la
%   valeur critique.
%
%   Exemple :
%      lmctest(randn(1, 200))           % 0 : stationnaire
%      lmctest(cumsum(randn(1, 200)))   % 1 : ne l'est pas
%
%   Voir aussi KPSSTEST, ADFTEST, PPTEST, VRATIOTEST.
    serie = double(serie(:));
    n = numel(serie);
    retards = 0;
    avecTendance = true;
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'lags',  retards = round(varargin{k+1});
            case 'trend', avecTendance = logical(varargin{k+1});
            case 'alpha', alpha = varargin{k+1};
            otherwise
                error('econ:lmctest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if retards < 0 || retards >= n - 3
        error('econ:lmctest:Retards', ...
              'Le nombre de retards doit rester entre zéro et %d.', n - 4);
    end
    % Ajustement d'un ARIMA(p,1,1) : sous l'hypothèse nulle la série est
    % stationnaire, donc sa différence a une racine unitaire dans sa
    % partie moyenne mobile ; sous l'alternative, elle ne l'a pas.
    modele = estimate(arima('ARLags', 1:retards, 'D', 1, 'MALags', 1), ...
                      serie, 'Display', 'off');
    phi = zeros(1, retards);
    for j = 1:retards
        phi(j) = modele.AR{j};
    end
    % Filtrage par la partie autorégressive : ce qui reste ne porte plus
    % que la tendance et une moyenne mobile d'ordre un.
    lignes = (retards + 1):n;
    filtre = serie(lignes);
    for j = 1:retards
        filtre = filtre - phi(j) * serie(lignes - j);
    end
    m = numel(filtre);
    if avecTendance
        X = [ones(m, 1), (1:m).'];
    else
        X = ones(m, 1);
    end
    residus = filtre - X * (X \ filtre);
    % La variance qui normalise n'est plus estimée sans modèle comme dans
    % KPSS, mais lue dans l'ajustement : sous l'hypothèse nulle, la série
    % filtrée moins sa tendance est le bruit du modèle, et c'est sa
    % variance qu'il faut.
    variance = modele.Variance;
    if variance <= 0
        variance = eps;
    end
    statistique = sum(cumsum(residus) .^ 2) / (m ^ 2 * variance);
    [pValeur, valeurCritique] = matlibre_kpss_table(statistique, avecTendance, alpha);
    rejet = statistique > valeurCritique;
end
