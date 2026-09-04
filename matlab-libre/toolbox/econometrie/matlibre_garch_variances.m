function [variances, innovations] = matlibre_garch_variances(y, constante, garchs, archs, offset, depart)
%MATLIBRE_GARCH_VARIANCES Récurrence de la variance conditionnelle.
%   GARCHS et ARCHS sont les coefficients rangés retard par retard. Les
%   valeurs antérieures au début de l'échantillon prennent DEPART, en
%   général la variance empirique de la série.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    y = y(:);
    T = numel(y);
    innovations = y - offset;
    carres = innovations .^ 2;
    p = numel(garchs);
    q = numel(archs);
    variances = zeros(T, 1);
    for t = 1:T
        valeur = constante;
        for i = 1:p
            if t - i >= 1
                valeur = valeur + garchs(i) * variances(t - i);
            else
                valeur = valeur + garchs(i) * depart;
            end
        end
        for j = 1:q
            if t - j >= 1
                valeur = valeur + archs(j) * carres(t - j);
            else
                valeur = valeur + archs(j) * depart;
            end
        end
        variances(t) = valeur;
    end
end
