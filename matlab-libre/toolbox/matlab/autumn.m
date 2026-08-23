function carte = autumn(m)
%AUTUMN Carte de couleurs rouge - jaune.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [ones(numel(g), 1), g, zeros(numel(g), 1)];
end
