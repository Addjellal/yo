function cc = bwconncomp(bw, connexite)
%BWCONNCOMP Composantes connexes d'une image binaire.
%   CC = BWCONNCOMP(BW,CONNEXITE) rend une structure aux champs
%   Connectivity, ImageSize, NumObjects et PixelIdxList — la même que
%   celle de MATLAB.
%
%   Exemple :
%      bw = false(20, 20);
%      bw(3:6, 3:6) = true;        % un carre de 16 pixels
%      bw(10:18, 10:18) = true;    % un autre de 81
%      cc = bwconncomp(bw);
%      cc.NumObjects               % 2
    if nargin < 2, connexite = 8; end
    bw = logical(bw);
    [etiquettes, nombre] = bwlabel(bw, connexite);
    cc = struct();
    cc.Connectivity = connexite;
    cc.ImageSize = size(bw);
    cc.NumObjects = nombre;
    liste = cell(1, nombre);
    for k = 1:nombre
        liste{k} = find(etiquettes == k);
    end
    cc.PixelIdxList = liste;
end
