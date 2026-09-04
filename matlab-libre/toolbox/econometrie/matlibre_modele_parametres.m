function [noms, valeurs] = matlibre_modele_parametres(modele)
%MATLIBRE_MODELE_PARAMETRES Noms et valeurs des paramètres estimés.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    noms = {};
    valeurs = [];
    if isa(modele, 'garch')
        noms{end+1} = 'Constant';
        valeurs(end+1) = modele.Constant;
        listes = {'GARCH', 'ARCH', 'Leverage'};
        retards = {modele.GARCHLags, modele.ARCHLags, modele.LeverageLags};
    else
        noms{end+1} = 'Constant';
        valeurs(end+1) = modele.Constant;
        listes = {'AR', 'SAR', 'MA', 'SMA'};
        retards = {modele.ARLags, modele.SARLags, modele.MALags, modele.SMALags};
    end
    for k = 1:numel(listes)
        coefficients = modele.(listes{k});
        for j = 1:numel(coefficients)
            noms{end+1} = sprintf('%s{%d}', listes{k}, retards{k}(j));   %#ok<AGROW>
            valeurs(end+1) = coefficients{j};                            %#ok<AGROW>
        end
    end
    if ~isa(modele, 'garch')
        noms{end+1} = 'Variance';
        valeurs(end+1) = modele.Variance;
    end
end
