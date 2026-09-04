function distordus = matlibre_camera_distordre(normalises, parametres)
%MATLIBRE_CAMERA_DISTORDRE Applique la distorsion de l'objectif.
%   La distorsion radiale déplace les points le long du rayon, d'autant
%   plus qu'ils sont loin du centre ; la distorsion tangentielle corrige
%   le fait que la lentille n'est jamais parfaitement parallèle au
%   capteur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    radiale = parametres.RadialDistortion;
    tangentielle = parametres.TangentialDistortion;
    x = normalises(:, 1);
    y = normalises(:, 2);
    r2 = x .^ 2 + y .^ 2;
    facteur = ones(size(r2));
    for k = 1:numel(radiale)
        facteur = facteur + radiale(k) * r2 .^ k;
    end
    p1 = 0; p2 = 0;
    if numel(tangentielle) >= 1, p1 = tangentielle(1); end
    if numel(tangentielle) >= 2, p2 = tangentielle(2); end
    dx = 2 * p1 * x .* y + p2 * (r2 + 2 * x .^ 2);
    dy = p1 * (r2 + 2 * y .^ 2) + 2 * p2 * x .* y;
    distordus = [x .* facteur + dx, y .* facteur + dy];
end
