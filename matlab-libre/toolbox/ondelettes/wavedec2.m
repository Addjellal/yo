function [C, S] = wavedec2(x, niveaux, varargin)
%WAVEDEC2 Décomposition multiniveaux d'une image en ondelettes.
%   [C,S] = WAVEDEC2(X,N,'wname') empile les coefficients en un vecteur
%   ligne : approximation du niveau N, puis, du niveau N au niveau 1, les
%   détails horizontal, vertical et diagonal. S donne les tailles : celle
%   de l'approximation du niveau N, puis celle des détails de chaque
%   niveau, du N-ième au premier, puis celle de l'image.
%   WAVEDEC2(X,N,Lo_D,Hi_D) emploie des filtres donnés ; les bords
%   suivent DWTMODE ('sym' par défaut).
%   Une image en couleurs (trois pages) donne des tailles à trois
%   colonnes.
%
%   Exemple :
%      [c, s] = wavedec2(magic(8), 2, 'haar');
%      a = appcoef2(c, s, 'haar', 2);
%
%   Voir aussi WAVEREC2, APPCOEF2, DETCOEF2, WRCOEF2.
    if nargin < 3
        varargin = {'haar'};
    end
    [Lo_D, Hi_D] = matlibre_ondelette_arguments(varargin, 'd', 'wavedec2');
    if ~(isnumeric(niveaux) && isscalar(niveaux) && niveaux >= 1 && niveaux == round(niveaux))
        error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
              'WAVEDEC2 : le nombre de niveaux est un entier positif.');
    end
    x = double(x);
    C = [];
    S = size(x);
    for k = 1:niveaux
        [x, h, v, d] = dwt2(x, Lo_D, Hi_D);
        C = [h(:).', v(:).', d(:).', C]; %#ok<AGROW>
        S = [size(x); S]; %#ok<AGROW>
    end
    C = [x(:).', C];
    S = [size(x); S];
end
