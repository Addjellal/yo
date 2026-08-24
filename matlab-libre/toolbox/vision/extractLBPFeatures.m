function descripteur = extractLBPFeatures(I, varargin)
%EXTRACTLBPFEATURES Motifs binaires locaux.
%   F = EXTRACTLBPFEATURES(I) compare chaque pixel à ses voisins sur un
%   cercle : le motif binaire obtenu décrit la texture locale, et
%   l'histogramme de ces motifs décrit la texture de l'image.
%
%   Le motif ne dépend que de l'ordre des intensités, pas de leur valeur :
%   le descripteur est donc insensible à tout changement monotone
%   d'éclairage, ce qui est sa raison d'être.
%
%   Options et valeurs par défaut :
%     'NumNeighbors'  8
%     'Radius'        1
%     'Upright'       true   sinon le motif est ramené à sa rotation
%                            minimale, ce qui le rend invariant par
%                            rotation
%     'CellSize'      la taille de l'image, soit un seul histogramme
%     'Normalization' 'L2', ou 'None'
%
%   La longueur du descripteur vaut le nombre de cellules multiplié par
%   P*(P-1)+3 si Upright, par P+2 sinon : seuls les motifs uniformes,
%   ceux qui ont au plus deux transitions, reçoivent leur propre case.
%
%   Exemple :
%      f = extractLBPFeatures(rand(32));
%      numel(f)   % 59
%
%   Voir aussi EXTRACTHOGFEATURES, EXTRACTFEATURES.
    nVoisins = 8;
    rayon = 1;
    droit = true;
    tailleCellule = [];
    normalisation = 'l2';
    for k = 1:2:numel(varargin)-1
        switch lower(char(varargin{k}))
            case 'numneighbors',  nVoisins = double(varargin{k+1});
            case 'radius',        rayon = double(varargin{k+1});
            case 'upright',       droit = logical(varargin{k+1});
            case 'cellsize',      tailleCellule = double(varargin{k+1});
            case 'normalization', normalisation = lower(char(varargin{k+1}));
            otherwise
                error('vision:extractLBPFeatures:BadOption', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    if isempty(tailleCellule), tailleCellule = size(I); end
    if isscalar(tailleCellule), tailleCellule = [tailleCellule tailleCellule]; end
    codes = motifsLocaux(I, nVoisins, rayon);
    [table, nCases] = tableMotifs(nVoisins, droit);
    cellules = max(floor(size(I) ./ tailleCellule), 1);
    descripteur = [];
    for ci = 1:cellules(1)
        lignes = (ci - 1) * tailleCellule(1) + (1:min(tailleCellule(1), size(I, 1) - (ci-1)*tailleCellule(1)));
        for cj = 1:cellules(2)
            colonnes = (cj - 1) * tailleCellule(2) + (1:min(tailleCellule(2), size(I, 2) - (cj-1)*tailleCellule(2)));
            bloc = codes(lignes, colonnes);
            histogramme = zeros(1, nCases);
            valides = bloc(~isnan(bloc));
            for p = 1:numel(valides)
                indice = table(valides(p) + 1);
                histogramme(indice) = histogramme(indice) + 1;
            end
            if strcmp(normalisation, 'l2')
                histogramme = histogramme / sqrt(sum(histogramme .^ 2) + 1e-12);
            end
            descripteur = [descripteur, histogramme];               %#ok<AGROW>
        end
    end
end

function codes = motifsLocaux(I, nVoisins, rayon)
%MOTIFSLOCAUX Code binaire de chaque pixel, NaN sur la bordure.
%   Les voisins sont pris sur un cercle et interpolés bilinéairement :
%   c'est ce qui permet un rayon non entier et un nombre de voisins
%   quelconque.
    [h, l] = size(I);
    codes = NaN(h, l);
    marge = ceil(rayon);
    angles = 2 * pi * (0:nVoisins-1) / nVoisins;
    decalagesY = -rayon * sin(angles);
    decalagesX = rayon * cos(angles);
    for i = 1 + marge:h - marge
        for j = 1 + marge:l - marge
            centre = I(i, j);
            code = 0;
            for p = 1:nVoisins
                valeur = interpolerBilineaire(I, i + decalagesY(p), j + decalagesX(p));
                code = code * 2 + double(valeur >= centre);
            end
            codes(i, j) = code;
        end
    end
end

function v = interpolerBilineaire(I, y, x)
    i0 = floor(y); j0 = floor(x);
    dy = y - i0; dx = x - j0;
    if abs(dy) < 1e-12 && abs(dx) < 1e-12
        v = I(i0, j0);
        return
    end
    i1 = min(i0 + 1, size(I, 1));
    j1 = min(j0 + 1, size(I, 2));
    v = I(i0, j0) * (1 - dy) * (1 - dx) + I(i0, j1) * (1 - dy) * dx + ...
        I(i1, j0) * dy * (1 - dx) + I(i1, j1) * dy * dx;
end

function [table, nCases] = tableMotifs(nVoisins, droit)
%TABLEMOTIFS Numéro de case de chaque motif possible.
%   Un motif est uniforme quand son écriture circulaire ne compte pas plus
%   de deux transitions entre zéro et un : ce sont ceux qui décrivent un
%   bord ou un coin, et ils forment l'écrasante majorité des motifs
%   observés dans les images naturelles.
    total = 2 ^ nVoisins;
    table = zeros(1, total);
    if droit
        nCases = nVoisins * (nVoisins - 1) + 3;
        suivant = 1;
        for code = 0:total-1
            bits = bitsDe(code, nVoisins);
            if transitions(bits) <= 2
                table(code + 1) = suivant;
                suivant = suivant + 1;
            else
                table(code + 1) = nCases;
            end
        end
    else
        nCases = nVoisins + 2;
        for code = 0:total-1
            bits = bitsDe(code, nVoisins);
            if transitions(bits) <= 2
                table(code + 1) = sum(bits) + 1;
            else
                table(code + 1) = nCases;
            end
        end
    end
end

function bits = bitsDe(code, n)
    bits = zeros(1, n);
    for k = n:-1:1
        bits(k) = mod(code, 2);
        code = floor(code / 2);
    end
end

function n = transitions(bits)
    n = sum(bits ~= bits([2:end, 1]));
end
