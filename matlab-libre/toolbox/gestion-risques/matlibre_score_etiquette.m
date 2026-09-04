function etiquette = matlibre_score_etiquette(reponse)
%MATLIBRE_SCORE_ETIQUETTE Valeur de la réponse qui désigne un bon dossier.
%   C'est la plus fréquente : les défauts sont, par construction, la
%   minorité.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if iscell(reponse)
        valeurs = unique(reponse);
        comptes = zeros(1, numel(valeurs));
        for k = 1:numel(valeurs)
            comptes(k) = sum(strcmp(reponse, valeurs{k}));
        end
        [~, rang] = max(comptes);
        etiquette = valeurs{rang};
    else
        valeurs = unique(reponse(:));
        comptes = zeros(1, numel(valeurs));
        for k = 1:numel(valeurs)
            comptes(k) = sum(reponse(:) == valeurs(k));
        end
        [~, rang] = max(comptes);
        etiquette = valeurs(rang);
    end
end
