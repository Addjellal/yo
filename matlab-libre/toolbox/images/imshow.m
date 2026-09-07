function imshow(x, varargin)
%IMSHOW Affiche une image dans les axes courants.
%   Le rendu se fait en SVG : « print » écrit le fichier.
%
%   Exemple :
%      imshow(rand(16));
%      close all;
%
%   Voir aussi IMREAD.
    imagesc(im2double(x));
    axis([0.5, size(x,2)+0.5, 0.5, size(x,1)+0.5]);
end
