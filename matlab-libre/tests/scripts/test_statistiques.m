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
% La structure se lit sous les deux orthographes : le code ecrit pour
% MATLAB demande les noms longs, les solveurs de MatLibre les courts.
assert(o.MaxIterations == 50);
assert(o2.StepTolerance == 1e-3 && o2.MaxIterations == 50);
o3 = optimoptions('fminunc', 'TolFun', 1e-8, 'MaxFunEvals', 300, 'TolCon', 1e-5);
assert(o3.OptimalityTolerance == 1e-8 && o3.TolFun == 1e-8);
assert(o3.MaxFunctionEvaluations == 300 && o3.MaxFunEvals == 300);
assert(o3.ConstraintTolerance == 1e-5 && o3.TolCon == 1e-5);
% Un nom long pose seul remplit aussi le court.
o4 = optimoptions('fmincon', 'StepTolerance', 1e-4);
assert(o4.TolX == 1e-4);

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

%% ------------------------------- optimisation directe et globale
% patternsearch trouve le minimum d'une quadratique exactement, et
% traverse aussi les fonctions non derivables.
[xPattern, vPattern, ~, sortiePattern] = patternsearch(@(p) (p(1)-1)^2 + (p(2)+2)^2, [0 0]);
assert(max(abs(xPattern - [1 -2])) < 1e-6);
assert(vPattern < 1e-12);
assert(sortiePattern.funccount > 0);
assert(max(abs(patternsearch(@(p) abs(p(1)-3) + abs(p(2)+1), [0 0]) - [3 -1])) < 1e-6);
% Bornes et contraintes lineaires sont respectees.
assert(abs(patternsearch(@(p) (p(1)-5)^2, 0, [], [], [], [], 0, 2) - 2) < 1e-9);
xContraint = patternsearch(@(p) -(p(1)+p(2)), [0 0], [1 1], 1, [], [], [0 0], [1 1]);
assert(abs(sum(xContraint) - 1) < 1e-6);
assert(all(xContraint >= -1e-9));

% Departs multiples : la ou un solveur local reste dans le premier creux
% venu, ils trouvent le bon. La fonction x^4-3x^2+x a son minimum global
% en x = -1.3 et un creux local en x = 1.13 ; partir de 2 y mene tout
% droit.
rng(3);
fonctionDeuxCreux = @(v) v ^ 4 - 3 * v ^ 2 + v;
problemeGlobal = createOptimProblem('fminunc', 'objective', fonctionDeuxCreux, ...
                                    'x0', 2, 'lb', -3, 'ub', 3);
assert(abs(fminunc(fonctionDeuxCreux, 2) - 1.13) < 0.05);
[xDeparts, valeurDeparts] = run(MultiStart('Display', 'off'), problemeGlobal, 20);
assert(abs(xDeparts + 1.3) < 0.1);
assert(valeurDeparts < fonctionDeuxCreux(1.13));
[xRecherche, valeurRecherche] = run(GlobalSearch('Display', 'off'), problemeGlobal);
assert(abs(xRecherche + 1.3) < 0.1);
assert(abs(valeurRecherche - valeurDeparts) < 1e-4);
% createOptimProblem refuse un solveur ou une option qu'il ne connait
% pas, et exige une fonction objectif.
for essaiProbleme = {@() createOptimProblem('toto', 'objective', @(x) x), ...
                     @() createOptimProblem('fmincon', 'toto', 1), ...
                     @() createOptimProblem('fmincon', 'x0', 1)}
    refuseProbleme = false;
    try
        essaiProbleme{1}();
    catch
        refuseProbleme = true;
    end
    assert(refuseProbleme);
end

% Les trois structures d'options : chaque champ se pose, une structure
% existante se complete, et une faute de frappe est refusee.
assert(gaoptimset().PopulationSize == 50 && gaoptimset().Generations == 100);
optionsGenetique = gaoptimset('PopulationSize', 200, 'Generations', 300);
assert(optionsGenetique.PopulationSize == 200);
assert(gaoptimset(optionsGenetique, 'EliteCount', 5).PopulationSize == 200);
assert(gaoptimset(optionsGenetique, 'EliteCount', 5).EliteCount == 5);
assert(psoptimset('MaxIter', 500).MaxIter == 500);
assert(psoptimset('MeshTolerance', 1e-9).MeshTolerance == 1e-9);
assert(saoptimset('InitialTemperature', 50).InitialTemperature == 50);
assert(saoptimset('InitialTemperature', 50).MaxIter == 1000);
for essaiOption = {@() gaoptimset('Toto', 1), @() psoptimset('Toto', 1), ...
                   @() saoptimset('Toto', 1)}
    refuseOption = false;
    try
        essaiOption{1}();
    catch
        refuseOption = true;
    end
    assert(refuseOption);
end
% Le solveur accepte la structure d'options.
assert(norm(ga(@(v) sum(v .^ 2), 2, [-5 -5], [5 5], ...
               gaoptimset('PopulationSize', 40, 'Generations', 60))) < 0.5);

% Front de Pareto de [x^2, (x-2)^2] : les solutions sont x dans [0,2].
rand('seed', 3);
deuxObjectifs = @(x) [x(1)^2, (x(1)-2)^2];
optionsPareto = struct('PopulationSize', 40, 'MaxGenerations', 30);
[xPareto, vPareto] = gamultiobj(deuxObjectifs, 1, [], [], [], [], -2, 4, optionsPareto);
assert(size(xPareto, 1) > 5);
assert(all(xPareto >= -0.05 & xPareto <= 2.05));
assert(min(xPareto) < 0.2 && max(xPareto) > 1.8);
% Par construction, aucun point du front n'en domine un autre.
for i = 1:size(vPareto, 1)
    for j = 1:size(vPareto, 1)
        if i ~= j
            assert(~(all(vPareto(j, :) <= vPareto(i, :)) && any(vPareto(j, :) < vPareto(i, :))));
        end
    end
end
optionsRecherche = struct('ParetoSetSize', 20, 'MaxIterations', 25);
[xRecherche, vRecherche] = paretosearch(deuxObjectifs, 1, [], [], [], [], -2, 4, [], optionsRecherche);
assert(size(xRecherche, 1) > 5);
assert(min(xRecherche) < 0.2 && max(xRecherche) > 1.8);
assert(size(vRecherche, 2) == 2);

% surrogateopt sur une fonction lisse : il approche le minimum en cent
% evaluations, sans jamais deriver.
rand('seed', 7);
[xSubstitut, vSubstitut, ~, sortieSubstitut] = ...
    surrogateopt(@(p) (p(1)-0.3)^2 + (p(2)+0.7)^2, [-1 -1], [1 1]);
assert(max(abs(xSubstitut - [0.3 -0.7])) < 0.05);
assert(vSubstitut < 5e-3);
assert(sortieSubstitut.funccount <= 100);

% fgoalattain : les deux objectifs valent 1 en x = 1, donc gamma = 0.
[xBut, vBut, gamma] = fgoalattain(deuxObjectifs, 0, [1 1], [1 1]);
assert(abs(xBut - 1) < 1e-3);
assert(max(abs(vBut - [1 1])) < 1e-3);
assert(abs(gamma) < 1e-3);
assert(all(vBut - gamma <= [1 1] + 1e-4));

% fseminf : minimiser x^2 sous x >= t + 0.2 pour tout t de [0,1] donne
% x = 1.2, la contrainte la plus serree etant celle de t = 1.
contrainteSemi = @(x, pas) deal([], [], -(x(1) - (0:pas:1)' - 0.2), pas);
[xSemi, vSemi, pireSemi] = fseminf(@(x) x(1)^2, 3, 1, contrainteSemi);
assert(abs(xSemi - 1.2) < 1e-3);
assert(abs(vSemi - 1.44) < 1e-2);
assert(pireSemi < 1e-6);

% ---------------------------------------------------------------- omitnan
% Un seul NaN rendait toute la colonne NaN : « omitnan » l'ecarte, comme
% depuis R2015a. Les fonctions nan* de la boite a outils s'y ramenent.
assert(abs(mean([1 2 NaN 4], 'omitnan') - 7/3) < 1e-12);
assert(isnan(mean([1 2 NaN 4])));
assert(isequal(mean([1 NaN; 3 4], 'omitnan'), [2 4]));
assert(isequal(mean([1 NaN; 3 4], 2, 'omitnan'), [1; 3.5]));
assert(abs(std([1 2 NaN 3], 'omitnan') - 1) < 1e-12);
assert(abs(var([1 2 NaN 3], 1, 'omitnan') - 2/3) < 1e-12);
assert(median([1 NaN 3 100], 'omitnan') == 3);
assert(isequal(cumsum([1 NaN 3], 'omitnan'), [1 1 4]));
assert(isequal(sum([1 NaN 3], 'omitnan'), 4));

assert(abs(nanmean([1 2 NaN 4]) - 7/3) < 1e-12);
assert(nansum([NaN NaN]) == 0);          % la somme d'aucun terme vaut zero
assert(isnan(nanmean([NaN NaN])));       % la moyenne d'aucun terme, non
assert(nanmedian([1 NaN 3 100]) == 3);
assert(abs(nanstd([1 2 NaN 3]) - 1) < 1e-12);
assert(abs(nanvar([1 2 NaN 3], 1) - 2/3) < 1e-12);
[maxNaN, ouMax] = nanmax([1 NaN 5 2]);
assert(maxNaN == 5 && ouMax == 3);
[minNaN, ouMin] = nanmin([3 NaN 1 2]);
assert(minNaN == 1 && ouMin == 3);
covComplet = nancov([1 2; 3 5; NaN 9; 4 8]);
assert(max(max(abs(covComplet - cov([1 2; 3 5; 4 8])))) < 1e-12);
covPaires = nancov([1 2; 3 5; NaN 9; 4 8], 'pairwise');
assert(abs(covPaires(2, 2) - var([2 5 9 8])) < 1e-12);
assert(abs(covPaires(1, 1) - var([1 3 4])) < 1e-12);

% ------------------------------------------------------- moyennes et rangs
assert(abs(geomean([1 4 16]) - 4) < 1e-12);
assert(abs(geomean([1.10 0.90]) - sqrt(0.99)) < 1e-12);
assert(max(abs(geomean([1 2; 3 4]) - [sqrt(3) sqrt(8)])) < 1e-12);
assert(abs(harmmean([30 60]) - 40) < 1e-12);
assert(abs(harmmean([1 2 4]) - 12/7) < 1e-12);
assert(harmmean([0 1 2]) == 0);
% La moyenne elaguee ignore la valeur aberrante que la moyenne subit.
assert(abs(trimmean([1 2 3 4 5 6 7 8 9 1000], 20) - 5.5) < 1e-12);
assert(abs(trimmean(1:10, 0) - 5.5) < 1e-12);
assert(isequal(tiedrank([10 20 20 40]), [1 2.5 2.5 4]));
assert(isequal(tiedrank([3 1 2]), [3 1 2]));
[rangsLies, correction] = tiedrank([1 1 1]);
assert(isequal(rangsLies, [2 2 2]) && correction == 12);
assert(isnan(tiedrank([1 NaN 2])) * [0;1;0] == 1);

% corr : Pearson comme corrcoef, Spearman insensible a la courbure.
xCorr = (1:10)';
assert(abs(corr(xCorr, xCorr .^ 3, 'type', 'Spearman') - 1) < 1e-12);
assert(abs(corr(xCorr, xCorr .^ 3, 'type', 'Kendall') - 1) < 1e-12);
matriceCorr = [1 2; 3 5; 4 9; 2 3];
assert(max(max(abs(corr(matriceCorr) - corrcoef(matriceCorr)))) < 1e-12);
assert(isequal(size(corr(randn(20, 3), randn(20, 2))), [3 2]));
[rhoCorr, pCorr] = corr(xCorr, [1 3 2 5 4 7 6 9 8 10]');
assert(rhoCorr > 0.9 && pCorr < 0.001);

% ---------------------------------------------------------- groupes
[indicesGroupe, nomsGroupe] = grp2idx({'b', 'a', 'b'});
assert(isequal(indicesGroupe, [2; 1; 2]));
assert(isequal(nomsGroupe, {'a'; 'b'}));
[indicesNombres, nomsNombres] = grp2idx([10 20 10 30]);
assert(isequal(indicesNombres, [1; 2; 1; 3]));
assert(strcmp(nomsNombres{3}, '30'));
[moyennesGroupe, ecartsGroupe, effectifsGroupe] = ...
    grpstats([1 2 3 10 11 12]', {'a','a','a','b','b','b'});
assert(isequal(moyennesGroupe, [2; 11]));
assert(max(abs(ecartsGroupe - [1; 1])) < 1e-12);
assert(isequal(effectifsGroupe, [3; 3]));

% ecdf : l'escalier part de zero a la plus petite observation.
[hauteurs, abscisses] = ecdf([3 1 4 1 5]);
assert(hauteurs(1) == 0 && abscisses(1) == 1);
assert(abs(hauteurs(2) - 0.4) < 1e-12);
assert(abs(hauteurs(end) - 1) < 1e-12);
assert(abscisses(end) == 5);

% ---------------------------------------------------------- distances
nuage = [0 0; 3 4; 0 4];
assert(isequal(pdist(nuage), [5 4 3]));
assert(isequal(pdist(nuage, 'cityblock'), [7 4 3]));
assert(isequal(pdist(nuage, 'chebychev'), [4 4 3]));
assert(abs(pdist([1 0; 0 1], 'cosine') - 1) < 1e-12);
carree = squareform(pdist(nuage));
assert(isequal(carree, [0 5 4; 5 0 3; 4 3 0]));
assert(isequal(squareform(carree), [5 4 3]));
assert(isequal(pdist([1 1 0; 1 0 1], 'hamming'), 2/3));
assert(abs(pdist([1 1 0; 1 0 1], 'jaccard') - 2/3) < 1e-12);
distances2 = pdist2(nuage, [0 0; 1 1]);
assert(isequal(size(distances2), [3 2]));
assert(distances2(1, 1) == 0);
[proches, ouProches] = pdist2([0 0; 3 4; 1 1], [0 0; 1 1], 'euclidean', 'Smallest', 1);
assert(max(abs(proches)) < 1e-12);
assert(isequal(ouProches, [1 3]));

% mahal : la distance tient compte de la forme du nuage.
rand('seed', 3);
randn('seed', 3);
nuageCorrele = randn(400, 2);
assert(mahal([0 0], nuageCorrele) < 0.2);
assert(mahal([4 4], nuageCorrele) > 10);

% ------------------------------------------------- regroupement hierarchique
donneesGrappes = [1 1; 1.2 1; 5 5; 5.1 5.2];
arbre = linkage(donneesGrappes);
assert(isequal(size(arbre), [3 3]));
assert(abs(arbre(1, 3) - 0.2) < 1e-12);
assert(abs(arbre(3, 3) - sqrt(3.8^2 + 4^2)) < 1e-12);   % plus proche voisin
arbreComplet = linkage(donneesGrappes, 'complete');
assert(abs(arbreComplet(3, 3) - sqrt(4.1^2 + 4.2^2)) < 1e-12);
% Ward : la distance vaut racine(2*n1*n2/(n1+n2)) fois l'ecart des centres.
arbreWard = linkage(donneesGrappes, 'ward');
ecartCentres = norm([1.1 1] - [5.05 5.1]);
assert(abs(arbreWard(3, 3) - sqrt(2) * ecartCentres) < 1e-10);
assert(isequal(cluster(arbre, 'maxclust', 2), [1; 1; 2; 2]));
assert(isequal(cluster(arbre, 'cutoff', 1), [1; 1; 2; 2]));
assert(isequal(clusterdata(donneesGrappes, 2), [1; 1; 2; 2]));
assert(cophenet(linkage(donneesGrappes, 'average'), pdist(donneesGrappes)) > 0.99);
[traitsArbre, feuilleDe, ordreFeuilles] = dendrogram(linkage(donneesGrappes, 'average'));
assert(numel(traitsArbre) == 3);
assert(isequal(sort(ordreFeuilles), 1:4));
assert(isequal(sort(feuilleDe'), 1:4));
close('all');

% ----------------------------------------------------- normale multivariee
assert(abs(mvnpdf([0 0]) - 1 / (2 * pi)) < 1e-12);
assert(abs(mvnpdf([0 0], [0 0], eye(2)) - 1 / (2 * pi)) < 1e-12);
% (2*pi)^-1 * det^-0.5 * exp(-d/2), calcule a la main
assert(abs(mvnpdf([1 1], [0 0], [2 1; 1 2]) - ...
           exp(-1/3) / (2 * pi * sqrt(3))) < 1e-12);
randn('seed', 11);
tiragesNormale = mvnrnd([0 0], [1 0.8; 0.8 1], 20000);
assert(max(max(abs(cov(tiragesNormale) - [1 0.8; 0.8 1]))) < 0.05);
assert(max(abs(mean(tiragesNormale))) < 0.05);
assert(abs(mvncdf([0 0]) - 0.25) < 1e-9);        % par symetrie
assert(abs(mvncdf([0 0], [0 0], [1 0.5; 0.5 1]) - 1/3) < 1e-6);
assert(abs(mvncdf(0) - 0.5) < 1e-12);
assert(abs(mvncdf([Inf Inf]) - 1) < 1e-12);
% Gauss-Legendre : les cinq noeuds de la table.
[noeudsGL, poidsGL] = matlibre_gauss_legendre(5);
assert(abs(noeudsGL(1) - 0.9061798459386640) < 1e-13);
assert(abs(poidsGL(3) - 0.5688888888888889) < 1e-13);
assert(abs(sum(poidsGL) - 2) < 1e-13);

% --------------------------------------------------- analyse de la variance
% Deux groupes bien separes : F = 37.5 a la main.
[pAnova, tableauAnova] = anova1([5 6 7 10 11 12], [1 1 1 2 2 2]);
assert(abs(tableauAnova.SSB - 37.5) < 1e-12);
assert(abs(tableauAnova.SSW - 4) < 1e-12);
assert(abs(tableauAnova.F - 37.5) < 1e-12);
assert(abs(pAnova - (1 - fcdf(37.5, 1, 4))) < 1e-12);
% La forme matricielle : une colonne par groupe.
[pColonnes, tableauColonnes] = anova1([1 2; 2 3; 3 4]);
assert(abs(tableauColonnes.F - 1.5) < 1e-12);
assert(abs(pColonnes - (1 - fcdf(1.5, 1, 4))) < 1e-12);
% anova2 sans repetition : SSE = SST - SSC - SSR.
[pDeux, tableauDeux] = anova2([12 15 20; 13 16 22]);
assert(numel(pDeux) == 2);
assert(abs(tableauDeux.SSE - (tableauDeux.SST - tableauDeux.SSC - tableauDeux.SSR)) < 1e-10);
assert(pDeux(1) < 0.01);
% anova2 avec repetitions : trois probabilites, dont l'interaction.
pInteraction = anova2([10 12; 11 13; 20 25; 21 24], 2);
assert(numel(pInteraction) == 3);
assert(pInteraction(2) < 0.001);
% Kruskal-Wallis : trois contre trois entierement separes donnent 0.0495,
% le plus petit que ce plan permette.
assert(abs(kruskalwallis([1 2 3 100 101 102], [1 1 1 2 2 2]) - ...
           (1 - chi2cdf(12/42 * 13.5, 1))) < 1e-12);
% Friedman : quatre juges, trois vins, classement identique a chaque fois.
assert(abs(friedman([3 5 8; 2 6 9; 4 5 7; 3 6 8]) - (1 - chi2cdf(8, 2))) < 1e-10);

% La plage studentisee, comparee a la table de Tukey.
assert(abs(matlibre_plage_studentisee(0.95, 3, 10) - 3.88) < 0.01);
assert(abs(matlibre_plage_studentisee(0.95, 2, 10) - 3.15) < 0.01);
assert(abs(matlibre_plage_studentisee(0.95, 5, Inf) - 3.86) < 0.01);
[~, ~, statsAnova] = anova1([5 6 7 10 11 12 5.5 6.5 7.5], [1 1 1 2 2 2 3 3 3]);
comparaisons = multcompare(statsAnova);
assert(isequal(size(comparaisons), [3 6]));
assert(comparaisons(1, 6) < 0.05);      % groupes 1 et 2
assert(comparaisons(2, 6) > 0.5);       % groupes 1 et 3 : semblables
assert(comparaisons(3, 6) < 0.05);      % groupes 2 et 3
% L'intervalle de Bonferroni est plus large que celui de Tukey.
comparaisonsBonferroni = multcompare(statsAnova, 'ctype', 'bonferroni');
assert(comparaisonsBonferroni(1, 3) < comparaisons(1, 3));
close('all');

% ------------------------------------------------------------------- tests
assert(abs(signtest([-2 -1 1 2]) - 1) < 1e-12);
assert(abs(signtest([1 2 3 4 5 6 7 8]) - 2 * binocdf(0, 8, 0.5)) < 1e-12);
assert(signtest([10 11 12], 11) == 1);
[hZ, pZ, ciZ, zZ] = ztest([102 100 104 99 101], 100, 2);
assert(hZ == 0);
assert(abs(zZ - (mean([102 100 104 99 101]) - 100) / (2 / sqrt(5))) < 1e-12);
assert(ciZ(1) < 100 && ciZ(2) > 100);
% vartest sur des donnees dont la variance est connue exactement.
donneesVariance = [1 2 3 4 5];        % variance 2.5
[hVar, pVar, ciVar, statsVar] = vartest(donneesVariance, 2.5);
assert(hVar == 0 && pVar > 0.8);
assert(abs(statsVar.chisqstat - 4) < 1e-12);
assert(ciVar(1) < 2.5 && ciVar(2) > 2.5);
assert(vartest(donneesVariance, 0.01) == 1);
[hVar2, pVar2, ciVar2, statsVar2] = vartest2([1 2 3 4 5], [1 2 3 4 5]);
assert(hVar2 == 0 && abs(pVar2 - 1) < 1e-12);
assert(abs(statsVar2.fstat - 1) < 1e-12);
assert(ciVar2(1) < 1 && ciVar2(2) > 1);
randn('seed', 5);
assert(vartest2(randn(80, 1), randn(80, 1) * 4) == 1);

% Kolmogorov-Smirnov a deux echantillons.
[hKS, pKS, dKS] = kstest2([1 2 3 4 5], [11 12 13 14 15]);
assert(hKS == 1 && dKS == 1);
assert(kstest2([1 2 3 4 5], [1 2 3 4 5]) == 0);
assert(abs(matlibre_kolmogorov_queue(0) - 1) < 1e-12);
assert(matlibre_kolmogorov_queue(3) < 1e-7);

% Jarque-Bera : la loi exponentielle est trop dissymetrique pour passer.
randn('seed', 13);
rand('seed', 13);
assert(jbtest(randn(3000, 1)) == 0);
assert(jbtest(exprnd(1, 400, 1)) == 1);
[~, ~, statistiqueJB] = jbtest([1 2 3 4 5 6 7 8]);
assert(statistiqueJB >= 0);

% Lilliefors : la valeur critique retrouve la table, 0.886/racine(n).
[hLil, ~, ~, critiqueLil] = lillietest(randn(200, 1));
assert(hLil == 0);
assert(abs(critiqueLil - 0.886 / sqrt(200)) < 0.005);
assert(lillietest(exprnd(1, 200, 1)) == 1);

% Le test des suites : l'alternance parfaite et la montee parfaite sont
% toutes deux rejetees, le bruit ne l'est pas.
[hSuites, pSuites, statsSuites] = runstest(repmat([1 -1], 1, 20));
assert(hSuites == 1 && statsSuites.nruns == 40);
assert(runstest(1:40) == 1);
assert(runstest(randn(200, 1)) == 0);
[~, pExact] = runstest(1:8, [], 'Method', 'exact');
assert(pExact > 0.05 && pExact < 0.1);

% Khi-deux d'adequation : le de a six faces bien equilibre.
rand('seed', 21);
[hDe, pDe, statsDe] = chi2gof(randi(6, 600, 1), 'Edges', 0.5:1:6.5, ...
                              'Expected', repmat(100, 1, 6));
assert(hDe == 0 && statsDe.df == 5);
assert(abs(statsDe.chi2stat - sum((statsDe.O - 100) .^ 2) / 100) < 1e-12);
assert(chi2gof(exprnd(1, 500, 1)) == 1);
assert(chi2gof(exprnd(2, 500, 1), 'CDF', @(t) expcdf(t, 2)) == 0);

% Les boites a moustaches : elles tracent sans rien casser.
figure('Visible', 'off');
boxplot([1 2 3 3 4 20 10 11 12 13], [1 1 1 1 1 1 2 2 2 2]);
boxplot(randn(30, 3), 'Labels', {'a', 'b', 'c'});
boxplot(randn(30, 2), 'Notch', 'on', 'Orientation', 'horizontal');
close('all');

% ------------------------------------------- poignees de courbes graphiques
% « h = plot(...) » rend une poignee, comme dans MATLAB : c'est ce qui
% manquait a set(h,...) et aux animations.
figure('Visible', 'off');
poigneeCourbe = plot([1 2 3], [4 5 6]);
assert(strcmp(class(poigneeCourbe), 'matlab.graphics.chart.primitive.Line'));
assert(strcmp(get(poigneeCourbe, 'Type'), 'line'));
assert(isequal(get(poigneeCourbe, 'XData'), [1 2 3]));
set(poigneeCourbe, 'LineWidth', 3, 'Color', 'r');
assert(get(poigneeCourbe, 'LineWidth') == 3);
assert(strcmp(get(poigneeCourbe, 'Color'), '#D95319'));
poigneeCourbe.LineStyle = '--';
assert(strcmp(poigneeCourbe.LineStyle, '--'));
poigneeCourbe.YData = [9 8 7];
assert(isequal(get(poigneeCourbe, 'YData'), [9 8 7]));
% Une courbe par colonne : un tableau de poignees, et la palette part
% bien de la premiere couleur.
poigneesMultiples = plot((1:3)', [1 2; 3 4; 5 6]);
assert(numel(poigneesMultiples) == 2);
assert(strcmp(get(poigneesMultiples(1), 'Color'), '#0072BD'));
assert(strcmp(get(poigneesMultiples(2), 'Color'), '#D95319'));
assert(isequal(get(poigneesMultiples(2), 'YData'), [2 4 6]));
set(poigneesMultiples, 'LineWidth', 2);
assert(get(poigneesMultiples(1), 'LineWidth') == 2);
% Le triplet de couleurs, et « Color » qui n'est plus pris pour un style.
poigneeTriplet = plot([1 2], [1 2], 'Color', [0.85 0.55 0]);
assert(strcmp(get(poigneeTriplet, 'Color'), '#D98C00'));
assert(isempty(get(poigneeTriplet, 'Marker')) || ...
       strcmp(get(poigneeTriplet, 'Marker'), 'none'));
close('all');

% [R,p] = chol(A) : une matrice non definie positive ne leve plus d'erreur.
[facteur, defaut] = chol([4 2; 2 3]);
assert(defaut == 0);
assert(max(max(abs(facteur' * facteur - [4 2; 2 3]))) < 1e-12);
[facteurPartiel, defautPartiel] = chol([1 2; 2 1]);
assert(defautPartiel == 2);
assert(isequal(size(facteurPartiel), [1 1]));

%% --------------------------------------------- fonctions glissantes
% La famille « mov… » : meme fenetre, meme traitement des bords, seul
% l'agregat change. Les valeurs sont celles de la documentation MATLAB.
serieGlissante = [4 8 6 -1 -2 -3 -1 3 4 5];
assert(norm(movmean(serieGlissante, 3) - ...
            [6 6 4+1/3 1 -2 -2 -1/3 2 4 4.5]) < 1e-12);
assert(isequal(movsum(serieGlissante, 3), [12 18 13 3 -6 -6 -1 6 12 9]));
assert(isequal(movmax(serieGlissante, 3), [8 8 8 6 -1 -1 3 4 5 5]));
assert(isequal(movmin(serieGlissante, 3), [4 4 -1 -2 -3 -3 -3 -1 3 4]));
assert(isequal(movprod([1 2 3 4], 2), [1 2 6 12]));
assert(isequal(movmedian([1 2 100 4 5], 3), [1.5 2 4 5 4.5]));

% Une fenetre paire penche du cote du passe : deux points avant, un
% apres, comme dans MATLAB.
assert(isequal(movsum(serieGlissante, 4), [12 18 17 11 0 -7 -3 3 11 12]));

% Les bords : 'discard' ne rend que les fenetres pleines, une valeur
% complete le tableau.
assert(numel(movmean(serieGlissante, 3, 'Endpoints', 'discard')) == 8);
assert(isequal(movsum(ones(1, 5), 3, 'Endpoints', 0), [2 3 3 3 2]));

% Un NaN contamine sa fenetre, sauf si on l'ecarte.
assert(all(isnan(movmean([1 NaN 3], 3))));
assert(isequal(movmean([1 NaN 3], 3, 'omitnan'), [1 2 3]));

% Sur une matrice, la fenetre glisse le long des colonnes, ou de la
% dimension demandee.
matriceGlissante = [1 2; 3 4; 5 6];
assert(isequal(movsum(matriceGlissante, 2), [1 2; 4 6; 8 10]));
assert(isequal(movsum(matriceGlissante, 2, 2), [1 3; 3 7; 5 11]));

% L'ecart type glissant : nul sur une fenetre d'un seul point.
assert(abs(movstd([1 2 3 4], 2) * [1; 0; 0; 0]) < 1e-12);
assert(abs(movvar([1 2 3 4], 2) * [0; 1; 0; 0] - 0.5) < 1e-12);

%% ------------------------------------------- modèles de Markov cachés
rng(7);
transitionsVraies = [0.9 0.1; 0.05 0.95];
emissionsVraies = [repmat(1/6, 1, 6); 0.5 0.1 0.1 0.1 0.1 0.1];
[suite, etatsVrais] = hmmgenerate(2000, transitionsVraies, emissionsVraies);
assert(numel(suite) == 2000 && min(suite) >= 1 && max(suite) <= 6);
% Les probabilités a posteriori d'un instant somment à un : c'est ce qui
% distingue un avant-arrière juste d'un avant-arrière mal normalisé.
posterieures = hmmdecode(suite(1:60), transitionsVraies, emissionsVraies);
assert(max(abs(sum(posterieures, 1) - 1)) < 1e-12);
[~, logVraisemblance] = hmmdecode(suite(1:60), transitionsVraies, emissionsVraies);
assert(logVraisemblance < 0 && isfinite(logVraisemblance));
% Viterbi retrouve la plupart des états cachés, et hmmestimate les
% matrices quand on les lui donne.
etatsEstimes = hmmviterbi(suite, transitionsVraies, emissionsVraies);
assert(mean(etatsEstimes == etatsVrais) > 0.7);
[transitionsEstimees, emissionsEstimees] = hmmestimate(suite, etatsVrais);
assert(max(abs(transitionsEstimees(:) - transitionsVraies(:))) < 0.05);
assert(max(abs(emissionsEstimees(:) - emissionsVraies(:))) < 0.05);
% Baum-Welch fait croître la vraisemblance à chaque tour : c'est la
% propriété qui définit l'algorithme.
[~, ~, courbe] = hmmtrain(suite(1:800), [0.8 0.2; 0.2 0.8], ...
                          [repmat(1/6, 1, 6); 0.4 0.12 0.12 0.12 0.12 0.12], ...
                          'Maxiterations', 30);
assert(all(diff(courbe) > -1e-9));

%% ---------------------------------------- factorisation non négative
rng(3);
matricePositive = rand(20, 3) * rand(3, 10);
[W, H, D] = nnmf(matricePositive, 3, 'Replicates', 3, 'MaxIter', 500);
assert(all(W(:) >= 0) && all(H(:) >= 0));
assert(D < 0.05);
% Les colonnes de W sortent normées, comme dans MATLAB.
assert(max(abs(sqrt(sum(W .^ 2, 1)) - 1)) < 1e-12);

%% ------------------------------------------------- régression pénalisée
rng(1);
Xlasso = randn(100, 10);
yLasso = Xlasso(:, 1) * 3 - Xlasso(:, 2) * 2 + 0.1 * randn(100, 1);
Blasso = lasso(Xlasso, yLasso, 'Lambda', 0.1);
% Le lasso met à zéro ce qui ne sert pas, et rétrécit le reste.
assert(nnz(Blasso) == 2);
assert(abs(Blasso(1)) < 3 && abs(Blasso(1)) > 2.5);
% À pénalité nulle, il retrouve les moindres carrés.
BsansPenalite = lasso(Xlasso, yLasso, 'Lambda', 1e-8);
moindresCarres = [ones(100, 1), Xlasso] \ yLasso;
assert(max(abs(BsansPenalite - moindresCarres(2:end))) < 1e-3);
% Le chemin par défaut part de tout à zéro.
[cheminLasso, infoLasso] = lasso(Xlasso, yLasso);
assert(nnz(cheminLasso(:, 1)) == 0 && infoLasso.DF(1) == 0);

%% --------------------------------------------- modèles linéaires généralisés
rng(1);
Xglm = randn(300, 1);
probabilites = 1 ./ (1 + exp(-(0.5 + 2 * Xglm)));
yBinaire = double(rand(300, 1) < probabilites);
modeleLogit = fitglm(Xglm, yBinaire, 'Distribution', 'binomial');
assert(abs(modeleLogit.Coefficients(1) - 0.5) < 3 * modeleLogit.SE(1));
assert(abs(modeleLogit.Coefficients(2) - 2) < 3 * modeleLogit.SE(2));
% Avec la loi normale et le lien identité, c'est exactement fitlm.
Xnormal = randn(200, 2);
yNormal = 1 + 2 * Xnormal(:, 1) - Xnormal(:, 2) + 0.1 * randn(200, 1);
assert(max(abs(fitglm(Xnormal, yNormal).Coefficients - ...
              fitlm(Xnormal, yNormal).Coefficients)) < 1e-10);
% Poisson : le lien logarithmique retrouve les coefficients.
yComptes = poissrnd(exp(0.5 + Xglm(1:200)));
modelePoisson = fitglm(Xglm(1:200), yComptes, 'Distribution', 'poisson');
assert(abs(modelePoisson.Coefficients(2) - 1) < 0.2);

%% ------------------------------------------ logistique multinomiale
rng(1);
Xmnr = randn(400, 2);
scoresVrais = [Xmnr * [2; -1], Xmnr * [-1; 2], zeros(400, 1)];
[~, categories] = max(scoresVrais + 0.5 * randn(400, 3), [], 2);
[Bmnr, deviance] = mnrfit(Xmnr, categories);
assert(isequal(size(Bmnr), [3 2]));
probabilitesMnr = mnrval(Bmnr, Xmnr);
assert(max(abs(sum(probabilitesMnr, 2) - 1)) < 1e-12);
[~, categoriesPredites] = max(probabilitesMnr, [], 2);
assert(mean(categoriesPredites == categories) > 0.8);
assert(deviance > 0);

%% ------------------------------------------------- classifieurs
rng(1);
Xdeux = [randn(50, 2); randn(50, 2) + 3];
yDeux = [ones(50, 1); 2 * ones(50, 1)];
% Bayésien naïf : les scores sont des probabilités a posteriori.
modeleBayes = fitcnb(Xdeux, yDeux);
[etiquettes, scoresBayes] = predict(modeleBayes, Xdeux);
assert(mean(etiquettes == yDeux) > 0.95);
assert(max(abs(sum(scoresBayes, 2) - 1)) < 1e-12);
assert(mean(predict(fitcnb(Xdeux, yDeux, 'DistributionNames', 'kernel'), Xdeux) == yDeux) > 0.95);

% Vecteurs de support : le noyau gaussien sépare ce que le linéaire ne
% peut pas — deux cercles concentriques.
ySigne = [-ones(50, 1); ones(50, 1)];
modeleSvm = fitcsvm(Xdeux, ySigne);
assert(mean(predict(modeleSvm, Xdeux) == ySigne) > 0.95);
assert(size(modeleSvm.SupportVectors, 1) < 50);
angles = linspace(0, 2*pi, 80)';
cercles = [cos(angles) sin(angles); 2.5*cos(angles) 2.5*sin(angles)] + 0.15 * randn(160, 2);
yCercles = [ones(80, 1); -ones(80, 1)];
assert(mean(predict(fitcsvm(cercles, yCercles), cercles) == yCercles) < 0.8);
modeleRbf = fitcsvm(cercles, yCercles, 'KernelFunction', 'rbf', ...
                    'KernelScale', 1, 'BoxConstraint', 10);
assert(mean(predict(modeleRbf, cercles) == yCercles) > 0.98);
% Le modèle allégé prédit la même chose sans ses points.
modeleAllege = discardSupportVectors(modeleSvm);
assert(isempty(modeleAllege.SupportVectors));
assert(isequal(predict(modeleAllege, Xdeux), predict(modeleSvm, Xdeux)));
refuseAllegement = false;
try
    discardSupportVectors(modeleRbf);
catch
    refuseAllegement = true;
end
assert(refuseAllegement);

% Codes correcteurs : trois classes, quatre apprenants différents.
Xtrois = [randn(40, 2); randn(40, 2) + 4; randn(40, 2) + [0 5]];
yTrois = [ones(40, 1); 2 * ones(40, 1); 3 * ones(40, 1)];
assert(mean(predict(fitcecoc(Xtrois, yTrois), Xtrois) == yTrois) > 0.9);
assert(mean(predict(fitcecoc(Xtrois, yTrois, 'Coding', 'onevsall'), Xtrois) == yTrois) > 0.85);
assert(mean(predict(fitcecoc(Xtrois, yTrois, 'Learners', 'tree'), Xtrois) == yTrois) > 0.95);

%% --------------------------------------------------- régressions
rng(1);
Xsvr = linspace(-3, 3, 60)';
ySvr = sin(Xsvr) + 0.05 * randn(60, 1);
modeleSvr = fitrsvm(Xsvr, ySvr, 'KernelFunction', 'rbf', 'KernelScale', 1);
assert(sqrt(mean((predict(modeleSvr, Xsvr) - ySvr) .^ 2)) < 0.1);
% L'arbre de régression suit une fonction non linéaire.
Xarbre = rand(200, 1) * 10;
yArbre = sin(Xarbre) + 0.1 * randn(200, 1);
assert(mean((predict(fitrtree(Xarbre, yArbre, 'MinLeafSize', 5) , Xarbre) - yArbre) .^ 2) < 0.05);
% Un modèle linéaire de grande dimension.
Xgrand = randn(200, 10);
yGrand = Xgrand * (1:10)' + randn(200, 1);
modeleLineaire = fitrlinear(Xgrand, yGrand, 'Learner', 'leastsquares', ...
                            'Lambda', 1e-6, 'PassLimit', 2000);
assert(corr(predict(modeleLineaire, Xgrand), yGrand) > 0.99);
assert(mean(predict(fitclinear([randn(100, 20); randn(100, 20) + 0.8], ...
                               [-ones(100, 1); ones(100, 1)]), ...
                    [randn(100, 20); randn(100, 20) + 0.8]) == ...
            [-ones(100, 1); ones(100, 1)]) > 0.7);

% Processus gaussien : il passe près des points observés, et sa variance
% remonte à la variance a priori loin d'eux.
Xgp = linspace(0, 10, 30)';
yGp = sin(Xgp) + 0.05 * randn(30, 1);
modeleGp = fitrgp(Xgp, yGp, 'KernelParameters', [1 1], 'Sigma', 0.05);
[moyenneGp, varianceGp] = predict(modeleGp, Xgp);
assert(sqrt(mean((moyenneGp - yGp) .^ 2)) < 0.1);
assert(mean(varianceGp) < 0.01);
[~, varianceLoin] = predict(modeleGp, [20; 30]);
assert(mean(varianceLoin) > 0.5);

%% ------------------------------------------------- mélanges gaussiens
rng(1);
melange = gmdistribution([0 0; 4 4], cat(3, eye(2), eye(2)), [0.6 0.4]);
assert(melange.NumComponents == 2);
tirages = random(melange, 1000);
assert(isequal(size(tirages), [1000 2]));
% La densité au centre d'une composante vaut son poids sur 2*pi.
assert(abs(pdf(melange, [0 0]) - 0.6 / (2 * pi)) < 1e-6);
assert(numel(unique(cluster(melange, tirages))) == 2);
% EM retrouve les deux composantes.
melangeAjuste = fitgmdist(tirages, 2);
assert(abs(max(melangeAjuste.ComponentProportion) - 0.6) < 0.1);
assert(melangeAjuste.Converged);
assert(fitgmdist(tirages, 2, 'CovarianceType', 'diagonal').NLogL > 0);

%% ------------------------------------------------------------ copules
rng(1);
% La copule de Clayton a une forme close : on la vérifie exactement.
assert(abs(copulacdf('Clayton', [0.5 0.5], 2) - 7 ^ (-0.5)) < 1e-12);
% À paramètre nul, toutes les familles archimédiennes redonnent
% l'indépendance.
assert(abs(copulacdf('Frank', [0.5 0.5], 1e-8) - 0.25) < 1e-6);
assert(abs(copulacdf('Gumbel', [0.5 0.5], 1) - 0.25) < 1e-12);
tiragesCopule = copularnd('Gaussian', 0.8, 3000);
assert(abs(corr(tiragesCopule(:, 1), tiragesCopule(:, 2)) - 0.8) < 0.05);
assert(abs(mean(tiragesCopule(:, 1)) - 0.5) < 0.03);
assert(copulapdf('Clayton', [0.5 0.5], 2) > 1);

%% -------------------------------------------- lois et échantillonnage
rng(1);
% Le système de Pearson reproduit les quatre moments demandés.
tirageP = pearsrnd(0, 1, 0.75, 4, 40000, 1);
assert(abs(mean(tirageP)) < 1e-10 && abs(std(tirageP) - 1) < 1e-10);
assert(abs(skewness(tirageP) - 0.75) < 0.1);
assert(abs(kurtosis(tirageP) - 4) < 0.3);
% L'échantillonnage par tranches sur une normale.
tirageTranches = slicesample(0, 4000, 'pdf', @(t) exp(-t .^ 2 / 2));
assert(abs(mean(tirageTranches)) < 0.1);
assert(abs(std(tirageTranches) - 1) < 0.1);

%% ------------------------------------------ variance et plans
rng(1);
facteurActif = repmat({'a', 'b', 'c'}, 1, 20)';
facteurInerte = repmat({'u', 'v'}, 1, 30)';
reponse = zeros(60, 1);
for k = 1:60
    reponse(k) = strcmp(facteurActif{k}, 'b') * 2 + 0.3 * randn();
end
pAnovan = anovan(reponse, {facteurActif, facteurInerte}, 'display', 'off');
assert(pAnovan(1) < 0.001 && pAnovan(2) > 0.1);
assert(numel(anovan(reponse, {facteurActif, facteurInerte}, ...
                    'model', 'interaction', 'display', 'off')) == 3);
% MANOVA : la dimension est nulle quand les moyennes coïncident.
Xmanova = [randn(30, 2); randn(30, 2) + 2];
groupeManova = [ones(30, 1); 2 * ones(30, 1)];
[dimension, pManova] = manova1(Xmanova, groupeManova);
assert(dimension == 1 && pManova(1) < 0.001);
rng(5);
[dimensionNulle, pNulle] = manova1([randn(30, 2); randn(30, 2)], groupeManova);
assert(dimensionNulle == 0 && pNulle(1) > 0.05);
% Le plan D-optimal et la matrice du modèle.
assert(isequal(x2fx([1 2; 3 4], 'interaction'), [1 1 2 2; 1 3 4 12]));
[reglages, planModele] = rowexch(2, 9, 'quadratic', 'tries', 2);
assert(isequal(size(reglages), [9 2]));
assert(det(planModele.' * planModele) > 0);

%% ------------------------------------------- choix de variables
rng(1);
Xchoix = randn(300, 5);
yChoix = double(Xchoix(:, 1) + Xchoix(:, 2) > 0) + 1;
rangs = relieff(Xchoix, yChoix, 10);
assert(all(ismember([1 2], rangs(1:2))));
critere = @(Xa, ya, Xt, yt) sum(predict(fitcnb(Xa, ya), Xt) ~= yt);
retenues = sequentialfs(critere, Xchoix(1:100, :), yChoix(1:100), 'cv', 5);
assert(any(retenues));

%% --------------------------------------------------- effets mixtes
rng(1);
groupeMixte = repmat((1:10)', 20, 1);
decalages = randn(10, 1) * 2;
xMixte = randn(200, 1);
yMixte = 1 + 3 * xMixte + decalages(groupeMixte) + 0.5 * randn(200, 1);
tableMixte = table(yMixte, xMixte, groupeMixte, ...
                   'VariableNames', {'y', 'x', 'g'});
modeleMixte = fitlme(tableMixte, 'y ~ 1 + x + (1|g)');
assert(abs(modeleMixte.Coefficients(2) - 3) < 0.1);
assert(abs(modeleMixte.Sigma - 0.5) < 0.1);
assert(modeleMixte.SigmaB > 1);
% REML corrige le biais de la variance : elle est plus grande qu'en ML.
modeleML = fitlme(tableMixte, 'y ~ 1 + x + (1|g)', 'FitMethod', 'ML');
assert(modeleMixte.SigmaB > modeleML.SigmaB);
% table nomme ses colonnes comme les variables qu'on lui passe.
colonnesNommees = table(xMixte, groupeMixte);
assert(isequal(colonnesNommees.Properties.VariableNames, {'xMixte', 'groupeMixte'}));

%% ------------------------------------------------- valeurs propres généralisées
% eig(A,B) résout A x = lambda B x ; le second argument était accepté
% puis ignoré, et MANOVA1 s'en trouvait faussé.
A = [2 0; 0 1];
B = [4 0; 0 2];
assert(max(abs(sort(eig(A, B)) - [0.5; 0.5])) < 1e-12);
rng(3);
Mgen = randn(4);
Sgen = Mgen.' * Mgen + eye(4);
Kgen = randn(4);
Kgen = Kgen.' * Kgen;
[vecteursGen, valeursGen] = eig(Kgen, Sgen);
assert(max(max(abs(Kgen * vecteursGen - Sgen * vecteursGen * valeursGen))) < 1e-10);
assert(max(abs(sort(eig(Kgen, Sgen)) - sort(eig(inv(Sgen) * Kgen)))) < 1e-9);


% FITCDISCR : analyse discriminante. Sa propriete definitoire est la
% frontiere — affine quand les classes partagent leur covariance,
% quadratique sinon.
rng(5);
nuage = [randn(60, 2); randn(60, 2) + 4];
etiquettesNuage = [ones(60, 1); 2 * ones(60, 1)];
modeleLineaire = fitcdiscr(nuage, etiquettesNuage);
[predites, aposteriori] = predict(modeleLineaire, nuage);
assert(mean(predites == etiquettesNuage) > 0.95);
assert(isequal(size(aposteriori), [120 2]));
assert(max(abs(sum(aposteriori, 2) - 1)) < 1e-12);
% Deux classes de meme covariance : la frontiere passe par le milieu des
% deux moyennes, et elle est perpendiculaire a la droite qui les joint
% seulement si la covariance est isotrope — c'est le cas ici.
milieu = mean(modeleLineaire.Mu, 1);
[~, scoreMilieu] = predict(modeleLineaire, milieu);
assert(abs(scoreMilieu(1) - 0.5) < 0.05, 'le milieu doit etre indecis');
% La variante quadratique donne un modele par classe.
modeleQuadratique = fitcdiscr(nuage, etiquettesNuage, 'DiscrimType', 'quadratic');
assert(mean(predict(modeleQuadratique, nuage) == etiquettesNuage) > 0.95);
assert(~isequal(modeleQuadratique.Sigma{1}, modeleQuadratique.Sigma{2}));
assert(isequal(modeleLineaire.Sigma{1}, modeleLineaire.Sigma{2}));
% Sur des classes de formes tres differentes, la quadratique fait mieux :
% c'est la seule des deux qui peut plier sa frontiere.
rng(6);
etroite = [randn(200, 1) * 0.3, randn(200, 1) * 3];
large = randn(200, 2) * 1.2;
melange = [etroite; large];
appartenance = [ones(200, 1); 2 * ones(200, 1)];
justesseLineaire = mean(predict(fitcdiscr(melange, appartenance), melange) == appartenance);
justesseQuadratique = mean(predict(fitcdiscr(melange, appartenance, ...
    'DiscrimType', 'quadratic'), melange) == appartenance);
fprintf('discriminant : lineaire %.3f, quadratique %.3f\n', ...
        justesseLineaire, justesseQuadratique);
assert(justesseQuadratique > justesseLineaire);
% Les a priori imposes deplacent la frontiere. Il faut des classes qui se
% recouvrent pour le voir : deux nuages bien separes ne changent pas
% d'avis, quel que soit l'a priori.
rng(9);
proches = [randn(150, 2); randn(150, 2) + 1];
voisinage = [ones(150, 1); 2 * ones(150, 1)];
sansBiais = predict(fitcdiscr(proches, voisinage), proches);
avecBiais = predict(fitcdiscr(proches, voisinage, 'Prior', [0.95 0.05]), proches);
fprintf('discriminant : classe 1 predite %d fois, %d avec a priori\n', ...
        sum(sansBiais == 1), sum(avecBiais == 1));
assert(sum(avecBiais == 1) > sum(sansBiais == 1));
disp('fitcdiscr : ok');

disp('statistiques : toutes les verifications passent');
