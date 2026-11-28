function [positions, metriques] = matlibre_coins(I, arguments, critere, fonction)
%MATLIBRE_COINS Détecteur de coins de Harris ou de Shi et Tomasi, à la manière de MATLAB.
%   [P,M] = MATLIBRE_COINS(I,ARGUMENTS,CRITERE,FONCTION) : CRITERE vaut
%   'harris' ou 'mineigen', ARGUMENTS les options 'MinQuality',
%   'FilterSize' et 'ROI'. Rend les positions [x y], affinées au
%   sous-pixel, et la métrique de chaque coin.
%
%   Les dérivées sont des différences centrées [-1 0 1], le tenseur de
%   structure est lissé par une gaussienne de FilterSize points et d'écart
%   type FilterSize/3, les bords étant prolongés par réplication : une
%   bordure d'image ne fait pas de coin. Un coin est un maximum local de
%   la métrique, au-dessus de MinQuality fois son maximum ; sur un
%   plateau, un seul pixel est retenu. Sa position est affinée par une
%   parabole dans chaque direction, sur ses deux voisins.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [p, m] = matlibre_coins(checkerboard(10), {}, 'harris', 'detectHarrisFeatures');
%
%   Voir aussi DETECTHARRISFEATURES, DETECTMINEIGENFEATURES.
    qualite = 0.01;
    taille = 5;
    zone = [];
    if mod(numel(arguments), 2) ~= 0
        error(['vision:' fonction ':Options'], 'Options must come in name-value pairs.');
    end
    for k = 1:2:numel(arguments)
        switch lower(char(arguments{k}))
            case 'minquality', qualite = arguments{k + 1};
            case 'filtersize', taille = arguments{k + 1};
            case 'roi',        zone = arguments{k + 1};
            otherwise
                error(['vision:' fonction ':Option'], '%s has no option ''%s''.', ...
                      fonction, char(arguments{k}));
        end
    end
    if ~isscalar(qualite) || qualite < 0 || qualite > 1
        error(['vision:' fonction ':MinQuality'], 'MinQuality must be between 0 and 1.');
    end
    if ~isscalar(taille) || taille < 3 || mod(taille, 2) ~= 1
        error(['vision:' fonction ':FilterSize'], 'FilterSize must be an odd integer, at least 3.');
    end
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    I = double(I);
    decalage = [0 0];
    if ~isempty(zone)
        zone = round(zone);
        if numel(zone) ~= 4 || zone(1) < 1 || zone(2) < 1 || zone(1) + zone(3) - 1 > size(I, 2) ...
                || zone(2) + zone(4) - 1 > size(I, 1) || any(zone(3:4) < 3)
            error(['vision:' fonction ':ROI'], ...
                  'ROI must be [x y width height], inside the image.');
        end
        I = I(zone(2):zone(2) + zone(4) - 1, zone(1):zone(1) + zone(3) - 1);
        decalage = zone(1:2) - 1;
    end
    Ix = imfilter(I, [-1 0 1], 'replicate', 'conv');
    Iy = imfilter(I, [-1; 0; 1], 'replicate', 'conv');
    g = fspecial('gaussian', taille, taille / 3);
    A = imfilter(Ix .* Ix, g, 'replicate');
    B = imfilter(Iy .* Iy, g, 'replicate');
    C = imfilter(Ix .* Iy, g, 'replicate');
    if strcmp(critere, 'harris')
        carte = A .* B - C .^ 2 - 0.04 * (A + B) .^ 2;
    else
        carte = ((A + B) - sqrt((A - B) .^ 2 + 4 * C .^ 2)) / 2;
    end
    plafond = max(carte(:));
    if ~(plafond > 0)
        positions = zeros(0, 2);
        metriques = zeros(0, 1);
        return
    end
    seuil = max(qualite * plafond, 0);
    [lignes, colonnes] = matlibre_maxima_locaux(carte, seuil);
    % Les maxima au seuil exact sont gardés, comme les pixels au-dessus.
    n = numel(lignes);
    positions = zeros(n, 2);
    metriques = zeros(n, 1);
    [h, ~] = size(carte);
    for k = 1:n
        i = lignes(k); j = colonnes(k);
        v = carte(i, j);
        dx = sommet(carte(i, j - 1), v, carte(i, j + 1));
        dy = sommet(carte(i - 1, j), v, carte(i + 1, j));
        positions(k, :) = [j + dx, i + dy] + decalage;
        metriques(k) = v;
    end
    if h == 0
        positions = zeros(0, 2);
    end
end

function d = sommet(gauche, centre, droite)
%SOMMET Abscisse du sommet de la parabole par trois points, bornée à un demi-pixel.
    courbure = gauche - 2 * centre + droite;
    if courbure >= 0
        d = 0;
    else
        d = max(-0.5, min(0.5, (gauche - droite) / (2 * courbure)));
    end
end
