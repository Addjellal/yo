function h = montage(images, varargin)
%MONTAGE Affiche plusieurs images en mosaïque.
%   MONTAGE(I) affiche côte à côte les images d'un tableau à quatre
%   dimensions — hauteur, largeur, canaux, nombre — ou d'un tableau de
%   cellules d'images.
%
%   MONTAGE(...,'Size',[L C]) impose le découpage ; sans lui, la
%   mosaïque est aussi carrée que possible.
%   MONTAGE(...,'BorderSize',B) sépare les vignettes de B pixels,
%   'BackgroundColor',C donne la couleur du fond, 'DisplayRange',[A B]
%   l'étendue des valeurs.
%
%   H = MONTAGE(...) rend l'image assemblée.
%
%   Exemple :
%      images = cat(4, mat2gray(peaks(40)), mat2gray(magic(40)));
%      montage(images);
%
%   Voir aussi IMSHOW, IMTILE, SUBPLOT, IMSHOWPAIR.
    decoupage = [];
    bordure = 0;
    fond = 0;
    etendue = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'size',            decoupage = round(double(varargin{k+1}));
            case 'bordersize',      bordure = round(double(varargin{k+1}));
            case 'backgroundcolor', fond = varargin{k+1};
            case 'displayrange',    etendue = double(varargin{k+1});
            case {'indices', 'thumbnailsize', 'parent'}
                % Acceptées et sans effet.
            otherwise
                error('images:montage:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if iscell(images)
        liste = images(:);
    else
        images = im2double(images);
        if ndims(images) == 4
            liste = cell(size(images, 4), 1);
            for j = 1:size(images, 4)
                liste{j} = images(:, :, :, j);
            end
        elseif ndims(images) == 3 && size(images, 3) ~= 3
            liste = cell(size(images, 3), 1);
            for j = 1:size(images, 3)
                liste{j} = images(:, :, j);
            end
        else
            liste = {images};
        end
    end
    nombre = numel(liste);
    if nombre == 0
        h = [];
        return;
    end
    if isempty(decoupage)
        colonnes = ceil(sqrt(nombre));
        lignes = ceil(nombre / colonnes);
    else
        lignes = decoupage(1);
        colonnes = decoupage(2);
    end
    hauteur = 0;
    largeur = 0;
    for j = 1:nombre
        liste{j} = im2double(liste{j});
        if size(liste{j}, 3) > 1
            liste{j} = im2gray(liste{j});
        end
        hauteur = max(hauteur, size(liste{j}, 1));
        largeur = max(largeur, size(liste{j}, 2));
    end
    if ischar(fond) || isstring(fond)
        fond = 0;
    else
        fond = double(fond(1));
    end
    mosaique = fond * ones(lignes * hauteur + (lignes - 1) * bordure, ...
                           colonnes * largeur + (colonnes - 1) * bordure);
    for j = 1:nombre
        ligne = floor((j - 1) / colonnes);
        colonne = mod(j - 1, colonnes);
        vignette = liste{j};
        i0 = ligne * (hauteur + bordure);
        j0 = colonne * (largeur + bordure);
        mosaique((i0 + 1):(i0 + size(vignette, 1)), ...
                 (j0 + 1):(j0 + size(vignette, 2))) = vignette;
    end
    if isempty(etendue)
        imagesc(mosaique);
    else
        imagesc(mosaique);
        clim(etendue);
    end
    axis('image');
    axis('off');
    if nargout > 0
        h = mosaique;
    end
end
