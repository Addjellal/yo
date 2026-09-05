% ajustement-courbes.m — Curve Fitting Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/ajustement-courbes.m
%
% Le cas : des mesures bruitées, et la question de savoir quelle courbe
% les traverse. Interpoler passe par tous les points ; ajuster passe au
% mieux entre eux ; lisser choisit entre les deux. Les trois répondent à
% des questions différentes.

fprintf('=== Ajustement de courbes : interpoler, ajuster, lisser ===\n\n');

%% 1. Ajuster un modèle de la bibliothèque
% Une décroissance exponentielle, cas d'école de la charge d'un
% condensateur ou de la désintégration.
x = linspace(0, 5, 60)';
rng(1);
y = 3 * exp(-1.4 * x) + 0.5 + 0.05 * randn(size(x));
ajustement = fit(x, y, 'exp1');
fprintf('Modele exp1 (a exp(b x)) :\n');
fprintf('  a = %.4f, b = %.4f\n', ajustement.a, ajustement.b);
% Avec la constante, le modele a deux termes convient mieux.
ajustement2 = fit(x, y, 'exp2');
fprintf('Modele exp2 : a = %.4f, b = %.4f, c = %.4f, d = %.4f\n', ...
        ajustement2.a, ajustement2.b, ajustement2.c, ajustement2.d);
% On juge sur le residu, pas sur les coefficients.
residu1 = norm(feval(ajustement, x) - y);
residu2 = norm(feval(ajustement2, x) - y);
fprintf('  residu : exp1 %.4f, exp2 %.4f\n', residu1, residu2);
assert(residu2 < residu1, 'le modele a deux termes doit coller mieux');

%% 2. Ajuster un modèle écrit à la main
% Quand aucun modèle de la bibliothèque ne convient, on écrit le sien.
modele = fittype('a * exp(-b * x) + c', 'independent', 'x');
depart = fitoptions('Method', 'NonlinearLeastSquares', 'StartPoint', [1 1 0]);
propre = fit(x, y, modele, depart);
fprintf('\nModele ecrit a la main, a exp(-b x) + c :\n');
fprintf('  a = %.4f (vrai 3), b = %.4f (vrai 1.4), c = %.4f (vrai 0.5)\n', ...
        propre.a, propre.b, propre.c);
assert(abs(propre.a - 3) < 0.2);
assert(abs(propre.b - 1.4) < 0.15);
assert(abs(propre.c - 0.5) < 0.1);

%% 3. Polynômes
% Le degré est un choix, non une donnée : trop bas il rate la forme,
% trop haut il suit le bruit.
xPoly = linspace(-3, 3, 40)';
rng(2);
yPoly = xPoly .^ 3 - 2 * xPoly + 1 + 0.5 * randn(size(xPoly));
fprintf('\nAjustement polynomial :\n');
residus = zeros(1, 6);
for degre = 1:6
    coefficients = polyfit(xPoly, yPoly, degre);
    residus(degre) = norm(polyval(coefficients, xPoly) - yPoly);
    fprintf('  degre %d : residu %.4f\n', degre, residus(degre));
end
% Le residu ne peut que baisser quand le degre monte : c'est mecanique,
% et c'est pourquoi il ne suffit pas a choisir le degre.
assert(all(diff(residus) <= 1e-9), 'le residu decroit toujours avec le degre');
% Le saut se lit entre le degre 2 et le degre 3 : c'est la que le modele
% cesse de manquer la forme.
gainRelatif = (residus(1:end-1) - residus(2:end)) ./ residus(1:end-1);
[~, sautPrincipal] = max(gainRelatif);
fprintf('  gain le plus net en passant au degre %d (vrai degre 3)\n', sautPrincipal + 1);
assert(sautPrincipal + 1 == 3);
coefficients3 = polyfit(xPoly, yPoly, 3);
assert(max(abs(coefficients3 - [1 0 -2 1])) < 0.3);

%% 4. Interpoler
% Une spline cubique passe exactement par tous les points, et elle est
% deux fois dérivable. C'est ce qui la distingue d'une interpolation
% linéaire, qui casse aux nœuds.
xNoeuds = (0:0.5:5)';
yNoeuds = sin(xNoeuds);
xFin = linspace(0, 5, 200)';
parSpline = spline(xNoeuds, yNoeuds, xFin);
parLigne = interp1(xNoeuds, yNoeuds, xFin);
fprintf('\nInterpolation de sin(x) sur %d noeuds :\n', numel(xNoeuds));
fprintf('  erreur maximale : spline %.5f, lineaire %.5f\n', ...
        max(abs(parSpline - sin(xFin))), max(abs(parLigne - sin(xFin))));
assert(max(abs(parSpline - sin(xFin))) < max(abs(parLigne - sin(xFin))) / 5);
% Elle passe exactement par les noeuds.
assert(max(abs(spline(xNoeuds, yNoeuds, xNoeuds) - yNoeuds)) < 1e-12);
% Et elle reproduit exactement un cubique, puisqu'elle en est un.
cube = @(t) t .^ 3 - 2 * t + 1;
assert(max(abs(spline(xNoeuds, cube(xNoeuds), xFin) - cube(xFin))) < 1e-9);

%% 5. Lisser
% Entre interpoler et ajuster une droite, il y a un curseur : le
% paramètre de lissage. À un, la spline passe par tous les points ; vers
% zéro, elle tend vers la droite des moindres carrés.
rng(3);
xLisse = linspace(0, 10, 80)';
yLisse = sin(xLisse) + 0.3 * randn(size(xLisse));
fprintf('\nSpline de lissage :\n');
for p = [1 0.99 0.5 1e-6]
    courbe = csaps(xLisse, yLisse, p);
    valeurs = fnval(courbe, xLisse);
    fprintf('  p = %-8g : ecart aux points %.4f, ecart au sinus %.4f\n', ...
            p, norm(valeurs - yLisse), norm(valeurs - sin(xLisse)));
end
% A p = 1, elle interpole exactement.
assert(max(abs(fnval(csaps(xLisse, yLisse, 1), xLisse) - yLisse)) < 1e-8);
% A p tres petit, elle devient la droite des moindres carres.
presqueDroite = fnval(csaps(xLisse, yLisse, 1e-9), xLisse);
droite = polyval(polyfit(xLisse, yLisse, 1), xLisse);
fprintf('  a p tres petit, ecart a la droite des moindres carres : %.6f\n', ...
        max(abs(presqueDroite - droite)));
assert(max(abs(presqueDroite - droite)) < 1e-3);

% Le lissage local, quand on ne veut pas d'un modele global.
lisseLocal = smooth(yLisse, 15, 'loess');
fprintf('  lissage local (loess, 15 points) : ecart au sinus %.4f\n', ...
        norm(lisseLocal - sin(xLisse)));
assert(norm(lisseLocal - sin(xLisse)) < norm(yLisse - sin(xLisse)));

%% 6. Surfaces
% Le même problème à deux variables. Une interpolation par triangulation
% reproduit exactement un champ affine, quel que soit le semis de points.
rng(4);
xs = rand(200, 1) * 10;
ys = rand(200, 1) * 10;
zsAffine = 2 * xs - 3 * ys + 5;
[grilleX, grilleY] = meshgrid(1:0.5:9, 1:0.5:9);
interpolee = griddata(xs, ys, zsAffine, grilleX, grilleY);
attendu = 2 * grilleX - 3 * grilleY + 5;
fprintf('\nInterpolation de surface :\n');
fprintf('  champ affine, ecart maximal : %.3e\n', max(max(abs(interpolee - attendu))));
assert(max(max(abs(interpolee - attendu))) < 1e-9, ...
       'une interpolation lineaire doit reproduire exactement un plan');

% Et l'ajustement d'une surface polynomiale.
zs = xs .^ 2 + ys + 0.1 * randn(200, 1);
surface = fit([xs, ys], zs, 'poly21');
fprintf('  surface poly21 ajustee, residu %.4f\n', ...
        norm(feval(surface, [xs, ys]) - zs) / sqrt(numel(zs)));
assert(norm(feval(surface, [xs, ys]) - zs) / sqrt(numel(zs)) < 0.2);

%% 7. Qualité de l'ajustement
[~, qualite] = fit(x, y, modele, depart);
fprintf('\nQualite de l''ajustement du modele a trois parametres :\n');
fprintf('  SSE %.5f, R2 %.5f, RMSE %.5f\n', qualite.sse, qualite.rsquare, qualite.rmse);
assert(qualite.rsquare > 0.99);
% Le R2 est bien un moins le rapport des sommes de carres.
totale = sum((y - mean(y)) .^ 2);
assert(abs(qualite.rsquare - (1 - qualite.sse / totale)) < 1e-9);

fprintf('\nToutes les verifications passent.\n');
