function [C, L] = wavedec(x, niveaux, varargin)
%WAVEDEC Décomposition multiniveaux en ondelettes.
%   [C,L] = WAVEDEC(X,N,'wname') applique N fois DWT à l'approximation et
%   empile les coefficients : l'approximation du niveau N, puis les
%   détails du niveau N au niveau 1. L donne leurs longueurs, suivies de
%   celle de X. [C,L] = WAVEDEC(X,N,Lo_D,Hi_D) emploie des filtres donnés.
%
%   Les bords suivent le mode de DWTMODE ('sym' par défaut, comme dans
%   MATLAB). Pour un X colonne, C et L sont des colonnes.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 3, 'db2');
%      l                                % [10 10 18 33 64] en mode 'sym'
%      sum(l(1:end-1)) == numel(c)      % 1 : tous les coefficients y sont
%      max(abs(waverec(c, l, 'db2') - x)) < 1e-10
%
%   Voir aussi WAVEREC, APPCOEF, DETCOEF, WRCOEF, DWTMODE, WMAXLEV.
    if nargin < 3
        varargin = {'haar'};
    end
    [Lo_D, Hi_D] = matlibre_ondelette_arguments(varargin, 'd', 'wavedec');
    if ~(isnumeric(niveaux) && isscalar(niveaux) && niveaux >= 1 && niveaux == round(niveaux))
        error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
              'WAVEDEC : le nombre de niveaux est un entier positif.');
    end
    if ~isvector(x) && ~isempty(x)
        error('Wavelet:FunctionInput:InvalidVector', ...
              'WAVEDEC attend un vecteur ; WAVEDEC2 traite les matrices.');
    end
    colonne = size(x, 1) > 1;
    x = double(x(:)).';
    C = [];
    L = zeros(1, niveaux + 2);
    L(end) = numel(x);
    for k = 1:niveaux
        [x, d] = dwt(x, Lo_D, Hi_D);
        C = [d, C]; %#ok<AGROW>
        L(niveaux + 2 - k) = numel(d);
    end
    C = [x, C];
    L(1) = numel(x);
    if colonne
        C = C(:);
        L = L(:);
    end
end
