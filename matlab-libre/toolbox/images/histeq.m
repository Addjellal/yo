function y = histeq(x, n)
%HISTEQ Égalisation d'histogramme.
%   Y = HISTEQ(X,N) étale les niveaux de gris pour que leur histogramme
%   soit à peu près plat sur N casiers, 64 par défaut.
%
%   Le principe : appliquer à l'image sa propre fonction de répartition
%   cumulée. Une image dont tous les pixels sont entassés dans une plage
%   étroite s'étale alors sur toute la dynamique, et son contraste
%   apparent augmente beaucoup.
%
%   Le procédé est brutal : il amplifie le bruit des zones uniformes
%   autant que le signal des zones utiles, et il change les rapports de
%   luminance. L'égalisation locale — CLAHE — corrige le premier défaut,
%   pas le second.
%
%   Exemple :
%      terne = 0.4 + 0.2 * rand(64);
%      clair = histeq(terne);
%      std(clair(:)) > std(terne(:))   % true : le contraste augmente
%
%   Voir aussi IMADJUST, IMHIST, IMBINARIZE.
    if nargin < 2
        n = 256;
    end
    x = im2double(x);
    [compte, ~] = imhist(x, n);
    cumul = cumsum(compte) / sum(compte);
    y = zeros(size(x));
    for k = 1:numel(x)
        indice = min(n, max(1, round(x(k) * (n - 1)) + 1));
        y(k) = cumul(indice);
    end
end
