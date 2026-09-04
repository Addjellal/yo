function matlibre_arima_afficher(obj)
%MATLIBRE_ARIMA_AFFICHER Écrit le modèle sous une forme lisible.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(obj.Description)
        fprintf('  ARIMA(%d,%d,%d)\n', ...
                nombreRetards(obj.ARLags), obj.D, nombreRetards(obj.MALags));
    else
        fprintf('  %s\n', obj.Description);
    end
    fprintf('    Distribution : %s\n', matlibre_texte_loi(obj.Distribution));
    fprintf('    P = %d, D = %d, Q = %d\n', obj.P, obj.D, obj.Q);
    fprintf('    Constant = %s\n', matlibre_texte_nombre(obj.Constant));
    ecrireListe('AR', obj.ARLags, obj.AR);
    ecrireListe('SAR', obj.SARLags, obj.SAR);
    ecrireListe('MA', obj.MALags, obj.MA);
    ecrireListe('SMA', obj.SMALags, obj.SMA);
    if obj.Seasonality > 0
        fprintf('    Seasonality = %d\n', obj.Seasonality);
    end
    fprintf('    Variance = %s\n', matlibre_texte_nombre(obj.Variance));
end

function n = nombreRetards(retards)
    if isempty(retards)
        n = 0;
    else
        n = max(retards);
    end
end

function ecrireListe(nom, retards, coefficients)
    if isempty(retards)
        return
    end
    morceaux = cell(1, numel(retards));
    for k = 1:numel(retards)
        morceaux{k} = sprintf('{%d: %s}', retards(k), ...
                              matlibre_texte_nombre(coefficients{k}));
    end
    fprintf('    %s = %s\n', nom, strjoin(morceaux, ' '));
end
