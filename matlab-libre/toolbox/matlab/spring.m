function carte = spring(m)
%SPRING Carte de couleurs magenta - jaune.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [ones(numel(g), 1), g, 1 - g];
end
