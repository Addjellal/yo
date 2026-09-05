function h = qshiftFiltre(L, K)
%QSHIFTFILTRE Filtre de quart de retard pour l'arbre double.
%   H = QSHIFTFILTRE(L,K) rend un filtre d'échelle orthonormal de
%   longueur L paire, à K moments nuls, dont le retard de groupe vaut
%   (L-1)/2 - 1/4 au lieu de (L-1)/2.
%
%   C'est ce quart de retard qui fait tout. Le second arbre prend le
%   filtre renversé : renverser un filtre de longueur L change son retard
%   d en L-1-d, donc l'écart entre les deux arbres vaut
%
%      (L-1) - 2 [(L-1)/2 - 1/4] = 1/2
%
%   soit exactement le demi-échantillon qui rend les deux ondelettes
%   conjuguées de Hilbert l'une de l'autre, et leur somme complexe
%   analytique. Un banc orthogonal ordinaire, à phase linéaire ou
%   minimale, ne donne pas cet écart.
%
%   Le filtre est la solution de :
%      orthonormalité   sum_n h[n] h[n+2k] = delta_k,  k = 0..L/2-1
%      moments nuls     sum_n (-1)^n n^k h[n] = 0,     k = 0..K-1
%      retard           Im( H(w) exp(i d w) ) = 0 sur la bande passante
%
%   les deux premières familles exactement, la troisième au sens des
%   moindres carrés — un filtre à support fini ne peut pas avoir un
%   retard fractionnaire exact. Le poids du retard est réduit par paliers
%   jusqu'à zéro : la forme du filtre est fixée aux premiers paliers, et
%   le dernier ramène l'orthonormalité à la précision machine sans
%   quitter la solution trouvée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi DTFILTERS, DUALTREE, WFILTERS.
    if mod(L, 2) ~= 0 || L < 6
        error('wavelet:qshiftFiltre:Longueur', ...
              'La longueur doit être paire et valoir au moins six.');
    end
    if nargin < 2 || isempty(K)
        K = max(2, floor(L / 4));
    end
    d = (L - 1) / 2 - 1 / 4;
    omega = linspace(0, pi / 2, 64);
    poids = 4 / numel(omega);
    depart = daubechiesFiltre(L / 2, 'symetrique');
    h = depart(:) / sum(depart(:)) * sqrt(2);
    % Le retard est une exigence approchée, l'orthonormalité une exigence
    % exacte : on cherche d'abord la forme du filtre avec les deux au même
    % poids, puis on efface le retard des moindres carrés par paliers, ce
    % qui ramène l'orthonormalité à la précision machine sans quitter la
    % solution trouvée.
    for palier = [1 1e-1 1e-2 1e-3 1e-4 1e-5 0]
        h = affinerQshift(h, L, K, d, omega, poids * palier);
    end
    if sum(h) < 0
        h = -h;
    end
    h = h';
end

function h = affinerQshift(h, L, K, d, omega, poids)
    lambda = 1e-2;
    r = residuQshift(h, L, K, d, omega, poids);
    for iteration = 1:600
        J = jacobienneQshift(h, L, K, d, omega, poids);
        normale = J' * J;
        gradient = J' * r;
        avance = false;
        for essai = 1:60
            pas = -(normale + lambda * eye(L)) \ gradient;
            candidat = h + pas;
            rc = residuQshift(candidat, L, K, d, omega, poids);
            if norm(rc) < norm(r)
                h = candidat;
                r = rc;
                lambda = max(lambda / 3, 1e-15);
                avance = true;
                break
            end
            lambda = lambda * 4;
        end
        if ~avance || norm(r) < 1e-15
            break
        end
    end
end

function r = residuQshift(h, L, K, d, omega, poids)
    r = zeros(L / 2 + K + numel(omega), 1);
    p = 1;
    for k = 0:(L / 2 - 1)
        decale = 2 * k;
        r(p) = sum(h(1:(L - decale)) .* h((1 + decale):L)) - (k == 0);
        p = p + 1;
    end
    n = (0:(L - 1))';
    signes = (-1) .^ n;
    for k = 0:(K - 1)
        r(p) = sum(signes .* (n / L) .^ k .* h);
        p = p + 1;
    end
    H = exp(-1i * n * omega).' * h;
    r(p:end) = poids * imag(H .* exp(1i * d * omega(:)));
end

function J = jacobienneQshift(h, L, K, d, omega, poids)
    J = zeros(L / 2 + K + numel(omega), L);
    p = 1;
    for k = 0:(L / 2 - 1)
        decale = 2 * k;
        ligne = zeros(1, L);
        for indice = 1:L
            if indice + decale <= L
                ligne(indice) = ligne(indice) + h(indice + decale);
            end
            if indice - decale >= 1
                ligne(indice) = ligne(indice) + h(indice - decale);
            end
        end
        J(p, :) = ligne;
        p = p + 1;
    end
    n = (0:(L - 1))';
    signes = (-1) .^ n;
    for k = 0:(K - 1)
        J(p, :) = (signes .* (n / L) .^ k)';
        p = p + 1;
    end
    base = exp(-1i * omega(:) * n') .* exp(1i * d * omega(:));
    J(p:end, :) = poids * imag(base);
end
