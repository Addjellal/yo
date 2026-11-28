function [Cnouveau, Lnouveau, cA] = upwlev(C, L, varargin)
%UPWLEV Remonte d'un niveau une décomposition en ondelettes.
%   [NC,NL,CA] = UPWLEV(C,L,'wname') fusionne l'approximation la plus
%   grossière avec son détail : la décomposition perd un niveau, et CA
%   rend l'approximation reconstruite, à la longueur que L garde.
%   UPWLEV(C,L,Lo_R,Hi_R) emploie des filtres donnés.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 3, 'db2');
%      [c2, l2] = upwlev(c, l, 'db2');
%      numel(l2) == numel(l) - 1   % 1 : un niveau de moins
%
%   Voir aussi WAVEDEC, APPCOEF, WAVEREC.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R] = matlibre_ondelette_arguments(varargin, 'r', 'upwlev');
    if numel(L) < 3
        error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
              'UPWLEV: the decomposition has no level to reconstruct.');
    end
    a = C(1:L(1));
    d = C(L(1) + (1:L(2)));
    cA = idwt(a, d, Lo_R, Hi_R, L(3));
    reste = C(L(1) + L(2) + 1:end);
    if size(C, 1) > 1
        Cnouveau = [cA(:); reste(:)];
        Lnouveau = [L(3); L(3:end)];
    else
        Cnouveau = [cA(:).', reste(:).'];
        Lnouveau = [L(3), L(3:end)];
    end
end
