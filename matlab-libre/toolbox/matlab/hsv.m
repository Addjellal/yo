function carte = hsv(m)
%HSV Carte de couleurs parcourant le cercle des teintes.
%   La saturation et la valeur restent à 1 : seule la teinte tourne, du
%   rouge au rouge en passant par tout le spectre.
    if nargin < 1 || isempty(m), m = 256; end
    m = round(m);
    if m <= 0
        carte = zeros(0, 3);
        return
    end
    teinte = (0:m-1)' / m;
    carte = hsv2rgb([teinte ones(m, 1) ones(m, 1)]);
end
