% test_signal.m — Signal Processing Toolbox.
% Les valeurs de référence viennent de la définition des fonctions telle
% que la documente MathWorks : coefficients de fenêtres, propriétés exactes
% des filtres aux fréquences de coupure, identités de transformées.
disp('--- signal ---');

%% ------------------------------------------------------------- fenêtres
% Kaiser : symétrique, maximum au centre, valeurs de la documentation.
w = kaiser(5, 5);
assert(numel(w) == 5);
assert(abs(w(3) - 1) < 1e-12);
assert(abs(w(1) - w(5)) < 1e-15);
assert(abs(w(1) - 0.0367) < 1e-4);
assert(abs(w(2) - 0.5529) < 1e-4);
assert(isequal(kaiser(1, 5), 1));

% Triangulaire : les extrémités ne sont pas nulles, contrairement à Bartlett.
assert(max(abs(triang(4)' - [0.25 0.75 0.75 0.25])) < 1e-12);
assert(abs(triang(5)(1) - 1/3) < 1e-12);
assert(bartlett(5)(1) == 0);

% Tukey : R = 0 donne la fenêtre rectangulaire, R = 1 celle de Hann.
assert(isequal(tukeywin(8, 0), rectwin(8)));
assert(max(abs(tukeywin(8, 1) - hann(8))) < 1e-12);

% Gaussienne, Blackman-Harris, sommet plat, Nuttall : sommes connues.
assert(abs(gausswin(3)(1) - exp(-0.5 * 2.5^2)) < 1e-12);
assert(abs(blackmanharris(3)(2) - 1) < 1e-12);
% Somme exacte : sum(cos(2*pi*m*k/(N-1))) vaut 1 pour tout m entier non
% nul, donc la somme de la fenêtre vaut N*a0 - a1 + a2 - a3.
assert(abs(sum(blackmanharris(9)) - (9 * 0.35875 - 0.48829 + 0.14128 - 0.01168)) < 1e-9);
% Les coefficients publiés de la fenêtre à sommet plat sont arrondis :
% leur somme vaut 1,000000003, et non exactement 1.
assert(abs(flattopwin(3)(2) - 1) < 1e-8);
assert(abs(nuttallwin(3)(2) - 1) < 1e-12);
assert(abs(parzenwin(5)(3) - 1) < 1e-12);
assert(abs(bohmanwin(5)(1)) < 1e-12);
assert(abs(barthannwin(3)(2) - 1) < 1e-12);

% Largeur de bande de bruit équivalente : 1 pour la fenêtre rectangulaire.
assert(abs(enbw(rectwin(10)) - 1) < 1e-12);
assert(enbw(hamming(64)) > 1);

%% ----------------------------------------------------- réponses de filtres
% Réponse impulsionnelle d'un premier ordre : les puissances de 1/2.
assert(max(abs(impz(1, [1 -0.5], 4)' - [1 0.5 0.25 0.125])) < 1e-12);
% Réponse indicielle : les sommes partielles.
assert(max(abs(stepz(1, [1 -0.5], 4)' - [1 1.5 1.75 1.875])) < 1e-12);
% Retard de groupe d'une moyenne de deux points : une demi-période partout.
assert(max(abs(grpdelay([1 1], 1, 8) - 0.5)) < 1e-9);
% Retard de groupe d'un retard pur de trois échantillons : trois.
assert(max(abs(grpdelay([0 0 0 1], 1, 8) - 3)) < 1e-9);

% freqz accepte un vecteur de fréquences, une fréquence d'échantillonnage
% et l'option « whole ».
assert(max(abs(abs(freqz([1 1], 1, [0 pi/2 pi])') - [2 sqrt(2) 0])) < 1e-12);
[h, f] = freqz([1 1], 1, 4, 1000);
assert(numel(h) == 4 && abs(max(f) - 375) < 1e-12);
assert(numel(freqz([1 1], 1, 8, 'whole')) == 8);

%% --------------------------------------------------- zéros, pôles, sections
[z, p, k] = tf2zp([1 -1], [1 -0.5]);
assert(abs(z - 1) < 1e-12);
assert(abs(p - 0.5) < 1e-12);
assert(abs(k - 1) < 1e-12);
[b, a] = zp2tf(1, 0.5, 1);
assert(max(abs(b - [1 -1])) < 1e-12);
assert(max(abs(a - [1 -0.5])) < 1e-12);

[b, a] = butter(4, 0.3);
[sos, g] = tf2sos(b, a);
assert(size(sos, 1) == 2 && size(sos, 2) == 6);
[b2, a2] = sos2tf(sos, g);
assert(max(abs(b - b2)) < 1e-12);
assert(max(abs(a - a2)) < 1e-12);
x = (1:50)';
assert(norm(sosfilt(sos, x, g) - filter(b, a, x)) < 1e-9);

%% ------------------------------------------------ conception de filtres
% Chebyshev I : le module vaut exactement 10^(-Rp/20) à la coupure, et en
% continu aussi quand l'ordre est pair.
[b, a] = cheby1(2, 1, 0.3);
h = abs(freqz(b, a, [0 0.3*pi pi]));
assert(abs(h(1) - 10^(-1/20)) < 1e-6);
assert(abs(h(2) - 10^(-1/20)) < 1e-6);
assert(h(3) < 1e-6);
% Ordre impair : le gain part de 1. Un scalaire passé à freqz est un
% nombre de points, comme dans MATLAB : on évalue donc sur un vecteur.
[b, a] = cheby1(3, 1, 0.3);
h = abs(freqz(b, a, [0 pi]));
assert(abs(h(1) - 1) < 1e-9);
assert(h(2) < 1e-6);

% Chebyshev II : atténuation exactement RS au début de la bande coupée.
[b, a] = cheby2(3, 20, 0.4);
h = abs(freqz(b, a, [0 0.4*pi]));
assert(abs(h(1) - 1) < 1e-9);
assert(abs(h(2) - 0.1) < 1e-6);

% Ordres minimaux : la formule de Butterworth, appliquée au gabarit.
[n, Wn] = buttord(0.2, 0.4, 1, 40);
assert(n == 7);
assert(Wn > 0.2 && Wn < 0.4);
[b, a] = butter(n, Wn);
h = abs(freqz(b, a, [0 0.4 * pi]));
assert(20 * log10(h(2)) < -40 + 1e-6);
assert(abs(h(1) - 1) < 1e-9);
assert(cheb1ord(0.2, 0.4, 1, 40) == 5);
[n2, Wn2] = cheb2ord(0.2, 0.4, 1, 40);
assert(n2 == 5 && Wn2 == 0.4);

% fir2 suit le gabarit demandé.
b = fir2(20, [0 0.5 0.5 1], [1 1 0 0]);
h = abs(freqz(b, 1, [0 0.9 * pi]));
assert(abs(h(1) - 1) < 0.01);
assert(h(2) < 0.05);

% kaiserord : la formule de Kaiser, à 40 décibels.
[n, Wn, beta] = kaiserord([1000 1200], [1 0], [0.05 0.01], 8000);
assert(abs(beta - 3.3953) < 1e-3);
assert(n > 0 && Wn > 0 && Wn < 1);

%% ----------------------------------------------------------- transformées
n = 8;
assert(norm(czt((1:n)') - fft((1:n)')) < 1e-10);
assert(abs(goertzel([1 2 3 4], 1) - 10) < 1e-12);
assert(norm(dftmtx(4) * (1:4)' - fft((1:4)')) < 1e-12);
assert(max(abs(cconv([1 2], [1 1], 2) - [3 3])) < 1e-12);
% Sans longueur imposée, la convolution circulaire redonne la linéaire.
assert(max(abs(cconv([1 2 3], [1 1]) - conv([1 2 3], [1 1]))) < 1e-12);

%% ------------------------------------------------------- rééchantillonnage
assert(numel(decimate(1:100, 4)) == 25);
assert(numel(interp(1:10, 3)) == 30);
% Un signal lentement variable traverse la décimation sans se déformer.
t = (0:199) / 200;
lent = sin(2 * pi * 2 * t);
d = decimate(lent, 4);
assert(max(abs(d - sin(2 * pi * 2 * t(1:4:end)))) < 0.02);

% buffer découpe en colonnes.
assert(isequal(buffer(1:6, 3), [1 4; 2 5; 3 6]));
b = buffer(1:5, 3);
assert(isequal(size(b), [3 2]));
assert(b(3, 2) == 0);        % la dernière colonne est complétée par zéro
assert(isequal(buffer(1:6, 3, 1), [0 3; 1 4; 2 5]) || size(buffer(1:6, 3, 1), 1) == 3);

%% ---------------------------------------------------------------- mesures
assert(peak2peak([1 5 2]) == 4);
assert(abs(peak2rms([1 -1 1 -1]) - 1) < 1e-12);
assert(abs(rssq([3 4]) - 5) < 1e-12);
assert(abs(bandpower([1 -1 1 -1]) - 1) < 1e-12);
assert(abs(zerocrossrate([1 -1 1 -1]) - 0.75) < 1e-12);
assert(finddelay([1 2 3 0 0], [0 0 1 2 3]) == 2);
assert(finddelay([0 0 1 2 3], [1 2 3 0 0]) == -2);
assert(seqperiod([1 2 1 2 1 2]) == 2);
assert(seqperiod([1 1 1 1]) == 1);

% Alignement : après recalage, les deux signaux se superposent.
[xa, ya] = alignsignals([1 2 3 0 0], [0 0 1 2 3]);
assert(numel(xa) == numel(ya));
assert(max(abs(xa(3:5) - ya(3:5))) < 1e-12);

% Covariance croisée normalisée : 1 au décalage nul.
c = xcov([1 2 3 4], 'coeff');
assert(abs(c(4) - 1) < 1e-12);

% Fréquence moyenne et médiane d'une sinusoïde pure.
s = sin(2 * pi * 0.1 * (0:199));
assert(abs(meanfreq(s, 1) - 0.1) < 0.01);
assert(abs(medfreq(s, 1) - 0.1) < 0.01);

% polystab replie les racines dans le disque unité.
b = polystab([1 -2]);
assert(max(abs(roots(b))) <= 1 + 1e-12);
assert(max(abs(b - [1 -0.5])) < 1e-12);

%% ----------------------------------------------- estimation spectrale
x = sin(2 * pi * 50 * (0:999) / 1000);
[s, f, t] = spectrogram(x, 128, 64, 128, 1000);
assert(size(s, 1) == 65);
assert(abs(max(f) - 500) < 1e-9);
[~, k] = max(abs(s(:, 1)));
assert(abs(f(k) - 46.875) < 1e-9);      % le bac le plus proche de 50 Hz
assert(numel(t) == size(s, 2));

% Cohérence d'un signal avec lui-même : exactement 1.
c = mscohere(x, x, 128, 64, 128, 1000);
assert(max(abs(c - 1)) < 1e-9);

% Fonction de transfert d'un doubleur : gain 2, phase nulle.
h = tfestimate(x, 2 * x, 128, 64, 128, 1000);
assert(abs(abs(h(7)) - 2) < 1e-9);
assert(abs(imag(h(7))) < 1e-9);

%% ------------------------------------------- filtrage aller-retour exact
% filtfilt prolonge le signal aux bords : le transitoire ne pollue plus.
x = sin(2 * pi * (0:99) / 25)';
b = fir1(30, 0.25);
assert(max(abs(filtfilt(b, 1, x) - x)) < 0.05);
% Phase nulle : le résultat reste symétrique quand l'entrée l'est.
y = filtfilt(b, 1, [zeros(20, 1); 1; zeros(20, 1)]);
assert(max(abs(y - flipud(y))) < 1e-12);

disp('signal : toutes les verifications passent');
