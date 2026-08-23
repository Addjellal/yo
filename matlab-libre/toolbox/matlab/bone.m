function carte = bone(m)
%BONE Carte de couleurs gris à reflet bleuté.
%   Sept huitièmes de gris et un huitième de HOT retourné.
    if nargin < 1 || isempty(m), m = 256; end
    chaud = hot(m);
    carte = (7 * gray(m) + chaud(:, [3 2 1])) / 8;
end
