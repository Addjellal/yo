function H = geoplot(latitudes, longitudes, varargin)
%GEOPLOT Trace une trajectoire sur des coordonnées géographiques.
%   GEOPLOT(LAT,LON) trace la ligne joignant les points donnés en degrés.
%   GEOPLOT(LAT,LON,STYLE) accepte le style de PLOT.
%   H = GEOPLOT(...) rend la poignée.
%
%   MATLAB dessine ici un fond de carte ; MatLibre n'en emporte pas et
%   trace la longitude en abscisse, la latitude en ordonnée, avec un
%   rapport d'aspect corrigé par le cosinus de la latitude moyenne. Cette
%   correction est ce qui empêche une trajectoire de paraître étirée : un
%   degré de longitude vaut cos(latitude) degré de latitude en distance,
%   et l'ignorer déforme tout dès qu'on quitte l'équateur.
%
%   La projection est donc une équirectangulaire locale. Elle est fausse
%   sur une grande étendue, comme toute projection plane, et l'aide le dit
%   plutôt que de laisser croire à une carte exacte.
%
%   Exemple :
%      figure();
%      geoplot([48.85 43.30 45.76], [2.35 5.37 4.83]);
%      close all;
%
%   Voir aussi GEOSCATTER, PLOT, AXIS.
    latitudes = double(latitudes(:));
    longitudes = double(longitudes(:));
    H = plot(longitudes, latitudes, varargin{:});
    matlibre_aspect_geographique(latitudes);
    xlabel('Longitude (deg)');
    ylabel('Latitude (deg)');
    grid on;
end
