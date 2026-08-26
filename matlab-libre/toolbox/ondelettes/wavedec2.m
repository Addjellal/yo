function [C, S] = wavedec2(x, niveaux, nom)
%WAVEDEC2 Décomposition multiniveaux d'une image en ondelettes.
%   [C,S] = WAVEDEC2(X,N,NOM) empile les coefficients en un vecteur
%   ligne : approximation du niveau N, puis, du niveau N au niveau 1, les
%   détails horizontal, vertical et diagonal. S donne les tailles, une
%   ligne par niveau plus la taille de l'image.
%
%   Exemple :
%      [c, s] = wavedec2(magic(8), 2, 'haar');
%      a = appcoef2(c, s, 'haar', 2);
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    x = double(x);
    courant = x;
    morceaux = {};
    tailles = [];
    for k = 1:niveaux
        [ca, ch, cv, cd] = dwt2(courant, nom);
        morceaux{k} = {ch, cv, cd};       %#ok<AGROW>
        tailles(k, :) = size(ch);         %#ok<AGROW>
        courant = ca;
    end
    C = courant(:)';
    S = size(courant);
    for k = niveaux:-1:1
        trio = morceaux{k};
        C = [C, trio{1}(:)', trio{2}(:)', trio{3}(:)'];   %#ok<AGROW>
        S = [S; tailles(k, :)];                           %#ok<AGROW>
    end
    S = [S; size(x)];
end
