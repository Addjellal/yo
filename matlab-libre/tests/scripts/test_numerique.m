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

disp('numerique : toutes les verifications passent');
