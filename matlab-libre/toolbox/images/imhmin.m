function sortie = imhmin(image, h, connexite)
%IMHMIN Comble les minima de profondeur inférieure à H.
%   Y = IMHMIN(X,H) relève les cuvettes dont la profondeur n'atteint pas
%   H, et laisse les autres.
%
%   C'est l'outil qui rend la ligne de partage des eaux utilisable : sans
%   lui, chaque petite cuvette du bruit devient un bassin, et la
%   segmentation éclate en centaines de régions. Combler les minima peu
%   profonds fusionne ces bassins avant même de commencer.
%
%   Exemple :
%      relief = ones(20); relief(5, 5) = 0.9; relief(15, 15) = 0.2;
%      comble = imhmin(relief, 0.5);
%      comble(5, 5) == 1               % true : la cuvette peu marquee
%      comble(15, 15) < 1              % true : la profonde reste
%
%   Voir aussi IMEXTENDEDMIN, IMEXTENDEDMAX, WATERSHED.
    if nargin < 3 || isempty(connexite), connexite = 8; end
    sortie = -imhmax(-double(image), h, connexite);
end
