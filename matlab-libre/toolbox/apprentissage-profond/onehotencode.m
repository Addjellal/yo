function A = onehotencode(etiquettes, dimension, varargin)
%ONEHOTENCODE Étiquettes en indicatrices.
%   A = ONEHOTENCODE(E,DIM) rend, pour chaque étiquette, un vecteur nul
%   sauf un un à la position de sa classe. DIM dit selon quelle dimension
%   ranger les classes : un pour une colonne par observation, deux pour
%   une ligne.
%
%   E peut être un tableau catégoriel, un tableau de cellules de chaînes,
%   ou un vecteur d'entiers. Les classes sont prises dans l'ordre de
%   CATEGORIES, c'est-à-dire l'ordre alphabétique pour des chaînes.
%
%   ONEHOTENCODE(...,'ClassNames',C) impose la liste des classes et leur
%   ordre — nécessaire dès qu'un lot ne les contient pas toutes.
%
%   Un classifieur ne prédit pas une étiquette mais une loi sur les
%   classes ; c'est cette forme-là qu'il faut lui donner comme cible.
%
%   Exemple :
%      onehotencode({'a','b','a'}, 1)
%
%   Voir aussi ONEHOTDECODE, CATEGORICAL, CROSSENTROPY.
    classes = {};
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'classnames')
            classes = varargin{k + 1};
        end
    end
    [indices, classes] = matlibre_dl_indices_classes(etiquettes, classes);
    nombre = numel(classes);
    n = numel(indices);
    A = zeros(nombre, n);
    for k = 1:n
        if indices(k) > 0
            A(indices(k), k) = 1;
        else
            A(:, k) = NaN;
        end
    end
    if dimension == 2
        A = A.';
    end
end
