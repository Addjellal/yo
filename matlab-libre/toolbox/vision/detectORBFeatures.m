function [positions, metriques, orientations, echelles] = detectORBFeatures(I, varargin)
%DETECTORBFEATURES Coins FAST orientés, à plusieurs échelles.
%   P = DETECTORBFEATURES(I) rend les coordonnées [x y] des coins trouvés
%   sur une pyramide d'images réduites, ramenées aux coordonnées de
%   l'image de départ.
%
%   [P,METRIQUE,ORIENTATION,ECHELLE] = DETECTORBFEATURES(I) rend aussi la
%   réponse de Harris de chaque coin, son orientation en radians, et
%   l'échelle du niveau où il a été trouvé.
%
%   Le détecteur est celui de FAST, appliqué à chaque niveau d'une
%   pyramide : c'est ce qui lui donne l'invariance d'échelle que FAST seul
%   n'a pas. Les coins sont ensuite classés par la réponse de Harris,
%   meilleure que le score de FAST pour écarter les points de contour.
%   L'orientation est celle du vecteur qui va du coin au centre de masse
%   des intensités de son voisinage : elle tourne avec l'image, ce qui
%   rend le point comparable d'une vue à l'autre.
%
%   Options et valeurs par défaut :
%     'ScaleFactor'  1.2, le rapport d'un niveau au suivant
%     'NumLevels'    8
%     'MinContrast'  0.08, l'écart d'intensité minimal, sur 0-1
%     'ROI'          [x y largeur hauteur]
%
%   Exemple :
%      I = zeros(80); I(20:50, 20:50) = 1;
%      [p, m, o] = detectORBFeatures(I);
%      size(p, 1) >= 4      % les quatre coins du carré
%
%   Voir aussi DETECTBRISKFEATURES, DETECTSURFFEATURES, DETECTFASTFEATURES,
%   DETECTHARRISFEATURES.
    facteur = 1.2;
    niveaux = 8;
    contraste = 0.08;
    zone = [];
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'scalefactor', facteur = double(varargin{k + 1});
            case 'numlevels',   niveaux = round(double(varargin{k + 1}));
            case 'mincontrast', contraste = double(varargin{k + 1});
            case 'roi',         zone = round(double(varargin{k + 1}));
            otherwise
                error('vision:detectORBFeatures:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    G = matlibre_gris_255(I);
    seuil = contraste * 255;
    positions = zeros(0, 2);
    metriques = zeros(0, 1);
    orientations = zeros(0, 1);
    echelles = zeros(0, 1);
    for niveau = 1:niveaux
        echelle = facteur ^ (niveau - 1);
        courante = matlibre_niveau_pyramide(G, echelle);
        if min(size(courante)) < 15
            break
        end
        score = matlibre_score_fast(courante);
        [lignes, colonnes] = matlibre_maxima_locaux(score, seuil);
        if isempty(lignes)
            continue
        end
        harris = matlibre_reponse_harris(courante);
        for j = 1:numel(lignes)
            positions(end + 1, :) = ...
                matlibre_coordonnee_originale([colonnes(j), lignes(j)], echelle);  %#ok<AGROW>
            metriques(end + 1, 1) = harris(lignes(j), colonnes(j));               %#ok<AGROW>
            orientations(end + 1, 1) = ...
                matlibre_orientation_centroide(courante, lignes(j), colonnes(j), 15); %#ok<AGROW>
            echelles(end + 1, 1) = echelle;                                        %#ok<AGROW>
        end
    end
    [positions, metriques, orientations, echelles] = ...
        matlibre_trier_points(positions, metriques, orientations, echelles);
    [positions, metriques, orientations, echelles] = ...
        matlibre_restreindre_zone(zone, positions, metriques, orientations, echelles);
end
