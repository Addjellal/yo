function [spectre, angles] = musicSpectrum(signaux, d, nSources, angles)
%MUSICSPECTRUM Estimation de direction d'arrivée par la méthode MUSIC.
    if nargin < 4
        angles = linspace(-pi/2, pi/2, 361);
    end
    n = size(signaux, 1);
    R = (signaux * signaux') / size(signaux, 2);
    [V, D] = eig(R);
    valeurs = real(diag(D));
    [~, ordre] = sort(valeurs, 'descend');
    V = V(:, ordre);
    bruit = V(:, nSources+1:end);
    spectre = zeros(size(angles));
    for k = 1:numel(angles)
        a = steeringVector(n, d, angles(k));
        spectre(k) = 1 / max(real(a' * (bruit * bruit') * a), 1e-12);
    end
end
