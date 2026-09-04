function nuage = matlibre_nuage_copier(modele, points, garde)
%MATLIBRE_NUAGE_COPIER Nuage de mêmes attributs, aux points donnés.
%   GARDE, s'il est donné, indique quels points d'origine sont conservés,
%   ce qui permet de trier couleurs et intensités avec eux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if ~isa(modele, 'pointCloud')
        nuage = pointCloud(points);
        return
    end
    nuage = pointCloud(points);
    if nargin >= 3 && ~isempty(garde)
        if ~isempty(modele.Color)
            couleurs = modele.Color;
            if ndims(couleurs) == 3
                couleurs = reshape(couleurs, [], size(couleurs, 3));
            end
            nuage.Color = couleurs(garde, :);
        end
        if ~isempty(modele.Normal)
            normales = matlibre_nuage_points(modele.Normal);
            nuage.Normal = normales(garde, :);
        end
        if ~isempty(modele.Intensity)
            intensites = modele.Intensity(:);
            nuage.Intensity = intensites(garde);
        end
    else
        nuage.Color = modele.Color;
        nuage.Normal = modele.Normal;
        nuage.Intensity = modele.Intensity;
    end
end
