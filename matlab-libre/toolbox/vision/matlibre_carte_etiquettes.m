function couleurs = matlibre_carte_etiquettes(specification, nombre)
%MATLIBRE_CARTE_ETIQUETTES Une couleur distincte par étiquette.
%   C = MATLIBRE_CARTE_ETIQUETTES(SPEC,N) rend N couleurs. SPEC vide donne
%   des teintes réparties sur le cercle chromatique, avec saturation et
%   clarté alternées pour que deux étiquettes voisines se distinguent même
%   quand elles sont nombreuses. SPEC peut aussi être un nom de carte
%   ('jet', 'hsv', 'gray') ou une matrice de couleurs.
%
%   Exemple :
%      size(matlibre_carte_etiquettes([], 5))   % 5 3
%
%   Voir aussi LABELOVERLAY, SUPERPIXELS, LABEL2RGB.
    if isempty(specification)
        % L'angle d'or fait tourner la teinte sans jamais retomber sur
        % une valeur déjà prise, ce qui sépare les étiquettes voisines.
        indices = (0:(nombre - 1)).';
        teinte = mod(indices * 0.6180339887498949, 1);
        saturation = 0.6 + 0.35 * mod(indices, 2);
        valeur = 0.95 - 0.25 * mod(floor(indices / 2), 2);
        couleurs = hsv2rgb([teinte, saturation, valeur]);
        return
    end
    if ischar(specification)
        couleurs = feval(specification, nombre);
        return
    end
    couleurs = double(specification);
    if size(couleurs, 2) ~= 3
        error('vision:carte:Forme', 'Une carte de couleurs a trois colonnes.');
    end
    if any(couleurs(:) > 1)
        couleurs = couleurs / 255;
    end
end
