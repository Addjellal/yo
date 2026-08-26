function y = sosfilt(sos, x, g)
%SOSFILT Filtre par sections du second ordre, en cascade.
%   Y = SOSFILT(SOS,X) applique chaque ligne de SOS l'une après l'autre.
%   C'est la forme numériquement stable pour les filtres d'ordre élevé.
    if nargin < 3, g = 1; end
    ligne = isrow(x);
    y = x(:) * g;
    for k = 1:size(sos, 1)
        y = filter(sos(k, 1:3), sos(k, 4:6), y);
    end
    if ligne, y = y.'; end
end
