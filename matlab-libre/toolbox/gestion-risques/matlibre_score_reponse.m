function [bons, mauvais, poids] = matlibre_score_reponse(grille)
%MATLIBRE_SCORE_REPONSE Indicatrices de bon et de mauvais dossier.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    reponse = grille.Data.(grille.ResponseVar);
    if iscell(reponse)
        bons = strcmp(reponse(:), grille.GoodLabel);
    else
        bons = double(reponse(:)) == grille.GoodLabel;
    end
    bons = double(bons);
    mauvais = 1 - bons;
    if isempty(grille.WeightsVar)
        poids = ones(size(bons));
    else
        poids = double(grille.Data.(grille.WeightsVar)(:));
    end
end
