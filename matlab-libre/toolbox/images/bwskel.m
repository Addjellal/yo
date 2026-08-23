function sortie = bwskel(bw, varargin)
%BWSKEL Squelette d'une image binaire.
%   Amincissement de Zhang et Suen jusqu'à stabilité : il ne reste qu'un
%   trait d'un pixel d'épaisseur, de même topologie que l'objet.
%
%   BWSKEL(...,'MinBranchLength',L) élague ensuite les barbes de moins de
%   L pixels.
%
%   Exemple :
%      bw = false(9); bw(4:6, 2:8) = true;
%      s = bwskel(bw);   % un segment horizontal
    longueurMini = 0;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'MinBranchLength')
            longueurMini = varargin{k + 1};
        end
    end
    sortie = bwmorph(logical(bw), 'thin', Inf);
    for tour = 1:longueurMini
        extremites = bwmorph(sortie, 'endpoints');
        sortie = sortie & ~extremites;
    end
end
