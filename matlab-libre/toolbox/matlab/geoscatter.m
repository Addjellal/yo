function H = geoscatter(latitudes, longitudes, varargin)
%GEOSCATTER Nuage de points sur des coordonnées géographiques.
%   GEOSCATTER(LAT,LON) place un point par couple. GEOSCATTER(LAT,LON,
%   TAILLE,COULEUR) suit la syntaxe de SCATTER.
%   H = GEOSCATTER(...) rend la poignée.
%
%   Comme GEOPLOT, la projection est une équirectangulaire locale, dont le
%   rapport d'aspect corrige le cosinus de la latitude moyenne.
%
%   Exemple :
%      figure();
%      geoscatter([48.85 43.30], [2.35 5.37]);
%      close all;
%
%   Voir aussi GEOPLOT, SCATTER, BUBBLECHART.
    latitudes = double(latitudes(:));
    longitudes = double(longitudes(:));
    H = scatter(longitudes, latitudes, varargin{:});
    matlibre_aspect_geographique(latitudes);
    xlabel('Longitude (deg)');
    ylabel('Latitude (deg)');
    grid on;
end
