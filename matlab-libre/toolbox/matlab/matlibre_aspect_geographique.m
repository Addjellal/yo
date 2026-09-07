function matlibre_aspect_geographique(latitudes)
%MATLIBRE_ASPECT_GEOGRAPHIQUE Corrige le rapport d'aspect d'une carte plane.
%   Un degré de longitude vaut cos(latitude) degré de latitude en
%   distance : sans cette correction, une trajectoire paraît étirée dès
%   qu'on quitte l'équateur, et d'autant plus qu'on s'en éloigne.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure();
%      plot([2 5], [48 43]);
%      matlibre_aspect_geographique([48 43]);
%      close all;
%
%   Voir aussi GEOPLOT, GEOSCATTER, DASPECT.
    if isempty(latitudes)
        return
    end
    moyenne = mean(latitudes(~isnan(latitudes)));
    if isempty(moyenne) || ~isfinite(moyenne)
        return
    end
    facteur = max(cos(deg2rad(moyenne)), 0.05);
    try
        daspect([1, facteur, 1]);
    catch
        % Sans gestion du rapport d'aspect, le trace reste correct.
    end
end
