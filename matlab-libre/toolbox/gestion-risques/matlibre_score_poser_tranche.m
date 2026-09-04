function grille = matlibre_score_poser_tranche(grille, nom, tranche)
%MATLIBRE_SCORE_POSER_TRANCHE Range ou remplace le découpage d'une variable.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    for k = 1:numel(grille.Bins)
        if strcmp(grille.Bins{k}.nom, nom)
            grille.Bins{k} = tranche;
            return
        end
    end
    grille.Bins{end+1} = tranche;
end
