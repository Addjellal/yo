function [Y, variances] = matlibre_arima_prevoir(obj, horizon, varargin)
%MATLIBRE_ARIMA_PREVOIR Prévision et variance de l'erreur de prévision.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    historique = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'y0', historique = double(varargin{k+1});
            case 'e0'  % les innovations sont retrouvées par la récurrence
            otherwise
                error('econ:arima:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    modele = matlibre_arima_verifier(obj);
    [phi, theta, phiNiveaux] = matlibre_arima_polynomes(modele);
    if isempty(historique)
        error('econ:arima:Historique', ...
              'FORECAST demande la série observée, passée par ''Y0''.');
    end
    if size(historique, 1) == 1
        historique = historique.';
    end
    chemins = size(historique, 2);
    Y = zeros(horizon, chemins);
    somme = sum(phi);
    moyenne = modele.Constant / (1 - somme);
    p = numel(phi);
    q = numel(theta);
    for c = 1:chemins
        colonne = historique(:, c);
        serie = matlibre_arima_differencier(colonne, modele.D, modele.Seasonality);
        innovations = matlibre_arima_residus(serie, modele.Constant, phi, theta);
        ecarts = serie - moyenne;
        prolonge = [ecarts; zeros(horizon, 1)];
        bruits = [innovations; zeros(horizon, 1)];
        n = numel(ecarts);
        for h = 1:horizon
            t = n + h;
            valeur = 0;
            for i = 1:min(p, t - 1)
                valeur = valeur + phi(i) * prolonge(t - i);
            end
            for j = 1:min(q, t - 1)
                valeur = valeur + theta(j) * bruits(t - j);
            end
            prolonge(t) = valeur;
        end
        previsions = moyenne + prolonge((n + 1):(n + horizon));
        if modele.D > 0 || modele.Seasonality > 0
            Y(:, c) = matlibre_arima_integrer(previsions, colonne, ...
                                              modele.D, modele.Seasonality);
        else
            Y(:, c) = previsions;
        end
    end
    % La variance de l'erreur de prévision se lit sur les poids de la
    % représentation en moyenne mobile infinie du modèle de niveau : la
    % différenciation en fait partie, ce qui explique qu'elle croisse
    % sans borne quand la série est intégrée.
    psi = matlibre_arima_psi(phiNiveaux, theta, horizon);
    variances = modele.Variance * cumsum(psi .^ 2).';
    if chemins > 1
        variances = repmat(variances, 1, chemins);
    end
end
