function [cA, cH, cV, cD] = dwt2(x, varargin)
%DWT2 Transformée en ondelettes discrète bidimensionnelle, un niveau.
%   [CA,CH,CV,CD] = DWT2(X,'wname') rend l'approximation et les détails
%   horizontal, vertical et diagonal ; DWT2(X,Lo_D,Hi_D) emploie des
%   filtres donnés, DWT2(...,'mode',MODE) un mode de prolongement (par
%   défaut celui de DWTMODE, 'sym').
%   La transformée est séparable, comme dans MATLAB : les lignes sont
%   filtrées et décimées, puis les colonnes. CH a été filtré en passe-bas
%   le long des lignes et en passe-haut le long des colonnes ; CV
%   l'inverse ; CD en passe-haut dans les deux sens.
%   Un X à trois dimensions (image en couleurs) est traité page par page.
%
%   Exemple :
%      [a, h, v, d] = dwt2(ones(4), 'db1');   % a = 2*ones(2), h = v = d = 0
%      size(dwt2(magic(8), 'db2'))             % 5 5 en mode 'sym'
%
%   Voir aussi IDWT2, WAVEDEC2, DWT, DWTMODE.
    if nargin < 2
        varargin = {'haar'};
    end
    [Lo_D, Hi_D, mode] = matlibre_ondelette_arguments(varargin, 'd', 'dwt2');
    if ndims(x) > 3
        error('Wavelet:FunctionInput:InvalidSizeArray', ...
              'DWT2 attend une matrice, ou une image en couleurs.');
    end
    x = double(x);
    pages = size(x, 3);
    for p = 1:pages
        [lo, hi] = selonColonnes(x(:, :, p).', Lo_D, Hi_D, mode);   % lignes
        [a, h] = selonColonnes(lo.', Lo_D, Hi_D, mode);             % colonnes
        [v, d] = selonColonnes(hi.', Lo_D, Hi_D, mode);
        if p == 1
            cA = zeros([size(a), pages]);
            cH = cA;
            cV = cA;
            cD = cA;
        end
        cA(:, :, p) = a;
        cH(:, :, p) = h;
        cV(:, :, p) = v;
        cD(:, :, p) = d;
    end
end

% DWT de chaque colonne de X.
function [A, D] = selonColonnes(X, Lo_D, Hi_D, mode)
    m = size(X, 1);
    lf = numel(Lo_D);
    if strcmp(mode, 'per')
        prolongement = lf / 2;
        dernier = 2 * ceil(m / 2);
    else
        prolongement = lf - 1;
        dernier = m + lf - 1;
    end
    Y = wextend('addrow', mode, X, prolongement);
    Z = conv2(Y, Lo_D(:), 'valid');
    A = Z(2:2:dernier, :);
    Z = conv2(Y, Hi_D(:), 'valid');
    D = Z(2:2:dernier, :);
end
