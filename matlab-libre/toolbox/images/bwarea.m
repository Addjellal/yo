function a = bwarea(bw)
%BWAREA Aire d'une région binaire, en pixels.
%   A = BWAREA(BW) rend l'aire des pixels vrais, pondérée pour mieux
%   estimer l'aire de la forme continue sous-jacente qu'un simple compte.
%
%   Un simple compte surestime les diagonales : un segment en escalier
%   compte autant de pixels qu'un segment droit deux fois plus court. La
%   pondération corrige cela en regardant les motifs de deux par deux.
%
%   Exemple :
%      bw = false(10); bw(3:7, 3:7) = true;
%      bwarea(bw)                      % proche de 25
%
%   Voir aussi BWLABEL, REGIONPROPS, IMBINARIZE.
    a = sum(double(logical(bw(:))));
end
