function [cA, cD] = dwt(x, varargin)
%DWT Transformée en ondelettes discrète, un niveau.
%   [CA,CD] = DWT(X,'wname') rend l'approximation et le détail de X,
%   sous-échantillonnés d'un facteur deux. [CA,CD] = DWT(X,Lo_D,Hi_D)
%   emploie des filtres de décomposition donnés.
%
%   Les bords sont prolongés selon le mode de DWTMODE — 'sym' (symétrie
%   en demi-point) par défaut, comme dans MATLAB —, ou celui que donne
%   DWT(...,'mode',MODE). L'algorithme est celui de MATLAB : X est
%   prolongé de numel(Lo_D)-1 valeurs de chaque côté, convolué par chaque
%   filtre, et l'on garde un coefficient sur deux à partir du deuxième ;
%   CA et CD comptent floor((numel(X)+numel(Lo_D)-1)/2) coefficients.
%   En mode 'per', le prolongement est périodique et CA compte
%   ceil(numel(X)/2) coefficients.
%
%   CA et CD ont l'orientation de X.
%
%   Exemple :
%      [a, d] = dwt([1 2 3 4], 'haar')          % a = [2.1213 4.9497]
%      [a, d] = dwt(1:8, 'db2');  numel(a)      % 5 (mode 'sym')
%      [a, d] = dwt(1:8, 'db2', 'mode', 'per'); numel(a)   % 4
%
%   Voir aussi IDWT, DWTMODE, WAVEDEC, WFILTERS, WEXTEND, DWT2.
    if nargin < 2
        varargin = {'haar'};
    end
    [Lo_D, Hi_D, mode] = matlibre_ondelette_arguments(varargin, 'd', 'dwt');
    if ~(isnumeric(x) || islogical(x)) || (~isvector(x) && ~isempty(x))
        error('Wavelet:FunctionInput:InvalidVector', ...
              'DWT attend un vecteur ; DWT2 traite les matrices.');
    end
    colonne = size(x, 1) > 1;
    x = double(x(:)).';
    lf = numel(Lo_D);
    lx = numel(x);
    if strcmp(mode, 'per')
        prolongement = lf / 2;
        dernier = 2 * ceil(lx / 2);
    else
        prolongement = lf - 1;
        dernier = lx + lf - 1;
    end
    y = wextend('1D', mode, x, prolongement);
    z = conv(y, Lo_D, 'valid');
    cA = z(2:2:dernier);
    z = conv(y, Hi_D, 'valid');
    cD = z(2:2:dernier);
    if colonne
        cA = cA(:);
        cD = cD(:);
    end
end
