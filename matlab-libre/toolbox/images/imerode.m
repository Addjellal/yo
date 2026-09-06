function y = imerode(x, element)
%IMERODE Érosion morphologique.
%   Y = IMERODE(X,ELEMENT) remplace chaque pixel par le minimum de son
%   voisinage.
%
%   L'érosion ne peut que rétrécir : le résultat est contenu dans
%   l'original. Elle efface ce qui est plus petit que l'élément
%   structurant, ce qui en fait un filtre de taille — c'est ainsi qu'on
%   supprime le bruit poivre et sel sans toucher aux grandes formes.
%
%   Éroder ce qu'on vient de dilater ne rend pas l'original en général :
%   la composition est la fermeture, qui bouche les trous. C'est
%   l'inverse pour l'ouverture.
%
%   Exemple :
%      bw = false(9); bw(5, 5) = true;
%      sum(sum(imerode(bw, true(3))))     % 0 : un point isole disparait
%
%   Voir aussi IMDILATE, IMOPEN, IMCLOSE.
    if nargin < 2
        element = ones(3, 3);
    end
    y = morphologie(x, element, 'min');
end
