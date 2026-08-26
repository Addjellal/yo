function carte = summer(m)
%SUMMER Carte de couleurs vert - jaune.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [g, 0.5 + g / 2, 0.4 * ones(numel(g), 1)];
end
