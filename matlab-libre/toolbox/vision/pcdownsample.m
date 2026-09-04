function nuage = pcdownsample(entree, methode, parametre, varargin)
%PCDOWNSAMPLE Allège un nuage de points.
%   Q = PCDOWNSAMPLE(P,'random',PART) garde une fraction des points,
%   tirée au hasard.
%   Q = PCDOWNSAMPLE(P,'gridAverage',PAS) découpe l'espace en cubes de
%   côté PAS et remplace les points de chaque cube par leur moyenne.
%   Q = PCDOWNSAMPLE(P,'nonuniformGridSample',N) garde environ un point
%   par cube, la taille du cube étant choisie pour qu'il reste N points.
%
%   La moyenne par grille ne se contente pas d'écarter des points : elle
%   les remplace par leur barycentre. Le nuage allégé est donc moins
%   bruité que le nuage d'origine, là où un tirage au hasard garde le
%   bruit tel quel.
%
%   Exemple :
%      q = pcdownsample(pointCloud(rand(10000, 3)), 'gridAverage', 0.1);
%
%   Voir aussi PCDENOISE, POINTCLOUD, PCMERGE.
    points = matlibre_nuage_points(entree);
    if isempty(points)
        nuage = entree;
        return
    end
    switch lower(char(methode))
        case 'random'
            part = double(parametre);
            nombre = max(round(part * size(points, 1)), 1);
            garde = randperm(size(points, 1), nombre);
            garde = sort(garde(:));
            nuage = matlibre_nuage_copier(entree, points(garde, :), garde);
        case 'gridaverage'
            pas = double(parametre);
            nuage = matlibre_nuage_grille(entree, points, pas);
        case 'nonuniformgridsample'
            cible = round(double(parametre));
            % On cherche le pas de grille qui laisse à peu près le nombre
            % de points voulu, par dichotomie sur son logarithme.
            etendue = max(max(points) - min(points));
            bas = etendue / max(size(points, 1), 1);
            haut = etendue;
            for iteration = 1:40
                pas = sqrt(bas * haut);
                essai = matlibre_nuage_grille(entree, points, pas);
                if essai.Count > cible
                    bas = pas;
                else
                    haut = pas;
                end
            end
            nuage = matlibre_nuage_grille(entree, points, sqrt(bas * haut));
        otherwise
            error('vision:pcdownsample:Methode', ...
                  'La méthode vaut ''random'', ''gridAverage'' ou ''nonuniformGridSample''.');
    end
end
