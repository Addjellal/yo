% test_identification.m — jeux de données, modèles, estimateurs, analyse.
%
% Les vérifications suivent un même principe : engendrer des données par
% un modèle connu, les identifier, et regarder si le modèle est retrouvé.
% C'est la seule vérification qui vaille en identification, et elle est
% exigeante — un estimateur biaisé la rate même sur des données parfaites.
disp('--- identification ---');

% Jeux de données.
t = (0:0.1:2)';
u = sign(sin(t));
y = filter(0.2, [1 -0.8], u);
z = iddata(y, u, 0.1);
assert(isequal(size(z), [21 1 1]));
assert(z.N == 21 && z.Ts == 0.1);
assert(strcmp(z.OutputName{1}, 'y1') && strcmp(z.InputName{1}, 'u1'));
% Retirer la tendance et la remettre rend les données de départ.
zt = iddata((1:10)' + 100, (1:10)');
[zd, tendance] = detrend(zt);
assert(abs(mean(zd.y)) < 1e-12);
assert(max(abs(retrend(zd, tendance).y - zt.y)) < 1e-12);
assert(max(abs(detrend(zt, 1).y)) < 1e-10);
% Découpe, données manquantes, décalage, fusion.
assert(z(1:5).N == 5);
assert(misdata(iddata([1; NaN; 3])).y(2) == 2);
assert(nkshift(iddata((1:5)', (1:5)'), 1).u(1) == 2);
zr = resample(iddata((1:10)', (1:10)'), 1, 2);
assert(zr.N == 5 && zr.Ts == 2);
zm = merge(iddata((1:5)'), iddata((6:10)'));
assert(nexp(zm) == 2 && getexp(zm, 2).y(1) == 6);
disp('jeux de donnees : ok');

% Modèles polynomiaux : simulation et prédiction.
m = idpoly([1 -0.8], [0 0.2], 1, 1, 1, 0, 0.1);
zs = sim(m, iddata([], ones(40, 1), 0.1));
assert(abs(zs.y(2) - 0.2) < 1e-12);
assert(abs(zs.y(end) - 1) < 0.01);
% Sur des données que le modèle engendre exactement, la prédiction à un
% pas et la simulation coïncident avec la sortie.
zj = iddata(zs.y, ones(40, 1), 0.1);
assert(max(abs(predict(m, zj, 1).y - zs.y)) < 1e-12);
assert(max(abs(predict(m, zj, Inf).y - zs.y)) < 1e-12);
% Le prédicteur à l'infini n'emploie pas la sortie mesurée : le lui
% changer ne change rien.
zfausse = iddata(zs.y + 5, ones(40, 1), 0.1);
assert(max(abs(predict(m, zfausse, Inf).y - zs.y)) < 1e-12);
% Les paramètres se lisent et se reposent.
assert(isequal(getpvec(idpoly([1 -0.8], [0 0.2])), [-0.8; 0.2]));
mr = setpvec(matlibre_id_squelette([1 1 0 0 0 1], 0.1), [-0.5; 0.3]);
assert(isequal(mr.A, [1 -0.5]) && isequal(mr.B, [0 0.3]));
assert(matlibre_id_retard_modele(idpoly(1, [0 0.2])) == 1);
disp('modeles polynomiaux : ok');

% ARX : sur des données sans bruit, il retrouve exactement le modèle.
zexact = iddata(filter([0 0.5], [1 -0.8], ones(200, 1)), ones(200, 1));
mexact = arx(zexact, [1 1 1]);
assert(max(abs(mexact.A - [1 -0.8])) < 1e-8);
assert(max(abs(mexact.B - [0 0.5])) < 1e-8);
assert(abs(mexact.Report.Fit.FitPercent - 100) < 1e-6);
% Avec un bruit qui entre par le même dénominateur, il reste juste.
rng(1);
u = sign(randn(600, 1));
e = 0.05 * randn(600, 1);
y = filter([0 0.5 0.2], [1 -1.2 0.4], u) + filter(1, [1 -1.2 0.4], e);
marx = arx(iddata(y, u), [2 2 1]);
fprintf('ARX : A %s (attendu 1 -1.2 0.4)\n', mat2str(round(marx.A, 3)));
assert(max(abs(marx.A - [1 -1.2 0.4])) < 0.05);
assert(max(abs(marx.B - [0 0.5 0.2])) < 0.05);
disp('arx : ok');

% ARMAX retrouve aussi le polynôme du bruit.
rng(1);
u = sign(randn(1200, 1));
e = 0.1 * randn(1200, 1);
y = filter([0 0.5], [1 -0.8], u) + filter([1 0.6], [1 -0.8], e);
mar = armax(iddata(y, u), [1 1 1 1]);
fprintf('ARMAX : A %s, B %s, C %s\n', mat2str(round(mar.A, 3)), ...
        mat2str(round(mar.B, 3)), mat2str(round(mar.C, 3)));
assert(abs(mar.A(2) + 0.8) < 0.03);
assert(abs(mar.B(2) - 0.5) < 0.03);
assert(abs(mar.C(2) - 0.6) < 0.06);
% Sortie-erreur : un bruit blanc ajouté à la sortie ne le biaise pas.
rng(2);
u = sign(randn(1200, 1));
y = filter([0 0.5], [1 -0.8], u) + 0.1 * randn(1200, 1);
mo = oe(iddata(y, u), [1 1 1]);
fprintf('OE : B %s, F %s\n', mat2str(round(mo.B, 3)), mat2str(round(mo.F, 3)));
assert(abs(mo.B(2) - 0.5) < 0.02);
assert(abs(mo.F(2) + 0.8) < 0.02);
% Box-Jenkins : chacun sa dynamique.
rng(4);
u = sign(randn(1500, 1));
y = filter([0 0.5], [1 -0.8], u) + filter([1 0.5], [1 -0.3], 0.1 * randn(1500, 1));
mb = bj(iddata(y, u), [1 1 1 1 1]);
fprintf('BJ : B %s, F %s\n', mat2str(round(mb.B, 3)), mat2str(round(mb.F, 3)));
assert(abs(mb.B(2) - 0.5) < 0.05);
assert(abs(mb.F(2) + 0.8) < 0.05);
% Autorégressif pur.
rng(1);
ya = filter(1, [1 -0.7 0.2], randn(2000, 1));
ma = ar(iddata(ya), 2);
assert(max(abs(ma.A - [1 -0.7 0.2])) < 0.05);
% PEM retrouve le même modèle que POLYEST.
mp = pem(iddata(y, u), [0 1 1 1 1 1]);
assert(abs(mp.B(2) - mb.B(2)) < 1e-6);
disp('familles de modeles : ok');

% Variables instrumentales : elles corrigent le biais de l'ARX quand le
% bruit est blanc en sortie.
rng(1);
u = sign(randn(2000, 1));
y = filter([0 0.5], [1 -0.8], u) + 0.3 * randn(2000, 1);
z = iddata(y, u);
biaisArx = abs(arx(z, [1 1 1]).A(2) + 0.8);
biaisIv = abs(iv4(z, [1 1 1]).A(2) + 0.8);
fprintf('biais sur a1 : arx %.4f, iv4 %.4f\n', biaisArx, biaisIv);
assert(biaisIv < biaisArx / 5);
disp('variables instrumentales : ok');

% Sous-espaces : les pôles sont retrouvés exactement sur des données
% sans bruit, et l'ordre choisi tout seul.
rng(1);
u = sign(randn(400, 1));
y = filter([0 0.5 0.2], [1 -1.2 0.4], u);
zs = iddata(y, u);
mn = n4sid(zs, 2);
polesVrais = sort(abs(roots([1 -1.2 0.4])));
fprintf('poles : %s (vrais %s)\n', mat2str(sort(round(abs(eig(mn.A)), 4)).'), ...
        mat2str(round(polesVrais, 4).'));
assert(max(abs(sort(abs(eig(mn.A))) - polesVrais)) < 1e-6);
[~, ajustement] = compare(mn, zs);
assert(ajustement > 99.99);
% SSEST affine sans dégrader.
mss = ssest(zs, 2);
[~, ajustementSs] = compare(mss, zs);
assert(ajustementSs > 99.99);
assert(order(mss) == 2);
% Les matrices se relisent.
[A, B, C, D] = ssdata(mn);
assert(isequal(size(A), [2 2]) && isequal(size(C), [1 2]));
disp('sous-espaces : ok');

% Fonction de transfert et modèle de procédé.
rng(1);
u = sign(randn(800, 1));
y = filter([0 0.5], [1 -0.8], u) + 0.02 * randn(800, 1);
zt = iddata(y, u, 1);
mt = tfest(zt, 1, 0, 1);
fprintf('TFEST : num %s, den %s, retard %g\n', mat2str(round(mt.Numerator, 3)), ...
        mat2str(round(mt.Denominator, 3)), mt.IODelay);
assert(abs(mt.Numerator(1) - 0.5) < 0.02);
assert(abs(mt.Denominator(2) + 0.8) < 0.02);
[~, ajustementTf] = compare(mt, zt);
assert(ajustementTf > 90);
% Le modèle continu ajuste aussi bien que le discret dont il vient.
mc = tfest(zt, 1, 0, 1, 'Ts', 0);
[~, ajustementContinu] = compare(mc, zt);
assert(abs(ajustementContinu - ajustementTf) < 0.5);
% Procédé : les constantes de temps sont retrouvées exactement.
tp = (0:0.2:60)';
up = double(tp > 5);
vrai = idproc('P1D', 'K', 2, 'Tp1', 4, 'Td', 1);
zp = sim(vrai, iddata([], up, 0.2));
mproc = procest(iddata(zp.y, up, 0.2), 'P1D');
fprintf('PROCEST : K %.4f, Tp1 %.4f, Td %.4f (attendus 2, 4, 1)\n', ...
        mproc.K, mproc.Tp1, mproc.Td);
assert(abs(mproc.K - 2) < 1e-3);
assert(abs(mproc.Tp1 - 4) < 1e-2);
assert(abs(mproc.Td - 1) < 1e-2);
disp('transfert et procede : ok');

% Comparaison, résidus et critères.
rng(1);
u = sign(randn(600, 1));
y = filter([0 0.5], [1 -0.8], u) + 0.05 * randn(600, 1);
z = iddata(y, u, 1);
m1 = arx(z, [1 1 1]);
[~, ajustement] = compare(m1, z);
fprintf('ajustement : %.2f %%\n', ajustement);
assert(ajustement > 80);
% Un modèle faux ajuste bien moins.
mfaux = idpoly([1 0.5], [0 0.1], 1, 1, 1, 0, 1);
[~, ajustementFaux] = compare(mfaux, z);
assert(ajustementFaux < ajustement - 20);
% Les résidus d'un modèle juste restent dans le seuil, presque partout.
[e, auto, croisee, seuil] = resid(m1, z);
assert(numel(e) == 600);
assert(abs(auto(26) - 1) < 1e-12);
horsSeuil = sum(abs(auto) > seuil) - 1;
fprintf('autocorrelations hors seuil : %d sur %d\n', horsSeuil, numel(auto) - 1);
assert(horsSeuil <= 5);
% Les critères pénalisent le nombre de paramètres.
assert(fpe(m1) > m1.Report.Fit.MSE);
n = m1.Report.Fit.nobs;
assert(abs(aic(m1) - (n * log(m1.Report.Fit.MSE) + 2 * 2)) < 1e-6);
assert(abs(aic(m1, 'nAIC') - (log(m1.Report.Fit.MSE) + 4 / n)) < 1e-9);
assert(abs(fpe(m1) - m1.Report.Fit.MSE * (1 + 2 / n) / (1 - 2 / n)) < 1e-12);
assert(aic(m1, 'BIC') > aic(m1));
disp('analyse : ok');

% Réponse fréquentielle : elle coïncide avec la réponse vraie.
rng(1);
u = sign(randn(3000, 1));
y = filter([0 0.5], [1 -0.8], u);
zf = iddata(y, u, 1);
g = spa(zf, 60);
w = 0.5;
attendu = 0.5 * exp(-1i * w) / (1 - 0.8 * exp(-1i * w));
obtenu = freqresp(g, w);
ecart = abs(obtenu - attendu) / abs(attendu);
fprintf('SPA a w = 0.5 : ecart relatif %.4f\n', ecart);
assert(ecart < 0.05);
assert(abs(abs(freqresp(g, 1e-6)) - 2.5) < 0.2);
ge = etfe(zf);
assert(abs(freqresp(ge, w) - attendu) / abs(attendu) < 0.3);
assert(numel(ge.Frequency) > 100);
disp('analyse spectrale : ok');

% Signaux d'entrée.
rng(1);
up = idinput(511, 'prbs');
assert(isequal(sort(unique(up)).', [-1 1]));
assert(abs(mean(up)) < 0.05);
% Une suite pseudo-aléatoire est presque décorrélée d'elle-même.
correlations = matlibre_id_correlation(up, up, 20);
assert(abs(correlations(21) - 1) < 1e-12);
assert(max(abs(correlations([1:20, 22:41]))) < 0.15);
ug = idinput(300, 'rgs', [0 1], [-2 2]);
assert(abs(min(ug) + 2) < 1e-9 && abs(max(ug) - 2) < 1e-9);
% Les conseils lisent le retard dans les données.
rng(1);
uc = idinput(500, 'prbs');
yc = filter([0 0 0.5], [1 -0.8], uc);
conseils = advice(iddata(yc, uc, 1));
fprintf('retard lu : %d (attendu 2)\n', conseils.RetardApparent);
assert(conseils.RetardApparent == 2);
assert(conseils.Echantillons == 500);
disp('signaux et conseils : ok');

% L'interpolation garde les nombres complexes, ce dont vit la réponse
% fréquentielle.
assert(abs(interp1([0; 1], [1 + 2i; 3 + 4i], 0.5) - (2 + 3i)) < 1e-12);

disp('identification : toutes les verifications passent');
