function valeur = matlibre_garch_logl(obj, libres, parametres, y, depart)
%MATLIBRE_GARCH_LOGL Log-vraisemblance gaussienne d'un GARCH.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    modele = matlibre_garch_poser(obj, libres, parametres);
    if isnan(modele.Offset)
        modele.Offset = mean(y);
    end
    garchs = cell2mat(modele.GARCH);
    archs = cell2mat(modele.ARCH);
    if modele.Constant <= 0 || any(garchs < 0) || any(archs < 0) || ...
       sum(garchs) + sum(archs) >= 1
        valeur = -1e12;
        return
    end
    [variances, innovations] = matlibre_garch_variances(y, modele.Constant, ...
        garchs, archs, modele.Offset, depart);
    if any(variances <= 0)
        valeur = -1e12;
        return
    end
    valeur = -0.5 * sum(log(2 * pi * variances) + innovations .^ 2 ./ variances);
    if ~isfinite(valeur)
        valeur = -1e12;
    end
end
