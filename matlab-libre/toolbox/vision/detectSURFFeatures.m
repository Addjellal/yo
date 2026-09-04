function [positions, metriques, echelles, signes] = detectSURFFeatures(I, varargin)
%DETECTSURFFEATURES Points d'intérêt par la Hessienne approchée.
%   P = DETECTSURFFEATURES(I) rend les coordonnées [x y] des taches
%   claires ou sombres de l'image, à toutes les tailles.
%
%   [P,METRIQUE,ECHELLE,SIGNE] = DETECTSURFFEATURES(I) rend aussi la force
%   de chaque point, l'échelle à laquelle il a été trouvé, et le signe de
%   la trace de la Hessienne — positif pour une tache sombre sur fond
%   clair, négatif pour l'inverse. Ce signe permet d'écarter d'emblée deux
%   points qui ne peuvent pas se correspondre.
%
%   Le détecteur cherche les maxima du déterminant de la matrice
%   hessienne, dans l'espace formé du plan de l'image et de l'échelle. Les
%   dérivées secondes sont approchées par des filtres à boîte, calculés en
%   temps fixe depuis l'image intégrale : c'est ce qui permet d'agrandir
%   le filtre plutôt que de réduire l'image, et donc de balayer les
%   échelles sans rééchantillonner.
%
%   Options et valeurs par défaut :
%     'MetricThreshold'  1000, sur une image ramenée à l'intervalle 0-255
%     'NumOctaves'       3
%     'NumScaleLevels'   4
%     'ROI'              [x y largeur hauteur], la zone à examiner
%
%   Exemple :
%      I = zeros(120); I(40:60, 40:60) = 1;
%      I = imfilter(I, fspecial('gaussian', 21, 4), 'replicate');
%      [p, m, e] = detectSURFFeatures(I);
%      p(1, :)      % le centre de la tache
%
%   Voir aussi DETECTBRISKFEATURES, DETECTORBFEATURES, EXTRACTFEATURES,
%   DETECTHARRISFEATURES.
    seuil = 1000;
    octaves = 3;
    niveaux = 4;
    zone = [];
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'metricthreshold', seuil = double(varargin{k + 1});
            case 'numoctaves',      octaves = round(double(varargin{k + 1}));
            case 'numscalelevels',  niveaux = round(double(varargin{k + 1}));
            case 'roi',             zone = round(double(varargin{k + 1}));
            otherwise
                error('vision:detectSURFFeatures:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    if niveaux < 3
        error('vision:detectSURFFeatures:Niveaux', ...
              'Il faut au moins trois échelles pour un maximum local.');
    end
    G = matlibre_gris_255(I);
    taille = size(G);
    cotes = zeros(octaves, niveaux);
    for o = 1:octaves
        for k = 1:niveaux
            cotes(o, k) = 3 * (2 ^ o * k + 1);
        end
    end
    marge = ceil(max(cotes(:)) / 2) + 1;
    integrale = integralImage(padarray(G, [marge marge], 'replicate'));
    positions = zeros(0, 2);
    metriques = zeros(0, 1);
    echelles = zeros(0, 1);
    signes = zeros(0, 1);
    for o = 1:octaves
        reponses = zeros(taille(1), taille(2), niveaux);
        traces = zeros(taille(1), taille(2), niveaux);
        for k = 1:niveaux
            [reponses(:, :, k), traces(:, :, k)] = ...
                matlibre_hessienne_approchee(integrale, marge, taille, cotes(o, k));
        end
        for k = 2:(niveaux - 1)
            [lignes, colonnes] = matlibre_extrema_echelle(reponses, k, seuil, ...
                                                          ceil(cotes(o, k) / 2));
            for j = 1:numel(lignes)
                positions(end + 1, :) = [colonnes(j), lignes(j)];   %#ok<AGROW>
                metriques(end + 1, 1) = reponses(lignes(j), colonnes(j), k);   %#ok<AGROW>
                % L'échelle rendue est celle de la gaussienne que le
                % filtre imite : sigma vaut 1,2 fois le côté sur neuf.
                echelles(end + 1, 1) = 1.2 * cotes(o, k) / 9;   %#ok<AGROW>
                signes(end + 1, 1) = sign(traces(lignes(j), colonnes(j), k));   %#ok<AGROW>
            end
        end
    end
    [positions, metriques, echelles, signes] = ...
        matlibre_trier_points(positions, metriques, echelles, signes);
    [positions, metriques, echelles, signes] = ...
        matlibre_restreindre_zone(zone, positions, metriques, echelles, signes);
end
