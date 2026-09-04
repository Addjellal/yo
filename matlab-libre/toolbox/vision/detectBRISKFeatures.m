function [positions, metriques, echelles] = detectBRISKFeatures(I, varargin)
%DETECTBRISKFEATURES Coins FAST retenus dans l'espace des échelles.
%   P = DETECTBRISKFEATURES(I) rend les coordonnées [x y] des coins, dans
%   les coordonnées de l'image de départ.
%
%   [P,METRIQUE,ECHELLE] = DETECTBRISKFEATURES(I) rend aussi le score de
%   chaque coin — le plus grand seuil auquel il reste un coin — et
%   l'échelle où il est le plus marqué.
%
%   La pyramide comporte, entre deux octaves, une couche intermédiaire à
%   une fois et demie l'échelle : les échelles sont donc 1, 1,5, 2, 3, 4,
%   6, et ainsi de suite. Un coin n'est retenu que s'il domine ses voisins
%   dans sa couche et dans les deux couches encadrantes — c'est cette
%   comparaison qui lui attribue une échelle propre, là où FAST seul en
%   rendrait un par couche. Sa position est ensuite affinée au sous-pixel
%   par une parabole, ce qui lui rend la précision que la réduction de
%   l'image lui avait ôtée.
%
%   Options et valeurs par défaut :
%     'MinContrast'  0.2, l'écart d'intensité minimal, sur 0-1
%     'MinQuality'   0.1, la part du score le plus fort en deçà de
%                    laquelle un coin est écarté
%     'NumOctaves'   4
%     'ROI'          [x y largeur hauteur]
%
%   Exemple :
%      I = zeros(90); I(25:60, 25:60) = 1;
%      [p, m, e] = detectBRISKFeatures(I);
%      size(p, 1)      % les quatre coins du carré
%
%   Voir aussi DETECTORBFEATURES, DETECTSURFFEATURES, DETECTFASTFEATURES.
    contraste = 0.2;
    qualite = 0.1;
    octaves = 4;
    zone = [];
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'mincontrast', contraste = double(varargin{k + 1});
            case 'minquality',  qualite = double(varargin{k + 1});
            case 'numoctaves',  octaves = round(double(varargin{k + 1}));
            case 'roi',         zone = round(double(varargin{k + 1}));
            otherwise
                error('vision:detectBRISKFeatures:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    G = matlibre_gris_255(I);
    seuil = contraste * 255;
    couches = matlibre_echelles_brisk(octaves);
    scores = cell(1, numel(couches));
    retenues = [];
    for k = 1:numel(couches)
        courante = matlibre_niveau_pyramide(G, couches(k));
        if min(size(courante)) < 12
            break
        end
        scores{k} = matlibre_score_fast(courante);
        retenues(end + 1) = couches(k);   %#ok<AGROW>
    end
    couches = retenues;
    positions = zeros(0, 2);
    metriques = zeros(0, 1);
    echelles = zeros(0, 1);
    for k = 1:numel(couches)
        [lignes, colonnes] = matlibre_maxima_locaux(scores{k}, seuil);
        for j = 1:numel(lignes)
            valeur = scores{k}(lignes(j), colonnes(j));
            if ~matlibre_domine_echelles(scores, couches, k, lignes(j), colonnes(j), valeur)
                continue
            end
            [dl, dc] = matlibre_sommet_quadratique(scores{k}, lignes(j), colonnes(j));
            positions(end + 1, :) = ...
                matlibre_coordonnee_originale([colonnes(j) + dc, lignes(j) + dl], ...
                                              couches(k));  %#ok<AGROW>
            metriques(end + 1, 1) = valeur;    %#ok<AGROW>
            echelles(end + 1, 1) = couches(k); %#ok<AGROW>
        end
    end
    if ~isempty(metriques)
        assez = metriques >= qualite * max(metriques);
        positions = positions(assez, :);
        metriques = metriques(assez);
        echelles = echelles(assez);
    end
    [positions, metriques, echelles] = ...
        matlibre_trier_points(positions, metriques, echelles, []);
    [positions, metriques, echelles] = ...
        matlibre_restreindre_zone(zone, positions, metriques, echelles, []);
end
