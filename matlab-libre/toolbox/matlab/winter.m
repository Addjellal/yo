function carte = winter(m)
%WINTER Carte de couleurs bleu - vert.
    if nargin < 1 || isempty(m), m = 256; end
    g = rampeCarte(m);
    carte = [zeros(numel(g), 1), g, 1 - g / 2];
end
