function [Cnouveau, Lnouveau, coefficients] = upwlev(C, L, nom)
%UPWLEV Remonte d'un niveau une décomposition en ondelettes.
%   [NC,NL,CA] = UPWLEV(C,L,NOM) fusionne l'approximation la plus
%   grossière avec son détail : la décomposition perd un niveau, et CA
%   rend l'approximation reconstruite.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 3, 'db2');
%      [c2, l2] = upwlev(c, l, 'db2');
%      numel(l2) == numel(l) - 1   % 1 : un niveau de moins
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    a = C(1:L(1));
    d = C(L(1) + (1:L(2)));
    coefficients = idwt(a, d, nom);
    Cnouveau = [coefficients(:)', C(L(1) + L(2) + 1:end)];
    Lnouveau = [numel(coefficients), L(3:end)];
end
