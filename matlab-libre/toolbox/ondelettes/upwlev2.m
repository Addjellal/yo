function [Cnouveau, Snouveau, approximation] = upwlev2(C, S, nom)
%UPWLEV2 Remonte d'un niveau une décomposition d'image.
%   [NC,NS,CA] = UPWLEV2(C,S,NOM) fusionne l'approximation la plus
%   grossière avec ses trois détails : la décomposition perd un niveau,
%   et CA rend l'approximation reconstruite.
%
%   Exemple :
%      [c, s] = wavedec2(magic(16), 3, 'haar');
%      [nc, ns, ca] = upwlev2(c, s, 'haar');
%      size(ns, 1) == size(s, 1) - 1  % 1 : un niveau de moins
%
%   Voir aussi UPWLEV, WAVEDEC2, APPCOEF2, IDWT2.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    if size(S, 1) < 3
        error('wavelet:upwlev2:Niveaux', ...
              'La décomposition n''a pas de niveau à remonter.');
    end
    tailleA = S(1, :);
    nA = prod(tailleA);
    tailleD = S(2, :);
    nD = prod(tailleD);
    a = reshape(C(1:nA), tailleA);
    ch = reshape(C(nA + (1:nD)), tailleD);
    cv = reshape(C(nA + nD + (1:nD)), tailleD);
    cd = reshape(C(nA + 2 * nD + (1:nD)), tailleD);
    approximation = idwt2(a, ch, cv, cd, nom);
    Cnouveau = [approximation(:)', C(nA + 3 * nD + 1:end)];
    Snouveau = [size(approximation); S(3:end, :)];
end
