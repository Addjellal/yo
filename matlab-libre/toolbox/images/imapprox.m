function [indices, carte] = imapprox(indicesEntree, carteEntree, n)
%IMAPPROX Réduit le nombre de couleurs d'une image indexée.
%   [Y,NEWMAP] = IMAPPROX(X,MAP,N) rend une image à N couleurs.
    rgb = ind2rgb(indicesEntree, carteEntree);
    [indices, carte] = rgb2ind(rgb, n);
end
