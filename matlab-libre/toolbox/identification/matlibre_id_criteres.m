function ajustement = matlibre_id_criteres(ajustementPourcent, residus, np)
%MATLIBRE_ID_CRITERES Le champ Report.Fit de MATLAB : ajustement et critères d'information.
%   F = MATLIBRE_ID_CRITERES(FIT,E,NP) : FIT en pour cent, E les erreurs
%   de prédiction (N échantillons x NY sorties), NP paramètres estimés. La
%   perte V est le déterminant de E'E/N — l'erreur quadratique moyenne pour
%   une sortie. Les formules sont celles de la documentation de MATLAB :
%      FPE  = V (1 + NP/N) / (1 - NP/N)                       (Akaike, 1969)
%      AIC  = N log V + 2 NP + N NY (log(2 pi) + 1)           (Akaike, 1974)
%      AICc = AIC + 2 NP (NP + 1) / (N - NP - 1)
%      nAIC = log V + 2 NP / N
%      BIC  = N log V + N (NY log(2 pi) + 1) + NP log N       (Schwarz, 1978)
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = matlibre_id_criteres(95, 0.1 * randn(300, 1), 4)
%
%   Voir aussi AIC, FPE.
    [N, ny] = size(residus);
    erreur = det(residus.' * residus / N);
    mse = sum(residus(:) .^ 2) / N;
    V = max(erreur, realmin);
    lnV = log(V);
    AIC = N * lnV + 2 * np + N * ny * (log(2 * pi) + 1);
    if N - np - 1 > 0
        AICc = AIC + 2 * np * (np + 1) / (N - np - 1);
    else
        AICc = Inf;
    end
    ajustement = struct('FitPercent', ajustementPourcent, 'LossFcn', erreur, 'MSE', mse, ...
                        'FPE', erreur * (1 + np / N) / max(1 - np / N, eps), ...
                        'AIC', AIC, 'AICc', AICc, 'nAIC', lnV + 2 * np / N, ...
                        'BIC', N * lnV + N * (ny * log(2 * pi) + 1) + np * log(N), ...
                        'nobs', N, 'nparams', np);
end
