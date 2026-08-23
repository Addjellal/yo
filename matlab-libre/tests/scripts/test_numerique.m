% test_numerique.m — algèbre linéaire, polynômes, intégration.
disp('--- numerique ---');

A = [4 1; 1 3];
assert(abs(det(A) - 11) < 1e-12);
assert(max(max(abs(A * inv(A) - eye(2)))) < 1e-12);
assert(abs(trace(A) - 7) < 1e-12);
assert(rank(A) == 2);
assert(abs(cond(A) - max(eig(A))/min(eig(A))) < 1e-8);

b = A \ [1; 2];
assert(max(abs(A * b - [1; 2])) < 1e-12);

% Décompositions.
[L, U, P] = lu(A);
assert(max(max(abs(P * A - L * U))) < 1e-12);
[Q, R] = qr(A);
assert(max(max(abs(Q * R - A))) < 1e-10);
assert(max(max(abs(Q' * Q - eye(2)))) < 1e-10);
C = chol(A);
assert(max(max(abs(C' * C - A))) < 1e-10);
[U2, S, V] = svd(A);
assert(max(max(abs(U2 * S * V' - A))) < 1e-9);

% Valeurs propres.
valeurs = sort(eig(A));
assert(abs(valeurs(1) + valeurs(2) - 7) < 1e-10);
assert(abs(valeurs(1) * valeurs(2) - 11) < 1e-10);
[Vp, D] = eig(A);
assert(max(max(abs(A * Vp - Vp * D))) < 1e-9);

% Exponentielle de matrice.
E = expm([0 1; 0 0]);
assert(max(max(abs(E - [1 1; 0 1]))) < 1e-12);

% Normes.
assert(abs(norm([3 4]) - 5) < 1e-12);
assert(abs(norm([1 2; 3 4], 'fro') - sqrt(30)) < 1e-12);
assert(abs(norm([1 -2 3], 1) - 6) < 1e-12);
assert(abs(norm([1 -2 3], inf) - 3) < 1e-12);

% Polynômes.
assert(abs(polyval([1 2 3], 2) - 11) < 1e-12);
r = sort(roots([1 -3 2]));
assert(max(abs(r - [1; 2])) < 1e-10);
assert(max(abs(poly([1 2]) - [1 -3 2])) < 1e-12);
p = polyfit([1 2 3], [2 4 6], 1);
assert(abs(p(1) - 2) < 1e-10);
assert(max(abs(polyder([3 2 1]) - [6 2])) < 1e-12);
assert(max(abs(conv([1 1], [1 -1]) - [1 0 -1])) < 1e-12);

% Interpolation.
assert(abs(interp1([1 2 3], [10 20 30], 2.5) - 25) < 1e-12);
assert(abs(spline([0 1 2 3], [0 1 4 9], 1.5) - 2.25) < 0.2);

% Zéros et minimisation.
assert(abs(fzero(@(x) x^2 - 2, [0 2]) - sqrt(2)) < 1e-8);
assert(abs(fminbnd(@(x) (x - 3)^2, 0, 10) - 3) < 1e-6);
xm = fminsearch(@(v) (v(1) - 1)^2 + (v(2) + 2)^2, [0 0]);
assert(abs(xm(1) - 1) < 1e-4 && abs(xm(2) + 2) < 1e-4);

% Intégration.
assert(abs(integral(@(x) x.^2, 0, 3) - 9) < 1e-8);
assert(abs(integral(@(x) sin(x), 0, pi) - 2) < 1e-8);
assert(abs(trapz([0 1 2], [0 1 2]) - 2) < 1e-12);

% Équations différentielles.
[t, y] = ode45(@(t, y) -y, [0 1], 1);
assert(abs(y(end) - exp(-1)) < 1e-5);
[t2, y2] = ode45(@(t, y) [y(2); -y(1)], [0 pi], [0; 1]);
assert(abs(y2(end, 1) - sin(pi)) < 1e-4);

%% ------------------------------------------- equations raides
% Un probleme raide dont on connait la solution exacte : pour
%    y' = L (y - sin t) + cos t,  y(0) = 0,
% la solution est y(t) = sin t quel que soit L. Avec L = -1e4 le probleme
% est franchement raide : un solveur explicite y prend des pas dictes par
% la stabilite, pas par la precision.
L = -1e4;
raide = @(t, y) L * (y - sin(t)) + cos(t);
for nomSolveur = {'ode15s', 'ode23s', 'ode23t', 'ode23tb'}
    [tr, yr] = feval(nomSolveur{1}, raide, [0 2*pi], 0);
    assert(tr(1) == 0 && abs(tr(end) - 2*pi) < 1e-12);
    assert(max(abs(yr - sin(tr))) < 1e-5);
    % Un solveur implicite doit y arriver en bien moins de pas qu'ode45.
    assert(numel(tr) < 6000);
end
% ode45 sur le meme probleme prend des milliers de pas : c'est la
% definition d'un probleme raide.
[t45, y45] = ode45(raide, [0 2*pi], 0);
assert(numel(t45) > 10000);
[t15, ~] = ode15s(raide, [0 2*pi], 0);
assert(numel(t15) < numel(t45) / 10);

% Systeme lineaire 2x2 a solution exacte : y' = [-2 1; 1 -2] y,
% y(0) = [1;0] donne y = [(e^-t + e^-3t)/2 ; (e^-t - e^-3t)/2].
A = [-2 1; 1 -2];
for nomSolveur = {'ode15s', 'ode23s', 'ode23t', 'ode23tb'}
    [tl, yl] = feval(nomSolveur{1}, @(t, y) A * y, [0 5], [1; 0]);
    exact1 = 0.5 * (exp(-tl) + exp(-3*tl));
    exact2 = 0.5 * (exp(-tl) - exp(-3*tl));
    assert(max(abs(yl(:, 1) - exact1)) < 1e-4);
    assert(max(abs(yl(:, 2) - exact2)) < 1e-4);
end

% Instants demandes : la sortie suit exactement le vecteur donne.
[td, yd] = ode15s(@(t, y) -y, [0 0.25 0.5 1], 1);
assert(isequal(size(yd), [4 1]));
assert(max(abs(td(:) - [0; 0.25; 0.5; 1])) < 1e-12);
assert(abs(yd(end) - exp(-1)) < 1e-4);

% Sortie a une seule variable : la structure de solution de MATLAB.
sol = ode23s(@(t, y) -y, [0 1], 1);
assert(isfield(sol, 'x') && isfield(sol, 'y'));
assert(abs(sol.y(end) - exp(-1)) < 1e-5);

% Les tolerances passees par odeset sont prises en compte : plus lache,
% moins de pas.
lache = odeset('RelTol', 1e-3, 'AbsTol', 1e-5);
[tLache, ~] = ode15s(raide, [0 2*pi], 0, lache);
[tSerre, ~] = ode15s(raide, [0 2*pi], 0, odeset('RelTol', 1e-9, 'AbsTol', 1e-12));
assert(numel(tLache) < numel(tSerre));
assert(abs(odeget(lache, 'RelTol') - 1e-3) < 1e-15);
assert(isempty(odeget(lache, 'MaxStep')));
assert(odeget(lache, 'MaxStep', 7) == 7);

% Robertson : cinetique chimique tres raide. La somme des especes est un
% invariant exact du systeme ; on la verifie sur toute la trajectoire.
robertson = @(t, y) [-0.04*y(1) + 1e4*y(2)*y(3);
                      0.04*y(1) - 1e4*y(2)*y(3) - 3e7*y(2)^2;
                      3e7*y(2)^2];
[tRob, yRob] = ode15s(robertson, [0 1e5], [1; 0; 0]);
assert(max(abs(sum(yRob, 2) - 1)) < 1e-6);
assert(all(diff(yRob(:, 3)) >= -1e-12));      % y3 ne peut que croitre
assert(all(yRob(:, 2) >= -1e-12));            % ni y2 devenir negatif
assert(yRob(end, 3) > 0.98 && yRob(end, 1) < 0.02);

% Van der Pol raide, mu = 1000 : l'exemple de reference. Deux solveurs
% independants doivent tomber sur la meme valeur finale.
mu = 1000;
vdp = @(t, y) [y(2); mu*(1 - y(1)^2)*y(2) - y(1)];
[~, yv] = ode15s(vdp, [0 3000], [2; 0]);
[~, yv2] = ode23s(vdp, [0 3000], [2; 0]);
assert(abs(yv(end, 1) - yv2(end, 1)) < 1e-2);
assert(abs(yv(end, 1) + 1.5106) < 1e-2);

disp('numerique : toutes les verifications passent');
