function [Abar, Bbar, Cbar, T, k] = ctrbf(A, B, C, tolerance)
%CTRBF Forme échelonnée de commandabilité.
%   [ABAR,BBAR,CBAR,T,K] = CTRBF(A,B,C) rend une base orthonormée dans
%   laquelle la partie non commandable se sépare :
%
%      Abar = T A T' = [ Anc   0  ]      Bbar = T B = [ 0  ]
%                      [ A21   Ac ]                   [ Bc ]
%
%   La paire (Ac,Bc) est commandable. K donne, échelon par échelon, le
%   nombre d'états que chaque puissance de A ajoute à l'espace atteignable
%   depuis B ; SUM(K) est la dimension de la partie commandable.
%
%   Les échelons sont construits par orthonormalisation successive de
%   B, AB, A^2B... : à chaque tour on ne garde que ce que le tour ajoute
%   vraiment, ce qui rend la décomposition numériquement stable.
%
%   Exemple :
%      [ab, bb, cb, t, k] = ctrbf([1 0; 0 2], [1; 0], [1 1]);
%      sum(k)   % 1 : un seul mode est commandable
%
%   Voir aussi OBSVF, CTRB, MINREAL.
    n = size(A, 1);
    if nargin < 3 || isempty(C), C = zeros(0, n); end
    if nargin < 4 || isempty(tolerance)
        tolerance = n * norm([A, B], 1) * eps;
        if tolerance == 0, tolerance = eps; end
    end
    % Construction des échelons de Krylov.
    echelons = {};
    total = zeros(n, 0);
    courant = orthonormaliser(B, total, tolerance);
    while ~isempty(courant)
        echelons{end+1} = courant;                       %#ok<AGROW>
        total = [total, courant];
        if size(total, 2) >= n, break, end
        courant = orthonormaliser(A * courant, total, tolerance);
    end
    % Complément orthogonal : la partie non commandable.
    complement = orthonormaliser(eye(n), total, tolerance);
    % Ordre : non commandable d'abord, puis les échelons du dernier au
    % premier, pour que B ne charge que les dernières lignes.
    base = complement;
    for j = numel(echelons):-1:1
        base = [base, echelons{j}];
    end
    T = base';
    Abar = T * A * T';
    Bbar = T * B;
    Cbar = C * T';
    k = zeros(1, n);
    for j = numel(echelons):-1:1
        k(numel(echelons) - j + 1) = size(echelons{j}, 2);
    end
end

function Q = orthonormaliser(M, dejaLa, tolerance)
%ORTHONORMALISER Base orthonormée de ce que M ajoute à DEJALA.
    if isempty(M)
        Q = zeros(size(dejaLa, 1), 0);
        return
    end
    if ~isempty(dejaLa)
        M = M - dejaLa * (dejaLa' * M);
    end
    [U, S, ~] = svd(M, 'econ');
    if isempty(S)
        Q = zeros(size(M, 1), 0);
        return
    end
    valeurs = diag(S);
    garde = valeurs > max(tolerance, max(valeurs) * 1e-12);
    Q = U(:, garde);
    % Une seconde passe de projection évite la perte d'orthogonalité.
    if ~isempty(dejaLa) && ~isempty(Q)
        Q = Q - dejaLa * (dejaLa' * Q);
        [U2, S2, ~] = svd(Q, 'econ');
        valeurs2 = diag(S2);
        Q = U2(:, valeurs2 > max(tolerance, max([valeurs2; eps]) * 1e-12));
    end
end
