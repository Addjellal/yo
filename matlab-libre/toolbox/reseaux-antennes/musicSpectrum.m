function [spectre, angles] = musicSpectrum(signaux, d, nSources, angles)
%MUSICSPECTRUM Estimation de direction d'arrivée par la méthode MUSIC.
%   [SPECTRE,ANGLES] = MUSICSPECTRUM(SIGNAUX,D,NSOURCES,ANGLES) rend un
%   spectre dont les pics donnent les directions d'arrivée.
%
%   Le principe : la matrice de covariance des signaux reçus se
%   décompose en un sous-espace signal, de dimension NSOURCES, et un
%   sous-espace bruit orthogonal. Les directions cherchées sont celles où
%   le vecteur de pointage est orthogonal au sous-espace bruit — le
%   spectre y diverge.
%
%   La résolution n'est donc plus bornée par l'ouverture du réseau, mais
%   par le rapport signal à bruit et le nombre d'échantillons. C'est ce
%   qu'on appelle la super-résolution : là où la formation de voies ne
%   voit qu'une bosse, MUSIC voit deux pics.
%
%   Le prix : il faut connaître le nombre de sources. En annoncer un de
%   moins en fait perdre une ; un de trop ajoute un pic parasite. C'est la
%   faiblesse de la méthode, et elle est de principe.
%
%   Exemple :
%      rng(1);
%      % Huit capteurs, une source a vingt degres, et du bruit.
%      a = steeringVector(8, 0.5, deg2rad(20));
%      recu = a * (randn(1, 200) + 1i * randn(1, 200)) / sqrt(2) ...
%             + 0.1 * (randn(8, 200) + 1i * randn(8, 200));
%      [spectre, angles] = musicSpectrum(recu, 0.5, 1);
%      [~, k] = max(spectre);
%      abs(rad2deg(angles(k)) - 20) < 5      % 1 : la source est retrouvee
%
%   Voir aussi BEAMFORMERDAS, STEERINGVECTOR, ARRAYGAIN.
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
