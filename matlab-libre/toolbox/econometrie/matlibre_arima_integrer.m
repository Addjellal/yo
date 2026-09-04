function niveaux = matlibre_arima_integrer(previsions, historique, D, saison)
%MATLIBRE_ARIMA_INTEGRER Ramène des prévisions différenciées aux niveaux.
%   HISTORIQUE est la série observée, dans ses unités d'origine ;
%   PREVISIONS sont celles de la série différenciée D fois, et une fois
%   de plus à la période SAISON quand celle-ci est non nulle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    historique = historique(:);
    previsions = previsions(:);
    horizon = numel(previsions);
    % On remonte les différences une à une, de la plus intérieure à la
    % plus extérieure, en prolongeant à chaque fois la série connue.
    courant = previsions;
    for k = D:-1:1
        connu = historique;
        if saison > 0
            connu = connu((saison + 1):end) - connu(1:(end - saison));
        end
        for j = 1:(k - 1)
            connu = diff(connu);
        end
        dernier = connu(end);
        courant = dernier + cumsum(courant);
    end
    if saison > 0
        niveaux = zeros(horizon, 1);
        n = numel(historique);
        for h = 1:horizon
            indice = n + h - saison;
            if indice <= n
                base = historique(indice);
            else
                base = niveaux(indice - n);
            end
            niveaux(h) = base + courant(h);
        end
    else
        niveaux = courant;
    end
end
