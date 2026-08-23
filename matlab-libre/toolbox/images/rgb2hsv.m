function h = rgb2hsv(r, g, b)
%RGB2HSV Couleurs RVB vers teinte, saturation, valeur.
%   H = RGB2HSV(IMAGE) où IMAGE est MxNx3 dans [0,1]. Les trois plans du
%   résultat sont la teinte (0 à 1), la saturation et la valeur.
%
%   Exemple :
%      c = rgb2hsv(cat(3, 1, 0, 0));   % rouge pur : teinte 0, S = V = 1
    if nargin == 3
        image = cat(3, r, g, b);
    else
        image = r;
    end
    image = im2double(image);
    R = image(:, :, 1);
    G = image(:, :, 2);
    B = image(:, :, 3);
    v = max(max(R, G), B);
    mini = min(min(R, G), B);
    delta = v - mini;
    s = zeros(size(v));
    utile = v > 0;
    s(utile) = delta(utile) ./ v(utile);
    teinte = zeros(size(v));
    plat = delta == 0;
    rouge = ~plat & (v == R);
    vert = ~plat & (v == G) & ~rouge;
    bleu = ~plat & ~rouge & ~vert;
    teinte(rouge) = mod((G(rouge) - B(rouge)) ./ delta(rouge), 6) / 6;
    teinte(vert) = ((B(vert) - R(vert)) ./ delta(vert) + 2) / 6;
    teinte(bleu) = ((R(bleu) - G(bleu)) ./ delta(bleu) + 4) / 6;
    h = cat(3, teinte, s, v);
end
