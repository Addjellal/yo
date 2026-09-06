function y = wconv2(type, x, f, forme)
%WCONV2 Convolution bidimensionnelle, ou par lignes, ou par colonnes.
%   Y = WCONV2(TYPE,X,F) convolue la matrice X par le filtre F.
%   Y = WCONV2(TYPE,X,F,FORME) choisit la forme : 'full' par défaut,
%   'same' pour la taille de X, 'valid' pour la partie sans débordement.
%
%   TYPE vaut 'row' pour convoluer chaque ligne séparément, 'col' pour
%   chaque colonne, et n'importe quoi d'autre — 'a' par exemple — pour une
%   convolution bidimensionnelle pleine.
%
%   C'est cette distinction qui sert à la transformée en ondelettes
%   séparable : filtrer les lignes puis les colonnes revient à filtrer par
%   le produit extérieur des deux filtres, mais coûte bien moins cher —
%   deux convolutions à une dimension au lieu d'une à deux.
%
%   L'ordre des arguments diffère de WCONV1, qui n'a pas de type : c'est
%   la convention de MATLAB.
%
%   Exemple :
%      image = magic(8);
%      wconv2('a', image, ones(3) / 9);         % moyenne locale
%      size(wconv2('row', image, [1 1] / 2))    % 8 sur 9 : lignes seules
%      size(wconv2('a', image, ones(3), 'same')) % 8 sur 8
%
%   Voir aussi WCONV1, CONV2, DWT2.
    if nargin < 4 || isempty(forme)
        forme = 'full';
    end
    x = double(x);
    f = double(f);
    switch lower(char(type))
        case 'row'
            y = conv2(x, f(:).', forme);
        case 'col'
            y = conv2(x, f(:), forme);
        otherwise
            y = conv2(x, f, forme);
    end
end
