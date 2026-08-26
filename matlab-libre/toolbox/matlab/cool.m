function carte = cool(m)
%COOL Carte de couleurs cyan - magenta.
    if nargin < 1 || isempty(m), m = 256; end
    r = rampeCarte(m);
    carte = [r, 1 - r, ones(numel(r), 1)];
end
