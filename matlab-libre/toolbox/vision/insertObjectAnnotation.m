function J = insertObjectAnnotation(I, forme, position, etiquette, varargin)
%INSERTOBJECTANNOTATION Entoure des objets et les nomme.
%   J = INSERTOBJECTANNOTATION(I,'rectangle',POSITION,ETIQUETTE) trace un
%   rectangle [x y largeur hauteur] par ligne de POSITION et écrit
%   l'étiquette correspondante au-dessus.
%
%   J = INSERTOBJECTANNOTATION(I,'circle',POSITION,ETIQUETTE) fait de même
%   avec des cercles [x y rayon].
%
%   ETIQUETTE est une chaîne, un tableau de cellules, ou un vecteur de
%   nombres — un score de détection, par exemple.
%
%   Options et valeurs par défaut :
%     'Color'           'yellow', une couleur ou une par objet
%     'TextColor'       'black'
%     'TextBoxOpacity'  0.6
%     'FontSize'        12
%     'LineWidth'       1
%
%   L'image rendue est en couleurs, dans la classe de l'image d'entrée.
%
%   Exemple :
%      I = zeros(80, 120);
%      J = insertObjectAnnotation(I, 'rectangle', [20 30 40 25], 'chat');
%      size(J)     % 80 120 3
%
%   Voir aussi INSERTTEXT, INSERTSHAPE, INSERTMARKER, BBOX2POINTS.
    couleur = 'yellow';
    couleurTexte = 'black';
    opacite = 0.6;
    taille = 12;
    epaisseur = 1;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'color',          couleur = varargin{k + 1};
            case 'textcolor',      couleurTexte = varargin{k + 1};
            case 'textboxopacity', opacite = double(varargin{k + 1});
            case 'fontsize',       taille = double(varargin{k + 1});
            case 'linewidth',      epaisseur = round(double(varargin{k + 1}));
            case 'font'
                % Une seule fonte est disponible.
            otherwise
                error('vision:insertObjectAnnotation:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    position = double(position);
    nombre = size(position, 1);
    couleurs = matlibre_couleur_dessin(couleur, nombre);
    [J, classe] = matlibre_image_rvb(I);
    for k = 1:nombre
        teinte = couleurs(min(k, size(couleurs, 1)), :);
        switch lower(char(forme))
            case 'rectangle'
                J = tracerRectangle(J, position(k, :), teinte, epaisseur);
            case 'circle'
                J = tracerCercle(J, position(k, :), teinte, epaisseur);
            otherwise
                error('vision:insertObjectAnnotation:Forme', ...
                      'Forme inconnue : %s.', char(forme));
        end
    end
    J = matlibre_image_classe(J, classe);
    if nargin < 4 || isempty(etiquette)
        return
    end
    lignes = matlibre_textes_cellules(etiquette, nombre);
    ancres = zeros(nombre, 2);
    for k = 1:nombre
        if strcmpi(char(forme), 'circle')
            ancres(k, :) = [position(k, 1) - position(k, 3), ...
                            position(k, 2) - position(k, 3) - 1];
        else
            ancres(k, :) = [position(k, 1), position(k, 2) - 1];
        end
    end
    J = insertText(J, ancres, lignes, 'FontSize', taille, ...
                   'TextColor', couleurTexte, 'BoxColor', couleurs, ...
                   'BoxOpacity', opacite, 'AnchorPoint', 'LeftBottom');
end

function J = tracerRectangle(J, boite, teinte, epaisseur)
    x = round(boite(1));
    y = round(boite(2));
    largeur = round(boite(3));
    hauteur = round(boite(4));
    for e = 0:(epaisseur - 1)
        J = poserLigne(J, y + e, x:(x + largeur), teinte);
        J = poserLigne(J, y + hauteur - e, x:(x + largeur), teinte);
        J = poserColonne(J, x + e, y:(y + hauteur), teinte);
        J = poserColonne(J, x + largeur - e, y:(y + hauteur), teinte);
    end
end

function J = tracerCercle(J, cercle, teinte, epaisseur)
    xc = cercle(1);
    yc = cercle(2);
    rayon = cercle(3);
    % Un point par demi-pixel de circonférence : le trait reste continu.
    angles = linspace(0, 2 * pi, max(16, ceil(8 * pi * rayon)));
    for e = 0:(epaisseur - 1)
        r = rayon - e;
        x = round(xc + r * cos(angles));
        y = round(yc + r * sin(angles));
        for k = 1:numel(x)
            J = poserPoint(J, y(k), x(k), teinte);
        end
    end
end

function J = poserLigne(J, ligne, colonnes, teinte)
    [h, l, ~] = size(J);
    if ligne < 1 || ligne > h
        return
    end
    colonnes = colonnes(colonnes >= 1 & colonnes <= l);
    for c = 1:3
        J(ligne, colonnes, c) = teinte(c);
    end
end

function J = poserColonne(J, colonne, lignes, teinte)
    [h, l, ~] = size(J);
    if colonne < 1 || colonne > l
        return
    end
    lignes = lignes(lignes >= 1 & lignes <= h);
    for c = 1:3
        J(lignes, colonne, c) = teinte(c);
    end
end

function J = poserPoint(J, ligne, colonne, teinte)
    [h, l, ~] = size(J);
    if ligne < 1 || ligne > h || colonne < 1 || colonne > l
        return
    end
    for c = 1:3
        J(ligne, colonne, c) = teinte(c);
    end
end
