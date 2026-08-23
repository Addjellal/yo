% test_statistiques.m — lois, tests et optimisation.
% Chaque valeur de référence est une expression fermée connue : densités
% aux points où elles valent une constante simple, quantiles tabulés,
% optima analytiques.
disp('--- statistiques ---');

%% ------------------------------------------------------------- densités
% Bêta(1,1), c'est la loi uniforme.
assert(abs(betapdf(0.5, 1, 1) - 1) < 1e-12);
assert(abs(betapdf(0.25, 1, 1) - 1) < 1e-12);
assert(abs(betacdf(0.5, 1, 1) - 0.5) < 1e-12);
assert(abs(betacdf(0, 1, 1)) < 1e-12);
assert(abs(betacdf(1, 1, 1) - 1) < 1e-12);
% Bêta(2,1) : densité 2x, répartition x^2.
assert(abs(betapdf(0.5, 2, 1) - 1) < 1e-9);
assert(abs(betacdf(0.5, 2, 1) - 0.25) < 1e-9);

% Gamma(1,1), c'est la loi exponentielle.
assert(abs(gampdf(1, 1, 1) - exp(-1)) < 1e-12);
assert(abs(gamcdf(1, 1, 1) - (1 - exp(-1))) < 1e-12);
assert(abs(gampdf(2, 2, 1) - 2 * exp(-2)) < 1e-12);

% Khi-deux à deux degrés : exponentielle d'échelle 2.
assert(abs(chi2pdf(2, 2) - 0.5 * exp(-1)) < 1e-12);
% Quantiles tabulés du khi-deux.
assert(abs(chi2inv(0.95, 1) - 3.8415) < 1e-3);
assert(abs(chi2inv(0.95, 2) - 5.9915) < 1e-3);
assert(abs(chi2inv(0.5, 1) - 0.4549) < 1e-3);

% Uniforme continue.
assert(abs(unifpdf(0.5, 0, 2) - 0.5) < 1e-12);
assert(abs(unifcdf(0.5, 0, 2) - 0.25) < 1e-12);
assert(unifpdf(3, 0, 2) == 0);

% Rayleigh : densité x/b^2 exp(-x^2/2b^2).
assert(abs(raylpdf(1, 1) - exp(-0.5)) < 1e-12);
assert(abs(raylcdf(1, 1) - (1 - exp(-0.5))) < 1e-12);

% Weibull(1,1) est l'exponentielle.
assert(abs(wblpdf(1, 1, 1) - exp(-1)) < 1e-12);
assert(abs(wblcdf(1, 1, 1) - (1 - exp(-1))) < 1e-12);
% Weibull de forme 2 : la Rayleigh d'échelle a/sqrt(2).
assert(abs(wblcdf(1, sqrt(2), 2) - raylcdf(1, 1)) < 1e-12);

% Log-normale : densité en 1 égale à celle de la normale en 0.
assert(abs(lognpdf(1, 0, 1) - 1 / sqrt(2 * pi)) < 1e-12);
assert(abs(logncdf(1, 0, 1) - 0.5) < 1e-12);

% Fonction bêta logarithmique.
assert(abs(betaln(2, 3) - log(beta(2, 3))) < 1e-12);
assert(abs(betaln(1, 1)) < 1e-12);

%% ------------------------------------------------------ tables et tests
[t, khi2, p] = crosstab([1 1 2 2], [1 2 1 2]);
assert(isequal(t, [1 1; 1 1]));
assert(abs(khi2) < 1e-12);        % indépendance parfaite
assert(abs(p - 1) < 1e-12);
[t2, khi2b] = crosstab([1 1 1 2 2 2], [1 1 1 2 2 2]);
assert(isequal(t2, [3 0; 0 3]));
assert(khi2b > 5);                % dépendance totale

% Wilcoxon : deux groupes disjoints se séparent nettement.
assert(ranksum(1:10, 11:20) < 0.001);
% Deux échantillons identiques ne se séparent pas.
assert(ranksum(1:10, 1:10) > 0.9);
% Rangs signés : une série symétrique autour de zéro n'est pas rejetée.
assert(signrank([-2 -1 0 1 2]) > 0.5);
assert(signrank([1 2 3 4 5 6 7 8 9 10]) < 0.01);

% Kolmogorov-Smirnov : une loi uniforme sur [0,1] n'est pas normale
% centrée réduite.
uniforme = ((1:200)' - 0.5) / 200;
assert(kstest(uniforme) == 1);
% Des quantiles normaux exacts passent le test.
normaux = norminv(((1:200)' - 0.5) / 200);
assert(kstest(normaux) == 0);

%% ------------------------------------------------------ densité par noyau
[f, xi] = ksdensity([0 0 0 1 1 2]);
assert(numel(f) == 100);
assert(abs(trapz(xi, f) - 1) < 0.02);      % une densité s'intègre à 1
assert(all(f >= 0));

% Bootstrap : la moyenne des rééchantillons reste proche de la moyenne.
donnees = (1:100)';
s = bootstrp(200, @mean, donnees);
assert(numel(s) == 200);
assert(abs(mean(s) - mean(donnees)) < 5);

%% ------------------------------------------------------- optimisation
% Moindres carrés non linéaires : les données sont exactes, on doit
% retrouver les paramètres au chiffre près.
t = (0:0.5:2)';
y = 3 * exp(-0.5 * t);
p = lsqnonlin(@(p) p(1) * exp(p(2) * t) - y, [1; -1]);
assert(abs(p(1) - 3) < 1e-4);
assert(abs(p(2) + 0.5) < 1e-4);
[~, resnorm] = lsqnonlin(@(p) p(1) * exp(p(2) * t) - y, [1; -1]);
assert(resnorm < 1e-8);

% Bornes respectées.
q = lsqnonlin(@(p) p(1) - 5, 0, -1, 1);
assert(q <= 1 + 1e-12 && q >= -1 - 1e-12);

% Options : les noms modernes et anciens mènent au même champ.
o = optimoptions('fmincon', 'MaxIterations', 50, 'Display', 'off');
assert(o.MaxIter == 50);
assert(strcmp(o.Display, 'off'));
o2 = optimoptions(o, 'TolX', 1e-3);
assert(abs(o2.TolX - 1e-3) < 1e-15);
assert(o2.MaxIter == 50);

% Programmation en nombres entiers : optima connus.
x = intlinprog([-1; -2], [1 2], [1 1], 4, [], [], [0; 0], [10; 10]);
assert(max(abs(x - [0; 4])) < 1e-6);
y2 = intlinprog([-3; -5], [1 2], [1 0; 0 1; 3 2], [4; 6; 18], [], [], [0; 0], [10; 10]);
assert(max(abs(y2 - [2; 6])) < 1e-6);
assert(all(abs(y2 - round(y2)) < 1e-9));

%% ------------------------------------------- lois de probabilite
% Les valeurs de reference viennent soit d'une forme fermee, soit d'une
% somme finie calculee independamment de la fonction verifiee.

% Fonction digamma : psi(1) = -gamma d'Euler, psi(n) = -gamma + H(n-1),
% psi(1,1) = pi^2/6, psi(3,1) = pi^4/15.
assert(abs(psi(1) + 0.5772156649015329) < 1e-13);
assert(abs(psi(5) - (-0.5772156649015329 + 1 + 1/2 + 1/3 + 1/4)) < 1e-12);
assert(abs(psi(0.5) - (-0.5772156649015329 - 2*log(2))) < 1e-12);
assert(abs(psi(1,1) - pi^2/6) < 1e-12);
assert(abs(psi(3,1) - pi^4/15) < 1e-11);
assert(isequal(size(psi([1 2 3])), [1 3]));

% Exponentielle : quantile en forme fermee, aller-retour avec la
% repartition, moments.
assert(abs(expinv(0.5, 1) - log(2)) < 1e-14);
assert(expinv(0, 3) == 0 && isinf(expinv(1, 3)));
assert(abs(expcdf(expinv(0.3, 4), 4) - 0.3) < 1e-12);
[m, v] = expstat(3);
assert(m == 3 && v == 9);
assert(abs(expfit([1 2 3 4]) - 2.5) < 1e-14);

% Normale : moments, ajustement, log-vraisemblance calculee a la main.
[m, v] = normstat(3, 2);
assert(m == 3 && abs(v - 4) < 1e-14);
donnees = [2 4 4 4 5 5 7 9];
[mu, sigma] = normfit(donnees);
assert(abs(mu - 5) < 1e-14);
assert(abs(sigma - sqrt(32/7)) < 1e-14);
% n log s + n/2 log(2 pi) + SCE/(2 s^2) avec n=8, s=2, SCE=32.
assert(abs(normlike([5 2], donnees) - (8*log(2) + 4*log(2*pi) + 4)) < 1e-12);

% Uniforme continue et discrete.
assert(unifinv(0.25, 2, 6) == 3);
[m, v] = unifstat(0, 1);
assert(m == 0.5 && abs(v - 1/12) < 1e-15);
[a, b] = unifit([3 1 4 1 5]);
assert(a == 1 && b == 5);
assert(abs(unidpdf(3, 6) - 1/6) < 1e-15);
assert(isequal(unidcdf([0 3 6 9], 6), [0 0.5 1 1]));
assert(isequal(unidinv([1/6 0.5 1], 6), [1 3 6]));
[m, v] = unidstat(6);
assert(m == 3.5 && abs(v - 35/12) < 1e-14);

% Gamma : gaminv(p,v/2,2) est le quantile du khi-deux a v degres.
assert(abs(gaminv(0.5, 1, 1) - log(2)) < 1e-12);
assert(abs(gaminv(0.95, 3, 2) - chi2inv(0.95, 6)) < 1e-6);
assert(abs(gamcdf(gaminv(0.37, 2.5, 1.7), 2.5, 1.7) - 0.37) < 1e-12);
[m, v] = gamstat(2, 3);
assert(m == 6 && v == 18);
[m, v] = chi2stat(4);
assert(m == 4 && v == 8);
% La densite du khi-deux en zero : elle diverge a 1 degre, vaut 1/2 a 2,
% s'annule au-dela.
assert(isinf(chi2pdf(0, 1)));
assert(abs(chi2pdf(0, 2) - 0.5) < 1e-15);
assert(chi2pdf(0, 4) == 0);
assert(chi2pdf(-1, 2) == 0);

% Beta : la loi (1,1) est l'uniforme, la loi (a,a) est symetrique.
assert(abs(betainv(0.5, 1, 1) - 0.5) < 1e-12);
assert(abs(betainv(0.5, 2, 2) - 0.5) < 1e-12);
assert(abs(betainv(0.3, 4, 4) + betainv(0.7, 4, 4) - 1) < 1e-12);
assert(abs(betacdf(betainv(0.3, 2, 5), 2, 5) - 0.3) < 1e-12);
[m, v] = betastat(2, 3);
assert(abs(m - 0.4) < 1e-14 && abs(v - 0.04) < 1e-14);
% n*betaln(a,b) - (a-1) sum log x - (b-1) sum log(1-x).
x = [0.2 0.5 0.7];
attendu = 3*betaln(2,3) - sum(log(x)) - 2*sum(log(1 - x));
assert(abs(betalike([2 3], x) - attendu) < 1e-12);

% Fisher et Student : moments en forme fermee.
[m, v] = fstat(4, 10);
assert(abs(m - 10/8) < 1e-14);
assert(abs(v - 2*100*12/(4*64*6)) < 1e-14);
[m, v] = tstat(5);
assert(m == 0 && abs(v - 5/3) < 1e-14);
assert(isnan(tstat(1)));

% Binomiale : la repartition par la beta incomplete coincide avec la
% somme directe des probabilites.
assert(abs(binocdf(5, 10, 0.5) - 0.623046875) < 1e-14);
assert(abs(binocdf(5, 10, 0.5) - sum(binopdf(0:5, 10, 0.5))) < 1e-14);
assert(binocdf(10, 10, 0.3) == 1);
assert(binoinv(0.5, 10, 0.5) == 5);
assert(binoinv(binocdf(4, 20, 0.3), 20, 0.3) == 4);
[m, v] = binostat(10, 0.5);
assert(m == 5 && v == 2.5);
% Intervalle exact de Clopper-Pearson, valeur documentee par MathWorks.
[phat, pci] = binofit(6, 10);
assert(abs(phat - 0.6) < 1e-14);
assert(abs(pci(1) - 0.2624) < 1e-4 && abs(pci(2) - 0.8784) < 1e-4);

% Poisson.
assert(abs(poisscdf(2, 1) - sum(poisspdf(0:2, 1))) < 1e-14);
assert(abs(poisscdf(2, 1) - 0.9196986029286058) < 1e-12);
assert(poissinv(poisscdf(7, 4), 4) == 7);
[m, v] = poisstat(3);
assert(m == 3 && v == 3);
assert(abs(poissfit([1 2 3 4]) - 2.5) < 1e-14);

% Geometrique : p (1-p)^x, support a partir de zero.
assert(abs(geopdf(2, 0.5) - 0.125) < 1e-15);
assert(abs(geocdf(2, 0.5) - 0.875) < 1e-15);
assert(geoinv(0.875, 0.5) == 2);
[m, v] = geostat(0.25);
assert(m == 3 && v == 12);

% Hypergeometrique : 3 tirages dans 10 objets dont 4 marques.
assert(abs(hygepdf(2, 10, 4, 3) - 0.3) < 1e-12);
assert(abs(sum(hygepdf(0:3, 10, 4, 3)) - 1) < 1e-12);
assert(abs(hygecdf(1, 10, 4, 3) - sum(hygepdf(0:1, 10, 4, 3))) < 1e-14);
[m, v] = hygestat(10, 4, 3);
assert(abs(m - 1.2) < 1e-14 && abs(v - 0.56) < 1e-14);

% Binomiale negative : nbinpdf(2,3,0.5) = C(4,2) 0.5^3 0.5^2 = 6/32.
assert(abs(nbinpdf(2, 3, 0.5) - 0.1875) < 1e-15);
assert(abs(nbincdf(2, 3, 0.5) - sum(nbinpdf(0:2, 3, 0.5))) < 1e-14);
assert(nbininv(nbincdf(5, 3, 0.4), 3, 0.4) == 5);
[m, v] = nbinstat(3, 0.5);
assert(m == 3 && v == 6);

% Log-normale, Rayleigh, Weibull, valeurs extremes.
assert(abs(logninv(0.5, 0, 1) - 1) < 1e-12);
assert(abs(logncdf(logninv(0.7, 1, 0.5), 1, 0.5) - 0.7) < 1e-12);
[m, v] = lognstat(0, 1);
assert(abs(m - exp(0.5)) < 1e-14 && abs(v - exp(1)*(exp(1) - 1)) < 1e-13);
assert(abs(raylinv(0.5, 1) - sqrt(2*log(2))) < 1e-14);
assert(abs(raylcdf(raylinv(0.4, 2), 2) - 0.4) < 1e-14);
[m, v] = raylstat(1);
assert(abs(m - sqrt(pi/2)) < 1e-14 && abs(v - (2 - pi/2)) < 1e-14);
assert(abs(wblinv(1 - exp(-1), 1, 1) - 1) < 1e-14);
assert(abs(wblcdf(wblinv(0.6, 2, 3), 2, 3) - 0.6) < 1e-12);
[m, v] = wblstat(2, 2);
assert(abs(m - 2*gamma(1.5)) < 1e-14);
assert(abs(v - 4*(gamma(2) - gamma(1.5)^2)) < 1e-14);
assert(abs(evpdf(0, 0, 1) - exp(-1)) < 1e-15);
assert(abs(evcdf(0, 0, 1) - (1 - exp(-1))) < 1e-15);
assert(abs(evinv(evcdf(1.3, 2, 0.7), 2, 0.7) - 1.3) < 1e-12);
[m, v] = evstat(0, 1);
assert(abs(m + 0.5772156649015329) < 1e-14 && abs(v - pi^2/6) < 1e-14);

% Acces par nom de loi : les memes valeurs par une autre porte.
assert(abs(pdf('Normal', 0, 0, 1) - normpdf(0, 0, 1)) < 1e-15);
assert(abs(cdf('Poisson', 2, 1) - poisscdf(2, 1)) < 1e-15);
assert(abs(icdf('Normal', 0.975, 0, 1) - 1.959963984540054) < 1e-12);
assert(abs(cdf('chi2', 3.841458820694124, 1) - 0.95) < 1e-12);
assert(icdf('Discrete Uniform', 0.5, 6) == 3);
erreurLoi = false;
try
    pdf('Machin', 1);
catch err
    erreurLoi = strcmp(err.identifier, 'stats:statPrefixeLoi:UnknownDistribution');
end
assert(erreurLoi);

% Regle de taille des arguments : scalaire etendu, tailles incompatibles
% refusees, comme dans MATLAB.
assert(isequal(size(expinv([0.1 0.2; 0.3 0.4], 2)), [2 2]));
assert(isequal(size(binocdf(1, [10 20], 0.5)), [1 2]));
erreurTaille = false;
try
    binocdf([1 2 3], [10 20], 0.5);
catch err
    erreurTaille = strcmp(err.identifier, 'stats:statAjuster:InputSizeMismatch');
end
assert(erreurTaille);

%% ------------------------------------- tirages : moments empiriques
% Les generateurs sont juges sur leurs deux premiers moments, avec une
% tolerance choisie a partir de l'erreur type de la moyenne.
rand('seed', 5);
randn('seed', 5);
n = 40000;
g = gamrnd(3, 2, 1, n);
assert(abs(mean(g) - 6) < 0.1 && abs(var(g) - 12) < 0.5);
gp = gamrnd(0.5, 1, 1, n);            % forme inferieure a 1 : autre branche
assert(abs(mean(gp) - 0.5) < 0.02 && abs(var(gp) - 0.5) < 0.05);
assert(all(gp(:) > 0));
b = betarnd(2, 5, 1, n);
assert(abs(mean(b) - 2/7) < 0.01);
assert(all(b > 0 & b < 1));
c = chi2rnd(4, 1, n);
assert(abs(mean(c) - 4) < 0.1 && abs(var(c) - 8) < 0.5);
t = trnd(10, 1, n);
assert(abs(mean(t)) < 0.05 && abs(var(t) - 1.25) < 0.15);
f = frnd(10, 20, 1, n);
assert(abs(mean(f) - 20/18) < 0.05);
bi = binornd(10, 0.3, 1, n);
assert(abs(mean(bi) - 3) < 0.05 && abs(var(bi) - 2.1) < 0.1);
assert(all(bi >= 0 & bi <= 10) && all(bi == round(bi)));
po = poissrnd(4, 1, n);
assert(abs(mean(po) - 4) < 0.05 && abs(var(po) - 4) < 0.15);
assert(all(po >= 0) && all(po == round(po)));
pg = poissrnd(100, 1, 5000);          % au-dela de 30 : branche par inversion
assert(abs(mean(pg) - 100) < 1.5);
ge = geornd(0.25, 1, n);
assert(abs(mean(ge) - 3) < 0.06);
hy = hygernd(10, 4, 3, 1, n);
assert(abs(mean(hy) - 1.2) < 0.02 && abs(var(hy) - 0.56) < 0.03);
assert(all(hy >= 0 & hy <= 3));
nb = nbinrnd(3, 0.5, 1, n);
assert(abs(mean(nb) - 3) < 0.05 && abs(var(nb) - 6) < 0.3);
ra = raylrnd(2, 1, n);
assert(abs(mean(ra) - 2*sqrt(pi/2)) < 0.03);
wb = wblrnd(2, 3, 1, n);
assert(abs(mean(wb) - 2*gamma(1 + 1/3)) < 0.02);
ev = evrnd(1, 2, 1, n);
assert(abs(mean(ev) - (1 - 2*0.5772156649015329)) < 0.05);
lo = lognrnd(0, 0.5, 1, n);
assert(abs(mean(lo) - exp(0.125)) < 0.02);
% Les generateurs prennent la taille des parametres quand rien n'est dit.
assert(isequal(size(gamrnd(ones(2, 3), 1)), [2 3]));
assert(isequal(size(exprnd(1, [2 3])), [2 3]));
assert(isequal(size(random('Poisson', 4, 1, 5)), [1 5]));

%% --------------------------------- estimation des parametres
% Chaque ajustement retrouve les parametres qui ont servi au tirage.
rand('seed', 9);
randn('seed', 9);
xg = gamrnd(4, 2, 1, 20000);
pg2 = gamfit(xg);
assert(abs(pg2(1) - 4) < 0.2 && abs(pg2(2) - 2) < 0.15);
xb = betarnd(3, 7, 1, 20000);
pb = betafit(xb);
assert(abs(pb(1) - 3) < 0.15 && abs(pb(2) - 7) < 0.4);
xw = wblrnd(2, 3, 1, 20000);
pw = wblfit(xw);
assert(abs(pw(1) - 2) < 0.05 && abs(pw(2) - 3) < 0.1);
xr = raylrnd(2, 1, 20000);
assert(abs(raylfit(xr) - 2) < 0.05);
xl = lognrnd(0, 0.5, 1, 20000);
[ml, sl] = lognfit(xl);
assert(abs(ml) < 0.02 && abs(sl - 0.5) < 0.02);
% Les ajustements refusent les donnees hors du support.
erreurDonnees = false;
try
    wblfit([1 -1 2]);
catch err
    erreurDonnees = strcmp(err.identifier, 'stats:wblfit:BadData');
end
assert(erreurDonnees);

disp('statistiques : toutes les verifications passent');
