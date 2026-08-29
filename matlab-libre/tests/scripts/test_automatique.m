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
% Sans terme dérivé, le numérateur reste de degré un : (2s + 1)/s.
assert(max(abs(c.num - [2 1])) < 1e-12);
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

%% ------------------------------------------- conversions et prédicats
% tf et ss se convertissent l'un dans l'autre sans rien perdre.
[a, b, c, d] = ssdata(tf(1, [1 2 1]));
assert(max(abs(sort(eig(a)) - [-1; -1])) < 1e-8);
[num, den] = tfdata(ss(-1, 1, 1, 0));
assert(max(abs(num - [0 1])) < 1e-12);
assert(max(abs(den - [1 1])) < 1e-12);
[z, p, k] = zpkdata(tf([2 2], [1 3 2]));
assert(abs(z + 1) < 1e-10);
assert(max(abs(sort(p) - [-2; -1])) < 1e-10);
assert(abs(k - 2) < 1e-12);
assert(isproper(tf(1, [1 1])));
assert(~isproper(tf([1 0], 1)));
assert(issiso(tf(1, [1 1])));
assert(~issiso(ss(-eye(2), eye(2), eye(2), zeros(2))));
assert(isct(tf(1, [1 1])) && ~isdt(tf(1, [1 1])));
assert(isdt(tf(1, [1 -0.5], 0.1)) && ~isct(tf(1, [1 -0.5], 0.1)));
assert(order(tf(1, [1 2 1])) == 2);
assert(order(ss([0 1; 0 0], [0; 1], [1 0], 0)) == 2);
assert(isstable(tf(1, [1 1])) && ~isstable(tf(1, [1 -1])));
assert(isstable(tf(1, [1 -0.5], 0.1)) && ~isstable(tf(1, [1 -1.5], 0.1)));
% tf(K) et ss(K) donnent un gain statique ; tf(ss) convertit.
assert(abs(dcgain(tf(3)) - 3) < 1e-12);
assert(abs(dcgain(ss(3)) - 3) < 1e-12);
assert(abs(dcgain(tf(ss(-1, 1, 1, 0))) - 1) < 1e-12);
% zpk reconstruit le produit, et accepte un modèle.
assert(abs(dcgain(zpk(-1, [-2 -3], 6)) - 1) < 1e-12);
assert(abs(dcgain(zpk(tf([2 2], [1 3 2]))) - 1) < 1e-12);
% filt écrit les coefficients en puissances de z^-1.
gFilt = filt(1, [1 -0.3 0.02], 0.5);
assert(max(abs(tfdata(gFilt) - [1 0 0])) < 1e-12);
% d2d conserve le gain statique.
gDiscret = c2d(tf(1, [1 1]), 0.1);
assert(abs(dcgain(d2d(gDiscret, 0.2)) - dcgain(gDiscret)) < 1e-10);

%% ------------------------------------------------ réponse fréquentielle
% Pour 1/(s+1), |H(j1)| = 1/sqrt(2) et la phase vaut -45 degrés.
assert(abs(abs(freqresp(tf(1, [1 1]), 1)) - 1/sqrt(2)) < 1e-12);
assert(abs(evalfr(tf(1, [1 1]), 0) - 1) < 1e-12);
assert(abs(evalfr(tf(1, [1 1]), 1i) - (0.5 - 0.5i)) < 1e-12);
assert(max(abs(sigma(tf(1, [1 1]), [0 1 100]) - [1, 1/sqrt(2), 1/sqrt(1+1e4)])) < 1e-12);
% Modèle à deux entrées et deux sorties : les valeurs singulières en zéro
% sont les gains statiques des deux voies.
assert(max(abs(sigma(ss(-eye(2), eye(2), diag([2 3]), zeros(2)), 0) - [3; 2])) < 1e-10);
[magNichols, phaseNichols] = nichols(tf(1, [1 1]), 1);
assert(abs(20 * log10(magNichols) + 3.0103) < 1e-3);
assert(abs(phaseNichols + 45) < 1e-8);
[polesCarte, zerosCarte] = pzmap(tf([1 1], [1 3 2]));
assert(max(abs(sort(polesCarte) - [-2; -1])) < 1e-10);
assert(abs(zerosCarte + 1) < 1e-10);
assert(isequal(dsort([0.5; 0.9; 0.1]), [0.9; 0.5; 0.1]));
assert(isequal(esort([-3; -1; -2]), [-1; -2; -3]));
% Toutes les marges de 1/(s(s+1)^2) : gain 2 en 1 rad/s, phase 21.39
% degrés en 0.6823 rad/s. Ce sont les valeurs de tous les manuels.
margesToutes = allmargin(tf(1, [1 2 1 0]));
assert(abs(margesToutes.GainMargin - 2) < 1e-4);
assert(abs(margesToutes.GMFrequency - 1) < 1e-4);
assert(abs(margesToutes.PhaseMargin - 21.3864) < 1e-3);
assert(abs(margesToutes.PMFrequency - 0.6823) < 1e-3);
assert(margesToutes.Stable);
assert(~allmargin(tf(3, [1 2 1 0])).Stable);

%% ------------------------------------------- bases et formes canoniques
sysBase = ss([0 1; -2 -3], [0; 1], [1 0], 0);
sysTransforme = ss2ss(sysBase, [1 0; 1 1]);
assert(max(abs(sort(pole(sysTransforme)) - sort(pole(sysBase)))) < 1e-10);
assert(abs(dcgain(sysTransforme) - dcgain(sysBase)) < 1e-12);
[modal, Tmodal] = canon(sysBase, 'modal');
assert(max(max(abs(modal.A - diag(diag(modal.A))))) < 1e-10);
assert(max(abs(sort(diag(modal.A)) - [-2; -1])) < 1e-10);
% Paire complexe : bloc réel [sigma omega; -omega sigma].
modalComplexe = canon(ss([0 1; -2 -2], [0; 1], [1 0], 0), 'modal');
assert(max(abs(sort(eig(modalComplexe.A)) - sort([-1+1i; -1-1i]))) < 1e-10);
assert(abs(modalComplexe.A(1, 2) - 1) < 1e-10 && abs(modalComplexe.A(2, 1) + 1) < 1e-10);
compagne = canon(sysBase, 'companion');
assert(max(max(abs(compagne.A - [0 -2; 1 -3]))) < 1e-10);
assert(max(abs(compagne.B - [1; 0])) < 1e-10);
% Forme échelonnée : un mode non commandable se sépare.
[Abarre, Bbarre, ~, Tstair, kstair] = ctrbf([1 0; 0 2], [1; 0], [1 1]);
assert(sum(kstair) == 1);
assert(norm(Tstair * Tstair' - eye(2)) < 1e-12);
assert(norm(Abarre - Tstair * [1 0; 0 2] * Tstair') < 1e-12);
assert(abs(Bbarre(1)) < 1e-12);
[~, ~, ~, ~, kCommandable] = ctrbf([0 1; -2 -3], [0; 1], [1 0]);
assert(sum(kCommandable) == 2);
[~, ~, Cobs, Tobs, kobs] = obsvf([1 0; 0 2], [1; 1], [1 0]);
assert(sum(kobs) == 1);
assert(norm(Tobs * Tobs' - eye(2)) < 1e-12);
assert(abs(Cobs(1)) < 1e-12);

%% -------------------------------------------------- réduction de modèle
% Pour 1/(s+1), les deux grammiens valent 1/2, donc la valeur singulière
% de Hankel vaut 1/2.
assert(abs(hsvd(ss(-1, 1, 1, 0)) - 0.5) < 1e-10);
sysLent = ss([-1 0; 0 -100], [1; 1], [1 1], 0);
% Grammien exact : Wc(i,j) = -B(i)B(j)/(a_i+a_j).
assert(max(max(abs(gram(sysLent, 'c') - [1/2 1/101; 1/101 1/200]))) < 1e-10);
valeursHankel = hsvd(sysLent);
assert(max(abs(valeursHankel - sort(sqrt(eig([1/2 1/101; 1/101 1/200] ^ 2)), 'descend'))) < 1e-8);
[sysEquilibre, gEquilibre] = balreal(sysLent);
assert(max(max(abs(gram(sysEquilibre, 'c') - diag(gEquilibre)))) < 1e-8);
assert(max(max(abs(gram(sysEquilibre, 'o') - diag(gEquilibre)))) < 1e-8);
assert(abs(dcgain(sysEquilibre) - dcgain(sysLent)) < 1e-10);
sysReduit = balred(sysLent, 1);
assert(order(sysReduit) == 1);
assert(abs(dcgain(sysReduit) - dcgain(sysLent)) < 1e-10);
% L'erreur de troncature équilibrée est bornée par deux fois la somme des
% valeurs singulières supprimées.
grille = logspace(-3, 3, 400);
assert(max(abs(freqresp(sysLent, grille) - freqresp(sysReduit, grille))) <= 2 * gEquilibre(2) + 1e-12);
assert(abs(dcgain(modred(sysEquilibre, 2)) - dcgain(sysLent)) < 1e-10);
assert(order(modred(sysEquilibre, 2, 'del')) == 1);
% append juxtapose sans relier.
sysEmpile = append(tf(1, [1 1]), tf(2, [1 2]));
[Aempile, Bempile, Cempile] = ssdata(sysEmpile);
assert(isequal(size(Aempile), [2 2]));
assert(max(max(abs(Aempile - diag([-1 -2])))) < 1e-10);
assert(max(max(abs(Bempile - eye(2)))) < 1e-10);
assert(max(max(abs(Cempile - diag([1 2])))) < 1e-10);

%% --------------------------------------------------- Riccati et synthèse
% dare(1,1,1,1) est le nombre d'or, et le gain son inverse.
assert(abs(dare(1, 1, 1, 1) - (1 + sqrt(5)) / 2) < 1e-10);
assert(abs(dlqr(1, 1, 1, 1) - 2 / (1 + sqrt(5))) < 1e-10);
assert(abs(lqr(0, 1, 1, 1) - 1) < 1e-10);
% Double intégrateur : K = [1 sqrt(3)], pôles de module un à 150 degrés.
[Kdouble, Sdouble, pDouble] = lqr([0 1; 0 0], [0; 1], eye(2), 1);
assert(max(abs(Kdouble - [1 sqrt(3)])) < 1e-8);
assert(max(abs(abs(pDouble) - 1)) < 1e-8);
% Résidus des deux équations de Riccati.
Ari = [0 1; -2 -3]; Bri = [0; 1]; Qri = diag([2 1]); Rri = 3;
[~, Sri] = lqr(Ari, Bri, Qri, Rri);
assert(norm(Ari' * Sri + Sri * Ari - Sri * Bri * (Rri \ (Bri' * Sri)) + Qri) < 1e-10);
Adi = [1 0.1; 0 1]; Bdi = [0.005; 0.1];
[Kdi, Sdi] = dlqr(Adi, Bdi, eye(2), 1);
assert(norm(Adi' * Sdi * Adi - Sdi - Adi' * Sdi * Bdi * ((Bdi' * Sdi * Bdi + 1) \ (Bdi' * Sdi * Adi)) + eye(2)) < 1e-10);
assert(all(abs(eig(Adi - Bdi * Kdi)) < 1));
% lqry avec C = 1 et D = 0 se ramène à lqr.
sysLqry = ss([0 1; -2 -3], [0; 1], [1 0], 0);
assert(max(abs(lqry(sysLqry, 5, 1) - lqr(sysLqry.A, sysLqry.B, sysLqry.C' * 5 * sysLqry.C, 1))) < 1e-8);
% lqi ajoute un état intégrateur et stabilise l'ensemble.
Klqi = lqi(ss(-1, 1, 1, 0), eye(2), 1);
assert(numel(Klqi) == 2);
assert(all(real(eig([-1 0; -1 0] - [1; 0] * Klqi)) < 0));
% lqrd tend vers lqr quand la période tend vers zéro.
assert(abs(lqrd(0, 1, 1, 1, 0.001) - lqr(0, 1, 1, 1)) < 1e-3);
assert(abs(lqrd(0, 1, 1, 1, 0.01) - lqr(0, 1, 1, 1)) < 1e-2);

%% ------------------------------------------- observateur et régulateur
% L'observateur place son pôle où le gain le demande.
assert(abs(pole(estim(ss(-1, 1, 1, 0), 2)) + 3) < 1e-10);
% Principe de séparation : les pôles de la boucle fermée sont la réunion
% de ceux du retour d'état et de ceux de l'observateur.
gSep = ss([0 1; -2 -3], [0; 1], [1 0], 0);
Ksep = place(gSep.A, gSep.B, [-3 -4]);
Lsep = place(gSep.A', gSep.C', [-10 -12])';
correcteur = reg(gSep, Ksep, Lsep);
polesSepares = sort(real(pole(feedback(series(correcteur, gSep), 1, +1))));
assert(max(abs(polesSepares - [-12; -10; -4; -3])) < 1e-6);
% covar : pour 1/(s+1) et un bruit d'intensité un, la variance vaut 1/2.
assert(abs(covar(ss(-1, 1, 1, 0), 1) - 0.5) < 1e-10);
assert(isinf(covar(ss(-1, 1, 1, 1), 1)));
gCovar = c2d(ss(-1, 1, 1, 0), 0.1);
[Pcovar, Qcovar] = covar(gCovar, 1);
assert(abs(gCovar.A * Qcovar * gCovar.A' + gCovar.B * gCovar.B' - Qcovar) < 1e-12);
assert(abs(Pcovar - Qcovar) < 1e-12);

%% ------------------------------------------------ signaux et correcteurs
[uEssai, tEssai] = gensig('square', 4, 12, 0.5);
assert(isequal(uEssai(1:8)', [1 1 1 1 0 0 0 0]));
assert(abs(tEssai(end) - 12) < 1e-12);
[uSinus, ~] = gensig('sin', 4, 4, 1);
assert(max(abs(uSinus' - [0 1 0 -1 0])) < 1e-10);
[uImpulsion, ~] = gensig('pulse', 4, 12, 1);
assert(isequal(uImpulsion', [1 0 0 0 1 0 0 0 1 0 0 0 1]));
% pidstd est la forme standard de pid.
assert(max(abs(tfdata(pidstd(2, 1, 0)) - [2 2])) < 1e-12);
assert(max(abs(tfdata(pid(2, 2, 0)) - [2 2])) < 1e-12);
% pidtune impose la marge de phase par construction.
procede = tf(1, [1 3 3 1]);
for genreCorrecteur = {'p', 'pi', 'pd', 'pid'}
    [correcteurRegle, renseignements] = pidtune(procede, genreCorrecteur{1});
    assert(abs(renseignements.PhaseMargin - 60) < 0.05);
    assert(renseignements.Stable);
end

%% ------------------------------------- les modeles sont des objets
% « tf » et « ss » sont des classes, avec les operateurs de MATLAB : on
% ecrit les modeles comme on les ecrit a la main. Ils etaient de simples
% structures, et « z - 1.5 » donnait « Operator '-' is not supported for
% operands of type 'struct' ».
assert(strcmp(class(tf(1, [1 1])), 'tf'));
assert(strcmp(class(ss(-1, 1, 1, 0)), 'ss'));
assert(isa(tf(1, [1 1]), 'tf'));
% Convertir un modele deja converti rend bien un modele, pas une structure.
assert(strcmp(class(ss(ss(-1, 1, 1, 0))), 'ss'));
assert(strcmp(class(tf(tf(1, [1 1]))), 'tf'));
assert(strcmp(class(tf(ss(-1, 1, 1, 0))), 'tf'));
assert(strcmp(class(ss(tf(1, [1 1]))), 'ss'));

% La variable de Laplace, et celle de l'avance echantillonnee.
s = tf('s');
assert(max(abs(s.num - [1 0])) < 1e-12 && max(abs(s.den - 1)) < 1e-12);
assert(s.Ts == 0);
z = tf('z', 0.1);
assert(z.Ts == 0.1);
assert(tf('z').Ts == -1);            % periode encore indeterminee

% L'arithmetique des fractions rationnelles.
G = 1 / (s^2 + 2*s + 1);
assert(max(abs(G.num - 1)) < 1e-12);
assert(max(abs(G.den - [1 2 1])) < 1e-12);
H = 2.5 / (z - 1.5);
assert(max(abs(H.num - 2.5)) < 1e-12);
assert(max(abs(H.den - [1 -1.5])) < 1e-12);
assert(H.Ts == 0.1);
C = 0.5 * (z - 0.9) / (z - 1);
assert(max(abs(C.num - [0.5 -0.45])) < 1e-12);
assert(max(abs(C.den - [1 -1])) < 1e-12);
% Somme, produit, difference, puissance, inverse.
assert(max(abs((tf(1, [1 1]) + tf(1, [1 2])).num - [2 3])) < 1e-12);
assert(max(abs((tf(1, [1 1]) + tf(1, [1 2])).den - [1 3 2])) < 1e-12);
assert(max(abs((tf(1, [1 1]) - tf(1, [1 1])).num - 0)) < 1e-12);
assert(max(abs((tf(2, [1 1]) * tf(3, [1 2])).num - 6)) < 1e-12);
assert(max(abs((tf(1, [1 1])^2).den - [1 2 1])) < 1e-12);
assert(max(abs(inv(tf(1, [1 1])).num - [1 1])) < 1e-12);
assert(max(abs((1 - tf(1, [1 1])).num - [1 0])) < 1e-12);   % s/(s+1)
% Un gain n'impose aucune periode : il se marie aux deux.
assert((3 * z).Ts == 0.1);
% Deux periodes differentes ne se melangent pas.
essaiPeriodes = false;
try
    tf(1, [1 -0.5], 0.1) + tf(1, [1 -0.5], 0.2);   %#ok<VUNUS>
catch err
    essaiPeriodes = strcmp(err.identifier, 'Control:tf:periodes');
end
assert(essaiPeriodes);
% Un modele d'etat garde sa forme a travers les operations.
assert(strcmp(class(ss(-1, 1, 1, 0) * 2), 'ss'));
assert(abs(dcgain(ss(-1, 1, 1, 0) * 2) - 2) < 1e-10);
% Et l'ecriture par operateurs donne le meme resultat que feedback.
boucle = feedback(tf(1, [1 1]), 1);
assert(max(abs(boucle.den - [1 2])) < 1e-12);

% L'affichage nomme la variable et la periode, comme MATLAB.
texte = evalc('disp(2.5 / (tf(''z'', 1) - 1.5))');
assert(contains(texte, 'z - 1.5'));
assert(contains(texte, 'Sample time: 1 seconds'));
assert(contains(texte, 'Discrete-time transfer function.'));
texte = evalc('disp(tf(1, [1 2 1]))');
assert(contains(texte, 's^2 + 2 s + 1'));
assert(contains(texte, 'Continuous-time transfer function.'));

disp('automatique : toutes les verifications passent');
