function critique = matlibre_es_critique(N, p, loi, degres, alpha)
%MATLIBRE_ES_CRITIQUE Quantile de la statistique d'Acerbi et Székely.
%   La loi de la statistique sous l'hypothèse nulle n'a pas de forme
%   fermée ; elle dépend du nombre d'observations, du niveau et de la loi
%   supposée des rendements. Elle est donc simulée — cinq mille tirages,
%   graine fixée, résultat mis en cache pour que les appels suivants aux
%   mêmes paramètres soient immédiats et identiques.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    persistent cache
    if isempty(cache)
        cache = struct('cles', {{}}, 'valeurs', []);
    end
    cle = sprintf('%d|%.10g|%s|%.10g|%.10g', N, p, loi, degres, alpha);
    rang = find(strcmp(cache.cles, cle), 1);
    if ~isempty(rang)
        critique = cache.valeurs(rang);
        return
    end
    etat = rng(20240904);
    reps = 5000;
    if strcmpi(loi, 't')
        quantileVaR = -tinv(p, degres) / sqrt(degres / (degres - 2));
        pertesMoyennes = -matlibre_es_student(p, degres) / sqrt(degres / (degres - 2));
    else
        quantileVaR = -norminv(p);
        pertesMoyennes = exp(-norminv(p) ^ 2 / 2) / (p * sqrt(2 * pi));
    end
    valeurs = zeros(reps, 1);
    for r = 1:reps
        if strcmpi(loi, 't')
            X = trnd(degres, N, 1) / sqrt(degres / (degres - 2));
        else
            X = randn(N, 1);
        end
        depassements = X < -quantileVaR;
        valeurs(r) = sum(X .* depassements) / (N * p * pertesMoyennes) + 1;
    end
    critique = quantile(valeurs, alpha);
    rng(etat);
    cache.cles{end+1} = cle;
    cache.valeurs(end+1) = critique;
end
