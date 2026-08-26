function s = regionprops(entree, varargin)
%REGIONPROPS Mesures sur les régions d'une image étiquetée.
%   S = REGIONPROPS(BW) ou REGIONPROPS(L) rend un tableau de structures,
%   une par région. Mesures reconnues : 'Area', 'Centroid',
%   'BoundingBox', 'PixelIdxList', 'PixelList', 'MajorAxisLength',
%   'MinorAxisLength', 'Orientation', 'Perimeter', 'Eccentricity',
%   'EquivDiameter', 'Extent', 'FilledArea', 'all'.
%
%   Exemple :
%      s = regionprops(bwlabel([1 1 0; 1 1 0; 0 0 1]));
%      s(1).Area   % 4
    if islogical(entree)
        [etiquettes, nombre] = bwlabel(entree, 8);
    else
        etiquettes = entree;
        nombre = max(0, max(etiquettes(:)));
    end
    mesures = varargin;
    if isempty(mesures) || (numel(mesures) == 1 && strcmpi(char(mesures{1}), 'all'))
        mesures = {'Area', 'Centroid', 'BoundingBox', 'MajorAxisLength', ...
                   'MinorAxisLength', 'Orientation', 'Eccentricity', ...
                   'EquivDiameter', 'Extent', 'Perimeter', 'PixelIdxList', 'PixelList'};
    end
    [m, ~] = size(etiquettes);
    if nombre == 0
        s = struct([]);
        return
    end
    % On remplit à rebours : la première affectation crée le tableau à sa
    % taille finale, sans réallocation.
    for k = nombre:-1:1
        idx = find(etiquettes == k);
        lignes = mod(idx - 1, m) + 1;
        colonnes = floor((idx - 1) / m) + 1;
        aire = numel(idx);
        for j = 1:numel(mesures)
            nom = char(mesures{j});
            switch lower(nom)
                case 'area',        valeur = aire;
                case 'centroid',    valeur = [mean(colonnes), mean(lignes)];
                case 'boundingbox'
                    valeur = [min(colonnes) - 0.5, min(lignes) - 0.5, ...
                              max(colonnes) - min(colonnes) + 1, ...
                              max(lignes) - min(lignes) + 1];
                case 'pixelidxlist', valeur = idx;
                case 'pixellist',    valeur = [colonnes, lignes];
                case 'equivdiameter', valeur = sqrt(4 * aire / pi);
                case 'extent'
                    boite = (max(colonnes) - min(colonnes) + 1) * ...
                            (max(lignes) - min(lignes) + 1);
                    valeur = aire / boite;
                case 'filledarea'
                    masque = false(size(etiquettes));
                    masque(idx) = true;
                    valeur = sum(sum(imfill(masque, 'holes')));
                case 'perimeter'
                    masque = false(size(etiquettes));
                    masque(idx) = true;
                    valeur = sum(sum(bwperim(masque)));
                case {'majoraxislength', 'minoraxislength', 'orientation', 'eccentricity'}
                    [grand, petit, angle_, excentricite] = ellipseEquivalente(lignes, colonnes);
                    switch lower(nom)
                        case 'majoraxislength', valeur = grand;
                        case 'minoraxislength', valeur = petit;
                        case 'orientation',     valeur = angle_;
                        otherwise,              valeur = excentricite;
                    end
                otherwise
                    valeur = [];
            end
            s(k).(nom) = valeur;
        end
    end
end

function [grand, petit, angle_, excentricite] = ellipseEquivalente(lignes, colonnes)
%ELLIPSEEQUIVALENTE Ellipse de mêmes moments d'ordre deux que la région.
    x = colonnes - mean(colonnes);
    y = -(lignes - mean(lignes));
    n = numel(x);
    xx = sum(x.^2) / n + 1 / 12;
    yy = sum(y.^2) / n + 1 / 12;
    xy = sum(x .* y) / n;
    commun = sqrt((xx - yy)^2 + 4 * xy^2);
    grand = 2 * sqrt(2) * sqrt(xx + yy + commun);
    petit = 2 * sqrt(2) * sqrt(max(xx + yy - commun, 0));
    if xy == 0
        if xx >= yy, angle_ = 0; else, angle_ = 90; end
    else
        angle_ = atan2d(2 * xy, xx - yy) / 2;
    end
    if grand > 0
        excentricite = sqrt(1 - (petit / grand)^2);
    else
        excentricite = 0;
    end
end
