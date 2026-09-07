function r = imbothat(image, element)
%IMBOTHAT Chapeau bas de forme : la fermeture moins l'image.
%   Fait ressortir les détails sombres.
%
%   Exemple :
%      bw = false(20, 20);
%      bw(5:15, 5:15) = true;
%      bw(9:11, 9:11) = false;     % un trou
%      sum(sum(imbothat(double(bw), ones(3)))) > 0   % le chapeau noir voit le trou
%
%   Voir aussi IMTOPHAT, IMOPEN, IMCLOSE, STREL.
    r = double(imclose(image, element)) - double(image);
end
