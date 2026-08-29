% test_numerique.m — algèbre linéaire, polynômes, intégration.
disp('--- numerique ---');

A = [4 1; 1 3];
assert(abs(det(A) - 11) < 1e-12);
assert(max(max(abs(A * inv(A) - eye(2)))) < 1e-12);
assert(abs(trace(A) - 7) < 1e-12);
assert(rank(A) == 2);
assert(abs(cond(A) - max(eig(A))/min(eig(A))) < 1e-8);

b = A \ [1; 2];
assert(max(abs(A * b - [1; 2])) < 1e-12);

% Décompositions.
[L, U, P] = lu(A);
assert(max(max(abs(P * A - L * U))) < 1e-12);
[Q, R] = qr(A);
assert(max(max(abs(Q * R - A))) < 1e-10);
assert(max(max(abs(Q' * Q - eye(2)))) < 1e-10);
C = chol(A);
assert(max(max(abs(C' * C - A))) < 1e-10);
[U2, S, V] = svd(A);
assert(max(max(abs(U2 * S * V' - A))) < 1e-9);

% Valeurs propres.
valeurs = sort(eig(A));
assert(abs(valeurs(1) + valeurs(2) - 7) < 1e-10);
assert(abs(valeurs(1) * valeurs(2) - 11) < 1e-10);
[Vp, D] = eig(A);
assert(max(max(abs(A * Vp - Vp * D))) < 1e-9);

% Exponentielle de matrice.
E = expm([0 1; 0 0]);
assert(max(max(abs(E - [1 1; 0 1]))) < 1e-12);

% Normes.
assert(abs(norm([3 4]) - 5) < 1e-12);
assert(abs(norm([1 2; 3 4], 'fro') - sqrt(30)) < 1e-12);
assert(abs(norm([1 -2 3], 1) - 6) < 1e-12);
assert(abs(norm([1 -2 3], inf) - 3) < 1e-12);

% Polynômes.
assert(abs(polyval([1 2 3], 2) - 11) < 1e-12);
r = sort(roots([1 -3 2]));
assert(max(abs(r - [1; 2])) < 1e-10);
assert(max(abs(poly([1 2]) - [1 -3 2])) < 1e-12);
p = polyfit([1 2 3], [2 4 6], 1);
assert(abs(p(1) - 2) < 1e-10);
assert(max(abs(polyder([3 2 1]) - [6 2])) < 1e-12);
assert(max(abs(conv([1 1], [1 -1]) - [1 0 -1])) < 1e-12);

% Interpolation.
assert(abs(interp1([1 2 3], [10 20 30], 2.5) - 25) < 1e-12);
% Hors de l'intervalle : NaN, sauf si on donne 'extrap' ou une valeur.
assert(isnan(interp1([1 2 3], [10 20 30], 4)));
assert(interp1([1 2 3], [10 20 30], 4, 'linear', 0) == 0);
assert(interp1([1 2 3], [10 20 30], 0, 'linear', -1) == -1);
assert(abs(interp1([1 2 3], [10 20 30], 4, 'linear', 'extrap') - 40) < 1e-12);
assert(isnan(interp1([1 2 3], [10 20 30], 0.5, 'nearest')));
assert(interp1([1 2 3], [10 20 30], 0.5, 'nearest', 7) == 7);
assert(interp1([1 2 3], [10 20 30], 1.4, 'nearest') == 10);
assert(abs(spline([0 1 2 3], [0 1 4 9], 1.5) - 2.25) < 0.2);

% Zéros et minimisation.
assert(abs(fzero(@(x) x^2 - 2, [0 2]) - sqrt(2)) < 1e-8);
assert(abs(fminbnd(@(x) (x - 3)^2, 0, 10) - 3) < 1e-6);
xm = fminsearch(@(v) (v(1) - 1)^2 + (v(2) + 2)^2, [0 0]);
assert(abs(xm(1) - 1) < 1e-4 && abs(xm(2) + 2) < 1e-4);

% Intégration.
assert(abs(integral(@(x) x.^2, 0, 3) - 9) < 1e-8);
assert(abs(integral(@(x) sin(x), 0, pi) - 2) < 1e-8);
assert(abs(trapz([0 1 2], [0 1 2]) - 2) < 1e-12);
% Bornes infinies : MATLAB les accepte, par changement de variable. Sans
% cela le milieu de [-Inf, Inf] valait NaN, et la subdivision ne
% s'arretait jamais.
assert(abs(integral(@(x) exp(-x.^2), -Inf, Inf) - sqrt(pi)) < 1e-6);
assert(abs(integral(@(x) 1./(1+x.^2), -Inf, Inf) - pi) < 1e-5);
assert(abs(integral(@(x) exp(-x), 0, Inf) - 1) < 1e-6);
assert(abs(integral(@(x) exp(x), -Inf, 0) - 1) < 1e-6);
assert(abs(quadgk(@(x) exp(-x.^2), -Inf, Inf) - sqrt(pi)) < 1e-6);
% Les bornes finies n'ont pas change.
assert(abs(integral(@sin, 0, pi) - 2) < 1e-8);
assert(abs(integral(@(x) x.^2, 3, 0) + 9) < 1e-8);   % bornes inversees

% Équations différentielles.
[t, y] = ode45(@(t, y) -y, [0 1], 1);
assert(abs(y(end) - exp(-1)) < 1e-5);
[t2, y2] = ode45(@(t, y) [y(2); -y(1)], [0 pi], [0; 1]);
assert(abs(y2(end, 1) - sin(pi)) < 1e-4);

%% ------------------------------------------- equations raides
% Un probleme raide dont on connait la solution exacte : pour
%    y' = L (y - sin t) + cos t,  y(0) = 0,
% la solution est y(t) = sin t quel que soit L. Avec L = -1e4 le probleme
% est franchement raide : un solveur explicite y prend des pas dictes par
% la stabilite, pas par la precision.
L = -1e4;
raide = @(t, y) L * (y - sin(t)) + cos(t);
for nomSolveur = {'ode15s', 'ode23s', 'ode23t', 'ode23tb'}
    [tr, yr] = feval(nomSolveur{1}, raide, [0 2*pi], 0);
    assert(tr(1) == 0 && abs(tr(end) - 2*pi) < 1e-12);
    assert(max(abs(yr - sin(tr))) < 1e-5);
    % Un solveur implicite doit y arriver en bien moins de pas qu'ode45.
    assert(numel(tr) < 6000);
end
% ode45 sur le meme probleme prend des milliers de pas : c'est la
% definition d'un probleme raide.
[t45, y45] = ode45(raide, [0 2*pi], 0);
assert(numel(t45) > 10000);
[t15, ~] = ode15s(raide, [0 2*pi], 0);
assert(numel(t15) < numel(t45) / 10);

% Systeme lineaire 2x2 a solution exacte : y' = [-2 1; 1 -2] y,
% y(0) = [1;0] donne y = [(e^-t + e^-3t)/2 ; (e^-t - e^-3t)/2].
A = [-2 1; 1 -2];
for nomSolveur = {'ode15s', 'ode23s', 'ode23t', 'ode23tb'}
    [tl, yl] = feval(nomSolveur{1}, @(t, y) A * y, [0 5], [1; 0]);
    exact1 = 0.5 * (exp(-tl) + exp(-3*tl));
    exact2 = 0.5 * (exp(-tl) - exp(-3*tl));
    assert(max(abs(yl(:, 1) - exact1)) < 1e-4);
    assert(max(abs(yl(:, 2) - exact2)) < 1e-4);
end

% Instants demandes : la sortie suit exactement le vecteur donne.
[td, yd] = ode15s(@(t, y) -y, [0 0.25 0.5 1], 1);
assert(isequal(size(yd), [4 1]));
assert(max(abs(td(:) - [0; 0.25; 0.5; 1])) < 1e-12);
assert(abs(yd(end) - exp(-1)) < 1e-4);

% Sortie a une seule variable : la structure de solution de MATLAB.
sol = ode23s(@(t, y) -y, [0 1], 1);
assert(isfield(sol, 'x') && isfield(sol, 'y'));
assert(abs(sol.y(end) - exp(-1)) < 1e-5);

% Les tolerances passees par odeset sont prises en compte : plus lache,
% moins de pas.
lache = odeset('RelTol', 1e-3, 'AbsTol', 1e-5);
[tLache, ~] = ode15s(raide, [0 2*pi], 0, lache);
[tSerre, ~] = ode15s(raide, [0 2*pi], 0, odeset('RelTol', 1e-9, 'AbsTol', 1e-12));
assert(numel(tLache) < numel(tSerre));
assert(abs(odeget(lache, 'RelTol') - 1e-3) < 1e-15);
assert(isempty(odeget(lache, 'MaxStep')));
assert(odeget(lache, 'MaxStep', 7) == 7);

% Robertson : cinetique chimique tres raide. La somme des especes est un
% invariant exact du systeme ; on la verifie sur toute la trajectoire.
robertson = @(t, y) [-0.04*y(1) + 1e4*y(2)*y(3);
                      0.04*y(1) - 1e4*y(2)*y(3) - 3e7*y(2)^2;
                      3e7*y(2)^2];
[tRob, yRob] = ode15s(robertson, [0 1e5], [1; 0; 0]);
assert(max(abs(sum(yRob, 2) - 1)) < 1e-6);
assert(all(diff(yRob(:, 3)) >= -1e-12));      % y3 ne peut que croitre
assert(all(yRob(:, 2) >= -1e-12));            % ni y2 devenir negatif
assert(yRob(end, 3) > 0.98 && yRob(end, 1) < 0.02);

% Van der Pol raide, mu = 1000 : l'exemple de reference. Deux solveurs
% independants doivent tomber sur la meme valeur finale.
mu = 1000;
vdp = @(t, y) [y(2); mu*(1 - y(1)^2)*y(2) - y(1)];
[~, yv] = ode15s(vdp, [0 3000], [2; 0]);
[~, yv2] = ode23s(vdp, [0 3000], [2; 0]);
assert(abs(yv(end, 1) - yv2(end, 1)) < 1e-2);
assert(abs(yv(end, 1) + 1.5106) < 1e-2);

%% ------------------------------------------- options des solveurs d'EDO
% odeset accepte n'importe quelle casse, et fusionne avec des options
% existantes ; odeget lit de même.
optionsCasse = odeset('reltol', 1e-8, 'ABSTOL', 1e-10);
assert(isfield(optionsCasse, 'RelTol') && isfield(optionsCasse, 'AbsTol'));
assert(odeget(optionsCasse, 'reltol') == 1e-8);
optionsFusion = odeset(optionsCasse, 'MaxStep', 0.01);
assert(odeget(optionsFusion, 'RelTol') == 1e-8);
assert(odeget(optionsFusion, 'MaxStep') == 0.01);
assert(odeget(optionsFusion, 'Refine', 4) == 4);

%% ------------------------------------------------ sortie dense et deval
% Le pas interne d'ode45 est raffiné : les points intermédiaires sont
% aussi justes que les extrémités, ce qu'une corde ne donnerait pas.
[tDense, yDense] = ode45(@(t, y) -y, [0 1], 1);
assert(max(abs(yDense - exp(-tDense))) < 1e-7);
[tBrut, yBrut] = ode45(@(t, y) -y, [0 1], 1, odeset('Refine', 1));
assert(numel(tDense) > 3 * numel(tBrut));
assert(max(abs(yBrut - exp(-tBrut))) < 1e-7);
% Instants imposés : la solution y est interpolée, pas recalculée.
[tImposes, yImposes] = ode45(@(t, y) -y, [0 0.25 0.5 0.75 1], 1);
assert(isequal(size(yImposes), [5 1]));
assert(max(abs(yImposes - exp(-tImposes))) < 1e-7);
% deval évalue la solution partout, à la précision de l'intégration.
solutionDense = ode45(@(t, y) -y, [0 1], 1);
instantsFins = linspace(0, 1, 17);
assert(max(abs(deval(solutionDense, instantsFins) - exp(-instantsFins))) < 1e-7);
assert(abs(deval(solutionDense, 0.5) - exp(-0.5)) < 1e-7);
solutionSysteme = ode45(@(t, y) [y(2); -y(1)], [0 2*pi], [0; 1]);
assert(max(abs(deval(solutionSysteme, pi/2) - [1; 0])) < 1e-6);
assert(abs(deval(solutionSysteme, pi/2, 1) - 1) < 1e-6);
% Même chose pour un solveur implicite, par interpolation d'Hermite.
solutionRaide = ode15s(@(t, y) -y, [0 1], 1, odeset('RelTol', 1e-10, 'AbsTol', 1e-12));
assert(max(abs(deval(solutionRaide, instantsFins) - exp(-instantsFins))) < 1e-8);
[tRaideImposes, yRaideImposes] = ode15s(@(t, y) -y, linspace(0, 1, 11), 1, ...
                                        odeset('RelTol', 1e-10, 'AbsTol', 1e-12));
assert(max(abs(yRaideImposes - exp(-tRaideImposes))) < 1e-8);

%% ---------------------------------------------------------- événements
% Chute libre : la balle touche le sol à sqrt(2h/g), et l'intégration
% s'arrête là. L'instant est trouvé sur l'interpolant, pas au pas près.
optionsChute = odeset('Events', @evenementSol, 'RelTol', 1e-9, 'AbsTol', 1e-12);
[tChute, ~, tContact, yContact, iContact] = ode45(@(t, y) [y(2); -9.81], [0 10], [10; 0], optionsChute);
assert(abs(tContact - sqrt(2 * 10 / 9.81)) < 1e-8);
assert(abs(yContact(1)) < 1e-9);
assert(abs(yContact(2) + sqrt(2 * 9.81 * 10)) < 1e-6);
assert(iContact == 1);
assert(abs(tChute(end) - tContact) < 1e-12);
% Événement non terminal : les passages par zéro d'un sinus sont tous
% relevés, et seulement eux.
optionsZero = odeset('Events', @evenementZero, 'RelTol', 1e-10, 'AbsTol', 1e-12);
[~, ~, instantsZero] = ode45(@(t, y) [y(2); -y(1)], [0 10], [0; 1], optionsZero);
assert(numel(instantsZero) == 3);
assert(max(abs(instantsZero' - [pi 2*pi 3*pi])) < 1e-7);
% Le sens de traversée filtre : une fois sur deux.
[~, ~, instantsMontants] = ode45(@(t, y) [y(2); -y(1)], [0 10], [0; 1], ...
                                 odeset('Events', @evenementMontant, 'RelTol', 1e-10));
assert(numel(instantsMontants) == 1);
assert(abs(instantsMontants - 2*pi) < 1e-6);
% Les solveurs implicites détectent les événements de la même façon.
optionsSeuil = odeset('Events', @evenementSeuil, 'RelTol', 1e-9, 'AbsTol', 1e-12);
for nomSolveurEvenement = {'ode15s', 'ode23t', 'ode23tb'}
    [tSeuil, ~, tDemi, yDemi] = feval(nomSolveurEvenement{1}, @(t, y) -y, [0 5], 1, optionsSeuil);
    assert(abs(tDemi - log(2)) < 1e-7);
    assert(abs(yDemi - 0.5) < 1e-8);
    assert(abs(tSeuil(end) - tDemi) < 1e-12);
end

%% --------------------------------------- masse, jacobienne, motif creux
% M y' = f : la solution est y = exp(-t/M) composante par composante.
matriceMasse = [2 0; 0 4];
solutionMasse = ode45(@(t, y) [-y(1); -y(2)], [0 1], [1; 1], ...
                      odeset('Mass', matriceMasse, 'RelTol', 1e-10, 'AbsTol', 1e-12));
valeurMasse = deval(solutionMasse, 1);
assert(max(abs(valeurMasse - [exp(-0.5); exp(-0.25)])) < 1e-8);
[~, yMasseRaide] = ode15s(@(t, y) [-y(1); -y(2)], [0 1], [1; 1], ...
                          odeset('Mass', matriceMasse, 'RelTol', 1e-10, 'AbsTol', 1e-12));
assert(max(abs(yMasseRaide(end, :) - [exp(-0.5) exp(-0.25)])) < 1e-8);
% Jacobienne fournie, en fonction ou en constante : même solution.
coefficientRaide = -1e4;
problemeRaide = @(t, y) coefficientRaide * (y - sin(t)) + cos(t);
[tJacobienne, yJacobienne] = ode15s(problemeRaide, [0 2*pi], 0, ...
                                    odeset('Jacobian', @(t, y) coefficientRaide));
assert(max(abs(yJacobienne - sin(tJacobienne))) < 1e-5);
[tConstante, yConstante] = ode15s(problemeRaide, [0 2*pi], 0, ...
                                  odeset('Jacobian', coefficientRaide));
assert(max(abs(yConstante - sin(tConstante))) < 1e-5);
% JPattern : le résultat ne change pas, mais la jacobienne se calcule par
% groupes de colonnes disjointes. Sur un tridiagonal, trois groupes
% suffisent pour vingt colonnes.
tailleTridiagonale = 20;
matriceTridiagonale = -2 * eye(tailleTridiagonale) + ...
                      diag(ones(tailleTridiagonale - 1, 1), 1) + ...
                      diag(ones(tailleTridiagonale - 1, 1), -1);
motifCreux = double(matriceTridiagonale ~= 0);
etatInitialTridiagonal = sin((1:tailleTridiagonale)' * pi / (tailleTridiagonale + 1));
optionsSerrees = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
[~, ySansMotif] = ode15s(@(t, y) matriceTridiagonale * y, [0 1], etatInitialTridiagonal, optionsSerrees);
[~, yAvecMotif] = ode15s(@(t, y) matriceTridiagonale * y, [0 1], etatInitialTridiagonal, ...
                         odeset(optionsSerrees, 'JPattern', motifCreux));
assert(max(abs(ySansMotif(end, :) - yAvecMotif(end, :))) < 1e-12);
solutionExacte = expm(matriceTridiagonale) * etatInitialTridiagonal;
assert(max(abs(yAvecMotif(end, :)' - solutionExacte)) < 1e-7);

disp('numerique : toutes les verifications passent');

function [valeur, arret, sens] = evenementSol(t, y)
%EVENEMENTSOL La balle touche le sol quand sa hauteur s'annule en
%   descendant.
    valeur = y(1);
    arret = 1;
    sens = -1;
end

function [valeur, arret, sens] = evenementZero(t, y)
    valeur = y(1);
    arret = 0;
    sens = 0;
end

function [valeur, arret, sens] = evenementMontant(t, y)
    valeur = y(1);
    arret = 0;
    sens = 1;
end

function [valeur, arret, sens] = evenementSeuil(t, y)
    valeur = y(1) - 0.5;
    arret = 1;
    sens = 0;
end
