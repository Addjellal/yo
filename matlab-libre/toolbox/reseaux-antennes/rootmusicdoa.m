function ang = rootmusicdoa(R, nsig, varargin)
%ROOTMUSICDOA Directions d'arrivée par la méthode MUSIC polynomiale (root-MUSIC).
%   ANG = ROOTMUSICDOA(R,NSIG) estime, en degrés depuis la normale, les
%   directions d'arrivée de NSIG ondes planes reçues par un réseau
%   linéaire uniforme d'éléments espacés d'une demi-longueur d'onde, dont
%   R est la covariance spatiale N x N. ANG est une ligne 1 x NSIG.
%   ANG = ROOTMUSICDOA(R,NSIG,'ElementSpacing',D) donne l'espacement en
%   longueurs d'onde.
%
%   Le sous-espace bruit En (les N - NSIG vecteurs propres des plus
%   petites valeurs propres) est orthogonal aux vecteurs de pointage des
%   sources. Le spectre nul a(z)' En En' a(z), où z = exp(i 2 pi d
%   sin(theta)), est un polynôme en z dont les coefficients sont les
%   sommes des diagonales de En En' : ses racines les plus proches du
%   cercle unité donnent les directions (Barabell, 1983). Contrairement
%   au spectre de MUSIC, il n'y a pas de grille d'angles à balayer.
%
%   Exemple :
%      % Documentation de MATLAB.
%      R = sensorcov((0:9) * 0.5, [0 -25 30], db2pow(-5));
%      doa = rootmusicdoa(R, 3)            % -25, 0, 30 (dans un ordre ou un autre)
%
%   Voir aussi ESPRITDOA, MUSICDOA, SENSORCOV, STEERVEC.
    [R, d] = matlibre_doa_options(R, nsig, varargin, 'rootmusicdoa', {'ElementSpacing'});
    n = size(R, 1);
    [V, D] = eig(R);
    [~, ordre] = sort(real(diag(D)), 'ascend');
    En = V(:, ordre(1:n - nsig));
    C = En * En';
    coefficients = zeros(1, 2 * n - 1);
    for k = -(n - 1):(n - 1)
        coefficients(n - k) = sum(diag(C, k));
    end
    z = roots(coefficients);
    % Les racines vont par paires z, 1/conj(z) : on garde celles du disque,
    % et dans la région visible quand l'espacement est sous la demi-onde.
    z = z(abs(z) <= 1 + 1e-12);
    visibles = abs(angle(z)) <= 2 * pi * d + 1e-12;
    if nnz(visibles) >= nsig
        z = z(visibles);
    end
    if numel(z) < nsig
        error('phased:rootmusicdoa:Racines', ...
              'Le polynôme n''a que %d racines dans le disque unité, pour %d signaux.', ...
              numel(z), nsig);
    end
    [~, proches] = sort(abs(1 - abs(z)));
    z = z(proches(1:nsig));
    s = angle(z) / (2 * pi * d);
    ang = asind(max(-1, min(1, s))).';
end
