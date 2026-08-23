function sortie = bwareaopen(bw, p, connexite)
%BWAREAOPEN Retire les composantes de moins de P pixels.
%
%   Exemple :
%      bw = false(5); bw(2,2) = true; bw(4:5,4:5) = true;
%      bwareaopen(bw, 2)   % le point isolé disparaît
    if nargin < 3 || isempty(connexite), connexite = 8; end
    bw = logical(bw);
    [etiquettes, nombre] = bwlabeln(bw, connexite);
    sortie = false(size(bw));
    for k = 1:nombre
        dedans = etiquettes == k;
        if sum(dedans(:)) >= p
            sortie(dedans) = true;
        end
    end
end
