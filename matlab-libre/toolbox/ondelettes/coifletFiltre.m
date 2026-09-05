function h = coifletFiltre(N)
%COIFLETFILTRE Filtre d'échelle d'une coiflette, par ses conditions.
%   H = COIFLETFILTRE(N) rend le filtre d'échelle de coifN, de longueur
%   6N et de somme racine de deux, dans l'ordre de synthèse : c'est
%   celui de MATLAB, où le plus gros coefficient tombe à l'indice 4N-1.
%
%   Aucune table n'est recopiée : le filtre est la solution du système
%   qui définit une coiflette. Avec j l'indice de 0 à 6N-1, m = 2N le
%   centre et n = (j-m)/2N l'abscisse centrée et réduite :
%
%      somme                  sum_j h[j] = sqrt(2)
%      orthogonalité          sum_j h[j] h[j+2k] = delta_k, k = 0..3N-1
%      moments de l'ondelette sum_j (-1)^j n^k h[j] = 0,    k = 0..2N-1
%      moments de l'échelle   sum_j n^k h[j] = 0,           k = 1..2N-1
%
%   Les moments de la fonction d'échelle sont ce qui distingue une
%   coiflette d'une ondelette de Daubechies : celle-ci n'annule que les
%   moments de l'ondelette. Comme la fonction d'échelle est alors elle
%   aussi aveugle aux polynômes de degré inférieur à 2N, les coefficients
%   d'approximation d'un signal polynomial sont, à un facteur près, les
%   échantillons du signal — ce qui n'est vrai d'aucune dbN.
%
%   Le système est écrit sur le filtre d'analyse, renversé du filtre
%   rendu : renverser échange les rôles des deux, comme le fait ORTHFILT,
%   et déplace le centre de 2N à 4N-1 sans rien changer aux conditions.
%
%   Le système compte 7N-1 équations pour 6N inconnues ; il n'a de
%   solution que parce que certaines conditions dépendent des autres.
%   Un solveur parti de la symlette y trouve un minimum local dès N = 3 :
%   la solution est donc atteinte par continuation, coifN partant de
%   coif(N-1) prolongée de zéros, avec relances au hasard si besoin.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi COIFWAVF, DAUBECHIESFILTRE, WFILTERS.
    persistent connus
    N = round(N);
    if ~isscalar(N) || N < 1 || N > 8
        error('wavelet:coifletFiltre:Ordre', ...
              'L''ordre d''une coiflette doit être un entier de 1 à 8.');
    end
    if isempty(connus)
        connus = {};
    end
    if numel(connus) >= N && ~isempty(connus{N})
        h = connus{N};
        return
    end
    depart = [];
    for ordre = 1:N
        if numel(connus) >= ordre && ~isempty(connus{ordre})
            depart = connus{ordre}(:);
            continue
        end
        depart = resoudreCoiflette(ordre, depart);
        connus{ordre} = depart;   %#ok<AGROW>
    end
    h = connus{N};
end

function h = resoudreCoiflette(N, precedente)
    L = 6 * N;
    m = 2 * N;
    j = ((0:(L - 1))' - m) / (2 * N);
    signes = (-1) .^ (0:(L - 1))';
    if isempty(precedente)
        % La symlette de même longueur satisfait déjà l'orthogonalité et
        % les moments de l'ondelette : il ne reste qu'à déplacer la
        % solution vers ceux de la fonction d'échelle.
        base = daubechiesFiltre(3 * N, 'symetrique');
        base = base(:) / sum(base(:)) * sqrt(2);
    else
        % La précédente est rendue dans l'ordre de synthèse : on la
        % renverse pour retrouver l'ordre où le système est écrit. Deux
        % zéros à gauche et quatre à droite portent la longueur de 6(N-1)
        % à 6N et le centre de 2(N-1) à 2N.
        precedente = precedente(end:-1:1);
        base = [zeros(2, 1); precedente(:); zeros(4, 1)];
    end
    meilleure = base;
    meilleurEcart = inf;
    for essai = 0:24
        depart = base;
        if essai > 0
            rng(essai);
            depart = base + (0.01 * ceil(essai / 8)) * randn(L, 1);
            depart = depart / sum(depart) * sqrt(2);
        end
        [candidate, ecart] = affinerCoiflette(depart, N, L, j, signes);
        if ecart < meilleurEcart
            meilleurEcart = ecart;
            meilleure = candidate;
        end
        if meilleurEcart < 1e-13
            break
        end
    end
    if meilleurEcart > 1e-8
        error('wavelet:coifletFiltre:Convergence', ...
              'La coiflette d''ordre %d n''a pas convergé (écart %g).', ...
              N, meilleurEcart);
    end
    if sum(meilleure) < 0
        meilleure = -meilleure;
    end
    h = meilleure(end:-1:1)';
end

function [h, ecart] = affinerCoiflette(h, N, L, j, signes)
    lambda = 1e-3;
    r = residuCoiflette(h, N, L, j, signes);
    for iteration = 1:2000
        J = jacobienneCoiflette(h, N, L, j, signes);
        normale = J' * J;
        gradient = J' * r;
        avance = false;
        for essai = 1:80
            pas = -(normale + lambda * eye(L)) \ gradient;
            candidate = h + pas;
            rc = residuCoiflette(candidate, N, L, j, signes);
            if norm(rc) < norm(r)
                h = candidate;
                r = rc;
                lambda = max(lambda / 3, 1e-16);
                avance = true;
                break
            end
            lambda = lambda * 4;
        end
        if ~avance || norm(r) < 1e-15
            break
        end
    end
    ecart = norm(r);
end

function r = residuCoiflette(h, N, L, j, signes)
    r = zeros(7 * N, 1);
    p = 1;
    r(p) = sum(h) - sqrt(2);
    p = p + 1;
    for k = 0:(3 * N - 1)
        d = 2 * k;
        r(p) = sum(h(1:(L - d)) .* h((1 + d):L)) - (k == 0);
        p = p + 1;
    end
    for k = 0:(2 * N - 1)
        r(p) = sum(signes .* j .^ k .* h);
        p = p + 1;
    end
    for k = 1:(2 * N - 1)
        r(p) = sum(j .^ k .* h);
        p = p + 1;
    end
    r = r(1:(p - 1));
end

function J = jacobienneCoiflette(h, N, L, j, signes)
    J = zeros(7 * N, L);
    p = 1;
    J(p, :) = 1;
    p = p + 1;
    for k = 0:(3 * N - 1)
        d = 2 * k;
        ligne = zeros(1, L);
        for indice = 1:L
            if indice + d <= L
                ligne(indice) = ligne(indice) + h(indice + d);
            end
            if indice - d >= 1
                ligne(indice) = ligne(indice) + h(indice - d);
            end
        end
        J(p, :) = ligne;
        p = p + 1;
    end
    for k = 0:(2 * N - 1)
        J(p, :) = (signes .* j .^ k)';
        p = p + 1;
    end
    for k = 1:(2 * N - 1)
        J(p, :) = (j .^ k)';
        p = p + 1;
    end
    J = J(1:(p - 1), :);
end
