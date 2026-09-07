function [sortie, indices] = bwselect(bw, c, r, connexite)
%BWSELECT Garde les objets qui contiennent les points désignés.
%   BWSELECT(BW,C,R) où C sont les colonnes et R les lignes des points,
%   dans cet ordre — c'est la convention de MATLAB.
%
%   Exemple :
%      bw = false(20, 20);
%      bw(3:6, 3:6) = true;        % un carre de 16 pixels
%      bw(10:18, 10:18) = true;    % un autre de 81
%      [sortie, indices] = bwselect(bw, 4, 4);
%      sum(sortie(:))              % 16 : la composante qui contient (4,4)
    if nargin < 4 || isempty(connexite), connexite = 8; end
    bw = logical(bw);
    [etiquettes, ~] = bwlabeln(bw, connexite);
    c = round(double(c(:)));
    r = round(double(r(:)));
    retenues = [];
    for k = 1:numel(c)
        if r(k) >= 1 && r(k) <= size(bw, 1) && c(k) >= 1 && c(k) <= size(bw, 2)
            e = etiquettes(r(k), c(k));
            if e > 0
                retenues(end + 1) = e;    %#ok<AGROW>
            end
        end
    end
    sortie = false(size(bw));
    for e = unique(retenues)
        sortie(etiquettes == e) = true;
    end
    indices = find(sortie);
end
