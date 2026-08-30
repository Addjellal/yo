function sys = lft(sys1, sys2, nu, ny)
%LFT Produit étoile de Redheffer : rebouclage partiel de deux modèles.
%   SYS = LFT(SYS1,SYS2) relie les dernières sorties de SYS1 aux premières
%   entrées de SYS2, et les premières sorties de SYS2 aux dernières
%   entrées de SYS1. Ce qui reste — les premières voies de SYS1 et les
%   dernières de SYS2 — devient l'entrée et la sortie du résultat.
%
%   Le nombre de voies reliées est le plus grand possible. Quand SYS2 est
%   le plus petit, tout SYS2 se referme et l'on obtient la boucle basse
%   F_l(SYS1,SYS2) — celle qui referme un correcteur sur un modèle
%   augmenté. Quand c'est SYS1, on obtient la boucle haute F_u(SYS2,SYS1)
%   — celle de l'analyse de robustesse, où l'incertitude referme le haut
%   du schéma.
%
%   SYS = LFT(SYS1,SYS2,NU,NY) impose le nombre de voies : NU sorties de
%   SYS1 vers SYS2, NY sorties de SYS2 vers SYS1.
%
%   En partitionnant SYS1 en [S11 S12 ; S21 S22] et SYS2 en
%   [T11 T12 ; T21 T22] selon ce découpage, et avec M = inv(I - T11*S22) :
%      R11 = S11 + S12*M*T11*S21     R12 = S12*M*T12
%      R21 = T21*(I + S22*M*T11)*S21 R22 = T22 + T21*S22*M*T12
%
%   Exemple :
%      P = augw(tf(1, [1 1]), 1, [], 1);
%      K = ss(-1, 1, 1, 0);
%      T = lft(P, K);            % la boucle fermée, pondérations comprises
%
%   Voir aussi FEEDBACK, SERIES, APPEND, HINFSYN, AUGW.
    sys1 = ss(sys1);
    sys2 = ss(sys2);
    [p, m] = size(sys1);
    [q, n] = size(sys2);
    if nargin < 3 || isempty(nu)
        nu = min(p, n);
    end
    if nargin < 4 || isempty(ny)
        ny = min(q, m);
    end
    if nu < 1 || ny < 1 || nu > p || nu > n || ny > q || ny > m
        error('Control:combination:LftSize', ...
              'The number of channels to connect does not fit the two models.');
    end
    p1 = p - nu;      % sorties de SYS1 qui restent
    m1 = m - ny;      % entrées de SYS1 qui restent
    q2 = q - ny;      % sorties de SYS2 qui restent
    n2 = n - nu;      % entrées de SYS2 qui restent

    % Les blocs, découpés dans les matrices : le résultat garde ainsi
    % exactement les états des deux modèles. Un assemblage par produits et
    % inverses en fabriquerait bien plus, et ses modes cachés — instables
    % même quand la boucle ne l'est pas — fausseraient toute mesure de
    % norme.
    A1 = sys1.A; A2 = sys2.A;
    n1etats = size(A1, 1);
    n2etats = size(A2, 1);
    B1w = sys1.B(:, 1:m1);            B1e = sys1.B(:, m1+1:m);
    C1z = sys1.C(1:p1, :);            C1v = sys1.C(p1+1:p, :);
    D1zw = sys1.D(1:p1, 1:m1);        D1ze = sys1.D(1:p1, m1+1:m);
    D1vw = sys1.D(p1+1:p, 1:m1);      D1ve = sys1.D(p1+1:p, m1+1:m);
    B2v = sys2.B(:, 1:nu);            B2w = sys2.B(:, nu+1:n);
    C2e = sys2.C(1:ny, :);            C2z = sys2.C(ny+1:q, :);
    D2ev = sys2.D(1:ny, 1:nu);        D2ew = sys2.D(1:ny, nu+1:n);
    D2zv = sys2.D(ny+1:q, 1:nu);      D2zw = sys2.D(ny+1:q, nu+1:n);

    boucle = eye(nu) - D1ve * D2ev;
    if rcond(boucle) < eps
        error('Control:combination:AlgebraicLoop', ...
              'The interconnection is algebraic : I - D1ve*D2ev is singular.');
    end
    M = inv(boucle);
    Vx1 = M * C1v;            Vx2 = M * D1ve * C2e;
    Vw1 = M * D1vw;           Vw2 = M * D1ve * D2ew;
    Ex1 = D2ev * Vx1;         Ex2 = C2e + D2ev * Vx2;
    Ew1 = D2ev * Vw1;         Ew2 = D2ew + D2ev * Vw2;

    A = [A1 + B1e * Ex1,   B1e * Ex2; ...
         B2v * Vx1,        A2 + B2v * Vx2];
    B = [B1w + B1e * Ew1,  B1e * Ew2; ...
         B2v * Vw1,        B2w + B2v * Vw2];
    C = [C1z + D1ze * Ex1, D1ze * Ex2; ...
         D2zv * Vx1,       C2z + D2zv * Vx2];
    D = [D1zw + D1ze * Ew1, D1ze * Ew2; ...
         D2zv * Vw1,        D2zw + D2zv * Vw2];
    sys = ss(A, B, C, D, ss.periode(sys1, sys2));
end
