function y = sosfilt(sos, x, g)
%SOSFILT Filtre par sections du second ordre, en cascade.
%   Y = SOSFILT(SOS,X) applique chaque ligne de SOS l'une après l'autre.
%   C'est la forme numériquement stable pour les filtres d'ordre élevé.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      [sos, g] = tf2sos(b, a);
%      rng(1);
%      x = randn(100, 1);
%      max(abs(sosfilt(sos, x, g) - filter(b, a, x))) < 1e-10
%
%   Voir aussi TF2SOS.
    if nargin < 3, g = 1; end
    ligne = isrow(x);
    y = x(:) * g;
    for k = 1:size(sos, 1)
        y = filter(sos(k, 1:3), sos(k, 4:6), y);
    end
    if ligne, y = y.'; end
end
