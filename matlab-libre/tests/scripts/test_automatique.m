% test_automatique.m — Control System Toolbox.
% Les références sont analytiques : solutions fermées des équations de
% Lyapunov et de Riccati, réponses connues du premier ordre, zéros de
% transmission qu'on lit sur la fonction de transfert.
disp('--- automatique ---');

%% ------------------------------------------------- équations matricielles
% A*X + X*A' + Q = 0 avec A = -1 et Q = 1 donne X = 1/2.
assert(abs(lyap(-1, 1) - 0.5) < 1e-12);
% Cas matriciel : la solution reste symétrique.
A = [-2 1; 0 -3];
Q = eye(2);
X = lyap(A, Q);
assert(norm(A * X + X * A' + Q, 'fro') < 1e-10);
assert(norm(X - X', 'fro') < 1e-12);

% Sylvester : A*X + X*B + C = 0.
Xs = lyap([-1 0; 0 -2], [-3 0; 0 -4], eye(2));
assert(norm([-1 0; 0 -2] * Xs + Xs * [-3 0; 0 -4] + eye(2), 'fro') < 1e-10);

% Lyapunov discrète : A*X*A' - X + Q = 0 avec A = 1/2 donne 1/(1-1/4).
assert(abs(dlyap(0.5, 1) - 4/3) < 1e-12);
Ad = [0.5 0.1; 0 0.3];
Xd = dlyap(Ad, eye(2));
assert(norm(Ad * Xd * Ad' - Xd + eye(2), 'fro') < 1e-10);

%% -------------------------------------------------------------- Riccati
% A'X + XA - XBR^-1B'X + Q = 0 avec A = 0, B = Q = R = 1 donne X = 1.
[X, K] = care(0, 1, 1, 1);
assert(abs(X - 1) < 1e-8);
assert(abs(K - 1) < 1e-8);
% Vérification directe de l'équation, sur un cas moins trivial.
A = [0 1; 0 0]; B = [0; 1];
[X2, K2] = care(A, B, eye(2), 1);
assert(norm(A' * X2 + X2 * A - X2 * B * B' * X2 + eye(2), 'fro') < 1e-6);
assert(max(real(eig(A - B * K2))) < 0);       % la boucle fermée est stable

% Riccati discrète : A = B = Q = R = 1 donne le nombre d'or.
[Xd, Kd] = dare(1, 1, 1, 1);
assert(abs(Xd - (1 + sqrt(5)) / 2) < 1e-8);
assert(abs(Kd - Xd / (Xd + 1)) < 1e-8);

%% ------------------------------------------------------------ grammiens
% Pour dx/dt = -x + u, y = x : les deux grammiens valent 1/2.
s = ss(-1, 1, 1, 0);
assert(abs(gram(s, 'c') - 0.5) < 1e-10);
assert(abs(gram(s, 'o') - 0.5) < 1e-10);

%% ------------------------------------------------------- réponse libre
% x0 = 1 sur dx/dt = -x : la sortie décroît en exp(-t).
y = initial(ss(-1, 0, 1, 0), 1, 5);
assert(abs(y(1) - 1) < 1e-12);
assert(abs(y(end) - exp(-5)) < 1e-6);

%% --------------------------------------------- fonction de transfert
% Leverrier : la conversion est exacte dans les deux sens.
[num, den] = ss2tf(-1, 1, -1, 1);
assert(max(abs(num - [1 0])) < 1e-12);        % s/(s+1)
assert(max(abs(den - [1 1])) < 1e-12);
[A, B, C, D] = tf2ss([1 -2], [1 3 2]);
[num2, den2] = ss2tf(A, B, C, D);
assert(max(abs(num2 - [0 1 -2])) < 1e-10);
assert(max(abs(den2 - [1 3 2])) < 1e-10);
[A3, B3, C3, D3] = tf2ss(2, [1 3 2]);
[num3, ~] = ss2tf(A3, B3, C3, D3);
assert(max(abs(num3 - [0 0 2])) < 1e-10);

%% ------------------------------------------------ zéros de transmission
% Le transfert de (A,B,C,D) = (-1,1,-1,1) vaut s/(s+1) : un zéro en 0.
assert(abs(tzero(-1, 1, -1, 1)) < 1e-12);
% (s-2)/(s^2+3s+2) : un zéro en 2.
assert(abs(tzero(A, B, C, D) - 2) < 1e-8);
% Un système sans zéro fini n'en rend aucun.
assert(isempty(tzero(A3, B3, C3, D3)));

%% ---------------------------------------------------------- correcteurs
c = pid(2, 1, 0);
assert(max(abs(c.num - [0 2 1])) < 1e-12);
assert(max(abs(c.den - [1 0])) < 1e-12);
assert(abs(dcgain(pid(3, 0, 0)) - 3) < 1e-12);      % correcteur purement P
d = pid(1, 0, 2);
assert(max(abs(d.num - [2 1])) < 1e-12);
assert(abs(d.den - 1) < 1e-12);
% Avec un filtre sur la dérivée, le degré monte d'un cran.
e = pid(1, 1, 1, 0.1);
assert(numel(e.den) == 3);
assert(abs(e.num(1) - (1 * 0.1 + 1)) < 1e-12);

%% ------------------------------------------- caractéristiques temporelles
% Premier ordre de constante 1 : montée de 10 % à 90 % en ln(9) secondes,
% aucun dépassement.
info = stepinfo(tf(1, [1 1]));
assert(abs(info.RiseTime - log(9)) < 0.05);
assert(info.Overshoot < 1e-6);
assert(info.SettlingTime > 3 && info.SettlingTime < 5);
% Second ordre peu amorti : le dépassement suit exp(-pi*z/sqrt(1-z^2)).
z = 0.5;
info2 = stepinfo(tf(1, [1 2*z 1]));
attendu = 100 * exp(-pi * z / sqrt(1 - z^2));
assert(abs(info2.Overshoot - attendu) < 2);

%% -------------------------------------------------------- bande passante
% Pour 1/(s+1), le gain descend de 3 dB exactement en 0,9976 rad/s.
assert(abs(bandwidth(tf(1, [1 1])) - 0.9976) < 1e-3);
% Un gain pur n'a pas de coupure.
assert(isinf(bandwidth(tf(1, 1))));

%% ------------------------------------------------- réalisation minimale
m = minreal(tf(conv([1 2], [1 1]), conv([1 2], [1 3])));
assert(max(abs(m.num - [1 1])) < 1e-8);
assert(max(abs(m.den - [1 3])) < 1e-8);

%% ------------------------------------------------------------ estimation
% Pour A = 0, C = 1, Q = R = 1, le gain de Kalman vaut 1.
assert(abs(lqe(0, 1, 1, 1, 1) - 1) < 1e-8);
[L, P] = lqe([-1 0; 0 -2], eye(2), eye(2), eye(2), eye(2));
assert(norm(P - P', 'fro') < 1e-8);
assert(all(real(eig([-1 0; 0 -2] - L * eye(2))) < 0));

disp('automatique : toutes les verifications passent');
