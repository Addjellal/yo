function [Cnouveau, Lnouveau, coefficients] = upwlev(C, L, nom)
%UPWLEV Remonte d'un niveau une décomposition en ondelettes.
%   [NC,NL,CA] = UPWLEV(C,L,NOM) fusionne l'approximation la plus
%   grossière avec son détail : la décomposition perd un niveau, et CA
%   rend l'approximation reconstruite.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    a = C(1:L(1));
    d = C(L(1) + (1:L(2)));
    coefficients = idwt(a, d, nom);
    Cnouveau = [coefficients(:)', C(L(1) + L(2) + 1:end)];
    Lnouveau = [numel(coefficients), L(3:end)];
end
