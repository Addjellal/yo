function [Cnouveau, Snouveau, cA] = upwlev2(C, S, varargin)
%UPWLEV2 Remonte d'un niveau une décomposition d'image.
%   [NC,NS,CA] = UPWLEV2(C,S,'wname') fusionne l'approximation la plus
%   grossière avec ses trois détails : la décomposition perd un niveau,
%   et CA rend l'approximation reconstruite, à la taille que S garde.
%   UPWLEV2(C,S,Lo_R,Hi_R) emploie des filtres donnés.
%
%   Exemple :
%      [c, s] = wavedec2(magic(16), 3, 'haar');
%      [nc, ns, ca] = upwlev2(c, s, 'haar');
%      size(ns, 1) == size(s, 1) - 1  % 1 : un niveau de moins
%
%   Voir aussi UPWLEV, WAVEDEC2, APPCOEF2, IDWT2.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R] = matlibre_ondelette_arguments(varargin, 'r', 'upwlev2');
    if size(S, 1) < 3
        error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
              'UPWLEV2 : la décomposition n''a pas de niveau à remonter.');
    end
    nmax = size(S, 1) - 2;
    a = reshape(C(1:prod(S(1, :))), S(1, :));
    [h, v, d] = detcoef2('all', C, S, nmax);
    cA = idwt2(a, h, v, d, Lo_R, Hi_R, S(3, :));
    debut = prod(S(1, :)) + 3 * prod(S(2, :)) + 1;
    Cnouveau = [cA(:).', C(debut:end)];
    Snouveau = [S(3, :); S(3:end, :)];
end
