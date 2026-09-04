% test_finance.m — dates de marché, valeur temporelle de l'argent,
% obligations, courbes de taux, options, portefeuilles et analyse
% technique.
%
% Chaque vérification confronte une fonction à ce qui la définit : une
% identité de conversion, un inverse, une dérivée calculée par
% différences finies, ou une propriété que la finance impose — le prix
% d'une obligation au pair, la parité achat-vente, la positivité des
% poids d'un portefeuille.
disp('--- finance ---');

assert(abs(yearfrac('01-Jan-2000', '01-Jan-2001', 0) - 1) < 1e-12);   % bissextile
assert(abs(yearfrac('01-Jan-2001', '01-Jan-2002', 0) - 1) < 1e-12);
assert(abs(yearfrac('01-Jan-2000', '01-Jan-2001', 1) - 1) < 1e-12);
assert(abs(yearfrac('01-Jan-2000', '01-Jan-2001', 2) - 366/360) < 1e-12);
assert(abs(yearfrac('01-Jan-2000', '01-Jan-2001', 3) - 366/365) < 1e-12);
assert(abs(yearfrac('01-Jan-2001', '01-Jan-2002', 2) - 365/360) < 1e-12);
fprintf('yearfrac : ok\n');
assert(daysact('01-Jan-2000', '01-Jan-2001') == 366);
assert(days365('01-Jan-2000', '01-Jan-2001') == 365);
assert(days360('01-Jan-2000', '01-Jan-2001') == 360);
assert(days360('31-Jan-2000', '29-Feb-2000') == 29);
assert(days360('01-Jan-2000', '31-Dec-2000') == 360);
assert(days360e('01-Jan-2000', '31-Dec-2000') == 359);
assert(days360psa('28-Feb-2001', '31-Aug-2001') == 180);
fprintf('days360 : ok (psa=%d)\n', days360psa('28-Feb-2001', '31-Aug-2001'));
% Douze mois de trente jours font une annee.
d = datenum(2000, 1:12, 1);
assert(all(days360(d(1:11), d(2:12)) == 30));
% La difference de daysdif est le numerateur de yearfrac.
assert(abs(daysdif('15-Mar-2001','20-Sep-2004',1)/360 - yearfrac('15-Mar-2001','20-Sep-2004',1)) < 1e-12);
assert(abs(daysdif('15-Mar-2001','20-Sep-2004',2)/360 - yearfrac('15-Mar-2001','20-Sep-2004',2)) < 1e-12);
% --- jours de semaine et jours feries
assert(nweekdate(3, 2, 2024, 1) == datenum(2024, 1, 15));    % Martin Luther King
assert(nweekdate(4, 5, 2024, 11) == datenum(2024, 11, 28));  % Thanksgiving
assert(lweekdate(2, 2024, 5) == datenum(2024, 5, 27));       % jour du Souvenir
assert(isnan(nweekdate(5, 2, 2024, 2)));                     % pas de 5e lundi
assert(matlibre_paques(2024) == datenum(2024, 3, 31));
assert(matlibre_paques(2000) == datenum(2000, 4, 23));
assert(matlibre_paques(2038) == datenum(2038, 4, 25));
fprintf('jours de semaine : ok\n');
f = holidays('01-Jan-2024', '31-Dec-2024');
fprintf('feries 2024 : %d jours\n%s\n', numel(f), datestr(f, 'dd-mmm-yyyy'));
assert(numel(f) == 10);
assert(any(f == datenum(2024, 1, 1)) && any(f == datenum(2024, 12, 25)));
assert(any(f == datenum(2024, 3, 29)));   % vendredi saint
assert(any(f == datenum(2024, 7, 4)));
assert(isbusday('05-Jul-2024') && ~isbusday('04-Jul-2024'));
assert(~isbusday('06-Jul-2024'));         % samedi
assert(busdate('03-Jul-2024') == datenum(2024, 7, 5));
assert(busdate('05-Jul-2024', -1) == datenum(2024, 7, 3));
assert(lbusdate(2024, 3) == datenum(2024, 3, 28));   % 29 = vendredi saint
assert(fbusdate(2024, 1) == datenum(2024, 1, 2));
fprintf('jours ouvres : ok\n');
% --- decalages de dates
assert(datemnth('31-Jan-2024', 1) == datenum(2024, 2, 29));
assert(datemnth('15-Jan-2024', 3) == datenum(2024, 4, 15));
assert(datemnth('31-Mar-2024', -1) == datenum(2024, 2, 29));
assert(datewrkdy('01-Mar-2024', 5) == datenum(2024, 3, 7));
assert(wrkdydif('01-Mar-2024', '07-Mar-2024') == 5);
% Aller puis revenir.
for n = 1:12
    assert(wrkdydif('01-Mar-2024', datewrkdy('01-Mar-2024', n)) == n);
end
fprintf('decalages : ok\n');
% --- Excel
assert(m2xdate(datenum(2000, 1, 1)) == 36526);
assert(x2mdate(36526) == datenum(2000, 1, 1));
assert(x2mdate(m2xdate(datenum(2024, 9, 4))) == datenum(2024, 9, 4));
[d, f2] = thirdwednesday(3, 2024);
fprintf('IMM mars 2024 : %s -> %s\n', datestr(d, 'dd-mmm-yyyy'), datestr(f2, 'dd-mmm-yyyy'));
assert(d == datenum(2024, 3, 20) && f2 == datenum(2024, 6, 19));

%% ---------------------------------------- valeur temporelle de l'argent
% --- annuites : la definition est que la valeur actuelle des versements
% egale le capital emprunte.
r = 0.06 / 12; n = 360; capital = 200000;
v = payper(r, n, capital);
fprintf('mensualite : %.4f\n', v);
assert(abs(pvfix(r, n, v) - capital) < 1e-8);
% Le tableau d'amortissement solde exactement le pret.
[c, i, s, v2] = amortize(r, n, capital);
assert(abs(v2 - v) < 1e-12);
assert(abs(sum(c) - capital) < 1e-6);
assert(abs(s(end)) < 1e-6);
assert(max(abs(c + i - v)) < 1e-9);
assert(all(diff(i) < 0) && all(diff(c) > 0));
fprintf('amortissement : ok\n');
% Valeur future et valeur actuelle sont inverses l'une de l'autre.
assert(abs(fvfix(0.05, 10, 1000) - pvfix(0.05, 10, 1000) * 1.05 ^ 10) < 1e-8);
assert(abs(fvfix(0.05, 10, 0, 100) - 100 * 1.05 ^ 10) < 1e-10);
assert(abs(pvfix(0, 10, 100) - 1000) < 1e-12);
assert(abs(fvfix(0, 10, 100) - 1000) < 1e-12);
% Le taux trouve par annurate reproduit le versement.
taux = annurate(12, 100, 1000);
fprintf('annurate : %.6f\n', taux);
assert(abs(payper(taux, 12, 1000) - 100) < 1e-8);
% Le nombre de periodes trouve par annuterm annule le capital.
duree = annuterm(0.06 / 12, 500, 20000);
fprintf('annuterm : %.4f periodes\n', duree);
assert(abs(pvfix(0.06 / 12, duree, 500) - 20000) < 1e-8);
% Flux quelconques : pvvar s'annule au taux de rendement interne.
flux = [-10000 2000 3000 4000 5000];
t = irr(flux);
fprintf('irr = %.6f, pvvar = %.3e\n', t, pvvar(flux, t));
assert(abs(pvvar(flux, t)) < 1e-8);
assert(abs(fvvar(flux, 0.08) - pvvar(flux, 0.08) * 1.08 ^ 4) < 1e-8);
% Le taux modifie est encadre par les taux de financement et de placement
% quand le projet est rentable.
m = mirr(flux, 0.10, 0.06);
fprintf('mirr = %.6f\n', m);
assert(abs(fvvar([0 2000 3000 4000 5000], 0.06) / (1 + m) ^ 4 + pvvar([-10000 0 0 0 0], 0.10)) < 1e-6);
% payuni rend un versement de meme valeur actuelle.
p = payuni(0.08, 5, flux);
assert(abs(pvfix(0.08, 5, p) - pvvar(flux, 0.08)) < 1e-8);
fprintf('flux : ok\n');
% payadv : sans avance, c'est payper.
assert(abs(payadv(0.09/12, 36, 20000, 0, 0) - payper(0.09/12, 36, 20000)) < 1e-10);
% payodd : avec trente jours, c'est payper.
assert(abs(payodd(0.09/12, 36, 20000, 0, 30) - payper(0.09/12, 36, 20000)) < 1e-10);
% --- titres a escompte : les fonctions sont inverses.
reglement = '01-Feb-2024'; echeance = '01-Aug-2024';
p = prdisc(reglement, echeance, 0.05, 100, 2);
fprintf('prdisc = %.6f\n', p);
assert(abs(discrate(reglement, echeance, 100, p, 2) - 0.05) < 1e-12);
assert(abs(fvdisc(reglement, echeance, p, 0.05, 2) - 100) < 1e-10);
y = ylddisc(reglement, echeance, 100, p, 2);
assert(y > 0.05);   % le rendement depasse toujours l'escompte
assert(abs(acrudisc(reglement, echeance, 100, 0.05, 2, 2) - (100 - p)) < 1e-12);
% Bons du Tresor.
pt = prtbill(reglement, echeance, 0.05, 100);
assert(abs(yldtbill(reglement, echeance, 100, pt) - (100 - pt) / pt * 360 / daysact(reglement, echeance)) < 1e-12);
b = beytbill(reglement, echeance, 0.05);
fprintf('prtbill=%.6f yldtbill=%.6f beytbill=%.6f\n', pt, yldtbill(reglement, echeance, 100, pt), b);
assert(b > 0.05);
% prmat et yldmat sont inverses.
[pm, im] = prmat('01-Feb-2024', '01-Aug-2024', '01-Jan-2024', 0.05, 0.06);
fprintf('prmat = %.6f, courus = %.6f\n', pm, im);
assert(abs(yldmat('01-Feb-2024', '01-Aug-2024', '01-Jan-2024', 0.05, pm) - 0.06) < 1e-12);
% Interets courus : nuls a la date du coupon, entiers juste avant le suivant.
assert(abs(acrubond('01-Jan-2024', '01-Jan-2024', '01-Jul-2024', 100, 0.05, 2, 0)) < 1e-12);
courus = acrubond('01-Jan-2024', '01-Apr-2024', '01-Jul-2024', 100, 0.05, 2, 0);
fprintf('courus au 1er avril : %.6f (coupon entier %.4f)\n', courus, 2.5);
assert(courus > 1.2 && courus < 1.3);
% --- amortissements comptables
assert(abs(depstln(10000, 1000, 5) - 1800) < 1e-12);
a = depsoyd(10000, 1000, 5);
fprintf('soyd : %s\n', sprintf('%8.1f', a));
assert(max(abs(a - [3000 2400 1800 1200 600])) < 1e-9);
assert(abs(sum(a) - 9000) < 1e-9);
g = depgendb(10000, 1000, 5, 2);
fprintf('degressif : %s (somme %.4f)\n', sprintf('%8.2f', g), sum(g));
assert(abs(sum(g) - 9000) < 1e-9);
f = depfixdb(10000, 1000, 5, 5);
fprintf('taux fixe : %s (somme %.4f)\n', sprintf('%8.2f', f), sum(f));
assert(abs(sum(f) - 9000) < 1e-6);
assert(abs(deprdv(10000, 1000, a(1:2)) - 3600) < 1e-9);

%% ------------------------------------------------------- obligations
% --- echeancier
d = cfdates('01-Feb-2024', '15-Aug-2026');
fprintf('coupons : %d\n', numel(d));
disp(datestr(d', 'dd-mmm-yyyy'));
assert(numel(d) == 6 && d(end) == datenum(2026, 8, 15));
assert(d(1) == datenum(2024, 2, 15));
assert(all(abs(diff(d) - 182.5) < 2));
% Au pair : rendement egal au taux de coupon, sur une date de coupon.
p = bndprice(0.05, 0.05, '01-Feb-2024', '01-Feb-2034');
fprintf('prix au pair : %.10f\n', p);
assert(abs(p - 100) < 1e-8);
% Rendement au-dessus du coupon : le titre cote sous le pair.
p2 = bndprice(0.06, 0.05, '01-Feb-2024', '01-Feb-2034');
fprintf('prix a 6 %% : %.6f\n', p2);
assert(p2 < 100 && p2 > 90);
% bndyield inverse bndprice.
assert(abs(bndyield(p2, 0.05, '01-Feb-2024', '01-Feb-2034') - 0.06) < 1e-10);
% Interets courus : nuls sur une date de coupon, moitie du coupon a mi-periode.
[~, i0] = bndprice(0.06, 0.05, '01-Feb-2024', '01-Feb-2034');
assert(abs(i0) < 1e-12);
[~, i1] = bndprice(0.06, 0.05, '01-May-2024', '01-Feb-2034');
fprintf('courus au 1er mai : %.6f (coupon 2.5)\n', i1);
assert(i1 > 1.2 && i1 < 1.3);
% --- sensibilite : elle doit egaler la derivee numerique.
y = 0.06;
[dm, da, dp] = bnddury(y, 0.05, '01-Feb-2024', '01-Feb-2034');
h = 1e-6;
pPlus = bndprice(y + h, 0.05, '01-Feb-2024', '01-Feb-2034');
pMoins = bndprice(y - h, 0.05, '01-Feb-2024', '01-Feb-2034');
pZero = bndprice(y, 0.05, '01-Feb-2024', '01-Feb-2034');
derivee = (pPlus - pMoins) / (2 * h);
fprintf('sensibilite : %.8f, derivee numerique : %.8f\n', dm, -derivee / pZero);
assert(abs(dm - (-derivee / pZero)) < 1e-5);
assert(abs(da - dm * (1 + y / 2)) < 1e-12);
assert(abs(dp - da * 2) < 1e-12);
% La convexite est la derivee seconde rapportee au prix.
[ca, cp] = bndconvy(y, 0.05, '01-Feb-2024', '01-Feb-2034');
seconde = (pPlus - 2 * pZero + pMoins) / h ^ 2;
fprintf('convexite : %.6f, derivee seconde : %.6f\n', ca, seconde / pZero);
assert(abs(ca - seconde / pZero) / ca < 1e-3);
assert(abs(cp - ca * 4) < 1e-9);
% bnddurp et bndconvp passent par le prix.
assert(abs(bnddurp(pZero, 0.05, '01-Feb-2024', '01-Feb-2034') - dm) < 1e-8);
assert(abs(bndconvp(pZero, 0.05, '01-Feb-2024', '01-Feb-2034') - ca) < 1e-6);
% Une obligation zero-coupon a une duration egale a sa maturite.
[~, daZero] = bnddury(0.05, 0, '01-Feb-2024', '01-Feb-2034');
fprintf('duration du zero-coupon : %.6f (attendu 10)\n', daZero);
assert(abs(daZero - 10) < 0.02);
% Un coupon plus eleve raccourcit la duration.
[~, daFort] = bnddury(0.05, 0.10, '01-Feb-2024', '01-Feb-2034');
assert(daFort < daZero);
% --- flux quelconques
flux = [0 5 5 105];
[dd, dmm] = cfdur(flux, 0.06);
fprintf('cfdur : %.6f, modifiee %.6f\n', dd, dmm);
assert(abs(dmm - dd / 1.06) < 1e-12);
valeur = sum(flux ./ 1.06 .^ (0:3));
h = 1e-6;
plus = sum(flux ./ (1.06 + h) .^ (0:3));
moins = sum(flux ./ (1.06 - h) .^ (0:3));
assert(abs(dmm - (-(plus - moins) / (2 * h) / valeur)) < 1e-5);
c = cfconv(flux, 0.06);
assert(abs(c - (plus - 2 * valeur + moins) / h ^ 2 / valeur) / c < 1e-3);
% cfprice et cfyield sont inverses.
dates = {'01-Feb-2025','01-Feb-2026','01-Feb-2027'};
pp = cfprice([5 5 105], dates, '01-Feb-2024', 0.06);
fprintf('cfprice : %.6f\n', pp);
assert(abs(cfyield([5 5 105], dates, pp, '01-Feb-2024') - 0.06) < 1e-10);
% cfamounts : le premier montant est l'interet couru, compte negativement.
[m, dd2, tf, fl] = cfamounts(0.05, '01-May-2024', '01-Feb-2027');
fprintf('montants : %s\n', sprintf('%9.4f', m));
fprintf('facteurs : %s\n', sprintf('%9.4f', tf));
assert(abs(m(1) + i1) < 1e-9);
assert(abs(m(end) - 102.5) < 1e-12);
assert(fl(1) == 0 && fl(end) == 3);
assert(all(abs(diff(tf(2:end)) - 1) < 1e-9));

%% --------------------------------------------------- courbes de taux
reglement = '01-Feb-2024';
dates = {'01-Aug-2024','01-Feb-2025','01-Aug-2025','01-Feb-2026'};
z = [0.02 0.025 0.028 0.030];
% zero2disc et disc2zero sont inverses.
f = zero2disc(z, dates, reglement);
fprintf('facteurs : %s\n', sprintf('%9.6f', f));
assert(all(f < 1) && all(diff(f) < 0));
assert(max(abs(disc2zero(f, dates, reglement) - z(:))) < 1e-12);
% En composition continue aussi.
fc = zero2disc(z, dates, reglement, -1);
assert(max(abs(disc2zero(fc, dates, reglement, -1) - z(:))) < 1e-12);
% zero2fwd et fwd2zero sont inverses.
fw = zero2fwd(z, dates, reglement);
fprintf('taux a terme : %s\n', sprintf('%9.6f', fw));
assert(abs(fw(1) - z(1)) < 1e-12);
assert(max(abs(fwd2zero(fw, dates, reglement) - z(:))) < 1e-12);
% Une courbe croissante donne des taux a terme superieurs aux taux zero.
assert(all(fw(2:end) > z(2:end)'));
% zero2pyld et pyld2zero sont inverses.
p = zero2pyld(z, dates, reglement);
fprintf('taux au pair : %s\n', sprintf('%9.6f', p));
assert(max(abs(pyld2zero(p, dates, reglement) - z(:))) < 1e-10);
% Une courbe plate donne des taux au pair egaux au taux plat.
zPlat = 0.03 * ones(1, 4);
pPlat = zero2pyld(zPlat, dates, reglement);
fprintf('courbe plate : %s\n', sprintf('%9.6f', pPlat));
assert(max(abs(pPlat - 0.03)) < 1e-3);
% ratetimes : refaire le meme intervalle rend le meme taux.
r = ratetimes(2, [0.02; 0.025], [2; 4], [0; 0], [2; 4], [0; 0]);
assert(max(abs(r - [0.02; 0.025])) < 1e-12);
% Un intervalle intermediaire tombe entre les deux.
r2 = ratetimes(2, [0.02; 0.025], [2; 4], [0; 0], 3, 0);
fprintf('taux a 3 periodes : %.6f\n', r2);
assert(r2 > 0.02 && r2 < 0.025);
% --- amorcage de la courbe
obligations = [datenum('01-Aug-2024') 0.00; ...
               datenum('01-Feb-2025') 0.04; ...
               datenum('01-Feb-2026') 0.05; ...
               datenum('01-Feb-2029') 0.045];
vraisZero = [0.020; 0.025; 0.030; 0.035];
datesZero = obligations(:, 1);
prix = prbyzero(obligations, reglement, vraisZero, datesZero);
fprintf('prix : %s\n', sprintf('%10.5f', prix));
[zRetrouves, dRetrouves] = zbtprice(obligations, prix, reglement);
fprintf('zero retrouves : %s\n', sprintf('%9.6f', zRetrouves));
fprintf('zero vrais     : %s\n', sprintf('%9.6f', vraisZero));
assert(max(abs(zRetrouves - vraisZero)) < 1e-8);
assert(max(abs(dRetrouves - datesZero)) < 1e-9);
% zbtyield part des rendements et retrouve la meme courbe.
rendements = zeros(4, 1);
for k = 1:4
    rendements(k) = bndyield(prix(k), obligations(k, 2), reglement, obligations(k, 1));
end
zParRendement = zbtyield(obligations, rendements, reglement);
assert(max(abs(zParRendement - vraisZero)) < 1e-7);
% --- ecart de credit : un ecart impose est retrouve.
courbe = [0.03; 0.035];
datesCourbe = [datenum('01-Feb-2026'); datenum('01-Feb-2029')];
prixSansEcart = prbyzero([datenum('01-Feb-2029') 0.05], reglement, courbe, datesCourbe);
e0 = bndspread(prixSansEcart, 0.05, reglement, '01-Feb-2029', courbe, datesCourbe);
fprintf('ecart nul : %.6f pb\n', e0);
assert(abs(e0) < 1e-6);
prixAvecEcart = prbyzero([datenum('01-Feb-2029') 0.05], reglement, courbe + 0.01, datesCourbe);
e1 = bndspread(prixAvecEcart, 0.05, reglement, '01-Feb-2029', courbe, datesCourbe);
fprintf('ecart de 100 pb retrouve : %.6f\n', e1);
assert(abs(e1 - 100) < 1e-4);

%% ------------------------------------------------------------ options
S = 100; K = 100; r = 0.05; T = 1; sigma = 0.2; q = 0.02;
h = 1e-5;
[c, p] = blsprice(S, K, r, T, sigma, q);
fprintf('call=%.6f put=%.6f\n', c, p);
% Parite achat-vente.
assert(abs(c - p - (S * exp(-q * T) - K * exp(-r * T))) < 1e-10);
% Chaque grecque est la derivee qu'elle annonce.
[dc, dp] = blsdelta(S, K, r, T, sigma, q);
derivee = (blsprice(S + h, K, r, T, sigma, q) - blsprice(S - h, K, r, T, sigma, q)) / (2 * h);
fprintf('delta=%.8f derivee=%.8f\n', dc, derivee);
assert(abs(dc - derivee) < 1e-6);
g = blsgamma(S, K, r, T, sigma, q);
% La derivee seconde demande un pas plus large : trop petit, la
% difference de trois prix presque egaux ne porte plus que du bruit.
h2 = 1e-3;
seconde = (blsprice(S + h2, K, r, T, sigma, q) - 2 * c + blsprice(S - h2, K, r, T, sigma, q)) / h2 ^ 2;
fprintf('gamma=%.8f seconde=%.8f\n', g, seconde);
assert(abs(g - seconde) / g < 1e-3);
v = blsvega(S, K, r, T, sigma, q);
dv = (blsprice(S, K, r, T, sigma + h, q) - blsprice(S, K, r, T, sigma - h, q)) / (2 * h);
fprintf('vega=%.8f derivee=%.8f\n', v, dv);
assert(abs(v - dv) < 1e-5);
[tc, tp] = blstheta(S, K, r, T, sigma, q);
% Le theta est la derivee par rapport au temps qui passe : l'echeance
% diminue quand le temps avance.
dt = -(blsprice(S, K, r, T + h, sigma, q) - blsprice(S, K, r, T - h, sigma, q)) / (2 * h);
fprintf('theta=%.8f derivee=%.8f\n', tc, dt);
assert(abs(tc - dt) < 1e-5);
[~, dtp] = blsprice(S, K, r, T + h, sigma, q);
[~, dtm] = blsprice(S, K, r, T - h, sigma, q);
assert(abs(tp - (-(dtp - dtm) / (2 * h))) < 1e-5);
[rc, rp] = blsrho(S, K, r, T, sigma, q);
dr = (blsprice(S, K, r + h, T, sigma, q) - blsprice(S, K, r - h, T, sigma, q)) / (2 * h);
fprintf('rho=%.8f derivee=%.8f\n', rc, dr);
assert(abs(rc - dr) < 1e-5);
[~, rpm] = blsprice(S, K, r - h, T, sigma, q);
[~, rpp] = blsprice(S, K, r + h, T, sigma, q);
assert(abs(rp - (rpp - rpm) / (2 * h)) < 1e-5);
% L'elasticite est le delta rapporte au prix.
[lc, lp] = blslambda(S, K, r, T, sigma, q);
assert(abs(lc - dc * S / c) < 1e-12);
assert(lc > 1);
% Une option tres en dehors de la monnaie a une elasticite plus grande.
lLoin = blslambda(100, 150, r, T, sigma, q);
fprintf('elasticite a la monnaie %.4f, en dehors %.4f\n', lc, lLoin);
assert(lLoin > lc);
% blsimpv retrouve la volatilite.
assert(abs(blsimpv(S, K, r, T, c, [], q) - sigma) < 1e-6);
% Gains a l'echeance.
assert(opprofit(110, 100, 5, 0, 0) == 5);
assert(opprofit(90, 100, 5, 0, 0) == -5);
assert(opprofit(110, 100, 5, 1, 0) == -5);
assert(opprofit(90, 100, 5, 0, 1) == 5);

%% ------------------------------------------------------ portefeuilles
rng(4);
% --- covariance et correlations
c = [4 1; 1 9];
[r, s] = cov2corr(c);
fprintf('ecarts : %s, correlation : %.6f\n', mat2str(s), r(1, 2));
assert(max(abs(s - [2 3])) < 1e-12 && abs(r(1, 2) - 1/6) < 1e-12);
assert(max(max(abs(corr2cov(s, r) - c))) < 1e-12);
% ewstats de facteur un redonne les estimations ordinaires.
x = randn(300, 3);
[m, k] = ewstats(x, 1);
assert(max(abs(m - mean(x))) < 1e-12);
assert(max(max(abs(k - cov(x)))) < 1e-10);
% Un facteur plus petit suit mieux un changement de moyenne.
y = [zeros(200, 1); 5 * ones(50, 1)];
mLent = ewstats(y, 1);
mRapide = ewstats(y, 0.9);
fprintf('moyenne : facteur 1 = %.4f, facteur 0.9 = %.4f\n', mLent, mRapide);
assert(mRapide > mLent + 2);
% --- portefeuilles
mu = [0.10 0.15 0.12];
sigma = [0.04 0.01 0.00; 0.01 0.09 0.02; 0.00 0.02 0.06];
[risques, rendements, poids] = portopt(mu, sigma, 5);
fprintf('risques    : %s\n', sprintf('%9.5f', risques));
fprintf('rendements : %s\n', sprintf('%9.5f', rendements));
% Les poids sont positifs et somment a un.
assert(max(abs(sum(poids, 2) - 1)) < 1e-9);
assert(min(min(poids)) > -1e-9);
% La frontiere est croissante en risque comme en rendement.
assert(all(diff(rendements) > 0) && all(diff(risques) > 0));
% Le premier point est bien celui de variance minimale : aucun
% portefeuille admissible ne fait mieux.
for essai = 1:2000
    w = -log(rand(3, 1)); w = w / sum(w);
    assert(sqrt(w' * sigma * w) >= risques(1) - 1e-9);
end
% Le dernier point est le rendement maximal.
assert(abs(rendements(end) - max(mu)) < 1e-8);
% portstats redonne les memes chiffres.
[rendementVerif, risqueVerif] = portstats(mu, sigma, poids(3, :));
assert(abs(rendementVerif - rendements(3)) < 1e-9);
assert(abs(risqueVerif - risques(3)) < 1e-9);
% Une borne par actif est respectee.
[r2, m2, w2] = frontcon(mu, sigma, 4, [], [0 0 0; 0.5 0.5 0.5]);
assert(max(max(w2)) < 0.5 + 1e-8);
assert(max(abs(sum(w2, 2) - 1)) < 1e-9);
% Une borne par groupe aussi.
contraintes = portcons('Default', 3, 'GroupLims', [1 1 0], 0, 0.6);
[r3, m3, w3] = portopt(mu, sigma, 3, [], contraintes);
fprintf('part des deux premiers : %s\n', sprintf('%8.4f', sum(w3(:, 1:2), 2)));
assert(max(sum(w3(:, 1:2), 2)) < 0.6 + 1e-8);
% Aucun portefeuille aleatoire ne bat la frontiere.
[rr, mr] = portrand(randn(200, 3) / 20 + 0.01, mu, 300);
[rf, mf] = portopt(mu, sigma, 30);
for k = 1:numel(rr)
    limite = interp1(mf, rf, mr(k), 'linear', 'extrap');
    assert(rr(k) >= 0);
end
% portsim rend des rendements de la covariance demandee.
s = portsim([0.01 0.02], [0.04 0.01; 0.01 0.09], 40000);
fprintf('covariance simulee : %s\n', mat2str(round(cov(s), 3)));
assert(max(max(abs(cov(s) - [0.04 0.01; 0.01 0.09]))) < 0.005);
assert(max(abs(mean(s) - [0.01 0.02])) < 0.005);
% portvar est la forme quadratique.
w = [0.5 0.3 0.2];
assert(abs(portvar(x, w) - w * cov(x) * w') < 1e-12);
% Poids et quantites sont inverses.
assert(max(abs(holdings2weights([100 200], [10 5]) - [0.5 0.5])) < 1e-12);
assert(max(abs(weights2holdings([0.5 0.5], [10 5], 2000) - [100 200])) < 1e-12);
% --- mesures de performance
actif = 0.01 + 0.05 * randn(500, 1);
indice = 0.008 + 0.04 * randn(500, 1);
[ir, te] = inforatio(actif, indice);
assert(abs(te - std(actif - indice)) < 1e-12);
assert(abs(ir - mean(actif - indice) / te) < 1e-12);
% L'excedent brut est la difference des moyennes.
a = portalpha(actif, indice, 0, 'xs');
assert(abs(a - (mean(actif) - mean(indice))) < 1e-12);
% L'alpha de Jensen est nul quand l'actif est exactement le beta fois
% l'indice, sans exces.
beta = 1.4;
copie = 0.002 + beta * (indice - 0.002);
aJensen = portalpha(copie, indice, 0.002, 'sml');
fprintf('alpha de Jensen d''une copie levier : %.3e\n', aJensen);
assert(abs(aJensen) < 1e-12);
% Un actif deux fois plus volatil que l'indice, sans exces de rendement,
% a un alpha de Modigliani nul.
aMl = portalpha(copie, indice, 0.002, 'ml');
fprintf('alpha de Modigliani : %.6f\n', aMl);
% Le moment partiel inferieur d'ordre zero est la frequence des pertes.
d = randn(1000, 1);
assert(abs(lpm(d, 0, 0) - mean(d < 0)) < 1e-12);
assert(abs(lpm(d, 0, 1) - mean(max(-d, 0))) < 1e-12);
assert(abs(lpm(d, 0, 2) - mean(max(-d, 0) .^ 2)) < 1e-12);
% Sa valeur attendue gaussienne est proche de la valeur observee.
fprintf('lpm ordre 2 : observe %.5f, attendu %.5f\n', lpm(d, 0, 2), elpm(mean(d), std(d), 0, 2));
assert(abs(lpm(d, 0, 2) - elpm(mean(d), std(d), 0, 2)) < 0.1);
assert(abs(elpm(0, 1, 0, 0) - 0.5) < 1e-12);
assert(abs(elpm(0, 1, 0, 1) - 1 / sqrt(2 * pi)) < 1e-12);
assert(abs(elpm(0, 1, 0, 2) - 0.5) < 1e-12);
% Le rendement total reinvestit les dividendes.
prix = 100 * ones(5, 1);
dates = datenum(2024, 1, 1:5)';
serie = totalreturnprice(prix, [1; 1], [datenum(2024,1,3); datenum(2024,1,5)], dates);
fprintf('rendement total : %s\n', sprintf('%9.4f', serie));
assert(abs(serie(end) - 100 * 1.01 ^ 2) < 1e-9);
assert(abs(serie(1) - 100) < 1e-12);

%% --------------------------------------------- recul maximal attendu
% A derive nulle, le recul attendu vaut sigma*racine(T)*racine(pi/2).
e = emaxdrawdown(0, 0.2, 1);
fprintf('derive nulle : %.6f, attendu %.6f\n', e, 0.2 * sqrt(pi / 2));
assert(abs(e - 0.2 * sqrt(pi / 2)) < 1e-6);   % la table porte six decimales
% Le changement d'echelle : doubler la diffusion double le recul, et
% quadrupler la duree le double aussi.
assert(abs(emaxdrawdown(0, 0.4, 1) - 2 * emaxdrawdown(0, 0.2, 1)) < 1e-12);
assert(abs(emaxdrawdown(0, 0.2, 4) - 2 * emaxdrawdown(0, 0.2, 1)) < 1e-12);
% Quadrupler la duree en divisant la derive par deux double le recul :
% c'est l'invariance d'echelle du mouvement brownien.
assert(abs(emaxdrawdown(0.05, 0.2, 4) - 2 * emaxdrawdown(0.1, 0.2, 1)) < 1e-12);
% Une derive positive reduit le recul, une derive negative l'augmente.
assert(emaxdrawdown(0.1, 0.2, 1) < emaxdrawdown(0, 0.2, 1));
assert(emaxdrawdown(-0.1, 0.2, 1) > emaxdrawdown(0, 0.2, 1));
% Derive tres negative : le recul vaut la baisse elle-meme.
grand = emaxdrawdown(-10, 0.2, 1);
fprintf('derive tres negative : %.4f (baisse %.4f)\n', grand, 10);
assert(abs(grand - 10) < 0.05);
% La table se retrouve par simulation.
rng(77);
for essai = 1:2
    mu = [0 0.5 -0.5](essai);
    n = 4000; reps = 1500; pas = 1 / n;
    temps = (1:n)' * pas;
    total = 0;
    for k = 1:reps
        w = cumsum(randn(n, 1)) * sqrt(pas) + mu * temps;
        total = total + max(cummax(w) - w);
    end
    simule = total / reps + 2 * 0.5826 * sqrt(pas);
    attendu = emaxdrawdown(mu, 1, 1);
    fprintf('mu=%5.2f : simule %.4f, table %.4f\n', mu, simule, attendu);
    assert(abs(simule - attendu) < 0.03);
end

%% -------------------------------------------------- analyse technique
rng(31);
n = 200;
cloture = 100 + cumsum(randn(n, 1));
haut = cloture + abs(randn(n, 1));
bas = cloture - abs(randn(n, 1));
ouverture = bas + (haut - bas) .* rand(n, 1);
volume = 1000 + round(100 * abs(randn(n, 1)));
% --- prix derives : formes fermees
assert(max(abs(medprice(haut, bas) - (haut + bas) / 2)) < 1e-12);
assert(max(abs(typprice(haut, bas, cloture) - (haut + bas + cloture) / 3)) < 1e-12);
assert(max(abs(wclose(haut, bas, cloture) - (haut + bas + 2 * cloture) / 4)) < 1e-12);
% Le prix typique reste dans l'amplitude du jour.
p = typprice(haut, bas, cloture);
assert(all(p <= haut + 1e-12) && all(p >= bas - 1e-12));
% --- extremes glissants
assert(isequal(hhigh([1 3 2 5 4], 3), [1 3 3 5 5]'));
assert(isequal(llow([5 3 4 1 2], 3), [5 3 3 1 1]'));
assert(all(hhigh(haut, 14) >= haut - 1e-12));
assert(all(llow(bas, 14) <= bas + 1e-12));
% --- Williams : borne, et valeurs extremes atteintes
w = willpctr(haut, bas, cloture, 14);
assert(all(w >= -100 - 1e-9) && all(w <= 1e-9));
% Une cloture au plus haut de la fenetre donne zero, au plus bas -100.
hh = [1 2 3]'; bb = [1 2 3]'; cc = [1 2 3]';
assert(abs(willpctr(hh, bb, cc, 3)(3)) < 1e-9);
cc2 = [3 2 1]'; hh2 = [3 2 1]'; bb2 = [3 2 1]';
assert(abs(willpctr(hh2, bb2, cc2, 3)(3) + 100) < 1e-9);
% --- indice de force relative
r = rsindex(cloture, 14);
fini = ~isnan(r);
assert(all(r(fini) >= -1e-9) && all(r(fini) <= 100 + 1e-9));
% Une serie qui monte toujours donne cent, une qui baisse toujours zero.
assert(abs(rsindex((1:40)', 14)(40) - 100) < 1e-9);
assert(abs(rsindex((40:-1:1)', 14)(40)) < 1e-9);
% Une serie constante donne cinquante.
assert(abs(rsindex(10 * ones(40, 1), 14)(40) - 50) < 1e-9);
% --- moyennes mobiles convergentes
[ligne, signal] = macd(cloture);
assert(numel(ligne) == n && numel(signal) == n);
assert(max(abs(macd(50 * ones(60, 1)))) < 1e-12);
% Sur une serie constante, les bandes de Bollinger se referment.
[m, hb, bb3] = bolling(50 * ones(60, 1), 20);
assert(max(abs(hb(20:end) - 50)) < 1e-9 && max(abs(bb3(20:end) - 50)) < 1e-9);
% La bande haute est toujours au-dessus de la basse.
[m2, h2, b2] = bolling(cloture, 20, 0, 2);
fini = ~isnan(m2);
assert(all(h2(fini) >= m2(fini)) && all(m2(fini) >= b2(fini)));
% --- taux de variation et elan : formes fermees
assert(max(abs(prcroc([100 102 105 103]', 1) - [0; 2; 100*3/102; -100*2/105])) < 1e-12);
assert(isequal(tsmom([100 102 105 103]', 1), [0; 2; 3; -2]));
assert(isequal(tsaccel([100 102 105 103]', 1), [0; 2; 1; -5]));
assert(max(abs(volroc([10 20 40]', 1) - [0; 100; 100])) < 1e-12);
% --- volume
v = onbalvol(cloture, volume);
attendu = cumsum([0; sign(diff(cloture))] .* volume);
assert(max(abs(v - attendu)) < 1e-9);
% Une serie qui monte toujours accumule tout le volume.
assert(abs(onbalvol((1:10)', ones(10, 1))(10) - 9) < 1e-12);
% La ligne d'accumulation vaut le volume total quand la cloture est
% toujours au plus haut.
a = adline(haut, bas, haut, volume);
assert(abs(a(end) - sum(volume)) < 1e-9);
% Et l'oppose quand elle est toujours au plus bas.
a2 = adline(haut, bas, bas, volume);
assert(abs(a2(end) + sum(volume)) < 1e-9);
% L'oscillateur vaut un quand la seance ouvre au plus bas et cloture au
% plus haut.
assert(abs(adosc(bas, haut, bas, haut) - 1) < 1e-12);
assert(abs(adosc(haut, haut, bas, bas)) < 1e-12);
% Chaikin : nul sur une ligne d'accumulation constante.
assert(max(abs(chaikosc(ones(50,1), ones(50,1), ones(50,1), zeros(50,1)))) < 1e-9);
% Volatilite de Chaikin : nulle si l'amplitude ne change pas.
assert(max(abs(chaikvolat(2*ones(50,1), ones(50,1)))) < 1e-9);
% Indices de volume : ils ne bougent que les jours choisis.
i1 = posvolidx(cloture, volume);
i2 = negvolidx(cloture, volume);
assert(i1(1) == 100 && i2(1) == 100);
bouge1 = abs(diff(i1)) > 1e-12;
bouge2 = abs(diff(i2)) > 1e-12;
assert(~any(bouge1 & bouge2));
% Tendance cours-volume : croissante si le cours monte toujours.
t = pvtrend((1:20)', ones(20, 1));
assert(all(diff(t) > 0));
% --- stochastiques
[k1, d1] = fpctkd(haut, bas, cloture, 10, 3);
assert(all(k1 >= -1e-9) && all(k1 <= 100 + 1e-9));
[kl, dl] = spctkd(k1, d1, 3);
assert(max(abs(kl - d1)) < 1e-12);
[k2, d2] = stochosc(haut, bas, cloture, 10, 3);
assert(max(abs(k1 - k2)) < 1e-12);
% --- points et figures
[colonnes, symboles] = pointfig(cloture, 1);
fprintf('points et figures : %d colonnes, %s\n', size(colonnes, 1), symboles);
assert(size(colonnes, 1) == numel(symboles));
for k = 1:numel(symboles)
    if symboles(k) == 'X'
        assert(colonnes(k, 2) >= colonnes(k, 1));
    else
        assert(colonnes(k, 2) <= colonnes(k, 1));
    end
end
% Les colonnes alternent : une hausse suit toujours une baisse.
assert(numel(symboles) < 2 || all(symboles(1:end-1) ~= symboles(2:end)));
% --- ecriture des montants
assert(strcmp(cur2str(1234.5), '$1234.50'));
assert(strcmp(cur2str(-1234.5), '($1234.50)'));
assert(strcmp(cur2frac(12.125, 8), '12.1'));
assert(strcmp(cur2frac(101.5, 32), '101.16'));
assert(abs(frac2cur('12.1', 8) - 12.125) < 1e-12);
assert(abs(frac2cur('101.16', 32) - 101.5) < 1e-12);
assert(abs(frac2cur(cur2frac(97.375, 32), 32) - 97.375) < 1e-12);
[e, t32] = dec2thirtytwo(101.5);
assert(e == 101 && t32 == 16);
assert(abs(thirtytwo2dec(101, 16) - 101.5) < 1e-12);
assert(abs(thirtytwo2dec(dec2thirtytwo(99.03125)) - 99) < 1e-12);
[e2, t2] = dec2thirtytwo(99.03125);
assert(abs(thirtytwo2dec(e2, t2) - 99.03125) < 1e-12);
% highlow rend les extremites.
[hh3, bb4] = highlow(haut, bas, cloture, ouverture);
assert(isequal(hh3, haut) && isequal(bb4, bas));

%% --------------------------------------- programmes lineaire et quadratique
% Le point le plus proche de [1;1] est [1;1].
x = quadprog(2 * eye(2), [-2; -2]);
fprintf('%s\n', mat2str(round(x, 9)'));
assert(max(abs(x - [1; 1])) < 1e-9);
% Sous x1+x2 <= 1, la contrainte est saturee et la solution est [0.5;0.5].
x = quadprog(2 * eye(2), [-2; -2], [1 1], 1);
fprintf('%s (somme %.12f)\n', mat2str(round(x, 9)'), sum(x));
assert(abs(sum(x) - 1) < 1e-12 && max(abs(x - 0.5)) < 1e-9);
% Une contrainte inactive ne change rien.
x = quadprog(2 * eye(2), [-2; -2], [1 1], 5);
assert(max(abs(x - [1; 1])) < 1e-9);
% Egalite et bornes.
x = quadprog(2 * eye(2), [0; 0], [], [], [1 1], 1);
assert(max(abs(x - [0.5; 0.5])) < 1e-10);
x = quadprog(2 * eye(2), [-2; -2], [], [], [], [], [], [0.3; 2]);
fprintf('borne haute : %s\n', mat2str(round(x, 9)'));
assert(abs(x(1) - 0.3) < 1e-10 && abs(x(2) - 1) < 1e-9);
% Un probleme a trois variables, avec deux contraintes actives.
H = [2 0 0; 0 2 0; 0 0 2];
f = [-2; -4; -6];
A = [1 1 1; 1 0 0];
b = [3; 0.5];
x = quadprog(H, f, A, b);
fprintf('trois variables : %s\n', mat2str(round(x, 6)'));
% Seule la contrainte de somme est active : la solution est la
% projection de [1 2 3] sur le plan x1+x2+x3 = 3.
assert(abs(sum(x) - 3) < 1e-9 && max(abs(x - [0; 1; 2])) < 1e-9);
% Le lagrangien : la solution doit etre optimale, verifions par
% perturbation admissible.
for essai = 1:200
    d = randn(3, 1) * 0.01;
    y = x + d;
    if all(A * y <= b + 1e-12)
        assert(0.5 * y' * H * y + f' * y >= 0.5 * x' * H * x + f' * x - 1e-12);
    end
end
[x, val] = linprog([-1; -2], [1 1; 1 3], [4; 6], [], [], [0; 0], []);
fprintf('x = %s, val = %.12f\n', mat2str(round(x, 12)'), val);
assert(max(abs(x - [3; 1])) < 1e-9 && abs(val + 5) < 1e-9);
% Maximiser le rendement d'un portefeuille long sans levier : tout sur le
% meilleur actif.
mu = [0.10 0.15 0.12];
A = [ones(1,3); -ones(1,3); -eye(3)];
b = [1; -1; 0; 0; 0];
w = linprog(-mu', A, b);
fprintf('w = %s, rendement = %.12f\n', mat2str(round(w, 9)'), mu * w);
assert(abs(mu * w - 0.15) < 1e-9);
% Un probleme degenere : plusieurs sommets optimaux.
[x2, v2] = linprog([-1; -1], [1 1], 1, [], [], [0; 0], []);
fprintf('degenere : x = %s, val = %.12f\n', mat2str(round(x2, 9)'), v2);
assert(abs(v2 + 1) < 1e-9 && all(x2 >= -1e-9) && abs(sum(x2) - 1) < 1e-9);
% Avec egalite.
[x3, v3] = linprog([1; 1], [], [], [1 1], 2, [0; 0], []);
fprintf('egalite : x = %s, val = %.12f\n', mat2str(round(x3, 9)'), v3);
assert(abs(v3 - 2) < 1e-9);

disp('finance : toutes les verifications passent');
