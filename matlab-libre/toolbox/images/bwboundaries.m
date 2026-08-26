function [contours, etiquettes, nombre, adjacence] = bwboundaries(bw, connexite, options)
%BWBOUNDARIES Contours des objets d'une image binaire.
%   B = BWBOUNDARIES(BW) rend un tableau de cellules ; chaque cellule est
%   une liste de couples [ligne colonne] parcourant le contour d'un
%   objet, le premier point étant répété à la fin.
%
%   [B,L,N,A] = BWBOUNDARIES(...) rend aussi l'image étiquetée, le nombre
%   d'objets et la matrice d'adjacence entre objets et trous.
%
%   BWBOUNDARIES(BW,CONN,'noholes') ignore les trous.
%
%   Exemple :
%      bw = false(5); bw(2:4, 2:4) = true;
%      b = bwboundaries(bw);   % un contour de huit points plus le retour
    if nargin < 2 || isempty(connexite), connexite = 8; end
    if nargin < 3, options = 'holes'; end
    if ischar(connexite) || isstring(connexite)
        options = connexite;
        connexite = 8;
    end
    bw = logical(bw);
    avecTrous = ~strncmpi(char(options), 'noholes', 7);
    [etiquettes, nombre] = bwlabeln(bw, connexite);
    contours = {};
    origines = [];
    for k = 1:nombre
        objet = etiquettes == k;
        depart = premierPixel(objet);
        contours{end + 1, 1} = bwtraceboundary(objet, depart, 'N', connexite);  %#ok<AGROW>
        origines(end + 1, 1) = k;                                              %#ok<AGROW>
    end
    nombreObjets = nombre;
    if avecTrous
        trous = imfill(bw, 'holes') & ~bw;
        [etiquettesTrous, nombreTrous] = bwlabeln(trous, connexite);
        for k = 1:nombreTrous
            objet = etiquettesTrous == k;
            depart = premierPixel(objet);
            contours{end + 1, 1} = bwtraceboundary(objet, depart, 'N', connexite);  %#ok<AGROW>
            origines(end + 1, 1) = -k;                                             %#ok<AGROW>
        end
    end
    if nargout > 3
        adjacence = zeros(numel(contours));
        for k = 1:numel(contours)
            if origines(k) < 0
                % Un trou est adjacent à l'objet qui l'entoure.
                point = contours{k}(1, :);
                voisin = etiquettes(max(1, point(1) - 1), point(2));
                indice = find(origines == voisin, 1);
                if ~isempty(indice)
                    adjacence(k, indice) = 1;
                end
            end
        end
    end
    nombre = nombreObjets;
end

function p = premierPixel(objet)
    [lignes, colonnes] = find(objet);
    [~, k] = min(colonnes * size(objet, 1) + lignes);
    p = [lignes(k) colonnes(k)];
end
