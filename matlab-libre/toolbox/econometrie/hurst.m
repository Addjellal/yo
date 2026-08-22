function h = hurst(x)
%HURST Exposant de Hurst estimé par l'analyse R/S.
    x = x(:);
    n = numel(x);
    tailles = unique(round(logspace(log10(8), log10(floor(n/2)), 10)));
    logTailles = [];
    logRS = [];
    for t = 1:numel(tailles)
        m = tailles(t);
        blocs = floor(n / m);
        if blocs < 1
            continue;
        end
        valeurs = [];
        for b = 1:blocs
            segment = x((b-1)*m + 1 : b*m);
            ecart = segment - mean(segment);
            cumule = cumsum(ecart);
            R = max(cumule) - min(cumule);
            S = std(segment);
            if S > 0
                valeurs(end+1) = R / S;
            end
        end
        if ~isempty(valeurs)
            logTailles(end+1) = log(m);
            logRS(end+1) = log(mean(valeurs));
        end
    end
    p = polyfit(logTailles, logRS, 1);
    h = p(1);
end
