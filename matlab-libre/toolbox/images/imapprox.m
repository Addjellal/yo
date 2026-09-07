function [indices, carte] = imapprox(indicesEntree, carteEntree, n)
%IMAPPROX Réduit le nombre de couleurs d'une image indexée.
%   [Y,NEWMAP] = IMAPPROX(X,MAP,N) rend une image à N couleurs.
%
%   Exemple :
%      rng(1);
%      [i, c] = imapprox(randi(64, 10, 10), rand(64, 3), 8);
%      size(c, 1)                  % 8 : la palette est reduite
    rgb = ind2rgb(indicesEntree, carteEntree);
    [indices, carte] = rgb2ind(rgb, n);
end
