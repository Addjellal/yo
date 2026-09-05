% optimisation.m — Optimization Toolbox sur des cas d'école.
%
%   matlibre exemples/toolboxes/optimisation.m
%
% Quatre problèmes classiques, un par famille : une fonction à minimiser
% sans contrainte, un programme linéaire, un ajustement aux moindres
% carrés, et une équation à résoudre.

fprintf('=== Optimisation : les quatre familles ===\n\n');

%% 1. Sans contrainte : la banane de Rosenbrock
% Le cas d'école de la descente. Son minimum est en (1,1), au fond d'une
% vallée courbe et étroite où les méthodes naïves zigzaguent.
rosenbrock = @(x) 100 * (x(2) - x(1) ^ 2) ^ 2 + (1 - x(1)) ^ 2;
depart = [-1.2; 1];
[solution, valeur] = fminunc(rosenbrock, depart);
fprintf('Rosenbrock depuis %s :\n', mat2str(depart'));
fprintf('  minimum trouve : %s\n', mat2str(round(solution', 6)));
fprintf('  valeur         : %.3e (attendu 0)\n', valeur);
assert(max(abs(solution - 1)) < 1e-3, 'le minimum est en (1,1)');
assert(valeur < 1e-6);

% La même chose par un simplexe, qui n'emploie aucune dérivée.
[solutionSimplexe, valeurSimplexe] = fminsearch(rosenbrock, depart);
fprintf('  par simplexe   : %s, valeur %.3e\n', ...
        mat2str(round(solutionSimplexe', 4)), valeurSimplexe);
assert(max(abs(solutionSimplexe - 1)) < 1e-2);

% En une dimension, sur un intervalle.
[xMin, yMin] = fminbnd(@(x) (x - 3) .^ 2 + 2, 0, 10);
fprintf('  fminbnd sur (x-3)^2+2 : x = %.6f, y = %.6f\n', xMin, yMin);
assert(abs(xMin - 3) < 1e-5 && abs(yMin - 2) < 1e-9);

%% 2. Avec contraintes
% Minimiser sous des contraintes linéaires et une contrainte non
% linéaire. Le minimum sans contrainte est en (1,1) ; la contrainte le
% déplace, et c'est cela qu'on veut voir.
objectif = @(x) (x(1) - 1) ^ 2 + (x(2) - 1) ^ 2;
% x1 + x2 <= 1 : le minimum libre viole la contrainte.
A = [1 1];
b = 1;
[avecContrainte, valeurContrainte] = fmincon(objectif, [0; 0], A, b);
fprintf('\nSous la contrainte x1 + x2 <= 1 :\n');
fprintf('  solution : %s, valeur %.6f\n', ...
        mat2str(round(avecContrainte', 6)), valeurContrainte);
% Par symétrie la solution est (0.5, 0.5), et la contrainte est saturée.
assert(max(abs(avecContrainte - 0.5)) < 1e-4);
assert(abs(A * avecContrainte - b) < 1e-6, 'la contrainte doit etre saturee');
% Des bornes simples suffisent parfois.
borne = fmincon(objectif, [0; 0], [], [], [], [], [-Inf; -Inf], [0.3; 0.3]);
fprintf('  avec x <= 0.3 : %s\n', mat2str(round(borne', 6)));
assert(max(abs(borne - 0.3)) < 1e-4);

%% 3. Programme linéaire
% Le problème du menu : deux aliments, deux besoins nutritionnels, un
% coût à minimiser. L'optimum d'un programme linéaire est toujours sur un
% sommet du polyèdre des solutions admissibles.
cout = [2; 3];                   % prix des deux aliments
Anutri = [-1 -2; -3 -1];         % besoins, ecrits en <= en changeant le signe
bnutri = [-10; -12];             % au moins 10 et 12 unites
[menu, prix, drapeau] = linprog(cout, Anutri, bnutri, [], [], [0; 0]);
fprintf('\nProgramme lineaire (probleme du menu) :\n');
fprintf('  quantites : %s\n', mat2str(round(menu', 4)));
fprintf('  cout      : %.4f, drapeau %d\n', prix, drapeau);
assert(drapeau > 0, 'le programme doit converger');
assert(all(Anutri * menu <= bnutri + 1e-6), 'les besoins doivent etre couverts');
assert(abs(prix - cout' * menu) < 1e-9);
% Deux contraintes actives sur deux inconnues : la solution est leur
% intersection exacte.
assert(max(abs(Anutri * menu - bnutri)) < 1e-6);

%% 4. Moindres carrés non linéaires
% Ajuster une exponentielle décroissante sur des mesures bruitées. C'est
% le cas d'école de la décroissance radioactive ou de la charge d'un
% condensateur.
t = linspace(0, 5, 60)';
vrai = [3.0, 1.4];               % amplitude et constante de temps
rng(2);
mesures = vrai(1) * exp(-t / vrai(2)) + 0.05 * randn(size(t));
modele = @(p, t) p(1) * exp(-t / p(2));
[parametres, residuel] = lsqcurvefit(modele, [1; 1], t, mesures);
fprintf('\nAjustement d''une exponentielle :\n');
fprintf('  amplitude  %.4f (vraie %.1f)\n', parametres(1), vrai(1));
fprintf('  constante  %.4f (vraie %.1f)\n', parametres(2), vrai(2));
fprintf('  residu     %.6f\n', residuel);
assert(abs(parametres(1) - vrai(1)) < 0.1);
assert(abs(parametres(2) - vrai(2)) < 0.1);
% Le résidu rendu est bien la somme des carrés des écarts.
assert(abs(residuel - sum((modele(parametres, t) - mesures) .^ 2)) < 1e-9);

% Les moindres carrés linéaires avec des bornes.
Alin = [1 1; 1 2; 1 3; 1 4];
blin = [6; 5; 7; 10];
sansBorne = Alin \ blin;
avecBorne = lsqlin(Alin, blin, [], [], [], [], [0; 0], [10; 1]);
fprintf('  moindres carres : libre %s, borne a 1 %s\n', ...
        mat2str(round(sansBorne', 4)), mat2str(round(avecBorne', 4)));
assert(avecBorne(2) <= 1 + 1e-9, 'la borne doit etre respectee');
% Et la version à coefficients positifs.
positif = lsqnonneg(Alin, blin);
assert(all(positif >= -1e-12));

%% 5. Résoudre une équation
% Trouver où une fonction s'annule, en une et en plusieurs dimensions.
racine = fzero(@(x) cos(x) - x, [0 1]);
fprintf('\nEquations :\n');
fprintf('  cos(x) = x  : x = %.10f\n', racine);
assert(abs(cos(racine) - racine) < 1e-10);

systeme = @(x) [x(1) ^ 2 + x(2) ^ 2 - 4; x(1) - x(2)];
solutionSysteme = fsolve(systeme, [1; 1]);
fprintf('  cercle et bissectrice : %s\n', mat2str(round(solutionSysteme', 6)));
assert(max(abs(systeme(solutionSysteme))) < 1e-8);
% Les deux coordonnées valent racine de deux.
assert(max(abs(solutionSysteme - sqrt(2))) < 1e-6);

%% 6. Optimisation globale
% Une fonction à minimums multiples : la descente locale s'arrête au
% premier creux rencontré, la recherche globale les traverse.
multiple = @(x) x .^ 2 / 10 + sin(3 * x) .* cos(x / 2) * 2;
[localDepuisDroite, valeurLocale] = fminsearch(multiple, 6);
grille = linspace(-10, 10, 20001);
[valeurGlobale, kGlobal] = min(multiple(grille));
fprintf('\nMinimums multiples :\n');
fprintf('  depuis x = 6 : x = %.4f, f = %.4f\n', localDepuisDroite, valeurLocale);
fprintf('  vrai minimum : x = %.4f, f = %.4f\n', grille(kGlobal), valeurGlobale);
assert(valeurLocale > valeurGlobale, ...
       'la descente locale ne doit pas trouver le minimum global');
% Un recuit simule, lui, en sort.
rng(4);
[recuit, valeurRecuit] = simulannealbnd(multiple, 6, -10, 10);
fprintf('  par recuit   : x = %.4f, f = %.4f\n', recuit, valeurRecuit);
assert(valeurRecuit < valeurLocale, 'le recuit doit faire mieux que la descente');

fprintf('\nToutes les verifications passent.\n');
