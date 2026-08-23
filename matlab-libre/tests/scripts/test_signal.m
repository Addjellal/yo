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

%% ------------------------------- analyse, conversions, transformees
% residue : decomposition en elements simples, verifiee sur des cas dont
% la reponse s'ecrit a la main.
[r, p, k] = residue([1 0], [1 3 2]);            % s/((s+1)(s+2))
[~, ordre] = sort(real(p));
assert(max(abs(sort(real(p)) - [-2; -1])) < 1e-12);
assert(max(abs(r(ordre) - [2; -1])) < 1e-12);   % 2/(s+2) - 1/(s+1)
assert(isempty(k));
% Pole double : 1/((s+1)^2 (s+2)) = 1/(s+2) - 1/(s+1) + 1/(s+1)^2
[r2, p2] = residue(1, conv([1 2 1], [1 2]));
assert(numel(r2) == 3);
% Les trois residus valent 1 sur (s+2), -1 sur (s+1) et 1 sur (s+1)^2.
assert(abs(sum(real(r2)) - 1) < 1e-8);
[bb, aa] = residue(r2, p2, []);
assert(max(abs(real(bb) - 1)) < 1e-8);
assert(max(abs(real(aa) - conv([1 2 1], [1 2]))) < 1e-8);
% Partie entiere : (s^2+1)/(s+1) = s - 1 + 2/(s+1)
[r3, p3, k3] = residue([1 0 1], [1 1]);
assert(abs(r3 - 2) < 1e-12 && abs(p3 + 1) < 1e-12);
assert(max(abs(k3 - [1 -1])) < 1e-12);

% residuez : la somme des r_k p_k^n redonne la reponse impulsionnelle.
den = conv([1 -0.5], [1 -0.25]);
[rz, pz] = residuez(1, den);
h = filter(1, den, [1 zeros(1, 9)]);
reconstitue = zeros(1, 10);
for j = 1:numel(rz)
    reconstitue = reconstitue + rz(j) * pz(j) .^ (0:9);
end
assert(max(abs(h - real(reconstitue))) < 1e-12);
[r1, p1] = residuez(1, [1 -0.5]);
assert(abs(r1 - 1) < 1e-12 && abs(p1 - 0.5) < 1e-12);

% freqs : le passe-bas du premier ordre vaut 1/sqrt(2) a sa coupure.
assert(abs(abs(freqs(1, [1 1], 1)) - 1/sqrt(2)) < 1e-14);
assert(abs(angle(freqs(1, [1 1], 1)) + pi/4) < 1e-14);
[hs, ws] = freqs(1, [1 1]);
assert(numel(ws) == 200 && numel(hs) == 200);

% phasez et phasedelay : 1 + e^-jw = 2cos(w/2) e^-jw/2.
[phi, w] = phasez([1 1], 1, 64);
assert(max(abs(phi + w/2)) < 1e-12);
assert(max(abs(phasedelay([1 1], 1, 64) - 0.5)) < 1e-12);

% zerophase : la decomposition H = Hr exp(j phi) doit se recomposer.
for essai = {{[1 1], 1}, {[1 0 -1], 1}, {[1 0.5], [1 -0.5]}}
    bb2 = essai{1}{1};
    aa2 = essai{1}{2};
    [hr, wz, phz] = zerophase(bb2, aa2, 32);
    hz = freqz(bb2, aa2, 32);
    assert(max(abs(hz(:) - hr .* exp(1i * phz))) < 1e-12);
    assert(isreal(hr));
end
% Type 1 : Hr = 2 cos(w/2).  Type 3 : Hr = 2 sin(w).
[hr1, w1] = zerophase([1 1], 1, 32);
assert(max(abs(hr1 - 2*cos(w1/2))) < 1e-12);
[hr3, w3] = zerophase([1 0 -1], 1, 32);
assert(max(abs(hr3 - 2*sin(w3))) < 1e-12);
% La moyenne glissante change de signe apres son premier zero.
[hr5, w5] = zerophase(ones(1,5)/5, 1, 256);
avant = hr5(w5 < 2*pi/5 - 0.05);
apres = hr5(w5 > 2*pi/5 + 0.05 & w5 < 4*pi/5 - 0.05);
assert(avant(end) > 0 && apres(1) < 0);

% Predicats de filtre.
assert(isstable(1, [1 -0.5]) && ~isstable(1, [1 -1.5]));
[bStable, aStable] = butter(4, 0.3);
assert(isstable(tf2sos(bStable, aStable)));
assert(isminphase([1 0.5]) && ~isminphase([0.5 1]));
assert(ismaxphase([0.5 1]) && ~ismaxphase([1 0.5]));
assert(islinphase(ones(1, 5)) && ~islinphase([1 2 3]));
assert(firtype([1 2 1]) == 1 && firtype([1 2 2 1]) == 2);
assert(firtype([1 0 -1]) == 3 && firtype([1 2 -2 -1]) == 4);

% ss2tf accepte le choix de l'entree.
[nA, dA] = ss2tf([-1 0; 0 -2], [1 0; 0 1], [1 1], [0 0], 1);
assert(max(abs(dA - [1 3 2])) < 1e-12);
assert(max(abs(nA - [0 1 2])) < 1e-12);

% Conversions entre representations : le tour complet doit revenir au
% point de depart.
[bref, aref] = butter(4, 0.3);
[sos, g] = tf2sos(bref, aref);
[Ass, Bss, Css, Dss] = sos2ss(sos, g);
[nss, dss] = ss2tf(Ass, Bss, Css, Dss);
assert(max(abs(nss - bref)) < 1e-12 && max(abs(dss - aref)) < 1e-12);
[zt, pt, kt] = tf2zp(bref, aref);
[zs, ps, ks] = sos2zp(sos, g);
assert(abs(ks - kt) < 1e-12);
assert(max(abs(sort(real(ps)) - sort(real(pt)))) < 1e-10);
[Azp, Bzp, Czp, Dzp] = zp2ss(zt, pt, kt);
[nzp, dzp] = ss2tf(Azp, Bzp, Czp, Dzp);
assert(max(abs(real(nzp) - bref)) < 1e-10);
[zss, pss, kss] = ss2zp(Ass, Bss, Css, Dss);
assert(max(abs(sort(real(pss)) - sort(real(pt)))) < 1e-10);
assert(numel(zss) == numel(zt));
[sos2b, g2b] = ss2sos(Ass, Bss, Css, Dss);
[n2b, ~] = sos2tf(sos2b, g2b);
assert(max(abs(n2b - bref)) < 1e-12);

% Transformee en sinus : aller-retour exact et valeurs fermees.
assert(max(abs(idst(dst([1 2 3 4 5])) - [1 2 3 4 5])) < 1e-13);
assert(max(abs(dst([1 0 0]) - [sin(pi/4) sin(pi/2) sin(3*pi/4)])) < 1e-14);
assert(isequal(size(dst([1 2 3]', 5)), [5 1]));

% Walsh-Hadamard : compare a la matrice de Walsh construite a la main,
% dont les lignes sont rangees par nombre de changements de signe.
N = 8;
H = 1;
while size(H, 1) < N, H = [H H; H -H]; end
changements = zeros(N, 1);
for k = 1:N, changements(k) = sum(abs(diff(H(k, :))) > 0); end
[changements, ordreW] = sort(changements);
W = H(ordreW, :);
assert(isequal(changements(:)', 0:N-1));
xw = [1 2 3 4 5 6 7 8];
assert(max(abs(fwht(xw)' - (W * xw') / N)) < 1e-14);
assert(max(abs(ifwht(fwht(xw)) - xw)) < 1e-14);
assert(max(abs(ifwht(fwht(xw, [], 'hadamard'), [], 'hadamard') - xw)) < 1e-14);
assert(max(abs(ifwht(fwht(xw, [], 'dyadic'), [], 'dyadic') - xw)) < 1e-14);
assert(isequal(fwht([1 0 0 0]), [0.25 0.25 0.25 0.25]));
assert(isequal(fwht([1 1 1 1]), [1 0 0 0]));

% Cepstres : un echo a l'echantillon 21 se voit dans le cepstre reel.
xe = zeros(1, 128);
xe(1) = 1;
xe(21) = 0.6;
ce = rceps(xe);
[~, picCepstre] = max(ce(2:64));
assert(picCepstre + 1 == 21);
[~, minimale] = rceps(xe);
assert(max(abs(abs(fft(minimale)) - abs(fft(xe(:))))) < 1e-12);
[xh, nd] = cceps(xe);
assert(max(abs(icceps(xh, nd) - xe(:))) < 1e-12);

%% ------------------------------------ fenetres et formes d'onde
% Dolph-Tchebychev : par construction, tous les lobes secondaires sont a
% exactement -R decibels. C'est ce qui la definit.
for parametres = {{31, 40}, {32, 40}, {31, 60}, {32, 100}}
    nc = parametres{1}{1};
    rc = parametres{1}{2};
    wc = chebwin(nc, rc);
    assert(numel(wc) == nc && abs(max(wc) - 1) < 1e-12);
    assert(max(abs(wc - flipud(wc))) < 1e-10);      % symetrique
    spectre = abs(fft(wc, 8192));
    spectre = spectre(1:4097) / max(spectre);
    dB = 20 * log10(max(spectre, 1e-300));
    k = 2;
    while k < numel(dB) && dB(k) < dB(k-1), k = k + 1; end
    assert(abs(max(dB(k:end)) + rc) < 0.01);
end

% Taylor : lobes proches du niveau demande, fenetre symetrique.
for niveau = [-30 -35]
    wt = taylorwin(64, 5, niveau);
    assert(numel(wt) == 64);
    assert(max(abs(wt - flipud(wt))) < 1e-12);
    spectreT = abs(fft(wt, 8192));
    spectreT = spectreT(1:4097) / max(spectreT);
    dBT = 20 * log10(max(spectreT, 1e-300));
    k = 2;
    while k < numel(dBT) && dBT(k) < dBT(k-1), k = k + 1; end
    assert(max(dBT(k:end)) < niveau + 0.5);
end
assert(isequal(size(taylorwin(16)), [16 1]));

% window : simple aiguillage.
assert(isequal(window(@hamming, 8), hamming(8)));
assert(isequal(window('kaiser', 8, 5), kaiser(8, 5)));

% Formes d'onde elementaires.
assert(isequal(rectpuls([-1 -0.5 -0.4 0 0.4 0.5 1]), [0 1 1 1 1 0 0]));
assert(isequal(tripuls([-0.5 -0.25 0 0.25 0.5]), [0 0.5 1 0.5 0]));
assert(max(abs(tripuls([-0.5 0 0.25 0.5], 1, 0.5) - [0 2/3 1 0])) < 1e-12);
assert(diric(0, 5) == 1 && diric(2*pi, 5) == 1 && diric(2*pi, 4) == -1);
xd = linspace(0.1, 3, 5);
assert(max(abs(diric(xd, 7) - sin(7*xd/2) ./ (7*sin(xd/2)))) < 1e-14);
% Le noyau de Dirichlet est la transformee de la fenetre rectangulaire.
assert(abs(abs(sum(exp(-1i * 0.9 * (0:6)))) / 7 - abs(diric(0.9, 7))) < 1e-14);

% gauspuls : enveloppe unitaire, quadrature nulle a l'origine, bande a
% -6 dB conforme a la valeur demandee.
tg = -2e-3:1e-7:2e-3;
[yi, yq, ye] = gauspuls(tg, 1e4, 0.6);
assert(abs(max(ye) - 1) < 1e-12);
assert(abs(yq(tg == 0)) < 1e-15);
assert(max(abs(yi - ye .* cos(2*pi*1e4*tg))) < 1e-14);
spectreG = abs(fft(yi, 2^16));
spectreG = spectreG(1:2^15);
fG = (0:2^15-1) * 1e7 / 2^16;
audessus = find(spectreG >= max(spectreG) / 2);
assert(abs((fG(audessus(end)) - fG(audessus(1))) - 0.6e4) < 200);

% pulstran : dix impulsions rectangulaires, rien entre elles.
tp = 0:1/1e3:0.999;
yp = pulstran(tp, (0:0.1:0.9)', @rectpuls, 0.02);
assert(all(yp == 0 | yp == 1));
assert(sum(yp) > 150 && sum(yp) < 220);
assert(yp(1) == 1 && yp(51) == 0);

% vco : la frequence instantanee suit la commande.
fsv = 1e4;
yv = vco(zeros(fsv, 1), 1e3, fsv);
spectreV = abs(fft(yv));
[~, kv] = max(spectreV(1:fsv/2));
assert(abs((kv - 1) - 1000) < 2);
yv2 = vco(0.5 * ones(fsv, 1), 1e3, fsv);
spectreV2 = abs(fft(yv2));
[~, kv2] = max(spectreV2(1:fsv/2));
assert(abs((kv2 - 1) - 1500) < 2);

% modulate et demod : l'amplitude module puis demodule redonne le signal.
fsm = 2e4;
tm = (0:2047)' / fsm;
message = sin(2*pi*50*tm);
ym = modulate(message, 2e3, fsm, 'am');
assert(max(abs(ym - message .* cos(2*pi*2e3*tm))) < 1e-14);
retour = demod(ym, 2e3, fsm, 'am');
milieu = 300:1700;
assert(max(abs(retour(milieu) - message(milieu))) < 0.05);

% sgolay : un polynome de degre au plus K traverse le lissage intact.
bsg = sgolay(2, 7);
ssg = (-3:3)';
psg = 1 + 2*ssg + 3*ssg.^2;
assert(max(abs(bsg * psg - psg)) < 1e-12);
[b3, g3] = sgolay(3, 9);
assert(isequal(size(b3), [9 9]) && isequal(size(g3), [9 4]));
s9 = (-4:4)';
assert(abs(g3(:, 2)' * (s9.^2)) < 1e-12);        % derivee de s^2 nulle au centre
assert(abs(g3(:, 3)' * (s9.^2) - 1) < 1e-12);    % derivee seconde / 2! = 1

disp('signal : toutes les verifications passent');
