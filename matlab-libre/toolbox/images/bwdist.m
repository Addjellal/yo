function [d, indices] = bwdist(bw)
%BWDIST Distance euclidienne au pixel vrai le plus proche.
%   D = BWDIST(BW) rend, pour chaque pixel, la distance au plus proche
%   pixel vrai. [D,IDX] = BWDIST(BW) rend aussi l'indice linéaire de ce
%   pixel.
%
%   Exemple :
%      a = false(3); a(2,2) = true; bwdist(a)(1,1)   % sqrt(2)
    bw = logical(bw);
    [m, n] = size(bw);
    d = inf(m, n);
    indices = zeros(m, n);
    [li, co] = find(bw);
    if isempty(li)
        d = inf(m, n);
        return
    end
    for i = 1:m
        for j = 1:n
            ecarts = (li - i).^2 + (co - j).^2;
            [meilleur, k] = min(ecarts);
            d(i, j) = sqrt(meilleur);
            indices(i, j) = li(k) + (co(k) - 1) * m;
        end
    end
end
