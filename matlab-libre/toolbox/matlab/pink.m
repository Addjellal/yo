function carte = pink(m)
%PINK Carte de couleurs pastel, pour les images en sépia.
    if nargin < 1 || isempty(m), m = 256; end
    carte = sqrt((2 * gray(m) + hot(m)) / 3);
end
