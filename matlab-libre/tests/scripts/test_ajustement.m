% test_ajustement.m — modèles d'ajustement, courbes, surfaces et splines.
%
% Les vérifications sont des propriétés que l'ajustement doit avoir. Un
% modèle ajusté à des données qu'il engendre exactement doit retrouver ses
% propres coefficients, et son R carré valoir un. Un intervalle de
% confiance doit contenir la valeur vraie, et rétrécir quand les données
% s'accumulent. Une spline de lissage doit interpoler à un bout du réglage
% et se réduire à une droite à l'autre. Une spline « not-a-knot » doit
% reproduire exactement tout polynôme de degré trois.
disp('--- ajustement de courbes ---');

% Modèles écrits à la main : les coefficients se relèvent dans
% l'expression, et la linéarité se contrôle en évaluant.
ft = fittype('a*x^2 + b');
assert(isequal(coeffnames(ft), {'a'; 'b'}));
assert(islinear(ft));
assert(abs(feval(ft, [2 1], 3) - 19) < 1e-12);
assert(isequal(feval(ft, [1 0], [1; 2; 3]), [1; 4; 9]));
assert(~islinear(fittype('a*exp(b*x)')));
assert(islinear(fittype('a*sin(x) + b*cos(x)')));
% Un paramètre imposé n'est pas un coefficient.
fp = fittype('a*x + c*n', 'problem', 'n');
assert(isequal(coeffnames(fp), {'a'; 'c'}));
assert(isequal(probnames(fp), {'n'}));
assert(abs(feval(fp, [2 3], 2, 3) - 12) < 1e-12);
% Les modèles de la bibliothèque.
assert(strcmp(formula(fittype('poly2')), 'p1*x^2 + p2*x + p3'));
assert(numcoeffs(fittype('gauss3')) == 9);
assert(numcoeffs(fittype('fourier2')) == 6);
assert(strcmp(type(fittype('rat21')), 'rat21'));
disp('modeles : ok');

% Un modèle ajusté à ses propres valeurs retrouve ses coefficients.
x = (1:10)';
[fo, gof] = fit(x, x .^ 2, 'poly2');
fprintf('poly2 : %s, R2 = %.12f\n', mat2str(round(coeffvalues(fo), 8)), gof.rsquare);
assert(max(abs(coeffvalues(fo) - [1 0 0])) < 1e-8);
assert(abs(gof.rsquare - 1) < 1e-12);
assert(abs(fo(3) - 9) < 1e-8);
% Non linéaires : l'exponentielle, la puissance, la gaussienne.
xg = (-4:0.1:4)';
fg = fit(xg, 2 * exp(-((xg - 0.5) / 1.2) .^ 2), 'gauss1');
fprintf('gauss1 : %s (attendu 2 0.5 1.2)\n', mat2str(round(coeffvalues(fg), 4)));
assert(max(abs(coeffvalues(fg) - [2 0.5 1.2])) < 1e-3);
xp = (1:0.2:8)';
fq = fit(xp, 1.7 * xp .^ 1.3, 'power1');
assert(max(abs(coeffvalues(fq) - [1.7 1.3])) < 1e-4);
xe = (0:0.1:5)';
fe = fit(xe, 3 * exp(-0.7 * xe), 'exp1');
assert(max(abs(coeffvalues(fe) - [3 -0.7])) < 1e-4);
% Une sinusoïde : la pulsation vient du spectre, et non d'un tirage.
xs = (0:0.02:4)';
fs = fit(xs, 1.5 * sin(3 * xs + 0.4), 'sin1');
fprintf('sin1 : %s (attendu 1.5 3 0.4)\n', mat2str(round(coeffvalues(fs), 3)));
assert(abs(coeffvalues(fs) * [0; 1; 0] - 3) < 0.05);
% Une fraction rationnelle.
xr = (1:0.2:10)';
fr = fit(xr, (2 * xr + 1) ./ (xr + 3), 'rat11');
assert(max(abs(fr(xr) - (2 * xr + 1) ./ (xr + 3))) < 1e-6);
disp('ajustements : ok');

% Intervalles de confiance : ils contiennent la valeur vraie, et
% rétrécissent quand les données s'accumulent.
rng(3);
xb = (0:0.05:5)';
bruit = 0.05;
yb = 2 - 0.5 * xb + bruit * randn(size(xb));
fb = fit(xb, yb, 'poly1');
bornes = confint(fb, 0.95);
fprintf('pente dans [%.4f %.4f], vraie -0.5\n', bornes(1, 1), bornes(2, 1));
assert(bornes(1, 1) < -0.5 && bornes(2, 1) > -0.5);
assert(bornes(1, 2) < 2 && bornes(2, 2) > 2);
largeurCourte = bornes(2, 1) - bornes(1, 1);
xl = (0:0.01:5)';
fl = fit(xl, 2 - 0.5 * xl + bruit * randn(size(xl)), 'poly1');
bornesLongues = confint(fl, 0.95);
largeurLongue = bornesLongues(2, 1) - bornesLongues(1, 1);
fprintf('largeur : %.5f puis %.5f avec cinq fois plus de points\n', ...
        largeurCourte, largeurLongue);
assert(largeurLongue < largeurCourte);
% Un intervalle à 99 % est plus large qu'à 95 %.
large = confint(fb, 0.99);
assert(large(2, 1) - large(1, 1) > largeurCourte);
% L'intervalle d'observation contient celui de la courbe, et
% l'intervalle simultané contient l'intervalle ponctuel.
courbe = predint(fb, 2.5, 0.95, 'functional', 'off');
observation = predint(fb, 2.5, 0.95, 'observation', 'off');
simultane = predint(fb, 2.5, 0.95, 'functional', 'on');
assert(observation(1) < courbe(1) && observation(2) > courbe(2));
assert(simultane(1) < courbe(1) && simultane(2) > courbe(2));
disp('intervalles : ok');

% Dérivée et primitive.
fd = fit((0:0.1:3)', (0:0.1:3)' .^ 2, 'poly2');
[premiere, seconde] = differentiate(fd, 1.5);
fprintf('derivees en 1.5 : %.6f et %.6f (attendu 3 et 2)\n', premiere, seconde);
assert(abs(premiere - 3) < 1e-4);
assert(abs(seconde - 2) < 1e-3);
assert(abs(integrate(fd, 3, 0) - 9) < 1e-6);
% Sur une spline, la dérivée est exacte.
fspline = fit((0:0.5:4)', (0:0.5:4)' .^ 3, 'cubicinterp');
assert(abs(differentiate(fspline, 2) - 12) < 1e-8);
assert(abs(integrate(fspline, 2, 0) - 4) < 1e-8);
disp('derivation et integration : ok');

% Ajustement robuste : une valeur aberrante déplace l'ajustement
% ordinaire, non l'ajustement robuste.
xa = (1:40)';
ya = 2 * xa + 1;
ya(20) = 500;
ordinaire = fit(xa, ya, 'poly1');
robuste = fit(xa, ya, 'poly1', 'Robust', 'Bisquare');
fprintf('ordonnee a l''origine : %.3f sans robustesse, %.6f avec (vraie 1)\n', ...
        coeffvalues(ordinaire) * [0; 1], coeffvalues(robuste) * [0; 1]);
assert(max(abs(coeffvalues(robuste) - [2 1])) < 1e-6);
% Le point aberrant est au milieu : il deplace surtout l'ordonnee a
% l'origine, que l'ajustement ordinaire remonte de plus de dix.
assert(abs(coeffvalues(ordinaire) * [0; 1] - 1) > 10);
% Exclure le point aberrant donne le même résultat que la robustesse.
exclus = false(40, 1);
exclus(20) = true;
sansPoint = fit(xa, ya, 'poly1', 'Exclude', exclus);
assert(max(abs(coeffvalues(sansPoint) - [2 1])) < 1e-8);
% Les poids agissent : un point très pesé attire l'ajustement.
poids = ones(40, 1);
poids(20) = 1000;
pese = fit(xa, ya, 'poly1', 'Weights', poids);
assert(coeffvalues(pese) * [0; 1] > coeffvalues(ordinaire) * [0; 1]);
% Normaliser ne change pas la courbe.
normalise = fit(xa, 2 * xa + 1, 'poly2', 'Normalize', 'on');
brut = fit(xa, 2 * xa + 1, 'poly2');
assert(max(abs(normalise(xa) - brut(xa))) < 1e-6);
disp('robustesse et ponderation : ok');

% Splines de lissage.
xc = (0:0.25:4)';
yc = xc .^ 2;
assert(max(abs(ppval(csaps(xc, yc, 1), xc) - yc)) < 1e-12);
droite = polyfit(xc, yc, 1);
assert(max(abs(ppval(csaps(xc, yc, 1e-12), xc) - polyval(droite, xc))) < 1e-9);
% La tolérance de SPAPS est atteinte exactement.
rng(1);
xt = linspace(0, 2 * pi, 60)';
yt = sin(xt) + 0.05 * randn(size(xt));
[pt, vt] = spaps(xt, yt, 60 * 0.05 ^ 2);
fprintf('spaps : somme des carres %.6f (visee %.6f)\n', sum((yt - vt) .^ 2), 60 * 0.05 ^ 2);
assert(abs(sum((yt - vt) .^ 2) - 60 * 0.05 ^ 2) < 1e-6);
assert(max(abs(vt - sin(xt))) < 0.1);
% Conditions de bord de CSAPE : elles sont exactement respectées.
xn = (0:4)';
yn = sin(xn);
naturelle = csape(xn, yn, 'natural');
assert(max(abs(ppval(fnder(naturelle, 2), [0; 4]))) < 1e-10);
imposee = csape(xn, yn, 'second', [1 -2]);
assert(max(abs(ppval(fnder(imposee, 2), [0; 4]) - [1; -2])) < 1e-10);
serree = csape(xn, yn, 'complete', [cos(0) cos(4)]);
assert(max(abs(ppval(fnder(serree), [0; 4]) - [cos(0); cos(4)])) < 1e-10);
periodique = csape((0:6)', [0 1 0 -1 0 1 0]', 'periodic');
assert(abs(ppval(fnder(periodique), 0) - ppval(fnder(periodique), 6)) < 1e-12);
disp('splines de lissage : ok');

% Splines par morceaux et B-splines.
pp = spline(1:5, (1:5) .^ 2);
% « not-a-knot » reproduit exactement un polynome de degre trois.
assert(abs(fnval(pp, 2.5) - 6.25) < 1e-12);
assert(abs(spline(1:5, (1:5) .^ 3, 2.5) - 2.5 ^ 3) < 1e-12);
assert(abs(fnval(fnder(pp), 3) - 6) < 1e-12);
assert(abs(fnval(fnder(pp, 2), 3) - 2) < 1e-12);
assert(abs(fnval(fnint(spline(0:4, (0:4) .^ 2)), 3) - 9) < 1e-12);
assert(fnbrk(pp, 'order') == 4 && fnbrk(pp, 'pieces') == 4);
assert(isequal(fnbrk(pp, 'interval'), [1 5]));
morceau = fnbrk(pp, 2);
assert(isequal(morceau.breaks, [2 3]));
% Les B-splines somment à un, et la spline des moindres carrés reproduit
% exactement un polynôme de son ordre.
N = matlibre_base_bspline([0 0 0 1 2 2 2], 3, [0.5; 1.5; 2]);
assert(max(abs(sum(N, 2) - 1)) < 1e-12);
xb2 = (0:0.05:1)';
sp = spap2(4, 4, xb2, xb2 .^ 3);
assert(max(abs(fnval(sp, xb2) - xb2 .^ 3)) < 1e-10);
assert(abs(fnval(fnder(sp), 0.5) - 3 * 0.25) < 1e-10);
assert(isequal(augknt([0 1 2], 3), [0 0 0 1 2 2 2]));
disp('splines par morceaux : ok');

% Lissage d'une suite.
assert(isequal(smooth([1 2 3 4 5]'), [1; 2; 3; 4; 5]));
carres = (1:9)' .^ 2;
assert(max(abs(smooth(carres, 5, 'sgolay', 2) - carres)) < 1e-10);
droiteX = (1:30)';
assert(max(abs(smooth(droiteX, droiteX, 0.4, 'lowess') - droiteX)) < 1e-10);
% Le lissage robuste résiste à une valeur aberrante là où l'autre cède.
aberrante = droiteX;
aberrante(15) = 300;
ordinaireLisse = smooth(droiteX, aberrante, 0.4, 'lowess');
robusteLisse = smooth(droiteX, aberrante, 0.4, 'rlowess');
fprintf('lissage au point aberrant : %.2f sans robustesse, %.2f avec\n', ...
        ordinaireLisse(15), robusteLisse(15));
assert(abs(robusteLisse(15) - 15) < abs(ordinaireLisse(15) - 15) / 5);
disp('lissage : ok');

% Préparation et exclusion des données.
[xd, yd] = prepareCurveData([], [1 NaN 3]);
assert(isequal(xd, [1; 3]) && isequal(yd, [1; 3]));
[xe2, ye2, ze2] = prepareSurfaceData(1:3, 1:2, [1 2 3; 4 5 6]);
assert(numel(ze2) == 6 && isequal(xe2.', [1 1 2 2 3 3]));
assert(sum(excludedata((1:10)', (1:10)', 'domain', [3 8])) == 4);
assert(sum(excludedata((1:10)', (1:10)', 'box', [3 8 4 9])) == 5);
assert(isequal(find(excludedata((1:10)', (1:10)', 'indices', [2 5])).', [2 5]));
residus = [0.1 -0.2 0.05 8 -0.1 0.2 0.15 -0.05 0.1 -0.15]';
assert(isequal(find(excludedata((1:10)', residus, 'outliers', residus)), 4));
disp('preparation des donnees : ok');

% Surfaces.
[X, Y] = meshgrid(0:0.2:1, 0:0.2:1);
Z = 1 + 2 * X - 3 * Y + 0.5 * X .* Y;
so = fit([X(:) Y(:)], Z(:), 'poly22');
fprintf('poly22 : %s\n', mat2str(round(coeffvalues(so), 6)));
assert(max(abs(coeffvalues(so) - [1 2 -3 0 0.5 0])) < 1e-8);
assert(abs(so(0.5, 0.5) - (1 + 1 - 1.5 + 0.125)) < 1e-8);
assert(isequal(coeffnames(so), {'p00'; 'p10'; 'p01'; 'p20'; 'p11'; 'p02'}));
[~, gofSurface] = fit([X(:) Y(:)], Z(:), 'poly22');
assert(abs(gofSurface.rsquare - 1) < 1e-12);
% Un plan est retrouvé par un modèle de degré un.
plan = 1 + 2 * X - 3 * Y;
sp1 = fit([X(:) Y(:)], plan(:), 'poly11');
assert(max(abs(coeffvalues(sp1) - [1 2 -3])) < 1e-8);
% Un interpolant passe par les points.
si = fit([X(:) Y(:)], Z(:), 'linearinterp');
assert(max(abs(si(X(:), Y(:)) - Z(:))) < 1e-10);
disp('surfaces : ok');

% Interpolation de données dispersées.
zp = 2 * X - 3 * Y;
assert(abs(griddata(X(:), Y(:), zp(:), 0.3, 0.7) - (0.6 - 2.1)) < 1e-12);
assert(abs(griddata(X(:), Y(:), zp(:), 0.3, 0.7, 'cubic') - (0.6 - 2.1)) < 1e-8);
assert(max(abs(griddata(X(:), Y(:), zp(:), X(:), Y(:), 'cubic') - zp(:))) < 1e-10);
assert(isnan(griddata(X(:), Y(:), zp(:), 2, 2)));
assert(isequal(matlibre_barycentriques([0 1 0], [0 0 1], 0.25, 0.25), [0.5 0.25 0.25]));
disp('donnees dispersees : ok');

disp('ajustement de courbes : toutes les verifications passent');
