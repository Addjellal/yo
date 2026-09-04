function psi = matlibre_arima_psi(phi, theta, horizon)
%MATLIBRE_ARIMA_PSI Poids de la représentation en moyenne mobile infinie.
%   PSI(k+1) est le poids de l'innovation de rang t-k dans y(t). Ils
%   donnent d'un coup la variance des erreurs de prévision : celle de la
%   prévision à H pas vaut sigma carré fois la somme des H premiers
%   carrés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    psi = zeros(1, horizon);
    psi(1) = 1;
    p = numel(phi);
    q = numel(theta);
    for k = 1:(horizon - 1)
        valeur = 0;
        if k <= q
            valeur = theta(k);
        end
        for i = 1:min(p, k)
            valeur = valeur + phi(i) * psi(k - i + 1);
        end
        psi(k + 1) = valeur;
    end
end
