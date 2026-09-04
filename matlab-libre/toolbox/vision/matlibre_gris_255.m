function G = matlibre_gris_255(I)
%MATLIBRE_GRIS_255 Image en niveaux de gris, sur l'échelle 0-255.
%   G = MATLIBRE_GRIS_255(I) convertit en gris si besoin et ramène les
%   valeurs à l'intervalle des images entières, pour que les seuils des
%   détecteurs aient partout le même sens.
%
%   Exemple :
%      max(max(matlibre_gris_255(ones(2))))    % 255
%
%   Voir aussi DETECTSURFFEATURES, DETECTBRISKFEATURES.
    G = double(I);
    if ndims(G) == 3
        G = rgb2gray(G);
    end
    % La tolérance importe : un lissage par un noyau dont les poids ne
    % somment pas exactement à un laisse une image dont le maximum vaut
    % 1 plus un epsilon, et qu'il ne faut pas prendre pour une image
    % déjà sur 0-255.
    if max(G(:)) <= 1 + 1e-6
        G = G * 255;
    end
end
