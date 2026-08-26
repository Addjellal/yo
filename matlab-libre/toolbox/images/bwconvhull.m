function sortie = bwconvhull(bw, methode, connexite)
%BWCONVHULL Enveloppe convexe des objets d'une image binaire.
%   BWCONVHULL(BW) rend l'enveloppe de l'ensemble des pixels allumés.
%   BWCONVHULL(BW,'objects') traite chaque composante à part.
    if nargin < 2 || isempty(methode), methode = 'union'; end
    if nargin < 3 || isempty(connexite), connexite = 8; end
    bw = logical(bw);
    if strncmpi(char(methode), 'obj', 3)
        [etiquettes, nombre] = bwlabeln(bw, connexite);
        sortie = false(size(bw));
        for k = 1:nombre
            sortie = sortie | enveloppe(etiquettes == k);
        end
    else
        sortie = enveloppe(bw);
    end
end

function masque = enveloppe(bw)
    [lignes, colonnes] = find(bw);
    masque = false(size(bw));
    if numel(lignes) < 3
        masque(bw) = true;
        return
    end
    k = convhull(colonnes, lignes);
    sommetsX = colonnes(k);
    sommetsY = lignes(k);
    [X, Y] = meshgrid(1:size(bw, 2), 1:size(bw, 1));
    masque = inpolygon(X, Y, sommetsX, sommetsY);
end
