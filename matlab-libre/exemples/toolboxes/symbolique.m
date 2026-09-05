% symbolique.m — calcul symbolique, cas d'école.
%
%   matlibre exemples/toolboxes/symbolique.m
%
% Le calcul symbolique manipule les expressions, non les nombres : une
% dérivée y est une expression, pas une différence finie.
%
% Ce que le moteur de MatLibre sait faire, et que cet exemple montre :
% dériver, intégrer un polynôme, développer, substituer, résoudre une
% équation polynomiale, prendre une limite, une somme, une jacobienne,
% une matrice hessienne, et convertir en fonction ou en LaTeX.
%
% Ce qu'il ne sait pas faire, et qu'il ne faut pas lui demander : les
% identités trigonométriques — SIMPLIFY ne ramène pas sin^2 + cos^2 à un
% —, l'intégration des fonctions transcendantes, les constantes exactes
% comme pi, les équations différentielles. Un système de calcul formel
% complet est un projet à lui seul.

fprintf('=== Symbolique : deriver, integrer, resoudre ===\n\n');

%% 1. Dériver
syms x
f = x ^ 3 - 2 * x + 1;
derivee = diff(f, x);
fprintf('Derivation :\n');
fprintf('  f     = %s\n', char(f));
fprintf('  df/dx = %s\n', char(derivee));
% La verification ne passe pas par la forme, qui depend de l'ecriture,
% mais par les valeurs : deux expressions egales prennent les memes.
for point = [-2 -0.5 0 1 3]
    assert(abs(double(subs(derivee, x, point)) - (3 * point ^ 2 - 2)) < 1e-12);
end
seconde = diff(f, x, 2);
fprintf('  d2f/dx2 = %s\n', char(seconde));
for point = [-2 0 3]
    assert(abs(double(subs(seconde, x, point)) - 6 * point) < 1e-12);
end
% Sur un produit de fonctions transcendantes, la regle du produit
% s'applique aussi.
g = sin(x) * exp(x);
derivGrande = diff(g, x);
fprintf('  d/dx (sin(x) exp(x)) = %s\n', char(derivGrande));
attendu = @(t) cos(t) * exp(t) + sin(t) * exp(t);
assert(abs(double(subs(derivGrande, x, 0.7)) - attendu(0.7)) < 1e-10);

%% 2. Intégrer
% L'intégration est le sens difficile : dériver est mécanique, intégrer
% ne l'est pas. Le moteur traite les polynômes, terme à terme.
primitive = int(f, x);
fprintf('\nIntegration :\n');
fprintf('  int f dx = %s\n', char(primitive));
% La verification est immediate : deriver la primitive rend l'integrande.
retour = diff(primitive, x);
for point = [-1 0.3 2]
    assert(abs(double(subs(retour, x, point)) - double(subs(f, x, point))) < 1e-10);
end
% Une integrale definie.
aire = int(x ^ 2, x, 0, 3);
fprintf('  int_0^3 x^2 dx = %s (exactement 27/3 = 9)\n', char(aire));
assert(abs(double(aire) - 9) < 1e-12);
% Elle est additive sur les intervalles, comme toute integrale.
gauche = double(int(x ^ 2, x, 0, 1));
droite = double(int(x ^ 2, x, 1, 3));
assert(abs(gauche + droite - double(aire)) < 1e-12);

%% 3. Résoudre
% Les racines d'un polynôme, rendues dans une cellule d'expressions.
solutions = solve(x ^ 2 - 5 * x + 6, x);
fprintf('\nResolution :\n');
fprintf('  x^2 - 5x + 6 = 0 : %d racines\n', numel(solutions));
valeurs = sort(cellfun(@double, solutions));
fprintf('  racines : %s\n', mat2str(round(valeurs', 6)));
assert(max(abs(valeurs(:)' - [2 3])) < 1e-10);
% Chaque racine annule bien le polynome : c'est la definition.
polynome = x ^ 2 - 5 * x + 6;
for k = 1:numel(solutions)
    assert(abs(double(subs(polynome, x, double(solutions{k})))) < 1e-10);
end
% Une racine irrationnelle est rendue en nombre, non en radical.
irrationnelles = sort(cellfun(@double, solve(x ^ 2 - 2, x)));
fprintf('  x^2 - 2 = 0 : %s\n', mat2str(round(irrationnelles', 6)));
assert(max(abs(irrationnelles(:)' - [-sqrt(2) sqrt(2)])) < 1e-12);

%% 4. Développer et substituer
developpee = expand((x + 1) ^ 3);
fprintf('\nManipulation :\n');
fprintf('  (x+1)^3 developpe : %s\n', char(developpee));
for point = [-2 0 1.5]
    assert(abs(double(subs(developpee, x, point)) - (point + 1) ^ 3) < 1e-10);
end
% Les coefficients d'un polynome se lisent directement.
coefficients = sym2poly(developpee);
fprintf('  coefficients : %s (attendu [1 3 3 1])\n', mat2str(coefficients));
assert(max(abs(coefficients - [1 3 3 1])) < 1e-12);
% Et POLY2SYM fait le chemin inverse.
refaite = poly2sym(coefficients, x);
assert(abs(double(subs(refaite, x, 2)) - 27) < 1e-10);
fprintf('  f(2) = %g\n', double(subs(f, x, 2)));
assert(double(subs(f, x, 2)) == 5);

%% 5. Limites et sommes
% Ce que le numérique ne peut qu'approcher.
fprintf('\nLimites et sommes :\n');
fprintf('  lim_{x->0} sin(x)/x = %s\n', char(limit(sin(x) / x, x, 0)));
assert(abs(double(limit(sin(x) / x, x, 0)) - 1) < 1e-6);
% Une limite qui vaut zero, et une qui vaut e.
assert(abs(double(limit(x / (x ^ 2 + 1), x, inf))) < 1e-4);
fprintf('  lim_{x->inf} (1 + 1/x)^x = %s (e = %.6f)\n', ...
        char(limit((1 + 1 / x) ^ x, x, inf)), exp(1));
% Une somme finie, exacte.
somme = symsum(x, x, 1, 100);
fprintf('  somme des entiers de 1 a 100 : %s (formule : %d)\n', ...
        char(somme), 100 * 101 / 2);
assert(double(somme) == 5050);
% Et une somme de carres.
assert(double(symsum(x ^ 2, x, 1, 10)) == 385);

%% 6. Dérivées à plusieurs variables
syms y
fprintf('\nPlusieurs variables :\n');
% Les expressions et les variables se donnent en cellules : un tableau
% de syms n'existe pas ici, une cellule le remplace.
J = jacobian({x * y, x + y}, {x, y});
fprintf('  jacobienne de [x y ; x + y] : %d lignes, %d colonnes\n', size(J, 1), size(J, 2));
assert(isequal(size(J), [2 2]));
% Ligne 1 : d(xy)/dx = y et d(xy)/dy = x.
assert(abs(double(subs(subs(J{1, 1}, x, 3), y, 4)) - 4) < 1e-12);
assert(abs(double(subs(subs(J{1, 2}, x, 3), y, 4)) - 3) < 1e-12);
% Ligne 2 : les deux derivees de x + y valent un.
assert(abs(double(J{2, 1}) - 1) < 1e-12);
assert(abs(double(J{2, 2}) - 1) < 1e-12);
% La hessienne est symetrique, comme toute matrice de derivees secondes
% d'une fonction assez reguliere — c'est le theoreme de Schwarz.
H = hessian(x ^ 2 * y, {x, y});
croisee1 = double(subs(subs(H{1, 2}, x, 2), y, 5));
croisee2 = double(subs(subs(H{2, 1}, x, 2), y, 5));
fprintf('  hessienne de x^2 y : derivees croisees %g et %g\n', croisee1, croisee2);
assert(abs(croisee1 - croisee2) < 1e-12);
assert(abs(croisee1 - 2 * 2) < 1e-10);   % d2/dxdy (x^2 y) = 2x

%% 7. Sortir du symbolique
% Une expression devient une fonction ordinaire, utilisable partout où
% l'on attend un handle — un intégrateur, un solveur, un tracé.
fonction = matlabFunction(f);
fprintf('\nConversions :\n');
fprintf('  en fonction : %s\n', func2str(fonction));
points = [-2 0 1 3.5];
assert(max(abs(fonction(points) - (points .^ 3 - 2 * points + 1))) < 1e-12);
% Elle est vectorisee : les operateurs sont ceux qui agissent terme a
% terme, sans quoi elle ne servirait qu'a un point a la fois.
assert(numel(fonction(points)) == numel(points));
% Et en LaTeX, pour un document.
fprintf('  en LaTeX    : %s\n', latex(f));
assert(contains(latex(f), 'x^{3}'));

fprintf('\nToutes les verifications passent.\n');
