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

disp('statistiques : toutes les verifications passent');
