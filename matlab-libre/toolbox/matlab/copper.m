function carte = copper(m)
%COPPER Carte de couleurs noir - cuivre.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [min(1, g * 1.25), g * 0.7812, g * 0.4975];
end
