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

    S11 = sys1(1:p1, 1:m1);
    S12 = sys1(1:p1, m1+1:m);
    S21 = sys1(p1+1:p, 1:m1);
    S22 = sys1(p1+1:p, m1+1:m);
    T11 = sys2(1:ny, 1:nu);
    T12 = sys2(1:ny, nu+1:n);
    T21 = sys2(ny+1:q, 1:nu);
    T22 = sys2(ny+1:q, nu+1:n);

    boucle = eye(ny) - T11.D * S22.D;
    if rcond(boucle) < eps
        error('Control:combination:AlgebraicLoop', ...
              'The interconnection is algebraic : I - T11.D*S22.D is singular.');
    end
    M = inv(eye(ny) - T11 * S22);

    % Les blocs vides — rien ne reste d'un côté — donnent une boucle
    % fermée sans entrée ou sans sortie : on rend alors le seul bloc utile.
    if p1 == 0 && m1 == 0
        sys = T22 + T21 * S22 * M * T12;
        return
    end
    if q2 == 0 && n2 == 0
        sys = S11 + S12 * M * T11 * S21;
        return
    end
    R11 = S11 + S12 * M * T11 * S21;
    R12 = S12 * M * T12;
    R21 = T21 * S21 + T21 * S22 * M * T11 * S21;
    R22 = T22 + T21 * S22 * M * T12;
    sys = [R11, R12; R21, R22];
end
