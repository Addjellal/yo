function J = insertText(I, position, texte, varargin)
%INSERTTEXT Écrit du texte dans une image.
%   J = INSERTTEXT(I,POSITION,TEXTE) dessine TEXTE dans l'image I, sur un
%   cartouche opaque, au point POSITION donné en [x y]. POSITION peut
%   avoir plusieurs lignes ; TEXTE est alors un tableau de cellules de la
%   même longueur, ou une seule chaîne répétée, ou un vecteur de nombres.
%
%   L'image rendue est toujours en couleurs, comme dans MATLAB : une
%   image en niveaux de gris est d'abord recopiée sur trois plans. La
%   classe de l'image d'entrée est conservée.
%
%   Options et valeurs par défaut :
%     'FontSize'     12, la hauteur des lettres en pixels
%     'TextColor'    'black'
%     'BoxColor'     'yellow'
%     'BoxOpacity'   0.6 ; zéro supprime le cartouche
%     'AnchorPoint'  'LeftTop', ou 'LeftBottom', 'CenterTop',
%                    'CenterCenter', 'RightBottom', etc.
%
%   La fonte est tracée dans MATLIBRE_POLICE_5X7, en cinq colonnes sur
%   sept lignes, agrandie d'un facteur entier pour approcher la taille
%   demandée. MatLibre n'ouvre aucun fichier de fonte du système.
%
%   Exemple :
%      I = zeros(60, 200);
%      J = insertText(I, [10 20], 'MatLibre', 'FontSize', 14);
%      size(J)     % 60 200 3
%
%   Voir aussi INSERTOBJECTANNOTATION, INSERTSHAPE, INSERTMARKER.
    taille = 12;
    couleurTexte = 'black';
    couleurBoite = 'yellow';
    opacite = 0.6;
    ancrage = 'lefttop';
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'fontsize',    taille = double(varargin{k + 1});
            case 'textcolor',   couleurTexte = varargin{k + 1};
            case 'boxcolor',    couleurBoite = varargin{k + 1};
            case 'boxopacity',  opacite = double(varargin{k + 1});
            case 'anchorpoint', ancrage = lower(char(varargin{k + 1}));
            case 'font'
                % Une seule fonte est disponible : l'option est acceptée.
            otherwise
                error('vision:insertText:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    position = double(position);
    if size(position, 2) < 2
        error('vision:insertText:Position', ...
              'POSITION donne un point [x y] par ligne.');
    end
    lignes = matlibre_textes_cellules(texte, size(position, 1));
    couleurTexte = matlibre_couleur_dessin(couleurTexte, numel(lignes));
    couleurBoite = matlibre_couleur_dessin(couleurBoite, numel(lignes));
    [J, classe] = matlibre_image_rvb(I);
    echelle = max(1, round(taille / 7));
    marge = max(1, round(echelle));
    for k = 1:numel(lignes)
        motif = matlibre_police_5x7(lignes{k});
        if isempty(motif)
            continue
        end
        motif = kron(double(motif), ones(echelle)) > 0;
        [hauteurTexte, largeurTexte] = size(motif);
        hauteur = hauteurTexte + 2 * marge;
        largeur = largeurTexte + 2 * marge;
        [x, y] = coinDepuisAncrage(position(k, 1), position(k, 2), ...
                                   largeur, hauteur, ancrage);
        J = poserCartouche(J, motif, round(x), round(y), marge, ...
                           couleurBoite(min(k, size(couleurBoite, 1)), :), ...
                           couleurTexte(min(k, size(couleurTexte, 1)), :), ...
                           opacite);
    end
    J = matlibre_image_classe(J, classe);
end

function [x, y] = coinDepuisAncrage(x, y, largeur, hauteur, ancrage)
% Le point donné est un coin, un milieu de bord ou le centre : on en
% déduit le coin supérieur gauche du cartouche. Le nom d'ancrage se lit
% en deux morceaux, l'horizontal puis le vertical.
    if strncmp(ancrage, 'right', 5)
        horizontal = 'right';
    elseif strncmp(ancrage, 'center', 6)
        horizontal = 'center';
    else
        horizontal = 'left';
    end
    vertical = ancrage((numel(horizontal) + 1):end);
    switch horizontal
        case 'right',  x = x - largeur + 1;
        case 'center', x = x - floor(largeur / 2);
    end
    switch vertical
        case 'bottom', y = y - hauteur + 1;
        case 'center', y = y - floor(hauteur / 2);
    end
end

function J = poserCartouche(J, motif, x, y, marge, fond, encre, opacite)
% Le cartouche est mélangé au fond selon son opacité ; les lettres, elles,
% sont opaques, sinon elles se perdent dans l'image.
    [h, l, ~] = size(J);
    hauteur = size(motif, 1) + 2 * marge;
    largeur = size(motif, 2) + 2 * marge;
    lignes = y:(y + hauteur - 1);
    colonnes = x:(x + largeur - 1);
    dansImage = lignes >= 1 & lignes <= h;
    dansLargeur = colonnes >= 1 & colonnes <= l;
    if ~any(dansImage) || ~any(dansLargeur)
        return
    end
    lignesUtiles = lignes(dansImage);
    colonnesUtiles = colonnes(dansLargeur);
    if opacite > 0
        for c = 1:3
            bloc = J(lignesUtiles, colonnesUtiles, c);
            J(lignesUtiles, colonnesUtiles, c) = ...
                (1 - opacite) * bloc + opacite * fond(c);
        end
    end
    % Le motif est recadré comme le cartouche, marge comprise.
    plein = false(hauteur, largeur);
    plein((marge + 1):(marge + size(motif, 1)), ...
          (marge + 1):(marge + size(motif, 2))) = motif;
    plein = plein(dansImage, dansLargeur);
    for c = 1:3
        bloc = J(lignesUtiles, colonnesUtiles, c);
        bloc(plein) = encre(c);
        J(lignesUtiles, colonnesUtiles, c) = bloc;
    end
end
