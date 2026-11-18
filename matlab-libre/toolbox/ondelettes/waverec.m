function x = waverec(C, L, varargin)
%WAVEREC Reconstruction d'une décomposition multiniveaux.
%   X = WAVEREC(C,L,'wname') reconstruit le signal à partir de la
%   décomposition rendue par WAVEDEC ; X = WAVEREC(C,L,Lo_R,Hi_R) emploie
%   des filtres de reconstruction donnés. L'ondelette doit être celle de
%   la décomposition, et le mode de DWTMODE aussi.
%
%   La remontée est symétrique de la descente : on part de l'approximation
%   la plus grossière, on lui adjoint le détail du niveau le plus profond
%   par IDWT, à la longueur que L garde pour ce niveau, et le résultat sert
%   d'approximation au niveau suivant. C'est APPCOEF(C,L,...,0).
%
%   La reconstruction est exacte à l'arrondi près pour un banc de filtres
%   à reconstruction parfaite, ce qui est la propriété qui définit une
%   ondelette orthogonale ou biorthogonale.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 3, 'db2');
%      max(abs(waverec(c, l, 'db2') - x)) < 1e-10
%
%   Voir aussi WAVEDEC, APPCOEF, IDWT, DWT.
    if nargin < 3
        varargin = {'haar'};
    end
    x = appcoef(C, L, varargin{:}, 0);
end
