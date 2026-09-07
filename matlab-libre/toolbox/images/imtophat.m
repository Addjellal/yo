function r = imtophat(image, element)
%IMTOPHAT Chapeau haut de forme : l'image moins son ouverture.
%   Fait ressortir les détails clairs plus petits que l'élément
%   structurant.
%
%   Exemple :
%      bw = zeros(20);
%      bw(10, 10) = 1;             % un point isole
%      sum(sum(imtophat(bw, ones(3)))) > 0   % le chapeau haut de forme le voit
%
%   Voir aussi IMBOTHAT, IMOPEN, IMCLOSE, STREL.
    r = double(image) - double(imopen(image, element));
end
