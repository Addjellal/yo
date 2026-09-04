function depart = matlibre_arima_depart(obj, serie, libres)
%MATLIBRE_ARIMA_DEPART Point de départ de l'optimisation.
%   La partie autorégressive part d'un ajustement de Yule-Walker, la
%   partie moyenne mobile de zéro, et la constante de ce qui reproduit la
%   moyenne observée. Un mauvais départ ne fausse pas le résultat mais
%   coûte des itérations, et peut faire tomber dans un minimum local.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    depart = zeros(1, numel(libres));
    ordreAR = 0;
    for k = 1:numel(libres)
        if strcmp(libres{k}.champ, 'AR')
            ordreAR = max(ordreAR, obj.ARLags(libres{k}.indice));
        end
    end
    coefficientsAR = [];
    if ordreAR > 0 && numel(serie) > 3 * ordreAR
        coefficientsAR = arfit(serie, ordreAR);
        coefficientsAR = coefficientsAR(:).';
        if max(abs(roots([1, -coefficientsAR]))) > 0.95
            coefficientsAR = 0.5 * coefficientsAR / max(abs(coefficientsAR));
        end
    end
    for k = 1:numel(libres)
        switch libres{k}.champ
            case 'Constant'
                if isempty(coefficientsAR)
                    depart(k) = mean(serie);
                else
                    depart(k) = mean(serie) * (1 - sum(coefficientsAR));
                end
            case 'AR'
                retard = obj.ARLags(libres{k}.indice);
                if retard <= numel(coefficientsAR)
                    depart(k) = coefficientsAR(retard);
                else
                    depart(k) = 0;
                end
            otherwise
                depart(k) = 0;
        end
    end
end
