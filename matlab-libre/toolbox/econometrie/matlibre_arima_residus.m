function [innovations, ecarts] = matlibre_arima_residus(serie, constante, phi, theta)
%MATLIBRE_ARIMA_RESIDUS Innovations d'un ARMA, par récurrence conditionnelle.
%   Les valeurs antérieures au début de l'échantillon sont prises nulles,
%   en écart à la moyenne du modèle. C'est la vraisemblance dite
%   conditionnelle : elle ne demande ni lissage ni rétroprévision, et
%   l'écart avec la vraisemblance exacte s'efface quand l'échantillon
%   grandit.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    serie = serie(:);
    T = numel(serie);
    p = numel(phi);
    q = numel(theta);
    somme = sum(phi);
    if abs(1 - somme) > 1e-8
        moyenne = constante / (1 - somme);
    else
        moyenne = mean(serie);
    end
    ecarts = serie - moyenne;
    % Partie autorégressive : elle se calcule d'un coup, sans récurrence.
    prevision = zeros(T, 1);
    for i = 1:p
        if phi(i) ~= 0 && i < T
            prevision((i + 1):T) = prevision((i + 1):T) + phi(i) * ecarts(1:(T - i));
        end
    end
    if q == 0
        innovations = ecarts - prevision;
        return
    end
    % Partie moyenne mobile : elle dépend des innovations passées, donc
    % il faut avancer pas à pas.
    innovations = zeros(T, 1);
    for t = 1:T
        cumul = prevision(t);
        for j = 1:min(q, t - 1)
            cumul = cumul + theta(j) * innovations(t - j);
        end
        innovations(t) = ecarts(t) - cumul;
    end
end
