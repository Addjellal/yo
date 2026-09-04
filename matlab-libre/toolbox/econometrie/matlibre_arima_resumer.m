function matlibre_arima_resumer(modele, information, covariance)
%MATLIBRE_ARIMA_RESUMER Tableau des estimations et de leur précision.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    noms = information.parametres;
    valeurs = information.valeurs(:);
    if isempty(covariance) || any(size(covariance) ~= numel(valeurs))
        ecarts = nan(numel(valeurs), 1);
    else
        diagonale = diag(covariance);
        diagonale(diagonale < 0) = NaN;
        ecarts = sqrt(diagonale);
    end
    fprintf('\n  %s\n\n', matlibre_arima_titre(modele));
    fprintf('  %-14s %12s %12s %10s %10s\n', ...
            'paramètre', 'valeur', 'écart type', 't', 'p');
    for k = 1:numel(valeurs)
        t = valeurs(k) / ecarts(k);
        p = 2 * (1 - normcdf(abs(t)));
        fprintf('  %-14s %12.6g %12.6g %10.4f %10.4f\n', ...
                noms{k}, valeurs(k), ecarts(k), t, p);
    end
    nombre = numel(valeurs);
    [aic, bic] = aicbic(information.logL, nombre, information.observations);
    fprintf('\n  log-vraisemblance %.4f   AIC %.4f   BIC %.4f   %d observations\n\n', ...
            information.logL, aic, bic, information.observations);
end
