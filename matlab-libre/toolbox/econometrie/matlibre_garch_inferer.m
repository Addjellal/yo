function [innovations, variances, logL] = matlibre_garch_inferer(obj, y)
%MATLIBRE_GARCH_INFERER Innovations et variances d'une série observée.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    modele = matlibre_garch_verifier(obj);
    y = double(y);
    if size(y, 1) == 1
        y = y.';
    end
    chemins = size(y, 2);
    T = size(y, 1);
    innovations = zeros(T, chemins);
    variances = zeros(T, chemins);
    logL = zeros(1, chemins);
    for c = 1:chemins
        depart = var(y(:, c) - modele.Offset);
        [v, e] = matlibre_garch_variances(y(:, c), modele.Constant, ...
            cell2mat(modele.GARCH), cell2mat(modele.ARCH), modele.Offset, depart);
        innovations(:, c) = e;
        variances(:, c) = v;
        logL(c) = -0.5 * sum(log(2 * pi * v) + e .^ 2 ./ v);
    end
    if chemins == 1
        logL = logL(1);
    end
end
