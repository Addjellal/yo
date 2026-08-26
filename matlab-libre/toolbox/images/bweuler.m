function e = bweuler(bw, connexite)
%BWEULER Nombre d'Euler : régions moins trous.
%   E = BWEULER(BW,8) par défaut.
    if nargin < 2, connexite = 8; end
    bw = logical(bw);
    [~, regions] = bwlabel(bw, connexite);
    % Un trou est une composante du fond qui ne touche pas le bord de
    % l'image ; la connexité du fond est l'opposée de celle des régions.
    if connexite == 8
        trous = 4;
    else
        trous = 8;
    end
    [etiquettesFond, composantesFond] = bwlabel(~bw, trous);
    [m, n] = size(bw);
    surLeBord = unique([etiquettesFond(1, :), etiquettesFond(m, :), ...
                        etiquettesFond(:, 1)', etiquettesFond(:, n)']);
    surLeBord = surLeBord(surLeBord > 0);
    nombreTrous = composantesFond - numel(surLeBord);
    e = regions - max(nombreTrous, 0);
end
