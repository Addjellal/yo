function tranche = matlibre_score_tranche(grille, nom)
%MATLIBRE_SCORE_TRANCHE Découpage rangé pour une variable.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    tranche = [];
    for k = 1:numel(grille.Bins)
        if strcmp(grille.Bins{k}.nom, nom)
            tranche = grille.Bins{k};
            return
        end
    end
end
