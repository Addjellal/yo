function carte = jet(m)
%JET Carte de couleurs bleu - cyan - jaune - rouge.
%   Construite par interpolation linéaire entre les six teintes qui la
%   définissent : bleu foncé, bleu, cyan, jaune, rouge, rouge foncé.
%
%   Exemple :
%      c = jet(64);   % c(1,:) vaut [0 0 0.5], c(end,:) vaut [0.5 0 0]
    if nargin < 1 || isempty(m), m = 256; end
    m = round(m);
    if m <= 1
        carte = [0 0 0.5];
        carte = carte(1:max(m, 0), :);
        return
    end
    noeuds = [0 0.125 0.375 0.625 0.875 1];
    rouge  = [0 0     0     1     1     0.5];
    vert   = [0 0     1     1     0     0];
    bleu   = [0.5 1   1     0     0     0];
    x = rampeCarte(m);
    carte = [interp1(noeuds, rouge, x), interp1(noeuds, vert, x), ...
             interp1(noeuds, bleu, x)];
end
