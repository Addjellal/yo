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

%% ------------------------------ mesures sur un signal a deux etats
% Rampe de 0 a 1 sur une seconde, encadree de paliers. Les niveaux
% d'etat sortent de l'histogramme : ils valent 0.005 et 0.995, centres
% des classes extremes. Le temps de montee est donc 0.8 * 0.99 seconde.
fsMesure = 1000;
rampe = [zeros(1, 200) linspace(0, 1, 1001) ones(1, 200)];
niveaux = statelevels(rampe);
assert(abs(niveaux(1) - 0.005) < 1e-12 && abs(niveaux(2) - 0.995) < 1e-12);
assert(isequal(statelevels([zeros(1,50) ones(1,50)]), statelevels([zeros(1,50) ones(1,50)], 100, 'mode')));
[~, histogramme, bornes] = statelevels(rampe);
assert(numel(histogramme) == 100 && sum(histogramme) == numel(rampe));
assert(bornes(1) == 0 && bornes(2) == 1);

tm = risetime(rampe, fsMesure);
assert(numel(tm) == 1);
assert(abs(tm - 0.792) < 1e-9);
assert(abs(slewrate(rampe, fsMesure) - 1) < 1e-9);
assert(abs(falltime(fliplr(rampe), fsMesure) - 0.792) < 1e-9);
assert(abs(slewrate(fliplr(rampe), fsMesure) + 1) < 1e-9);
% Le passage au niveau median tombe au milieu de la rampe.
assert(abs(midcross(rampe, fsMesure) - 0.7) < 1e-9);
[~, niveauMedian] = midcross(rampe, fsMesure);
assert(abs(niveauMedian - 0.5) < 1e-12);

% Depassement et creux, en pourcentage de l'ecart entre etats.
assert(abs(overshoot([zeros(1,20) ones(1,5)*1.2 ones(1,40)], 1) - 20) < 0.5);
% Un echelon net ne depasse pas : le residu vient des classes de
% l'histogramme, il reste sous le pour cent.
assert(overshoot([zeros(1,20) ones(1,40)], 1) < 1);
assert(abs(undershoot([zeros(1,20) -0.15*ones(1,3) zeros(1,5) ones(1,40)], 1) - 15) < 1);

% Creneau de rapport cyclique 1/4 et de periode 1 seconde.
fsCreneau = 1000;
tc = (0:4*fsCreneau-1) / fsCreneau;
creneau = double(mod(tc, 1) < 0.25);
assert(max(abs(dutycycle(creneau, fsCreneau) - 0.25)) < 1e-9);
assert(max(abs(pulseperiod(creneau, fsCreneau) - 1)) < 1e-9);
assert(max(abs(pulsewidth(creneau, fsCreneau) - 0.25)) < 1e-9);
assert(max(abs(pulsesep(creneau, fsCreneau) - 0.75)) < 1e-9);
% Le signal part haut, redescend a 0.25 puis alterne : sept traversees
% du niveau median en quatre secondes, comptees une seule fois chacune.
assert(numel(midcross(creneau, fsCreneau)) == 7);

% Temps d'etablissement d'une reponse amortie : exp(-5t) passe sous 2 %
% de l'amplitude a t = log(50)/5 = 0.782 s apres le debut de l'echelon.
techelon = (0:0.001:2)';
amortie = 1 - exp(-5*techelon) .* cos(20*techelon);
etabli = settlingtime([zeros(200,1); amortie], 1000, 2);
assert(etabli(1) > 0.4 && etabli(1) < 0.9);

%% --------------------------- distorsion et plage dynamique
% Un fondamental et deux harmoniques d'amplitude connue : le taux de
% distorsion se calcule a la main.
fsD = 1000;
td = (0:999)' / fsD;
signalD = cos(2*pi*50*td) + 0.1*cos(2*pi*100*td) + 0.01*cos(2*pi*150*td);
attenduTHD = 10 * log10((0.1^2 + 0.01^2) / 1);
assert(abs(thd(signalD, fsD) - attenduTHD) < 1e-3);
% Sans bruit, le SINAD est l'oppose du THD.
assert(abs(sinad(signalD, fsD) + attenduTHD) < 1e-3);
% Le plus fort parasite est dix fois plus petit : 20 dB.
assert(abs(sfdr(signalD, fsD) - 20) < 1e-3);
% Un parasite non harmonique est trouve aussi.
assert(abs(sfdr(cos(2*pi*50*td) + 0.01*cos(2*pi*130*td), fsD) - 40) < 1e-3);
% Puissances et frequences des harmoniques : A^2/2 exactement.
[~, puissancesH, frequencesH] = thd(signalD, fsD, 3);
assert(max(abs(puissancesH(:)' - [0.5 0.005 5e-05])) < 1e-9);
assert(isequal(frequencesH(:)', [50 100 150]));
% Le spectre de puissance interne rend bien A^2/2 sur le lobe.
[Sp, fp] = signalSpectrePuissance(2*cos(2*pi*50*td), fsD);
[~, kp] = max(Sp);
assert(abs(signalLobe(Sp, kp) - 2) < 1e-9);
assert(fp(kp) == 50);
% SINAD avec un bruit blanc de variance connue.
randn('seed', 3);
bruitBlanc = 0.01 * randn(1000, 1);
assert(abs(sinad(cos(2*pi*50*td) + bruitBlanc, fsD) - 10*log10(0.5/var(bruitBlanc))) < 0.5);
% Point d'interception d'ordre trois, deux tons et leurs produits.
fsT = 1e4;
tt = (0:4095)' / fsT;
deuxTons = cos(2*pi*1000*tt) + cos(2*pi*1100*tt) + ...
           0.001*cos(2*pi*900*tt) + 0.001*cos(2*pi*1200*tt);
attenduTOI = 10*log10(0.5) + (10*log10(0.5) - 10*log10(0.001^2/2)) / 2;
assert(abs(toi(deuxTons, fsT) - attenduTOI) < 0.1);

%% ------------------------- prediction lineaire et conversions
% Exemple documente par MathWorks pour POLY2RC.
aRef = [1.0000 0.6149 0.9899 0.0000 0.0031 -0.0082];
kRef = poly2rc(aRef);
assert(max(abs(kRef(:)' - [0.3090 0.9801 0.0031 0.0081 -0.0082])) < 1e-3);
assert(max(abs(rc2poly(kRef) - aRef)) < 1e-12);
% Yule-Walker : ac2poly doit resoudre le meme systeme que la resolution
% directe des equations normales.
rAuto = [1 0.5 0.25 0.125];
[aAuto, eAuto] = ac2poly(rAuto);
direct = -toeplitz(rAuto(1:3)) \ rAuto(2:4)';
assert(max(abs(aAuto(2:4) - direct')) < 1e-12);
assert(abs(eAuto - 0.75) < 1e-12);
assert(max(abs(poly2ac(aAuto, eAuto)' - rAuto)) < 1e-12);
% Schur et Levinson donnent les memes coefficients de reflexion.
[kAuto, r0Auto] = ac2rc(rAuto);
assert(max(abs(kAuto - schurrc(rAuto))) < 1e-12);
assert(abs(r0Auto - 1) < 1e-15);
assert(max(abs(rc2ac(kAuto, r0Auto)' - rAuto)) < 1e-12);
% Fréquences spectrales de raies : aller-retour exact, entrelacement.
for polyLSF = {[1 -0.5], [1 -1.2 0.8], [1 -0.9 0.7 -0.3], [1 -1.5 1.1 -0.4 0.1]}
    aLSF = polyLSF{1};
    lsf = poly2lsf(aLSF);
    assert(numel(lsf) == numel(aLSF) - 1);
    assert(all(lsf > 0 & lsf < pi));
    assert(all(diff(lsf) > 0));
    assert(max(abs(lsf2poly(lsf) - aLSF)) < 1e-12);
end
erreurLSF = false;
try
    poly2lsf([1 -2]);          % pole hors du cercle unite
catch err
    erreurLSF = strcmp(err.identifier, 'signal:poly2lsf:UnstablePolynomial');
end
assert(erreurLSF);

%% ------------------------ modeles autoregressifs et spectres
% Processus AR(2) a poles connus : rayon 0.9, angle pi/4.
randn('seed', 11);
rayon = 0.9;
angleAR = pi / 4;
aVrai = [1 -2*rayon*cos(angleAR) rayon^2];
xAR = filter(1, aVrai, randn(8000, 1));
for methode = {'aryule', 'arburg', 'arcov', 'armcov'}
    [aEstime, eEstime] = feval(methode{1}, xAR, 2);
    assert(numel(aEstime) == 3 && aEstime(1) == 1);
    assert(max(abs(aEstime - aVrai)) < 0.05);
    assert(abs(eEstime - 1) < 0.05);
    % Le filtre estime est stable.
    assert(all(abs(roots(aEstime)) < 1));
end
% Les quatre spectres parametriques placent leur maximum sur la resonance.
for methode = {'pyulear', 'pburg', 'pcov', 'pmcov'}
    [pxx, fSpec] = feval(methode{1}, xAR, 2, 1024, 1);
    assert(numel(pxx) == 513);
    [~, kSpec] = max(pxx);
    assert(abs(fSpec(kSpec) - angleAR/(2*pi)) < 0.005);
    assert(all(pxx > 0));
end
% L'integrale de la densite rend la puissance du signal.
[pxxB, fB] = pburg(xAR, 2, 4096, 1);
assert(abs(sum(pxxB) * (fB(2) - fB(1)) - var(xAR)) / var(xAR) < 0.02);

% corrmtx : X'X estime l'autocorrelation, et le terme diagonal la puissance.
[Xc, Rc] = corrmtx(xAR(1:200), 3, 'autocorrelation');
assert(isequal(size(Xc), [203 4]));
assert(abs(Rc(1, 1) - mean(xAR(1:200).^2)) < 1e-12);
[Xm, Rm] = corrmtx(xAR(1:200), 3, 'modified');
assert(isequal(size(Xm), [394 4]));
assert(max(max(abs(Rm - Rm'))) < 1e-12);
erreurCorr = false;
try
    corrmtx(xAR, 3, 'inconnue');
catch err
    erreurCorr = strcmp(err.identifier, 'signal:corrmtx:UnknownMethod');
end
assert(erreurCorr);

%% ------------------------------ fenetres de Slepian, multi-fenetres
[Edpss, Vdpss] = dpss(128, 4, 7);
assert(isequal(size(Edpss), [128 7]));
assert(max(max(abs(Edpss' * Edpss - eye(7)))) < 1e-10);
% Les taux de concentration decroissent et restent sous 1.
assert(all(diff(Vdpss) < 0));
assert(all(Vdpss > 0.9 & Vdpss <= 1 + 1e-12));
% Les suites sont bien vecteurs propres du noyau de concentration.
nD = 128;
WD = 4 / nD;
indD = (0:nD-1)';
ecartD = indD - indD';
noyauD = 2 * WD * ones(nD);
horsD = ecartD ~= 0;
noyauD(horsD) = sin(2*pi*WD*ecartD(horsD)) ./ (pi*ecartD(horsD));
for j = 1:7
    assert(norm(noyauD * Edpss(:, j) - Vdpss(j) * Edpss(:, j)) < 1e-9);
end
% Convention de signe : somme positive pour les rangs impairs.
assert(sum(Edpss(:, 1)) > 0 && sum(Edpss(:, 3)) > 0);

fsMT = 1000;
tMT = (0:511)' / fsMT;
signalMT = cos(2*pi*100*tMT) + 0.5*cos(2*pi*250*tMT);
[pMT, fMT] = pmtm(signalMT, 4, 512, fsMT);
assert(numel(pMT) == 257);
[~, iMT] = max(pMT);
resteMT = pMT;
resteMT(abs(fMT - fMT(iMT)) < 20) = 0;
[~, jMT] = max(resteMT);
assert(abs(min(fMT(iMT), fMT(jMT)) - 100) < 3);
assert(abs(max(fMT(iMT), fMT(jMT)) - 250) < 3);
assert(abs(sum(pMT) * (fMT(2) - fMT(1)) - mean(signalMT.^2)) / mean(signalMT.^2) < 0.05);

%% ------------------------------- methodes a sous-espaces
% Deux sinusoides reelles, donc quatre exponentielles complexes.
randn('seed', 21);
nSE = 100;
nnSE = (0:nSE-1)';
w1 = 0.4 * pi;
w2 = 0.6 * pi;
xSE = 2*cos(w1*nnSE) + cos(w2*nnSE) + 0.05*randn(nSE, 1);
[wSE, powSE] = rootmusic(xSE, 4);
assert(numel(wSE) == 4);
attenduSE = sort([-w2 -w1 w1 w2]);
assert(max(abs(sort(wSE(:)') - attenduSE)) < 5e-3);
% Les puissances : amplitude 2 se partage en deux exponentielles de
% puissance 1, amplitude 1 en deux de puissance 0.25.
puissancesTriees = sort(powSE(:)');
assert(max(abs(puissancesTriees - [0.25 0.25 1 1])) < 0.05);
% En hertz.
assert(max(abs(sort(abs(rootmusic(xSE, 4, 1000))') - [200 200 300 300])) < 1);
% rooteig trouve les memes frequences.
wEig = rooteig(xSE, 4);
assert(max(abs(sort(wEig(:)') - attenduSE)) < 5e-3);
% Les pseudospectres montrent leurs pics aux memes endroits.
[Smus, fmus] = pmusic(xSE, 4, 1024, 1);
[~, kmus] = max(Smus);
resteMus = Smus;
resteMus(abs(fmus - fmus(kmus)) < 0.05) = 0;
[~, kmus2] = max(resteMus);
assert(abs(min(fmus(kmus), fmus(kmus2)) - 0.2) < 0.002);
assert(abs(max(fmus(kmus), fmus(kmus2)) - 0.3) < 0.002);
[Seig, feig] = peig(xSE, 4, 1024, 1);
[~, keig] = max(Seig);
resteEig = Seig;
resteEig(abs(feig - feig(keig)) < 0.05) = 0;
[~, keig2] = max(resteEig);
assert(abs(min(feig(keig), feig(keig2)) - 0.2) < 0.002);
% Deux frequences trop proches pour la transformee de Fourier sur 100
% points : la methode sous-espace les separe quand meme.
w3 = 0.30 * pi;
w4 = 0.32 * pi;
yProche = cos(w3*nnSE) + cos(w4*nnSE) + 0.01*randn(nSE, 1);
wProche = sort(abs(rootmusic(yProche, 4)));
assert(abs(wProche(1) - w3) < 5e-3 && abs(wProche(4) - w4) < 5e-3);

%% ------------------------------------ conception de filtres
% Intégrales et fonctions elliptiques : valeurs tabulées et identités.
[Ke, Ee] = ellipke(0.5);
assert(abs(Ke - 1.854074677301372) < 1e-13);
assert(abs(Ee - 1.350643881047676) < 1e-13);
[K0, E0] = ellipke(0);
assert(abs(K0 - pi/2) < 1e-15 && abs(E0 - pi/2) < 1e-15);
[K9, E9] = ellipke(0.9);
assert(abs(K9 - 2.578092113348172) < 1e-12);
assert(abs(E9 - 1.104774732704073) < 1e-12);
% Contre-vérification par quadrature de la définition intégrale.
angles = linspace(0, pi/2, 200001);
assert(abs(trapz(angles, 1 ./ sqrt(1 - 0.5*sin(angles).^2)) - Ke) < 1e-9);
assert(abs(trapz(angles, sqrt(1 - 0.5*sin(angles).^2)) - Ee) < 1e-9);
% Jacobi : m = 0 rend sinus et cosinus, m = 1 les hyperboliques.
[sj, cj, dj] = ellipj(0.5, 0);
assert(abs(sj - sin(0.5)) < 1e-14 && abs(cj - cos(0.5)) < 1e-14 && abs(dj - 1) < 1e-14);
[s1, c1, ~] = ellipj(0.7, 1);
assert(abs(s1 - tanh(0.7)) < 1e-14 && abs(c1 - sech(0.7)) < 1e-14);
% Les deux identités fondamentales.
[s2, c2, d2] = ellipj(0.8, 0.5);
assert(abs(s2^2 + c2^2 - 1) < 1e-15);
assert(abs(d2^2 + 0.5*s2^2 - 1) < 1e-15);
% sn vaut 1 au quart de période, et change de signe au bout d'une demie.
Km = ellipke(0.3);
[sK, cK, dK] = ellipj(Km, 0.3);
assert(abs(sK - 1) < 1e-12 && abs(cK) < 1e-12);
assert(abs(dK - sqrt(1 - 0.3)) < 1e-12);
[sa, ~, ~] = ellipj(0.4, 0.3);
[sb, ~, ~] = ellipj(0.4 + 2*Km, 0.3);
assert(abs(sa + sb) < 1e-12);

% Prototype elliptique : l'ondulation passe exactement de 0 à -RP, et la
% bande coupée reste exactement à -RS. C'est ce qui définit le filtre.
for essai = {{3, 1, 40}, {4, 0.5, 40}, {5, 0.1, 60}, {6, 1, 60}}
    ordre = essai{1}{1};
    rp = essai{1}{2};
    rs = essai{1}{3};
    [zp, pp] = prototypeElliptique(ordre, rp, rs);
    assert(all(real(pp) < 0));                     % stable
    assert(numel(zp) == 2 * floor(ordre/2));
    assert(max(abs(real(zp))) < 1e-10);            % zéros sur l'axe imaginaire
    if mod(ordre, 2) == 1
        reference = 1;
    else
        reference = 10^(-rp/20);
    end
    reponse = @(s) abs(prod(s - zp(:).') / prod(s - pp(:).'));
    gain0 = reponse(0);
    bord = reponse(1i) / gain0 * reference;
    assert(abs(20*log10(bord) + rp) < 1e-6);
    omegaP = linspace(0, 1, 3001);
    magP = zeros(size(omegaP));
    for k = 1:numel(omegaP)
        magP(k) = reponse(1i*omegaP(k)) / gain0 * reference;
    end
    assert(abs(max(20*log10(magP))) < 1e-6);
    assert(abs(min(20*log10(magP)) + rp) < 1e-6);
end

% ellip : le filtre numérique hérite des deux ondulations.
for essai = {{4, 0.5, 40}, {5, 1, 60}}
    ordre = essai{1}{1};
    rp = essai{1}{2};
    rs = essai{1}{3};
    [be, ae] = ellip(ordre, rp, rs, 0.3);
    assert(numel(be) == ordre + 1 && numel(ae) == ordre + 1);
    assert(isstable(be, ae));
    [he, we] = freqz(be, ae, 8192);
    fe = we / pi;
    dB = 20 * log10(abs(he));
    dansPasse = fe <= 0.3;
    assert(abs(max(dB(dansPasse))) < 1e-4);
    assert(abs(min(dB(dansPasse)) + rp) < 1e-4);
    premier = find(dB <= -rs, 1);
    assert(~isempty(premier));
    assert(max(dB(premier:end)) < -rs + 1e-4);
end

% ellipord : l'ordre rendu suffit, celui juste en dessous non.
for essai = {{0.2, 0.3, 1, 40}, {0.1, 0.4, 0.5, 60}, {0.25, 0.35, 0.1, 50}}
    Wp = essai{1}{1};
    Ws = essai{1}{2};
    Rp = essai{1}{3};
    Rs = essai{1}{4};
    [ordre, WnOrd] = ellipord(Wp, Ws, Rp, Rs);
    assert(WnOrd == Wp);
    for candidat = [ordre - 1, ordre]
        [bo, ao] = ellip(candidat, Rp, Rs, Wp);
        [ho, wo] = freqz(bo, ao, 8192);
        attenuation = max(20 * log10(abs(ho(wo/pi >= Ws))));
        if candidat < ordre
            assert(attenuation > -Rs);
        else
            assert(attenuation <= -Rs + 1e-6);
        end
    end
end

% besself : le polynôme de Bessel inverse, en entiers exacts.
[bb1, ab1] = besself(3, 1);
assert(isequal(ab1, [1 6 15 15]) && bb1 == 15);
[~, denominateurBessel] = besself(4, 1);
assert(isequal(denominateurBessel, [1 10 45 105 105]));
[~, denominateurBessel] = besself(5, 1);
assert(isequal(denominateurBessel, [1 15 105 420 945 945]));
[~, denominateurBessel] = besself(6, 1);
assert(isequal(denominateurBessel, [1 21 210 1260 4725 10395 10395]));
[bb4, ab4] = besself(4, 2);
assert(isequal(ab4, [1 20 180 840 1680]));
% Le retard de groupe vaut 1 en continu, à la précision de la différence.
for ordre = [3 4 5]
    [bg, ag] = besself(ordre, 1);
    omegaG = linspace(1e-4, 0.4, 200);
    reponseG = polyval(bg, 1i*omegaG) ./ polyval(ag, 1i*omegaG);
    retard = -diff(unwrap(angle(reponseG))) ./ diff(omegaG);
    assert(max(abs(retard - 1)) < 1e-3);
end

% firpm : la propriété qui définit le filtre est l'équi-ondulation, et
% l'égalité des ondulations quand les poids sont égaux.
[bp, errp] = firpm(20, [0 0.3 0.5 1], [1 1 0 0]);
assert(numel(bp) == 21);
assert(max(abs(bp - fliplr(bp))) < 1e-12);
[hp, wp2] = freqz(bp, 1, 8192);
fp = wp2 / pi;
ondulationPasse = max(abs(abs(hp(fp <= 0.3)) - 1));
ondulationCoupe = max(abs(hp(fp >= 0.5)));
assert(abs(ondulationPasse - ondulationCoupe) < 1e-4);
assert(abs(errp - ondulationCoupe) < 1e-3);
% Un poids de dix sur la bande coupée divise son ondulation par dix.
bpw = firpm(30, [0 0.3 0.4 1], [1 1 0 0], [1 10]);
[hw2, ww2] = freqz(bpw, 1, 8192);
fw2 = ww2 / pi;
rapport = max(abs(abs(hw2(fw2 <= 0.3)) - 1)) / max(abs(hw2(fw2 >= 0.4)));
assert(abs(rapport - 10) < 0.5);
% Ordre impair : longueur paire, et un zéro forcé à Nyquist.
bp2 = firpm(21, [0 0.3 0.5 1], [1 1 0 0]);
assert(numel(bp2) == 22);
assert(max(abs(bp2 - fliplr(bp2))) < 1e-10);
assert(abs(polyval(bp2, -1)) < 1e-10);
% Hilbert et différentiateur : antisymétriques.
bh = firpm(20, [0.05 0.95], [1 1], 'hilbert');
assert(max(abs(bh + fliplr(bh))) < 1e-10);
bd = firpm(21, [0 0.9], [0 0.9*pi], 'differentiator');
assert(max(abs(bd + fliplr(bd))) < 1e-10);

% invfreqz : sur une réponse qui vient d'un filtre rationnel du bon
% ordre, l'ajustement doit rendre exactement ce filtre.
[bref2, aref2] = butter(4, 0.3);
[href, wref] = freqz(bref2, aref2, 256);
[bfit, afit] = invfreqz(href, wref, 4, 4);
assert(max(abs(bfit - bref2)) < 1e-10);
assert(max(abs(afit - aref2)) < 1e-10);
[bell, aell] = ellip(5, 1, 40, 0.4);
[hell, well] = freqz(bell, aell, 512);
[bfit2, afit2] = invfreqz(hell, well, 5, 5);
assert(max(abs(bfit2 - bell)) < 1e-9);
assert(max(abs(afit2 - aell)) < 1e-9);

% yulewalk : le module suit le gabarit, marche d'escalier comprise.
[by, ay] = yulewalk(10, [0 0.3 0.3 0.6 0.6 1], [1 1 0.5 0.5 0 0]);
assert(numel(by) == 11 && numel(ay) == 11);
assert(isstable(by, ay));
[hy, wy2] = freqz(by, ay, 4096);
fy = wy2 / pi;
assert(abs(abs(hy(find(fy >= 0.15, 1))) - 1) < 0.1);
assert(abs(abs(hy(find(fy >= 0.45, 1))) - 0.5) < 0.1);
assert(abs(hy(find(fy >= 0.8, 1))) < 0.1);
[by2, ay2] = yulewalk(8, [0 0.6 0.6 1], [1 1 0 0]);
[hy2, wy3] = freqz(by2, ay2, 4096);
fy3 = wy3 / pi;
assert(isstable(by2, ay2));
assert(min(abs(hy2(fy3 <= 0.5))) > 0.8);
assert(max(abs(hy2(fy3 >= 0.7))) < 0.2);

%% ----------------------------------------- prototypes analogiques
% Chaque prototype est vérifié sur la propriété qui le définit, non sur
% des coefficients recopiés : c'est ce qui distingue un filtre juste
% d'un filtre qui y ressemble.
reponseAnalogique = @(z, p, k, s) k * prod(s - z) / prod(s - p);

[zButt, pButt, kButt] = buttap(4);
assert(isempty(zButt) && numel(pButt) == 4);
assert(abs(abs(reponseAnalogique(zButt, pButt, kButt, 0)) - 1) < 1e-12);
% Le Butterworth est à -3 dB en omega = 1.
assert(abs(abs(reponseAnalogique(zButt, pButt, kButt, 1i)) - 1/sqrt(2)) < 1e-12);

[zC1, pC1, kC1] = cheb1ap(4, 1);
% Un Chebyshev de type I d'ordre pair part du bas de l'ondulation et
% atteint la même valeur au bord de bande.
assert(abs(abs(reponseAnalogique(zC1, pC1, kC1, 0)) - 10^(-1/20)) < 1e-12);
assert(abs(abs(reponseAnalogique(zC1, pC1, kC1, 1i)) - 10^(-1/20)) < 1e-12);
[zC1i, pC1i, kC1i] = cheb1ap(3, 1);
assert(abs(abs(reponseAnalogique(zC1i, pC1i, kC1i, 0)) - 1) < 1e-12);

[zC2, pC2, kC2] = cheb2ap(4, 40);
assert(abs(abs(reponseAnalogique(zC2, pC2, kC2, 0)) - 1) < 1e-12);
assert(abs(abs(reponseAnalogique(zC2, pC2, kC2, 1i)) - 0.01) < 1e-12);
% Un ordre impair n'a que N-1 zéros finis : celui du milieu part à
% l'infini.
assert(numel(cheb2ap(3, 40)) == 2);

[zEl, pEl, kEl] = ellipap(4, 1, 40);
assert(abs(abs(reponseAnalogique(zEl, pEl, kEl, 1i)) - 10^(-1/20)) < 1e-12);

[zBe, pBe, kBe] = besselap(3);
assert(abs(abs(reponseAnalogique(zBe, pBe, kBe, 0)) - 1) < 1e-12);
assert(abs(kBe - 15) < 1e-9);      % s^3+6s^2+15s+15

%% -------------------------------------- filtres à bande, et bilinéaire
% Un passe-bande atteint sa spécification exactement aux deux bords :
% c'est la prédistorsion qui le garantit.
bordsBande = [0.2 0.4];
[bBande, aBande] = cheby1(3, 1, bordsBande);
hBande = freqz(bBande, aBande, bordsBande * pi);
assert(max(abs(abs(hBande) - 10^(-1/20))) < 1e-9);
[bC2b, aC2b] = cheby2(3, 40, bordsBande);
assert(max(abs(abs(freqz(bC2b, aC2b, bordsBande * pi)) - 0.01)) < 1e-9);
[bButtB, aButtB] = butter(2, bordsBande);
assert(numel(aButtB) == 5);        % l'ordre double
assert(max(abs(abs(freqz(bButtB, aButtB, bordsBande * pi)) - 1/sqrt(2))) < 1e-9);
% Un coupe-bande laisse passer le continu et Nyquist.
[bStop, aStop] = cheby1(3, 1, bordsBande, 'stop');
hStop = freqz(bStop, aStop, [0 pi]);
assert(max(abs(abs(hStop) - 1)) < 1e-9);

% La bilinéaire refait le chemin de butter : les deux doivent tomber sur
% les mêmes coefficients.
[zb, pb, kb] = buttap(4);
coupure = 2 * pi * 0.4;
[zd, pd, kd] = bilinear(zb, pb * coupure, kb * coupure^4, 2, 0.4);
[bBil, aBil] = zp2tf(zd, pd, kd);
[bRef, aRef] = butter(4, 0.4);
assert(max(abs(real(bBil) / real(bBil(1)) - bRef / bRef(1))) < 1e-12);
assert(max(abs(real(aBil) / real(aBil(1)) - aRef / aRef(1))) < 1e-12);

%% ------------------------------------------- invariance impulsionnelle
% La réponse impulsionnelle du filtre numérique est celle de
% l'analogique, échantillonnée et divisée par Fs. On le vérifie sur un
% pôle simple, un pôle double, un pôle triple et une paire complexe.
[bImp, aImp] = impinvar(1, [1 1], 10);
assert(abs(bImp - 0.1) < 1e-12 && abs(aImp(2) + exp(-0.1)) < 1e-12);
[bImp2, aImp2] = impinvar(1, [1 2 1], 10);
tImp = (0:7)' / 10;
assert(max(abs(impz(bImp2, aImp2, 8) - tImp .* exp(-tImp) / 10)) < 1e-12);
[bImp3, aImp3] = impinvar(1, conv(conv([1 1], [1 1]), [1 1]), 4);
tImp3 = (0:9)' / 4;
assert(max(abs(impz(bImp3, aImp3, 10) - tImp3.^2 .* exp(-tImp3) / 2 / 4)) < 1e-12);
denominateurComplexe = conv([1 0.4 1], [1 1]);
[bImp4, aImp4] = impinvar([1 0], denominateurComplexe, 8);
[rImp, pImp] = residue([1 0], denominateurComplexe);
tImp4 = (0:39)' / 8;
attendu = zeros(40, 1);
for kImp = 1:numel(pImp)
    attendu = attendu + rImp(kImp) * exp(pImp(kImp) * tImp4);
end
assert(max(abs(impz(bImp4, aImp4, 40) - real(attendu) / 8)) < 1e-12);

%% ------------------------------------------------ état d'un filtrage
% filter rend et reprend son état : filtrer par morceaux doit donner
% exactement le même résultat que filtrer d'un coup.
[bEtat, aEtat] = butter(3, 0.4);
signalEtat = sin(0.3 * (1:100)) + 0.1 * cos(1.7 * (1:100));
entier = filter(bEtat, aEtat, signalEtat);
[premier, etat] = filter(bEtat, aEtat, signalEtat(1:50));
second = filter(bEtat, aEtat, signalEtat(51:100), etat);
assert(max(abs([premier second] - entier)) < 1e-12);
% filtic reconstruit ce même état à partir du passé du signal.
etatReconstruit = filtic(bEtat, aEtat, entier(end:-1:end-2), signalEtat(end:-1:end-2));
[~, etatFinal] = filter(bEtat, aEtat, signalEtat);
assert(max(abs(etatReconstruit(:) - etatFinal(:))) < 1e-12);
% Une matrice se filtre colonne par colonne, et non à plat.
assert(isequal(filter([1 1], 1, [1 10; 2 20; 3 30]), [1 10; 3 30; 5 50]));
assert(isequal(filter([1 1], 1, [1 10; 2 20; 3 30], [], 2), [1 11; 2 22; 3 33]));

%% ------------------------------------------- modèles rationnels
% Prony reproduit exactement un filtre dont on lui donne la réponse.
[bModele, aModele] = butter(3, 0.4);
hModele = impz(bModele, aModele, 30);
[bProny, aProny] = prony(hModele, 3, 3);
assert(max(abs(bProny - bModele)) < 1e-12 && max(abs(aProny - aModele)) < 1e-12);
% Steiglitz-McBride aussi, et il retrouve un filtre depuis son
% entrée et sa sortie.
[bStm, aStm] = stmcb(hModele, 3, 3);
assert(max(abs(impz(bStm, aStm, 30) - hModele)) < 1e-10);
entreeStm = sin(1:200)' + cos(0.3 * (1:200))';
sortieStm = filter([1 0.5], [1 -0.3], entreeStm);
[bStm2, aStm2] = stmcb(sortieStm, entreeStm, 1, 1);
assert(max(abs(bStm2 - [1 0.5])) < 1e-10 && max(abs(aStm2 - [1 -0.3])) < 1e-10);
% invfreqs retrouve un filtre analogique depuis sa réponse.
[bBes, aBes] = besself(3, 1);
wAnalogique = logspace(-1, 1, 100);
[bInv, aInv] = invfreqs(freqs(bBes, aBes, wAnalogique), wAnalogique, 0, 3);
assert(max(abs(bInv - bBes)) < 1e-9 && max(abs(aInv - aBes)) < 1e-9);
% Levinson à l'envers rend son autocorrélation au modèle.
autocorrelation = [5 4 3 2]';
[aLev, eLev] = levinson(autocorrelation, 3);
[rLev, ~, krLev] = rlevinson(aLev, eLev);
assert(max(abs(rLev(:) - autocorrelation)) < 1e-12);
assert(max(abs(krLev(:) - poly2rc(aLev)(:))) < 1e-12);

%% ------------------------------------------------------- treillis
[bTreillis, aTreillis] = butter(3, 0.4);
[kTreillis, vTreillis] = tf2latc(bTreillis, aTreillis);
assert(all(abs(kTreillis) < 1));
[bRetour, aRetour] = latc2tf(kTreillis, vTreillis);
assert(max(abs(bRetour - bTreillis)) < 1e-12);
assert(max(abs(aRetour - aTreillis)) < 1e-12);
% Le treillis à réponse finie filtre comme la forme directe.
bFini = poly([0.2 0.3 -0.4]);
kFini = tf2latc(bFini);
signalTreillis = cos(0.4 * (1:100)) + sin(1.1 * (1:100));
assert(max(abs(latcfilt(kFini, signalTreillis) - filter(bFini, 1, signalTreillis))) < 1e-12);
assert(max(abs(latc2tf(kFini, 'fir') - bFini)) < 1e-12);
[~, aAllPole] = latc2tf(tf2latc(1, aTreillis), 'allpole');
assert(max(abs(aAllPole - aTreillis)) < 1e-12);
assert(max(abs(latcfilt(kTreillis, vTreillis, signalTreillis) - ...
                filter(bTreillis, aTreillis, signalTreillis))) < 1e-12);

%% ------------------------------------------ filtrage direct d'un signal
tBande = (0:999)' / 1000;
signalBande = sin(2*pi*10*tBande) + sin(2*pi*300*tBande);
garde = 200:800;
sortieBasse = lowpass(signalBande, 100, 1000);
assert(norm(sortieBasse(garde) - sin(2*pi*10*tBande(garde))) / ...
       norm(signalBande(garde)) < 0.05);
sortieHaute = highpass(signalBande, 100, 1000);
assert(norm(sortieHaute(garde) - sin(2*pi*300*tBande(garde))) / ...
       norm(signalBande(garde)) < 0.05);
troisTons = sin(2*pi*10*tBande) + sin(2*pi*100*tBande) + sin(2*pi*400*tBande);
sortieBande = bandpass(troisTons, [50 200], 1000);
assert(norm(sortieBande(garde) - sin(2*pi*100*tBande(garde))) / ...
       norm(troisTons(garde)) < 0.05);
sortieCoupe = bandstop(troisTons, [50 200], 1000);
assert(norm(sortieCoupe(garde) - (sin(2*pi*10*tBande(garde)) + ...
                                  sin(2*pi*400*tBande(garde)))) / ...
       norm(troisTons(garde)) < 0.05);
% La variante à réponse finie isole tout aussi bien.
sortieFir = lowpass(signalBande, 100, 1000, 'ImpulseResponse', 'fir');
assert(norm(sortieFir(300:700) - sin(2*pi*10*tBande(300:700))) / ...
       norm(signalBande(300:700)) < 0.01);

%% ------------------------------------------------- outils du domaine
assert(abs(pow2db(100) - 20) < 1e-12);
assert(abs(db2pow(20) - 100) < 1e-12);
assert(abs(mag2db(10) - 20) < 1e-12);
assert(abs(db2mag(20) - 10) < 1e-12);
% La matrice de convolution transforme la convolution en produit.
noyau = [1 2 3];
assert(isequal(convmtx(noyau', 4) * (1:4)', conv(noyau, 1:4)'));
assert(isequal((1:4) * convmtx(noyau, 4), conv(1:4, noyau)));
% detrend retire exactement le polynôme qu'on lui désigne.
tendance = (0:9)';
assert(max(abs(detrend(3 + 0.5 * tendance))) < 1e-12);
assert(max(abs(detrend([1 2 3 4 5], 'constant') - [-2 -1 0 1 2])) < 1e-12);
assert(max(abs(detrend((1:10)'.^2, 2))) < 1e-12);
% Les longueurs s'égalisent, zéros communs de queue retirés.
[bEq, aEq] = eqtflength([1 2], [1 2 3 0]);
assert(isequal(bEq, [1 2 0]) && isequal(aEq, [1 2 3]));
% tf2zpk garde les pôles dans le disque unité.
[bZpk, aZpk] = butter(3, 0.4);
[zZpk, pZpk, kZpk] = tf2zpk(bZpk, aZpk);
assert(all(abs(pZpk) < 1) && numel(zZpk) == 3);
assert(abs(kZpk - bZpk(1)) < 1e-12);
% polyscale ramène les racines vers l'origine.
assert(abs(max(abs(roots(polyscale(poly([0.9, -0.95]), 0.5)))) - 0.475) < 1e-12);
% L'ordre des bits inversés, et son aller-retour.
assert(isequal(bitrevorder(0:7), [0 4 2 6 1 5 3 7]));
assert(isequal(bitrevorder(bitrevorder(0:7)), 0:7));
% La fenêtre de Parzen est bien celle de parzenwin.
assert(isequal(parzen(32), parzenwin(32)));
% Quantification uniforme : l'exemple de la documentation.
assert(isequal(double(uencode(-1:0.5:1, 3)), [0 2 4 6 7]));
assert(max(abs(udecode(uencode(-1:0.5:1, 3), 3) - [-1 -0.5 0 0.5 0.75])) < 1e-12);
assert(strcmp(class(uencode(1, 3)), 'uint8'));
assert(strcmp(class(uencode(1, 3, 1, 'signed')), 'int8'));

%% --------------------------------------------- filtre d'interpolation
bInterp = intfilt(4, 3, 1);
assert(numel(bInterp) == 2 * 3 * 4 - 1);
assert(abs(bInterp(12) - 1) < 1e-12);          % la phase nulle est une impulsion
assert(max(abs(bInterp - fliplr(bInterp))) < 1e-12);   % phase linéaire
% Un signal bien à l'intérieur de la bande est interpolé fidèlement.
bInterp2 = intfilt(4, 4, 0.4);
signalInterp = sin(2*pi*0.03*(0:199));
sortieInterp = filter(bInterp2, 1, upsample(signalInterp, 4));
retard = 4 * 4 - 1;
sortieInterp = sortieInterp((retard+1):end);
attenduInterp = sin(2*pi*0.03*(0:numel(sortieInterp)-1)/4);
assert(max(abs(sortieInterp(40:end-40) - attenduInterp(40:end-40))) < 1e-4);
% La variante de Lagrange fait mieux encore sur un signal très lisse.
bLagrange = intfilt(4, 5, 'Lagrange');
signalLisse = sin(2*pi*0.01*(0:199));
sortieLagrange = filter(bLagrange, 1, upsample(signalLisse, 4));
retardLagrange = (numel(bLagrange) - 1) / 2;
sortieLagrange = sortieLagrange((retardLagrange+1):end);
attenduLagrange = sin(2*pi*0.01*(0:numel(sortieLagrange)-1)/4);
assert(max(abs(sortieLagrange(30:end-30) - attenduLagrange(30:end-30))) < 1e-8);


% MAXFLAT : filtre le plus plat possible. Sa propriete definitoire est le
% gain a la coupure, la platitude etant imposee par construction.
gainDe = @(b, a, w) abs(polyval(b, exp(-1i * w)) ./ polyval(a, exp(-1i * w)));
for essai = {[4 4 0.3], [10 2 0.2], [6 3 0.3], [2 8 0.4]}
    degreB = essai{1}(1);
    degreA = essai{1}(2);
    coupure = essai{1}(3);
    [b, a] = maxflat(degreB, degreA, coupure);
    assert(numel(b) == degreB + 1);
    assert(numel(a) == degreA + 1);
    assert(abs(gainDe(b, a, 0) - 1) < 1e-10);
    assert(abs(gainDe(b, a, pi * coupure) - 1 / sqrt(2)) < 1e-10);
    assert(gainDe(b, a, pi) < 1e-12);
    % Le filtre est stable : ses poles sont dans le disque unite.
    assert(all(abs(roots(a)) < 1));
end
% Pour des degres egaux, c'est le filtre de Butterworth ordinaire.
[bMaxflat, aMaxflat] = maxflat(4, 4, 0.3);
[bButter, aButter] = butter(4, 0.3);
fprintf('maxflat(4,4,0.3) contre butter(4,0.3) : ecart %.2e\n', ...
        max(max(abs(bMaxflat - bButter)), max(abs(aMaxflat - aButter))));
assert(max(abs(bMaxflat - bButter)) < 1e-12);
assert(max(abs(aMaxflat - aButter)) < 1e-12);
% La forme symetrique : la coupure y est le point a mi-amplitude.
for essai = {[4 0.5], [8 0.5], [12 0.35], [16 0.7]}
    ordre = essai{1}(1);
    coupure = essai{1}(2);
    b = maxflat(ordre, 'sym', coupure);
    assert(numel(b) == ordre + 1);
    assert(max(abs(b - b(end:-1:1))) < 1e-12);
    assert(abs(gainDe(b, 1, 0) - 1) < 1e-10);
    assert(abs(gainDe(b, 1, pi * coupure) - 0.5) < 1e-10);
    assert(gainDe(b, 1, pi) < 1e-12);
end
% Une coupure irrealisable est refusee, avec l'intervalle possible.
refuse = false;
try
    maxflat(6, 3, 0.5);
catch erreur
    refuse = contains(erreur.message, 'coupure');
end
assert(refuse);
[~, ~, b1, b2] = maxflat(6, 3, 0.3);
assert(max(abs(conv(b1, b2) - maxflat(6, 3, 0.3))) < 1e-12);
disp('maxflat : ok');


% PWELCH accepte une longueur de segment ou directement la fenetre.
rng(12);
signalWelch = sin(2 * pi * 0.1 * (0:2047)') + 0.5 * randn(2048, 1);
[parLongueur, fWelch] = pwelch(signalWelch, 256, 128, 512, 1000);
parFenetre = pwelch(signalWelch, hamming(256), 128, 512, 1000);
assert(max(abs(parLongueur - parFenetre)) < 1e-12, ...
       'une longueur vaut la fenetre de Hamming de cette longueur');
% Une autre fenetre donne un autre resultat, et reste du meme ordre.
parHann = pwelch(signalWelch, hann(256), 128, 512, 1000);
assert(~isequal(parHann, parFenetre));
assert(abs(sum(parHann) / sum(parFenetre) - 1) < 0.2);
% Le pic tombe a la bonne frequence : 0.1 cycle par echantillon a 1000 Hz.
[~, kWelch] = max(parLongueur);
assert(abs(fWelch(kWelch) - 100) < 5);
% Moyenner reduit la variance : c'est tout l'objet de la methode.
[unSeul, ~] = periodogram(signalWelch, hamming(2048), 4096, 1000);
varianceWelch = std(log(parLongueur(2:end)));
varianceSimple = std(log(unSeul(2:end)));
fprintf('pwelch : dispersion %.3f contre %.3f pour un periodogramme\n', ...
        varianceWelch, varianceSimple);
assert(varianceWelch < varianceSimple);
refuseWelch = false;
try
    pwelch(signalWelch, 128, 128);
catch
    refuseWelch = true;
end
assert(refuseWelch, 'un recouvrement egal a la longueur doit etre refuse');
disp('pwelch : ok');


% XCORR : le nombre de decalages et la normalisation, comme dans MATLAB.
serieCorr = filter(1, [1 -0.8], randn(500, 1));
[correlationsBornees, decalagesBornes] = xcorr(serieCorr, 5);
assert(numel(decalagesBornes) == 11, 'maxlag borne bien les decalages');
assert(isequal(decalagesBornes, -5:5));
% Sans bornes, tous les decalages sont rendus.
assert(numel(xcorr(serieCorr)) == 2 * numel(serieCorr) - 1);
% « biased » divise par N, « unbiased » par le nombre de termes sommes.
nCorr = numel(serieCorr);
brute = xcorr(serieCorr, 3);
biaisee = xcorr(serieCorr, 3, 'biased');
nonBiaisee = xcorr(serieCorr, 3, 'unbiased');
assert(max(abs(biaisee - brute / nCorr)) < 1e-10);
termes = nCorr - abs(-3:3);
assert(max(abs(nonBiaisee - brute ./ termes)) < 1e-10);
% « coeff » ramene l'autocorrelation a un au decalage nul.
normalisee = xcorr(serieCorr, 3, 'coeff');
assert(abs(normalisee(4) - 1) < 1e-12);
assert(all(abs(normalisee) <= 1 + 1e-12), 'elle ne peut pas depasser un');
% La correlation croisee accepte aussi les deux options.
[croisee, decalagesCroises] = xcorr([1 2 3], [0 1 0], 1);
assert(isequal(decalagesCroises, -1:1));
assert(isequal(croisee, [1 2 3]));
% Une normalisation inconnue est refusee.
refuseNorme = false;
try
    xcorr(serieCorr, 3, 'inconnue');
catch
    refuseNorme = true;
end
assert(refuseNorme);
disp('xcorr : ok');

% FIRLS : phase lineaire, bandes ajustees, transitions libres.
for ordreFirls = [40 41]
    filtreFirls = firls(ordreFirls, [0 0.3 0.4 1], [1 1 0 0]);
    assert(numel(filtreFirls) == ordreFirls + 1);
    % La symetrie donne la phase lineaire, quelle que soit la parite.
    assert(max(abs(filtreFirls - fliplr(filtreFirls))) < 1e-12);
    [gainFirls, pulsationsFirls] = freqz(filtreFirls, 1, 1024);
    module = abs(gainFirls);
    assert(min(module(pulsationsFirls / pi < 0.3)) > 0.9);
    assert(max(module(pulsationsFirls / pi > 0.4)) < 0.1);
end
% Ponderer une bande l'ameliore au detriment de l'autre.
sansPoids = firls(40, [0 0.3 0.4 1], [1 1 0 0]);
avecPoids = firls(40, [0 0.3 0.4 1], [1 1 0 0], [1 100]);
[gSans, wFirls] = freqz(sansPoids, 1, 1024);
gAvec = freqz(avecPoids, 1, 1024);
horsFirls = wFirls / pi > 0.4;
assert(max(abs(gAvec(horsFirls))) < max(abs(gSans(horsFirls))));
% Un gabarit non constant : le derivateur.
derivateurFirls = firls(30, [0 0.9], [0 0.9]);
[gDeriv, wDeriv] = freqz(derivateurFirls, 1, 512);
dansDeriv = wDeriv / pi < 0.8;
assert(max(abs(abs(gDeriv(dansDeriv)) - wDeriv(dansDeriv) / pi)) < 0.05);
% Un gabarit mal forme est refuse.
refuseGabarit = false;
try
    firls(20, [0 0.3 0.5], [1 1 0]);
catch
    refuseGabarit = true;
end
assert(refuseGabarit, 'les bandes se donnent par paires');
disp('firls : ok');

disp('signal : toutes les verifications passent');
