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

%% --------------------------------------------------- les traces
% Un trace sans sortie ne doit rien afficher : « bode(S, w) » dessine, il
% n'ecrit pas des milliers de nombres dans la console.
G = tf(1, [1 0.4 1]);
T = feedback(series(G, tf(10, [1 0])), 1);
grille = logspace(-2, 2, 50);
figure
assert(isempty(strtrim(evalc('bode(G, grille)'))));
assert(isempty(strtrim(evalc('bodemag(G, grille)'))));
assert(isempty(strtrim(evalc('sigma(G, grille)'))));
assert(isempty(strtrim(evalc('step(G)'))));
assert(isempty(strtrim(evalc('impulse(G)'))));
assert(isempty(strtrim(evalc('nyquist(G)'))));
assert(isempty(strtrim(evalc('nichols(G)'))));
assert(isempty(strtrim(evalc('pzmap(G)'))));
assert(isempty(strtrim(evalc('rlocus(G)'))));
assert(isempty(strtrim(evalc('margin(G)'))));

% Plusieurs modeles sur le meme trace, chacun avec son style.
assert(isempty(strtrim(evalc('bode(G, ''b'', T, ''r--'', grille)'))));
assert(isempty(strtrim(evalc('sigma(G, T, grille)'))));
assert(isempty(strtrim(evalc('step(G, ''b'', T, ''r--'', 20)'))));
assert(isempty(strtrim(evalc('bodemag(G, T, {0.01, 100})'))));

% Avec des sorties, un seul modele — comme dans MATLAB.
plusieurs = false;
try
    [m, p] = sigma(G, T, grille);   %#ok<ASGLU>
catch err
    plusieurs = strcmp(err.identifier, 'Control:analysis:MultipleModels');
end
assert(plusieurs);

% « bode » coupe la case courante en deux : le gain en haut, la phase en
% bas. Les cases voisines ne bougent pas.
figure
subplot(2, 2, 1); plot(1:10);
subplot(2, 2, 2); bode(G, grille);
boites = numel(strfind(matlibre_svg(), 'fill="white" stroke="#222"'));
assert(boites == 3);                  % la case 1, plus les deux moities

% Le module et la phase, sur une grille imposee.
[m, p, w] = bode(tf(1, [1 1]), 1);
assert(abs(m - 1 / sqrt(2)) < 1e-12);
assert(abs(p + 45) < 1e-12);
assert(w == 1);
% « bodemag » rend le meme module que « bode ».
[m2, w2] = bodemag(tf(1, [1 1]), 1);
assert(abs(m2 - m) < 1e-15 && w2 == w);
% Les bornes {WMIN,WMAX} developpent une grille de deux cents points.
[~, ~, wBornes] = bode(G, {0.1, 10});
assert(numel(wBornes) == 200);
assert(abs(wBornes(1) - 0.1) < 1e-12 && abs(wBornes(end) - 10) < 1e-12);

% « margin » accepte aussi une reponse deja calculee.
[gmSys, pmSys] = margin(tf(1, [1 2 1 0]));
[mm, pp, ww] = bode(tf(1, [1 2 1 0]), logspace(-4, 4, 4000).');
[gmRep, pmRep] = margin(mm, pp, ww);
assert(abs(gmSys - gmRep) < 1e-12 && abs(pmSys - pmRep) < 1e-12);
assert(abs(gmSys - 2) < 1e-3);
close all

%% ------------------------------- modeles a plusieurs entrees et sorties
% L'algebre des schemas-blocs se fait dans l'espace d'etat : elle doit
% donner, a chaque pulsation, exactement ce que donne l'algebre des
% matrices sur les reponses frequentielles. C'est la seule verification
% qui vaille — deux chemins independants vers le meme nombre.
Am = [-1 0.5; 0 -2];
G2 = ss(Am, [1 0; 0.3 1], [1 0; 0 1], zeros(2, 2));
H2 = ss(-3 * eye(2), eye(2), [2 0; 0 1], 0.5 * eye(2));
pulsations = [0.1 1 7];
reponse = @(sys, p) freqresp(sys, p);

for p = pulsations
    a = reponse(G2, p);
    b = reponse(H2, p);
    assert(max(max(abs(reponse(G2 * H2, p) - a * b))) < 1e-10);
    assert(max(max(abs(reponse(G2 + H2, p) - (a + b)))) < 1e-10);
    assert(max(max(abs(reponse(G2 - H2, p) - (a - b)))) < 1e-10);
    assert(max(max(abs(reponse(-G2, p) + a))) < 1e-10);
    assert(max(max(abs(reponse(inv(H2), p) - inv(b)))) < 1e-10);
    assert(max(max(abs(reponse(G2 / H2, p) - a / b))) < 1e-10);
    assert(max(max(abs(reponse(H2 \ G2, p) - b \ a))) < 1e-10);
    assert(max(max(abs(reponse(2 * G2, p) - 2 * a))) < 1e-10);
    assert(max(max(abs(reponse(H2 ^ 2, p) - b * b))) < 1e-10);
    % Serie, parallele et boucle fermee.
    assert(max(max(abs(reponse(series(G2, H2), p) - b * a))) < 1e-10);
    assert(max(max(abs(reponse(parallel(G2, H2), p) - (a + b)))) < 1e-10);
    boucle = reponse(feedback(G2, H2), p);
    assert(max(max(abs(boucle - (eye(2) + a * b) \ a))) < 1e-9);
    positive = reponse(feedback(G2, H2, +1), p);
    assert(max(max(abs(positive - (eye(2) - a * b) \ a))) < 1e-9);
end

% La taille d'un modele, c'est [sorties entrees].
assert(isequal(size(G2), [2 2]));
assert(size(G2, 1) == 2 && size(G2, 2) == 2);
assert(order(G2) == 2);

% Choisir des voies : SYS(I,J) va des entrees J aux sorties I.
voie = G2(2, 1);
assert(isequal(size(voie), [1 1]));
for p = pulsations
    complet = reponse(G2, p);
    assert(abs(reponse(voie, p) - complet(2, 1)) < 1e-10);
    demi = reponse(G2(:, 2), p);
    assert(max(abs(demi - complet(:, 2))) < 1e-10);
end
horsVoie = false;
try
    G2(3, 1);   %#ok<VUNUS>
catch err
    horsVoie = strcmp(err.identifier, 'Control:ltiselect:IndexOutOfRange');
end
assert(horsVoie);

% Assembler : [G1 G2] cote a cote, [G1; G2] l'un sur l'autre.
cote = [G2, H2];
empile = [G2; H2];
assert(isequal(size(cote), [2 4]));
assert(isequal(size(empile), [4 2]));
for p = pulsations
    assert(max(max(abs(reponse(cote, p) - [reponse(G2, p), reponse(H2, p)]))) < 1e-10);
    assert(max(max(abs(reponse(empile, p) - [reponse(G2, p); reponse(H2, p)]))) < 1e-10);
end

% Une taille qui ne colle pas est refusee, avec le message de MATLAB.
mauvaiseTaille = false;
try
    G2 * ss(-1, 1, 1, 0);   %#ok<VUNUS>
catch err
    mauvaiseTaille = strcmp(err.identifier, 'Control:combination:TimesSize');
end
assert(mauvaiseTaille);

%% ------------------------------------------ le produit etoile de Redheffer
% LFT : la meme verification, en comparant l'assemblage des modeles a
% l'algebre des blocs sur les matrices de reponse.
P4 = ss([-1 0.2; 0 -3], [1 0.5; 0 1], [1 0; 1 1], [0.1 0; 0 0.2]);
K1 = ss(-2, 1, 1, 0.3);
basse = lft(P4, K1);           % K1 referme la derniere voie
for p = pulsations
    S = reponse(P4, p);
    T = reponse(K1, p);
    attendu = S(1,1) + S(1,2) * T / (1 - S(2,2) * T) * S(2,1);
    assert(abs(reponse(basse, p) - attendu) < 1e-9);
end
% Boucle haute : le petit modele vient en premier et referme les
% PREMIERES voies du grand.
haute = lft(K1, P4);
for p = pulsations
    S = reponse(P4, p);
    T = reponse(K1, p);
    attendu = S(2,2) + S(2,1) * T / (1 - S(1,1) * T) * S(1,2);
    assert(abs(reponse(haute, p) - attendu) < 1e-9);
end
% Produit etoile general : une voie de chaque cote reste libre.
G4 = ss(blkdiag(-1, -2), eye(2), eye(2), [0.2 0; 0.1 0.3]);
H4 = ss(blkdiag(-4, -5), eye(2), eye(2), [0.4 0.1; 0 0.5]);
etoile = lft(G4, H4, 1, 1);
assert(isequal(size(etoile), [2 2]));
for p = pulsations
    S = reponse(G4, p);
    T = reponse(H4, p);
    M = 1 / (1 - T(1,1) * S(2,2));
    R = [S(1,1) + S(1,2) * M * T(1,1) * S(2,1), S(1,2) * M * T(1,2); ...
         T(2,1) * S(2,1) + T(2,1) * S(2,2) * M * T(1,1) * S(2,1), ...
         T(2,2) + T(2,1) * S(2,2) * M * T(1,2)];
    assert(max(max(abs(reponse(etoile, p) - R))) < 1e-9);
end

%% ------------------------------ assembler par les noms : connect et sumblk
% CONNECT doit donner exactement ce que donne l'ecriture a la main : c'est
% la seule facon de verifier un assembleur.
Gc = ss(tf(2, [1 1]));  Gc.InputName = 'u';  Gc.OutputName = 'y';
Kc = ss(tf(10, [1 0])); Kc.InputName = 'e';  Kc.OutputName = 'u';
Sc = sumblk('e = r - y');
assert(isequal(Sc.D, [1 -1]));
assert(isequal(Sc.InputName(:)', {'r', 'y'}));
assert(isequal(Sc.OutputName(:)', {'e'}));
Tc = connect(Gc, Kc, Sc, 'r', 'y');
Tref = feedback(series(Kc, Gc), 1);
for p = [0.1 1 10]
    assert(abs(freqresp(Tc, p) - freqresp(Tref, p)) < 1e-12);
end
assert(order(Tc) == order(Gc) + order(Kc));
assert(isequal(Tc.InputName(:)', {'r'}));

% Plusieurs sorties : la boucle fermee et la commande.
TU = connect(Gc, Kc, Sc, 'r', {'y', 'u'});
assert(isequal(size(TU), [2 1]));
for p = [0.5 5]
    voies = freqresp(TU, p);
    assert(abs(voies(1) - freqresp(Tref, p)) < 1e-12);
    assert(abs(voies(2) - freqresp(feedback(Kc, Gc), p)) < 1e-12);
end

% Un gain dans le point de sommation, et un signal a plusieurs voies.
S2 = sumblk('u = a - 2*b + c');
assert(isequal(S2.D, [1 -2 1]));
S3 = sumblk('e = r - y', 2);
assert(isequal(size(S3.D), [2 4]));
assert(isequal(S3.InputName(:)', {'r(1)', 'r(2)', 'y(1)', 'y(2)'}));

% Un nom qui ne mene nulle part est signale, non ignore.
inconnu = '';
try
    connect(Gc, Kc, Sc, 'r', 'z');
catch err
    inconnu = err.identifier;
end
assert(strcmp(inconnu, 'Control:connect:Unknown'));
% Un bloc sans noms aussi.
sansNoms = '';
try
    connect(ss(-1, 1, 1, 0), 'r', 'y');
catch err
    sansNoms = err.identifier;
end
assert(strcmp(sansNoms, 'Control:connect:NoNames'));

%% ---------------------------------------- retards, sensibilites, hasard
% L'approximation de Pade doit garder le gain et rendre la bonne phase :
% c'est tout ce qu'on lui demande.
[numPade, denPade] = pade(0.1, 1);
assert(max(abs(numPade - [-1 20])) < 1e-12);
assert(max(abs(denPade - [1 20])) < 1e-12);
retard = pade(0.5, 3);
assert(abs(dcgain(retard) - 1) < 1e-9);
for p = [0.5 1 2]
    % La phase suit celle du retard exact tant qu'on reste sous l'ordre.
    assert(abs(angle(freqresp(retard, p)) + 0.5 * p) < 1e-3);
end
assert(abs(abs(freqresp(retard, 3)) - 1) < 1e-9);   % le module reste unite

% Les six sensibilites d'une boucle, comparees a l'ecriture a la main.
Gs = tf(2, [1 1]);
Ks = tf(10, [1 0]);
L = loopsens(Gs, Ks);
assert(L.Stable);
for p = [0.1 1 10]
    g = freqresp(ss(Gs), p);
    k = freqresp(ss(Ks), p);
    assert(abs(freqresp(L.So, p) - 1 / (1 + g * k)) < 1e-9);
    assert(abs(freqresp(L.To, p) - g * k / (1 + g * k)) < 1e-9);
    assert(abs(freqresp(L.CSo, p) - k / (1 + g * k)) < 1e-9);
    assert(abs(freqresp(L.PSi, p) - g / (1 + k * g)) < 1e-9);
end

% Un modele tire au hasard est stable par construction.
for essai = 1:5
    assert(max(real(pole(rss(3)))) < 0);
    assert(max(abs(pole(drss(3)))) < 1);
end
assert(isequal(size(rss(2, 3, 4)), [3 4]));
assert(drss(2).Ts == 1);

% L'etat ajoute aux sorties ne change pas la dynamique.
base = ss([-1 0; 0 -2], [1; 1], [1 0], 0);
augmente = augstate(base);
assert(isequal(size(augmente), [3 1]));
assert(isequal(augmente.A, base.A));

% La separation stable / instable : la somme redonne le modele.
mixte = ss([-1 0; 0 2], [1; 1], [1 1], 0);
[partieStable, partieInstable] = stabsep(mixte);
assert(order(partieStable) == 1 && order(partieInstable) == 1);
assert(max(real(pole(partieStable))) < 0);
assert(max(real(pole(partieInstable))) > 0);
for p = [0.3 3]
    assert(abs(freqresp(partieStable, p) + freqresp(partieInstable, p) ...
               - freqresp(mixte, p)) < 1e-9);
end

% Le regulateur LQG, monte de deux facons, stabilise.
Glqg = ss(-1, 1, 1, 0);
[estimateur, gainL] = kalman(Glqg, 1, 1);          %#ok<ASGLU>
gainK = lqr(Glqg.A, Glqg.B, 1, 1);
regulateur = lqgreg(estimateur, gainK);
assert(max(real(pole(feedback(Glqg, -regulateur)))) < 0);
regulateur2 = lqg(Glqg, eye(2), eye(2));
assert(max(real(pole(feedback(Glqg, -regulateur2)))) < 0);

% La mise a l'echelle ne change ni les poles ni le gain.
malFichu = ss([-1 1e6; 0 -2], [1; 1e6], [1 1e-6], 0);
misALEchelle = prescale(malFichu);
assert(max(abs(sort(real(pole(misALEchelle))) - sort(real(pole(malFichu))))) < 1e-6);
assert(abs(dcgain(misALEchelle) - dcgain(malFichu)) / abs(dcgain(malFichu)) < 1e-9);

% Le facteur de Cholesky du grammien.
facteur = lyapchol([-1 0; 0 -2], eye(2));
gramien = facteur' * facteur;
assert(max(max(abs([-1 0; 0 -2] * gramien + gramien * [-1 0; 0 -2]' + eye(2)))) < 1e-12);

% Les grilles ne changent pas les bornes de l'axe.
figure
rlocus(tf(1, [1 2 0]));
bornesAvant = xlim();
sgrid;
assert(isequal(xlim(), bornesAvant));
figure
nichols(tf(1, [1 1 1]));
bornesNichols = ylim();
ngrid;
assert(isequal(ylim(), bornesNichols));
close all

% Les caracteristiques d'une reponse quelconque.
tLsim = linspace(0, 10, 500);
reponse = 1 - exp(-tLsim);
mesures = lsiminfo(reponse, tLsim);
assert(mesures.SettlingTime > 3 && mesures.SettlingTime < 5);
assert(abs(mesures.Max - reponse(end)) < 1e-9);

% Les retards ne sont pas representes, et la fonction le dit sans mentir.
assert(~hasdelay(tf(1, [1 1])));
assert(isequal(totaldelay(tf(1, [1 1])), 0));

%% ------------------------------------------------ retards
% Un passe-tout de Thiran ne change aucun module : seule la phase
% bouge, comme pour un vrai retard.
filtreRetard = thiran(0.25, 0.1);
[numRetard, denRetard] = tfdata(filtreRetard);
assert(max(abs(numRetard - denRetard(end:-1:1))) < 1e-12);
pulsations = linspace(0.01, pi, 30) / 0.1;
reponseRetard = freqresp(filtreRetard, pulsations);
assert(max(abs(abs(reponseRetard(:)) - 1)) < 1e-9);
% Un retard multiple de la période est un simple décalage.
[numEntier, denEntier] = tfdata(thiran(0.3, 0.1));
assert(numel(numEntier) == 4 && abs(numEntier(end) - 1) < 1e-12);
assert(abs(numEntier(1)) < 1e-12 && isequal(denEntier, 1));
% delayss approche le retard par Padé : l'ordre grandit d'autant.
assert(order(delayss(-1, 1, 1, 0, [1 1 0.5])) == 4);
assert(order(delayss(-1, 1, 1, 0, [])) == 1);

%% ----------------------------------------------------- unités
% Changer l'unité de temps ne change pas ce que le modèle décrit : le
% gain en continu reste le même, et la constante de temps se convertit.
enMinutes = chgTimeUnit(tf(1, [1 1]), 'minutes');
[~, denMinutes] = tfdata(enMinutes);
assert(abs(denMinutes(1) - 1/60) < 1e-12);
assert(abs(dcgain(enMinutes) - 1) < 1e-12);
assert(strcmp(enMinutes.TimeUnit, 'minutes'));
% L'aller-retour rend le modèle de départ.
[numRetour, denRetour] = tfdata(chgTimeUnit(enMinutes, 'seconds'));
assert(max(abs(denRetour - [1 1])) < 1e-9 && abs(numRetour - 1) < 1e-9);
% Une réponse en fréquence change d'unité de la même façon.
enHertz = chgFreqUnit(frd([1 0.5], [1 10]), 'Hz');
assert(max(abs(enHertz.Frequency(:) - [1; 10] / (2 * pi))) < 1e-12);
assert(strcmp(enHertz.FrequencyUnit, 'Hz'));

%% ------------------------------------------------- options et blocs
optionsBode = bodeoptions;
assert(strcmp(optionsBode.FreqUnits, 'rad/s') && strcmp(optionsBode.MagUnits, 'dB'));
optionsEchelon = stepDataOptions('StepAmplitude', 5, 'InputOffset', 1);
assert(optionsEchelon.StepAmplitude == 5 && optionsEchelon.InputOffset == 1);
% STEP suit ces niveaux : le premier gain statique fois l'offset, le
% dernier fois offset + amplitude. Un modele de gain statique un le
% montre directement.
premierOrdre = tf(1, [1 1]);
[yEchelon, ~] = step(premierOrdre, 0:0.05:12, optionsEchelon);
assert(abs(yEchelon(1) - 1) < 1e-6);
assert(abs(yEchelon(end) - 6) < 1e-3);
% Sans options, l'echelon reste unite : rien n'a bouge pour l'appelant
% qui n'en donne pas.
[yUnite, tUnite] = step(premierOrdre, 0:0.05:12);
assert(abs(yUnite(1)) < 1e-9 && abs(yUnite(end) - 1) < 1e-3);
% Un gain statique double double les deux niveaux.
[yDouble, ~] = step(tf(2, [1 1]), 0:0.05:12, optionsEchelon);
assert(abs(yDouble(1) - 2) < 1e-6 && abs(yDouble(end) - 12) < 2e-3);
% La reponse est bien affine en les deux reglages.
[yCinq, ~] = step(premierOrdre, 0:0.05:12, stepDataOptions('StepAmplitude', 5));
assert(norm(yCinq - 5 * yUnite) < 1e-9);
% Un integrateur n'a pas de gain statique : l'offset est refuse plutot
% que rendu faux.
offsetRefuse = false;
try
    step(tf(1, [1 0]), 0:0.1:5, stepDataOptions('InputOffset', 1));
catch
    offsetRefuse = true;
end
assert(offsetRefuse);
% BODE accepte les options sans se meprendre sur la grille.
figure('Visible', 'off');
optionsTrace = bodeoptions;
optionsTrace.FreqUnits = 'Hz';
optionsTrace.Grid = 'on';
optionsTrace.MagUnits = 'abs';
optionsTrace.PhaseUnits = 'rad';
optionsTrace.XLim = {[0.01 100]};
optionsTrace.Title.String = 'Essai';
bode(premierOrdre, optionsTrace);
bode(premierOrdre, logspace(-2, 2, 60), optionsTrace);
bode(premierOrdre, 'b', tf(1, [1 0.2 1]), 'r--', optionsTrace);
bodemag(premierOrdre, optionsTrace);
bodemag(premierOrdre, logspace(-2, 2, 60), optionsTrace);
close('all');
% Les reglages lus sont bien ceux demandes.
reglageHz = matlibre_reglages_bode(optionsTrace);
assert(abs(reglageHz.diviseurW - 2 * pi) < 1e-12);
assert(~reglageHz.enDecibels);
assert(abs(reglageHz.facteurPhase - pi / 180) < 1e-15);
assert(strcmp(reglageHz.grille, 'on') && strcmp(reglageHz.titre, 'Essai'));
assert(isequal(reglageHz.xlim, [0.01 100]));
% Une structure vide rend les valeurs par defaut.
reglageNu = matlibre_reglages_bode([]);
assert(reglageNu.diviseurW == 1 && reglageNu.enDecibels);
assert(reglageNu.facteurPhase == 1 && isempty(reglageNu.xlim));
% Avec des sorties, les options ne changent pas le calcul : le module et
% la phase restent ceux de la definition.
[moduleUn, phaseUn] = bode(premierOrdre, 1);
assert(abs(moduleUn - 1 / sqrt(2)) < 1e-12 && abs(phaseUn + 45) < 1e-12);
blocs = struct('C', pid(1, 2), 'G', tf(1, [1 1]));
assert(isa(getBlockValue(blocs, 'C'), 'tf'));
blocRefuse = false;
try
    getBlockValue(blocs, 'inconnu');
catch
    blocRefuse = true;
end
assert(blocRefuse);

%% ------------------------------------------- reglage et vues
[correcteur, infoReglage] = pidtool(tf(1, [1 3 3 1]), 'pid');
assert(isa(correcteur, 'tf'));
assert(infoReglage.PhaseMargin > 30);
figure('Visible', 'off');
sisotool(tf(1, [1 3 3 1]));
close('all');

%% -------------------------------------- proprietes d'un objet
% isprop, ismethod et properties disent ce qu'un modèle porte.
modeleTest = tf(1, [1 1]);
assert(isprop(modeleTest, 'num') && ~isprop(modeleTest, 'inexistant'));
assert(ismethod(modeleTest, 'horzcat'));
assert(~ismethod(modeleTest, 'inexistant'));
assert(numel(properties(modeleTest)) >= 5);
assert(numel(properties('duration')) >= 2);


% STEPINFO part aussi d'une reponse deja simulee.
modeleInfo = tf(1, [1 0.4 1]);
% La meme grille des deux cotes : STEPINFO(SYS) choisit la sienne, et
% deux grilles differentes ne donnent pas le meme sommet au pixel pres.
[reponseInfo, instantsInfo] = step(modeleInfo);
depuisModele = stepinfo(modeleInfo);
depuisReponse = stepinfo(reponseInfo, instantsInfo);
assert(abs(depuisModele.Overshoot - depuisReponse.Overshoot) < 1e-9);
assert(abs(depuisModele.Peak - depuisReponse.Peak) < 1e-9);
% Un second ordre peu amorti depasse : zeta = 0.2 donne environ 53 %.
assert(abs(depuisReponse.Overshoot - 100 * exp(-pi * 0.2 / sqrt(1 - 0.04))) < 2);
% La valeur finale peut etre imposee quand la simulation s'arrete tot.
courte = stepinfo(reponseInfo(1:60), instantsInfo(1:60), 1);
assert(isfinite(courte.Overshoot));
refuseInfo = false;
try
    stepinfo(reponseInfo);
catch
    refuseInfo = true;
end
assert(refuseInfo, 'STEPINFO(Y) sans les instants doit etre refuse');

% RLOCUS rend une ligne par pole et une colonne par gain, comme MATLAB.
modeleLieu = tf(1, [1 3 2]);
[racinesLieu, gainsLieu] = rlocus(modeleLieu);
assert(size(racinesLieu, 1) == numel(pole(modeleLieu)));
assert(size(racinesLieu, 2) == numel(gainsLieu));
% Au gain le plus faible, les branches partent des poles du modele.
assert(max(abs(sort(real(racinesLieu(:, 1))) - sort(pole(modeleLieu)))) < 0.05);
% Chaque colonne est bien l'ensemble des poles de la boucle fermee.
for essaiLieu = [1 50 numel(gainsLieu)]
    attenduLieu = sort(pole(feedback(gainsLieu(essaiLieu) * modeleLieu, 1)));
    obtenuLieu = sort(racinesLieu(:, essaiLieu));
    assert(max(abs(sort(real(obtenuLieu)) - sort(real(attenduLieu)))) < 1e-8);
end
disp('stepinfo et rlocus : ok');

disp('automatique : toutes les verifications passent');
