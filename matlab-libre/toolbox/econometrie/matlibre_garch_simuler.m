function [Y, E, V] = matlibre_garch_simuler(obj, nombre, varargin)
%MATLIBRE_GARCH_SIMULER Trajectoires d'un processus à variance changeante.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    chemins = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'numpaths', chemins = round(varargin{k+1});
            otherwise
                error('econ:garch:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    modele = matlibre_garch_verifier(obj);
    garchs = cell2mat(modele.GARCH);
    archs = cell2mat(modele.ARCH);
    persistance = sum(garchs) + sum(archs);
    if persistance >= 1
        error('econ:garch:Stationnarite', ...
              ['La somme des coefficients vaut %.4f : la variance ' ...
               'n''a pas de valeur de long terme.'], persistance);
    end
    longTerme = modele.Constant / (1 - persistance);
    p = numel(garchs);
    q = numel(archs);
    rodage = max(100, 20 * (p + q + 1));
    total = rodage + nombre;
    Y = zeros(nombre, chemins);
    E = zeros(nombre, chemins);
    V = zeros(nombre, chemins);
    for c = 1:chemins
        variances = zeros(total, 1);
        innovations = zeros(total, 1);
        bruit = randn(total, 1);
        for t = 1:total
            valeur = modele.Constant;
            for i = 1:p
                if t - i >= 1
                    valeur = valeur + garchs(i) * variances(t - i);
                else
                    valeur = valeur + garchs(i) * longTerme;
                end
            end
            for j = 1:q
                if t - j >= 1
                    valeur = valeur + archs(j) * innovations(t - j) ^ 2;
                else
                    valeur = valeur + archs(j) * longTerme;
                end
            end
            variances(t) = valeur;
            innovations(t) = sqrt(valeur) * bruit(t);
        end
        garde = (rodage + 1):total;
        E(:, c) = innovations(garde);
        V(:, c) = variances(garde);
        Y(:, c) = modele.Offset + innovations(garde);
    end
end
