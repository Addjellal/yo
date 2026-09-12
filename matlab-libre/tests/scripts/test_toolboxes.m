% test_toolboxes.m — une vérification au moins par toolbox.
%
% Le but n'est pas de tout couvrir mais de garantir que chaque module se
% charge et donne un résultat juste sur un cas dont la valeur exacte est
% connue.
disp('--- toolboxes ---');

% MATLAB de base
assert(nextpow2(1000) == 10);
assert(size(perms([1 2 3]), 1) == 6);
assert(abs(vecnorm([3; 4]) - 5) < 1e-12);

% Signal Processing
b = fir1(8, 0.5);
assert(numel(b) == 9);
assert(abs(sum(b) - 1) < 1e-9);
[bb, aa] = butter(2, 0.2);
assert(abs(bb(1) - 0.0675) < 1e-3);
assert(abs(aa(2) + 1.1430) < 1e-3);
% MEDFILT1 complete la fenetre par des zeros aux bords, comme MATLAB :
% la fenetre garde sa longueur, et le filtre reste invariant par
% decalage. « truncate » raccourcit la fenetre a la place.
assert(isequal(medfilt1([1 5 2], 3), [1 2 2]));
assert(isequal(medfilt1([1 100 1], 3), [1 1 1]));
assert(isequal(medfilt1([1 5 2], 3, 'truncate'), [3 2 3.5]));
assert(iscolumn(medfilt1([1; 5; 2], 3)));
% DCT et IDCT gardent l'orientation, comme FFT.
assert(max(abs(idct(dct([1 2 3 4])) - [1 2 3 4])) < 1e-10);
assert(isrow(dct([1 2 3 4])) && iscolumn(dct([1; 2; 3; 4])));
assert(max(abs(idct(dct([1; 2; 3; 4])) - [1; 2; 3; 4])) < 1e-10);
assert(abs(rms([3 4]) - sqrt(12.5)) < 1e-12);

% DSP System
assert(max(abs(fftfilt([1 1], [1 2 3 4]) - filter([1 1], 1, [1 2 3 4]))) < 1e-10);
[coefficients, erreur] = lpc([1 2 3 2 1 2 3 2], 2);
assert(coefficients(1) == 1);

% Control System
G = tf(1, [1 2 1]);
assert(abs(dcgain(G) - 1) < 1e-12);
assert(max(abs(sort(pole(G)) - [-1; -1])) < 1e-9);
[m, p] = bode(G, 1);
assert(abs(m - 0.5) < 1e-9 && abs(p + 90) < 1e-9);
[A, B, C, D] = tf2ss(1, [1 2 1]);
K = place(A, B, [-2 -3]);
assert(max(abs(sort(eig(A - B * K)) - [-3; -2])) < 1e-9);

% Robust Control
assert(abs(hinfnorm(tf(1, [1 0.5 1])) - 2.0656) < 1e-2);

% System Identification
donnees = iddata(filter([0 0.5], [1 -0.8], ones(100, 1)), ones(100, 1));
modele = arx(donnees, [1 1 1]);
assert(abs(modele.A(2) + 0.8) < 1e-6);

% Model Predictive Control
controleur = mpcSetup(0.9, 0.1, 1, 10, 3, 1, 0.01);
[y, u] = mpcsim(controleur, 1, 60);
assert(abs(y(end) - 1) < 0.1);

% Statistics and Machine Learning
assert(abs(zscore([1 2 3])(1) + 1) < 1e-12);
assert(abs(iqr([1 2 3 4]) - 2) < 0.6);
[etiquettes, centres] = kmeans([1 1; 1.2 1; 5 5; 5.2 5], 2, 'Start', [1 1; 5 5]);
assert(etiquettes(1) == etiquettes(2) && etiquettes(3) == etiquettes(4));
assert(etiquettes(1) ~= etiquettes(3));
assert(abs(regress([2; 4; 6], [1; 2; 3]) - 2) < 1e-12);
M = confusionmat([1 1 2 2], [1 2 2 2]);
assert(M(1, 1) == 1 && M(2, 2) == 2);
arbre = fitctree([1; 2; 8; 9], [1; 1; 2; 2]);
assert(isequal(predicttree(arbre, [1.5; 8.5]), [1; 2]));

% Optimization
assert(isequal(bintprog([-3; -2; -1], [1 1 1], 2), [1; 1; 0]));
xq = quadprog([2 0; 0 2], [-2; -4]);
assert(abs(xq(1) - 1) < 1e-3 && abs(xq(2) - 2) < 1e-3);

% Global Optimization
xp = particleswarm(@(v) (v(1) - 2)^2, 1, -5, 5, 20, 60);
assert(abs(xp(1) - 2) < 1e-2);

% Curve Fitting
p = fitCurve([1 2 3 4], [2 4 6 8], 'poly', 1);
assert(abs(p(1) - 2) < 1e-9);
stats = goodnessOfFit([1 2 3], [1 2 3]);
assert(abs(stats.R2 - 1) < 1e-12);

% Image Processing
image = zeros(20, 20);
image(6:14, 6:14) = 1;
assert(abs(graythresh(image) - 0.5) < 0.05);
[etiquettes2, nombre] = bwlabel(imbinarize(image));
assert(nombre == 1);
assert(sum(sum(edge(image))) > 0);
assert(isequal(size(imresize(image, 0.5)), [10 10]));

% Computer Vision
coins = detectHarrisFeatures(image);
assert(size(coins, 1) == 4);
assert(abs(bboxOverlapRatio([0 0 2 2], [0 0 2 2]) - 1) < 1e-12);

% Deep Learning
rng(1);
X = [0 0 1 1; 0 1 0 1];
Y = [1 0 0 1; 0 1 1 0];
couches = {fullyConnectedLayer(6), tanhLayer(), fullyConnectedLayer(2), softmaxLayer()};
reseau = trainNetwork(X, Y, couches, trainingOptions('sgdm', 'MaxEpochs', 400, ...
                                                     'InitialLearnRate', 0.3, ...
                                                     'MiniBatchSize', 4));
assert(isequal(classify(reseau, X).', [1 2 2 1]));

% Text Analytics
mots = tokenizedDocument('Le chat dort.');
assert(numel(mots) == 3);
assert(editDistance('chat', 'chats') == 1);

% Wavelet
[approximation, detail] = dwt([1 2 3 4], 'haar');
assert(max(abs(idwt(approximation, detail, 'haar') - [1 2 3 4])) < 1e-10);

% Fuzzy Logic
assert(abs(trimf(2, [1 2 3]) - 1) < 1e-12);

% Communications
symboles = pskmod([0 1 2 3], 4);
assert(isequal(pskdemod(symboles, 4), [0 1 2 3]));
code = convenc([1 0 1 1 0 0], [7 5], 3);
assert(isequal(vitdec(code, [7 5], 3), [1 0 1 1 0 0]));
assert(abs(berawgn(6, 'psk', 2) - 0.00239) < 1e-4);

% Wireless
signal = ofdmMod([1; 1i; -1; -1i], 8);
assert(max(abs(ofdmDemod(signal, 8, 1, 4) - [1; 1i; -1; -1i])) < 1e-10);

% Phased Array
assert(abs(abs(steeringVector(4, 0.5, 0)(2)) - 1) < 1e-12);

% RF
assert(abs(vswr(z2gamma(75, 50)) - 1.5) < 1e-12);

% Antenna
assert(abs(friis(1, 1, 1, 1, 1) - (1/(4*pi))^2) < 1e-15);

% Radar
assert(abs(range2time(150, 3e8) - 1e-6) < 1e-12);

% Aerospace
[T, a, P, rho] = atmosisa(0);
assert(abs(T - 288.15) < 1e-6);
assert(abs(P - 101325) < 1);
assert(abs(rho - 1.225) < 1e-3);

% Navigation
assert(abs(haversine(0, 0, 0, 1) - 111194.9) < 1);
grille = zeros(5, 5);
[chemin, cout] = astar(grille, [1 1], [5 5]);
assert(cout == 8);

% Automated Driving
assert(timeToCollision(10, 2) == 5);
assert(isinf(timeToCollision(10, -2)));

% Robotics
R = eul2rotm([0.3 0.2 0.1]);
assert(max(abs(rotm2eul(R) - [0.3 0.2 0.1])) < 1e-12);
assert(max(max(abs(quat2rotm(rotm2quat(R)) - R))) < 1e-12);
[x, y] = fkine2R([0.5 0.5], 1, 1);
assert(max(abs(ikine2R(x, y, 1, 1) - [0.5 0.5])) < 1e-9);

% Sensor Fusion
[etat, P2] = kalmanFilter([0; 0], eye(2), [1; 1], eye(2), eye(2), 0.01 * eye(2), 0.1 * eye(2));
assert(etat(1) > 0.8 && etat(1) < 1);

% Lidar
points = pointCloudFromRanges([1 1], [0 pi/2]);
assert(abs(points(1, 1) - 1) < 1e-12 && abs(points(2, 2) - 1) < 1e-12);

% Bioinformatics
assert(strcmp(seqrcomplement('ATGC'), 'GCAT'));
assert(strcmp(nt2aa('ATGGCCTAA'), 'MA*'));
assert(abs(gcContent('GGCCAT') - 2/3) < 1e-12);

% Econometrics
rng(11);
serie = filter(1, [1 -0.6], randn(400, 1));
phi = arfit(serie, 1);
assert(abs(phi - 0.6) < 0.15);

% Financial
[call, put] = blsprice(100, 100, 0.05, 1, 0.2);
assert(abs(call - 10.4506) < 1e-3);
assert(abs(put - 5.5735) < 1e-3);
assert(abs(irr([-100 60 60]) - 0.13066) < 1e-4);

% Financial Instruments
assert(abs(bondprice(0.05, 0.06, 10) - 107.7217) < 1e-3);
[macaulay, modifiee] = bonddur(0.05, 0.06, 10);
assert(abs(macaulay - 7.8921) < 1e-3);

% Risk Management
assert(abs(valueAtRisk([-0.05 0.02 0.01 -0.03 0.04], 0.95) - 0.05) < 1e-9);

% Predictive Maintenance
descripteurs = faultFeatures(sin(2 * pi * (0:99) / 20));
assert(abs(descripteurs.rms - 1/sqrt(2)) < 1e-2);

% Reinforcement Learning
env = gridworld(3, 3, [3 3]);
Q = qlearning(env, 200);
assert(max(max(Q)) > 0);

% Medical Imaging
assert(abs(diceIndex([1 1 0], [1 1 0]) - 1) < 1e-12);

% Mapping
[distance, cap] = distanceGC(0, 0, 0, 1);
assert(abs(distance - 111194.9) < 1);

% Vehicle
etat = bicycleModel([0 0 0], 10, 0, 2.5, 0.1);
assert(abs(etat(1) - 1) < 1e-12);

% PDE
[u, xg, tg] = heat1D(@(x) sin(pi * x), 1, 1, 0.1, 20, 50);
assert(abs(max(u(:, end)) - exp(-pi^2 * 0.1)) < 5e-3);
solution = fem1D(@(x) 1, 1, 20);
assert(abs(max(solution) - 0.125) < 1e-2);

% Symbolic Math
x = matlibre_sym_variable('x');
f = sympow(x, symnum(3));
assert(abs(symeval(symdiff(f, 'x'), {'x'}, 2) - 12) < 1e-12);
assert(strcmp(symstr(symint(x, 'x')), 'x^2/2'));

% L'objet symbolique : les operateurs construisent l'expression, et les
% fonctions de MATLAB la manipulent.
syms t u
assert(strcmp(class(t), 'sym'));
expressionSym = t ^ 3 - 2 * t;
assert(strcmp(char(diff(expressionSym)), '3*t^2 - 2'));
assert(strcmp(char(diff(expressionSym, t, 2)), '6*t'));
assert(double(subs(expressionSym, t, 2)) == 4);
assert(abs(double(int(expressionSym, t, 0, 1)) + 0.75) < 1e-12);
% Le developpement et les coefficients.
assert(isequal(sym2poly(expand((t + 1) * (t - 1))), [1 0 -1]));
assert(isequal(sym2poly(expand((t + 2) ^ 3)), [1 6 12 8]));
assert(strcmp(char(simplify(t - t)), '0'));
assert(strcmp(char(simplify(t + t)), '2*t'));
% POLY2SYM et SYM2POLY se defont l'un l'autre.
assert(isequal(sym2poly(poly2sym([1 0 -4])), [1 0 -4]));
assert(isequal(sym2poly(poly2sym([2 -3 0 5], u), u), [2 -3 0 5]));
% Les racines d'une equation polynomiale.
racinesSym = solve(t ^ 2 - 4);
assert(numel(racinesSym) == 2);
assert(abs(double(racinesSym{1}) + 2) < 1e-12);
assert(abs(double(racinesSym{2}) - 2) < 1e-12);
assert(abs(double(solve(3 * t - 6)) - 2) < 1e-12);
% La variable sous-entendue est la plus proche de x.
syms a x
assert(strcmp(char(symvar(a * x ^ 2, 1)), 'x'));
assert(strcmp(char(diff(a * x ^ 2)), 'a*2*x') || ...
       strcmp(char(diff(a * x ^ 2)), '2*a*x') || ...
       abs(double(subs(subs(diff(a * x ^ 2), a, 3), x, 2)) - 12) < 1e-12);
% Les derivees des fonctions elementaires.
assert(strcmp(char(diff(sin(x))), 'cos(x)'));
assert(abs(double(subs(diff(exp(2 * x)), x, 0)) - 2) < 1e-12);
assert(abs(double(subs(diff(log(x)), x, 2)) - 0.5) < 1e-12);

% Taylor : les coefficients sont ceux des derivees successives.
coefficientsTaylor = fliplr(sym2poly(taylor(exp(x), x, 0, 5)));
for kTaylor = 0:4
    assert(abs(coefficientsTaylor(kTaylor + 1) - 1 / factorial(kTaylor)) < 1e-12);
end
serieDecalee = taylor(exp(x), x, 1, 3);
assert(abs(double(subs(serieDecalee, x, 1)) - exp(1)) < 1e-12);
% Le developpement de sin n'a que des termes impairs.
coefficientsSinus = fliplr(sym2poly(taylor(sin(x), x, 0, 6)));
assert(abs(coefficientsSinus(1)) < 1e-15 && abs(coefficientsSinus(3)) < 1e-15);
assert(abs(coefficientsSinus(2) - 1) < 1e-12);
assert(abs(coefficientsSinus(4) + 1/6) < 1e-12);

% Limites : les cas d'ecole, y compris ceux qu'une substitution directe
% ne donne pas.
assert(abs(double(limit(sin(x) / x, x, 0)) - 1) < 1e-6);
assert(abs(double(limit((1 - cos(x)) / x ^ 2, x, 0)) - 0.5) < 1e-5);
assert(abs(double(limit(log(1 + x) / x, x, 0)) - 1) < 1e-6);
assert(abs(double(limit((1 + 1 / x) ^ x, x, Inf)) - exp(1)) < 1e-3);
assert(double(limit(x ^ 2, x, 3)) == 9);

% Jacobienne, hessienne, et le theoreme de Schwarz.
jacobienneSym = jacobian({x * a, x + a}, {x, a});
assert(strcmp(char(jacobienneSym{1, 1}), 'a'));
assert(strcmp(char(jacobienneSym{1, 2}), 'x'));
assert(strcmp(char(jacobienneSym{2, 1}), '1'));
hessienneSym = hessian(x ^ 2 * a, {x, a});
assert(strcmp(char(hessienneSym{1, 2}), char(hessienneSym{2, 1})));
assert(abs(double(subs(subs(hessienneSym{1, 1}, x, 5), a, 3)) - 6) < 1e-12);

% Le passage au numerique : la poignee accepte un vecteur.
poigneeSym = matlabFunction(diff(x ^ 3));
assert(poigneeSym(2) == 12);
assert(isequal(matlabFunction(x ^ 2 + 1)([1 2 3]), [2 5 10]));
assert(matlabFunction(x - a, 'Vars', {a, x})(1, 5) == 4);

% Sommes et produits sur un intervalle d'entiers.
syms k
assert(double(symsum(k, k, 1, 100)) == 5050);
assert(abs(double(symsum(1 / k ^ 2, k, 1, 1000)) - pi ^ 2 / 6) < 1e-3);
assert(double(symprod(k, k, 1, 6)) == 720);

% Ecritures : lisible, LaTeX, et arrondie.
assert(strcmp(pretty(x ^ 2 + 3 * x - 1), 'x^2 + 3*x - 1'));
assert(strcmp(latex((x + 1) / (x ^ 2)), '\frac{x + 1}{x^{2}}'));
assert(strcmp(char(vpa(sym(1) / 3, 6)), '0.333333'));
assert(abs(double(vpa(sym(2) ^ 10)) - 1024) < 1e-12);

% Parallel Computing
futur = parfeval(@(a, b) a + b, 1, 2, 3);
assert(fetchOutputs(futur) == 5);
assert(numlabs() == 1);

% Database
table = dbTable({'ville', 'montant'});
table = dbInsert(table, {'Paris', 10});
table = dbInsert(table, {'Lyon', 5});
table = dbInsert(table, {'Paris', 7});
[cles, sommes] = dbGroupSum(table, 'ville', 'montant');
assert(sommes(1) == 17);

% Data Acquisition
session = daq();
session = addAnalogInput(session, 'v', @(t) 2 * t);
[donnees, temps] = readData(session, 5);
assert(abs(donnees(3) - 2 * temps(3)) < 1e-12);

% Instrument Control
instrument = visadev('SIM::1');
[reponse, instrument] = query(instrument, '*IDN?');
assert(~isempty(strfind(reponse, 'MatLibre')));

% Audio
son = 0.5 * sin(2 * pi * 440 * (0:999) / 8000);
assert(abs(spectralCentroid(son, 8000) - 440) < 5);
fichier = [tempname() '.wav'];
audiowrite(fichier, son, 8000);
[relu, fs] = audioread(fichier);
assert(fs == 8000);
assert(max(abs(relu(:) - son(:))) < 1e-4);
delete(fichier);

% Simulink
modele = new_system('essai');
modele = add_block(modele, 'step', 'entree', 'Time', 0, 'After', 1);
modele = add_block(modele, 'transferfcn', 'systeme', 'Numerator', 1, 'Denominator', [1 1]);
modele = add_line(modele, 'entree', 'systeme', 1);
resultat = sim(modele, 5, 0.01);
assert(abs(resultat.signaux.systeme(end) - (1 - exp(-5))) < 2e-2);
% La forme « structure with time » que journalise Simulink : c'est celle
% que lisent les scripts ecrits pour lui.
assert(numel(resultat.time) == numel(resultat.temps));
assert(numel(resultat.signals) == 2);
assert(abs(resultat.signals(2).values(end) - resultat.signaux.systeme(end)) < 1e-12);
assert(strcmp(resultat.signals(2).label, 'systeme'));
% « sim » accepte aussi le nom d'un modele pose dans l'espace de travail.
resultatParNom = sim('modele', 5, 0.01);
assert(abs(resultatParNom.signaux.systeme(end) - resultat.signaux.systeme(end)) < 1e-12);
% Et il dit clairement ce qui manque quand le modele est introuvable, au
% lieu d'echouer sur une indexation par point.
introuvable = false;
try
    sim('modeleQuiNExistePas', 5);                       %#ok<VUNUS>
catch e
    introuvable = strcmp(e.identifier, 'Simulink:Commands:OpenSystemUnknownSystem');
end
assert(introuvable);

% Stateflow
machine = sfchart('bascule');
machine = sfstate(machine, 'bas');
machine = sfstate(machine, 'haut');
machine = sftransition(machine, 'bas', 'haut', @(contexte, u) u > 0.5);
machine = sftransition(machine, 'haut', 'bas', @(contexte, u) u < -0.5);
historique = sfrun(machine, [0 1 0 -1 0]);
assert(strcmp(historique{2}, 'haut'));
assert(strcmp(historique{4}, 'bas'));

% Simscape
c = circuit('diviseur');
c = addVoltageSource(c, 1, 0, 10);
c = addResistor(c, 1, 2, 1000);
c = addResistor(c, 2, 0, 1000);
tensions = solveDC(c);
assert(abs(tensions(2) - 5) < 1e-9);

% MATLAB Coder
resultat = codegen('carreDeTest', '-args', {0}, '-report');
assert(~isempty(strfind(resultat.source, 'double carreDeTest(double x)')));
assert(~isempty(strfind(resultat.source, 'return')));
assert(~isempty(strfind(resultat.entete, 'double carreDeTest(double x);')));

%% ------------------------------------ optimisation par expressions
% L'écriture par problème : on décrit ce qu'on veut, les matrices sont
% assemblées pour nous. On vérifie l'assemblage, puis la solution.
variable = optimvar('x', 2, 'LowerBound', 0);
probleme = optimproblem('Objective', -variable(1) - 2 * variable(2));
probleme.Constraints.c1 = variable(1) + variable(2) <= 4;
probleme.Constraints.c2 = variable(1) + 3 * variable(2) <= 6;
assemblage = prob2struct(probleme);
assert(strcmp(assemblage.solver, 'linprog'));
assert(isequal(assemblage.f, [-1; -2]));
assert(isequal(assemblage.Aineq, [1 1; 1 3]));
assert(isequal(assemblage.bineq, [4; 6]));
[solution, valeur] = solve(probleme);
assert(max(abs(solution.x - [3; 1])) < 1e-3);
assert(abs(valeur + 5) < 1e-3);
% Le sens « maximize » rend bien le maximum.
problemeMax = optimproblem('Objective', variable(1) + 2 * variable(2), ...
                           'ObjectiveSense', 'maximize');
problemeMax.Constraints.c1 = variable(1) + variable(2) <= 4;
problemeMax.Constraints.c2 = variable(1) + 3 * variable(2) <= 6;
[~, valeurMax] = solve(problemeMax);
assert(abs(valeurMax - 5) < 1e-3);
% Une variable entière change de solveur.
entiere = optimvar('y', 2, 'LowerBound', 0, 'Type', 'integer');
problemeEntier = optimproblem('Objective', -entiere(1) - 2 * entiere(2));
problemeEntier.Constraints.c = entiere(1) + 3 * entiere(2) <= 7;
problemeEntier.Constraints.d = entiere(1) + entiere(2) <= 4;
assert(strcmp(prob2struct(problemeEntier).solver, 'intlinprog'));
[solutionEntiere, valeurEntiere] = solve(problemeEntier);
assert(max(abs(solutionEntiere.y - round(solutionEntiere.y))) < 1e-6);
assert(abs(valeurEntiere + 5) < 1e-6);
% Un produit de deux expressions donne un objectif quadratique.
scalaire = optimvar('z', 1);
problemeCarre = optimproblem('Objective', (scalaire - 3) * (scalaire - 3));
assemblageCarre = prob2struct(problemeCarre);
assert(strcmp(assemblageCarre.solver, 'quadprog'));
assert(abs(assemblageCarre.H - 2) < 1e-12 && abs(assemblageCarre.f + 6) < 1e-12);
assert(abs(assemblageCarre.constante - 9) < 1e-12);
solutionCarre = solve(problemeCarre);
assert(abs(solutionCarre.z - 3) < 1e-3);
% Une égalité se range du bon côté.
positive = optimvar('w', 2, 'LowerBound', 0);
problemeEgalite = optimproblem('Objective', positive(1) + positive(2));
problemeEgalite.Constraints.e = positive(1) + 2 * positive(2) == 4;
assemblageEgalite = prob2struct(problemeEgalite);
assert(isequal(assemblageEgalite.Aeq, [1 2]) && isequal(assemblageEgalite.beq, 4));
[~, valeurEgalite] = solve(problemeEgalite);
assert(abs(valeurEgalite - 2) < 1e-2);

%% --------------------------------------------- cônes du second ordre
% Le point du disque unité le plus loin dans la direction (1,1) : c'est
% la bissectrice, à la distance racine de deux.
disque = secondordercone(eye(2), [0; 0], [0; 0], -1);
[pointCone, valeurCone, drapeauCone] = coneprog([-1; -1], disque);
assert(abs(norm(pointCone) - 1) < 1e-3);
assert(abs(valeurCone + sqrt(2)) < 1e-3);
assert(drapeauCone == 1);
% Le cône de Lorentz : minimiser x3 sous ||(x1,x2)|| <= x3 et x1 = 1.
lorentz = secondordercone([1 0 0; 0 1 0], [0; 0], [0; 0; 1], 0);
pointLorentz = coneprog([0; 0; 1], lorentz, [], [], [1 0 0], 1);
assert(abs(pointLorentz(3) - 1) < 1e-2);

%% ------------------------------- bornes infinies en programmation
% Une borne infinie n'en est pas une : la barrière logarithmique la
% prenait au mot et figeait la descente.
[pointBorne, valeurBorne] = linprog([-1; -2], [1 1; 1 3], [4; 6], ...
                                    zeros(0, 2), zeros(0, 1), [0; 0], [Inf; Inf]);
assert(max(abs(pointBorne(:) - [3; 1])) < 1e-3);
assert(abs(valeurBorne + 5) < 1e-3);


% FFTFILT garde l'orientation, et donne exactement FILTER.
rng(31);
signalFft = randn(2048, 1);
filtreFft = fir1(48, 0.35);
assert(iscolumn(fftfilt(filtreFft, signalFft)));
assert(isrow(fftfilt(filtreFft, signalFft.')));
assert(max(abs(fftfilt(filtreFft, signalFft) - filter(filtreFft, 1, signalFft))) < 1e-10);
% LPC rend la variance de l'erreur, non sa somme : elle ne doit pas
% dependre de la longueur du signal.
rng(32);
courtLpc = filter(1, [1 -1.5 0.7], randn(500, 1));
longLpc = filter(1, [1 -1.5 0.7], randn(4000, 1));
[aCourt, eCourt] = lpc(courtLpc, 2);
[aLong, eLong] = lpc(longLpc, 2);
assert(max(abs(aCourt - [1 -1.5 0.7])) < 0.1);
assert(abs(eCourt - var(filter(aCourt, 1, courtLpc))) / eCourt < 0.15);
assert(abs(eLong / eCourt - 1) < 0.3, ...
       'la variance de l''erreur ne depend pas de la longueur');
% Le predicteur rendu par Levinson est toujours stable.
assert(all(abs(roots(aLong)) < 1));
% LPC n'est que LEVINSON sur l'autocorrelation.
nLpc = numel(courtLpc);
autocorrLpc = arrayfun(@(k) sum(courtLpc(1:nLpc-k) .* courtLpc(1+k:nLpc)) / nLpc, 0:2);
assert(max(abs(levinson(autocorrLpc, 2) - aCourt)) < 1e-10);
disp('fftfilt et lpc : ok');

%% ------------------------------------------ OPEN_SYSTEM : LE SCHEMA
% Le rangement en couches : chaque bloc apres celui qui l'alimente, et
% les liens de rebouclage mis a part pour etre traces en retour.
schema = new_system('boucle');
schema = add_block(schema, 'step', 'consigne', 'Time', 0, 'After', 1);
schema = add_block(schema, 'sum', 'erreur', 'Signs', '+-');
schema = add_block(schema, 'gain', 'correcteur', 'Gain', 4);
schema = add_block(schema, 'integrator', 'sortie', 'InitialCondition', 0);
schema = add_line(schema, 'consigne', 'erreur', 1);
schema = add_line(schema, 'sortie', 'erreur', 2);
schema = add_line(schema, 'erreur', 'correcteur');
schema = add_line(schema, 'correcteur', 'sortie');

[rangs, retours] = matlibre_sl_rangs(schema);
assert(isequal(rangs, [0 1 2 3]), 'la chaine se range de la source vers la sortie');
assert(size(retours, 1) == 1, 'la contre-reaction est le seul lien de retour');
assert(isequal(retours(1, 1:2), [4 2]), 'elle va de la sortie vers la sommation');

% La disposition met chaque couche a sa place, de la gauche vers la droite.
[xSchema, ySchema, largeurBloc, hauteurBloc] = matlibre_sl_disposition(schema, rangs);
assert(issorted(xSchema), 'les abscisses suivent les couches');
assert(numel(unique(xSchema)) == 4, 'quatre couches, quatre abscisses');
assert(largeurBloc > 0 && hauteurBloc > 0);

% Un schema sans circuit n'a aucun retour ; un circuit pur en a un.
chaine = new_system('chaine');
chaine = add_block(chaine, 'constant', 'a', 'Value', 1);
chaine = add_block(chaine, 'gain', 'b', 'Gain', 2);
chaine = add_line(chaine, 'a', 'b');
[~, sansRetour] = matlibre_sl_rangs(chaine);
assert(isempty(sansRetour));

% Le rang est le plus long chemin, non le plus court : un bloc alimente a
% la fois par la source et par le bout de la chaine se place au bout.
losange = new_system('losange');
losange = add_block(losange, 'constant', 'entree', 'Value', 1);
losange = add_block(losange, 'gain', 'court', 'Gain', 1);
losange = add_block(losange, 'gain', 'long1', 'Gain', 1);
losange = add_block(losange, 'gain', 'long2', 'Gain', 1);
losange = add_block(losange, 'sum', 'fin', 'Signs', '++');
losange = add_line(losange, 'entree', 'court');
losange = add_line(losange, 'entree', 'long1');
losange = add_line(losange, 'long1', 'long2');
losange = add_line(losange, 'court', 'fin', 1);
losange = add_line(losange, 'long2', 'fin', 2);
rangsLosange = matlibre_sl_rangs(losange);
assert(rangsLosange(5) == 3, 'la sommation attend la plus longue branche');

% Ce que chaque bloc affiche : le reglage, non le type.
assert(strcmp(matlibre_sl_etiquette(schema.blocs{3}), '4'));
assert(strcmp(matlibre_sl_etiquette(schema.blocs{4}), '1/s'));
assert(strcmp(matlibre_sl_etiquette(struct('type', 'delay', 'parametres', struct())), '1/z'));
assert(strcmp(matlibre_sl_etiquette(struct('type', 'derivative', 'parametres', struct())), 'du/dt'));
assert(strcmp(matlibre_sl_signes(schema.blocs{2}), '+-'));
assert(strcmp(matlibre_sl_signes(struct('parametres', struct())), '++'), ...
       'une sommation sans signe declare additionne');

% Le trace lui-meme : il produit une figure, et les formes y sont.
figure;
poigneeSchema = open_system(schema);
assert(strcmp(class(poigneeSchema), 'matlab.ui.Figure'));
dessin = matlibre_svg();
assert(~isempty(strfind(dessin, 'consigne')), 'les noms de blocs sont ecrits');
assert(~isempty(strfind(dessin, '1/s')), 'l''integrateur porte sa transmittance');
assert(~isempty(strfind(dessin, 'boucle')), 'le titre est le nom du modele');
assert(~isempty(strfind(dessin, '<path')), 'les triangles et les pointes sont traces');

% Un modele qui n'en est pas un est refuse.
refuseModele = false;
try
    open_system(42);
catch err
    refuseModele = strcmp(err.identifier, 'Simulink:openSystem:Modele');
end
assert(refuseModele);
close all;

%% ------------------------------ SIMULINK : L'ORDRE DE CALCUL
% Un bloc a transmission directe doit etre calcule apres son entree, meme
% s'il est declare avant elle. Le tri les distinguait par un seuil sur le
% code du type, qui rangeait « math », « derivative » et une
% representation d'etat a D non nul parmi les blocs a memoire : leur
% sortie retardait alors d'un pas.
ordreCarre = new_system('ordre');
ordreCarre = add_block(ordreCarre, 'math', 'carre', 'Operator', 'square');
ordreCarre = add_block(ordreCarre, 'ramp', 'r', 'Slope', 1);
ordreCarre = add_line(ordreCarre, 'r', 'carre');
resOrdre = sim(ordreCarre, 0.05, 0.01);
assert(max(abs(resOrdre.signaux.carre - resOrdre.temps .^ 2)) < 1e-12, ...
       'le carre suit sa source dans le meme pas');

ordreDerive = new_system('ordre2');
ordreDerive = add_block(ordreDerive, 'derivative', 'd');
ordreDerive = add_block(ordreDerive, 'ramp', 'rd', 'Slope', 3);
ordreDerive = add_line(ordreDerive, 'rd', 'd');
resDerive = sim(ordreDerive, 0.05, 0.01);
assert(max(abs(resDerive.signaux.d(2:end) - 3)) < 1e-12, ...
       'la derivee d''une rampe de pente 3 vaut 3');

ordreEtat = new_system('ordre3');
ordreEtat = add_block(ordreEtat, 'statespace', 'ss1', 'A', 0, 'B', 0, 'C', 0, 'D', 2);
ordreEtat = add_block(ordreEtat, 'constant', 'un', 'Value', 5);
ordreEtat = add_line(ordreEtat, 'un', 'ss1');
resEtat = sim(ordreEtat, 0.02, 0.01);
assert(max(abs(resEtat.signaux.ss1 - 10)) < 1e-12, ...
       'D non nul transmet l''entree a l''instant meme');

% Un bloc sans transmission directe casse bien la boucle : il est le seul
% a pouvoir etre calcule avant son entree.
boucleFermee = new_system('boucleFermee');
boucleFermee = add_block(boucleFermee, 'constant', 'c', 'Value', 1);
boucleFermee = add_block(boucleFermee, 'sum', 'e', 'Signs', '+-');
boucleFermee = add_block(boucleFermee, 'integrator', 'x');
boucleFermee = add_line(boucleFermee, 'c', 'e', 1);
boucleFermee = add_line(boucleFermee, 'x', 'e', 2);
boucleFermee = add_line(boucleFermee, 'e', 'x');
resBoucle = sim(boucleFermee, 5, 1e-3);
assert(abs(resBoucle.signaux.x(end) - (1 - exp(-5))) < 1e-3, ...
       'x'' = 1 - x tend vers un');

% Un type de bloc inconnu passait sans bruit et rendait un resultat faux.
typeRefuse = false;
try
    sim(add_block(new_system('t'), 'chose', 'b'), 1, 0.1);
catch err
    typeRefuse = strcmp(err.identifier, 'Simulink:Commands:InvalidBlockType');
end
assert(typeRefuse, 'un bloc de type inconnu est refuse, non ignore');

%% ------------------------------ SIMULINK : LES BLOCS SANS MEMOIRE
sansMemoire = new_system('statique');
sansMemoire = add_block(sansMemoire, 'ramp', 'u', 'Slope', 1);
sansMemoire = add_block(sansMemoire, 'deadzone', 'zm', ...
                        'LowerValue', -0.5, 'UpperValue', 0.5);
sansMemoire = add_block(sansMemoire, 'quantizer', 'q', 'QuantizationInterval', 0.25);
sansMemoire = add_block(sansMemoire, 'sign', 'sg');
sansMemoire = add_block(sansMemoire, 'bias', 'b', 'Bias', 3);
sansMemoire = add_block(sansMemoire, 'trigonometry', 'tr', 'Operator', 'tanh');
sansMemoire = add_block(sansMemoire, 'lookup', 'tab', ...
                        'BreakpointsData', [0 1 2], 'TableData', [0 10 30]);
for cible = {'zm', 'q', 'sg', 'b', 'tr', 'tab'}
    sansMemoire = add_line(sansMemoire, 'u', cible{1});
end
resStatique = sim(sansMemoire, 2, 0.01);
tStatique = resStatique.temps;

% Zone morte : nulle dans la bande, et continue a ses deux bords.
attenduZone = zeros(size(tStatique));
attenduZone(tStatique > 0.5) = tStatique(tStatique > 0.5) - 0.5;
assert(max(abs(resStatique.signaux.zm - attenduZone)) < 1e-12);
assert(all(resStatique.signaux.zm(tStatique <= 0.5) == 0), 'la bande est morte');

% Quantificateur : la sortie est un multiple du pas, jamais plus loin que
% la moitie du pas de l'entree.
assert(max(abs(resStatique.signaux.q / 0.25 - round(resStatique.signaux.q / 0.25))) < 1e-12);
assert(max(abs(resStatique.signaux.q - tStatique)) <= 0.125 + 1e-12);

assert(all(resStatique.signaux.sg(tStatique > 0) == 1) && resStatique.signaux.sg(1) == 0);
assert(max(abs(resStatique.signaux.b - (tStatique + 3))) < 1e-12);
assert(max(abs(resStatique.signaux.tr - tanh(tStatique))) < 1e-12);

% Table : exacte aux points donnes, lineaire entre eux, tenue au-dela.
assert(abs(resStatique.signaux.tab(1) - 0) < 1e-12);
assert(abs(interp1(tStatique, resStatique.signaux.tab, 0.5) - 5) < 1e-9);
assert(abs(resStatique.signaux.tab(end) - 30) < 1e-12, 'au-dela, la valeur est tenue');

% Aiguillage, comparaison et logique : trois entrees, un critere.
aiguillage = new_system('aiguillage');
aiguillage = add_block(aiguillage, 'constant', 'a', 'Value', 10);
aiguillage = add_block(aiguillage, 'ramp', 'sel', 'Slope', 1);
aiguillage = add_block(aiguillage, 'constant', 'c', 'Value', -10);
aiguillage = add_block(aiguillage, 'switch', 'sw', 'Threshold', 0.5);
aiguillage = add_block(aiguillage, 'relational', 'cmp', 'Operator', '>');
aiguillage = add_block(aiguillage, 'constant', 'demi', 'Value', 0.5);
aiguillage = add_block(aiguillage, 'logic', 'nonPas', 'Operator', 'NOT');
aiguillage = add_line(aiguillage, 'a', 'sw', 1);
aiguillage = add_line(aiguillage, 'sel', 'sw', 2);
aiguillage = add_line(aiguillage, 'c', 'sw', 3);
aiguillage = add_line(aiguillage, 'sel', 'cmp', 1);
aiguillage = add_line(aiguillage, 'demi', 'cmp', 2);
aiguillage = add_line(aiguillage, 'cmp', 'nonPas', 1);
resAiguillage = sim(aiguillage, 1, 0.01);
tAig = resAiguillage.temps;
assert(all(resAiguillage.signaux.sw(tAig >= 0.5) == 10), 'au-dessus du seuil, u1');
assert(all(resAiguillage.signaux.sw(tAig < 0.5) == -10), 'au-dessous, u3');
assert(all(resAiguillage.signaux.cmp == double(tAig > 0.5)));
assert(all(resAiguillage.signaux.nonPas == 1 - resAiguillage.signaux.cmp), ...
       'NOT retourne exactement la comparaison');

%% ------------------------------ SIMULINK : LES BLOCS A MEMOIRE
memoireEtRetard = new_system('memoire');
memoireEtRetard = add_block(memoireEtRetard, 'ramp', 'r', 'Slope', 1);
memoireEtRetard = add_block(memoireEtRetard, 'memory', 'mem', 'InitialCondition', 0);
memoireEtRetard = add_block(memoireEtRetard, 'transportdelay', 'td', ...
                            'DelayTime', 0.5, 'InitialOutput', 0);
memoireEtRetard = add_block(memoireEtRetard, 'ratelimiter', 'rl', ...
                            'RisingSlewLimit', 0.5, 'FallingSlewLimit', -0.5, ...
                            'InitialOutput', 0);
memoireEtRetard = add_line(memoireEtRetard, 'r', 'mem');
memoireEtRetard = add_line(memoireEtRetard, 'r', 'td');
memoireEtRetard = add_line(memoireEtRetard, 'r', 'rl');
resMemoire = sim(memoireEtRetard, 1, 0.01);
tMem = resMemoire.temps;

% Memoire : la valeur du pas precedent, exactement.
assert(resMemoire.signaux.mem(1) == 0);
assert(max(abs(resMemoire.signaux.mem(2:end) - tMem(1:end-1))) < 1e-12);

% Retard pur : y(t) = u(t - 0,5), et la sortie initiale avant cela.
assert(all(resMemoire.signaux.td(tMem < 0.5 - 1e-9) == 0));
avecRetard = tMem >= 0.5;
assert(max(abs(resMemoire.signaux.td(avecRetard) - (tMem(avecRetard) - 0.5))) < 1e-12, ...
       'le retard decale le signal, il ne le deforme pas');

% Limiteur de pente : devant une rampe plus rapide que sa limite, il ne
% la rattrape jamais et monte a sa propre pente.
assert(max(diff(resMemoire.signaux.rl)) <= 0.5 * 0.01 + 1e-12);
assert(max(abs(resMemoire.signaux.rl - 0.5 * tMem)) < 1e-12, ...
       'la sortie monte a la limite, non a la pente de l''entree');

% Devant un echelon, il monte a sa limite puis rattrape et tient.
echelonLimite = new_system('echelonLimite');
echelonLimite = add_block(echelonLimite, 'step', 'e', 'Time', 0, 'After', 1);
echelonLimite = add_block(echelonLimite, 'ratelimiter', 'rl', ...
                          'RisingSlewLimit', 2, 'FallingSlewLimit', -2, ...
                          'InitialOutput', 0);
echelonLimite = add_line(echelonLimite, 'e', 'rl');
resEchelon = sim(echelonLimite, 1, 0.01);
assert(max(diff(resEchelon.signaux.rl)) <= 2 * 0.01 + 1e-12, ...
       'la pente reste sous la limite');
assert(abs(resEchelon.signaux.rl(end) - 1) < 1e-12, 'et la sortie rattrape l''entree');
assert(any(resEchelon.signaux.rl < 1), 'sans y arriver du premier coup');

%% ------------------------------ SIMULINK : LES BLOCS ECHANTILLONNES
% Tenue d'ordre zero : la sortie ne change qu'aux instants
% d'echantillonnage, et vaut alors l'entree.
tenue = new_system('tenue');
tenue = add_block(tenue, 'ramp', 'r', 'Slope', 1);
tenue = add_block(tenue, 'zoh', 'z', 'SampleTime', 0.1);
tenue = add_line(tenue, 'r', 'z');
resTenue = sim(tenue, 1, 0.01);
paliers = unique(round(resTenue.signaux.z * 1e9) / 1e9);
assert(numel(paliers) == 11, 'onze paliers de zero a un');
assert(max(abs(paliers(:)' - (0:0.1:1))) < 1e-8);
assert(all(diff(resTenue.signaux.z) >= -1e-12), 'la tenue ne redescend pas');

% Integrateur discret : les trois methodes se distinguent exactement, sur
% une entree constante, par ce qu'elles font de l'echantillon courant.
constante = 2;
periode = 0.05;
for essai = {{'ForwardEuler', 0}, {'BackwardEuler', periode}, ...
             {'Trapezoidal', periode / 2}}
    methode = essai{1}{1};
    decalage = essai{1}{2};
    integ = new_system('integ');
    integ = add_block(integ, 'constant', 'c', 'Value', constante);
    integ = add_block(integ, 'discreteintegrator', 'i', 'SampleTime', periode, ...
                      'IntegratorMethod', methode, 'InitialCondition', 0);
    integ = add_line(integ, 'c', 'i');
    resInteg = sim(integ, 0.5, periode);
    attendu = constante * (resInteg.temps + decalage);
    assert(max(abs(resInteg.signaux.i - attendu)) < 1e-12, ...
           sprintf('%s integre une constante exactement', methode));
end

% Fonction de transfert discrete 1/(z - a) : la reponse indicielle
% analytique, (1 - a^n)/(1 - a).
a = 0.6;
filtre = new_system('filtre');
filtre = add_block(filtre, 'constant', 'un', 'Value', 1);
filtre = add_block(filtre, 'discretetransferfcn', 'h', ...
                   'Numerator', [0 1], 'Denominator', [1 -a], 'SampleTime', 0.1);
filtre = add_line(filtre, 'un', 'h');
resFiltre = sim(filtre, 1, 0.1);
n = (0:numel(resFiltre.temps) - 1)';
assert(max(abs(resFiltre.signaux.h - (1 - a .^ n) / (1 - a))) < 1e-12, ...
       'la reponse indicielle suit la formule fermee');

% Representation d'etat discrete : x(k+1) = 0,5 x(k) + u, y = x.
etatD = new_system('etatD');
etatD = add_block(etatD, 'constant', 'un', 'Value', 1);
etatD = add_block(etatD, 'discretestatespace', 'sd', 'A', 0.5, 'B', 1, ...
                  'C', 1, 'D', 0, 'X0', 0, 'SampleTime', 0.1);
etatD = add_line(etatD, 'un', 'sd');
resEtatD = sim(etatD, 1, 0.1);
nD = (0:numel(resEtatD.temps) - 1)';
assert(max(abs(resEtatD.signaux.sd - 2 * (1 - 0.5 .^ nD))) < 1e-12);

% PID : sur une erreur constante, la sortie est la somme des trois
% termes, dont l'integral croit lineairement.
regulateur = new_system('pid');
regulateur = add_block(regulateur, 'constant', 'e', 'Value', 1);
regulateur = add_block(regulateur, 'pidcontroller', 'k', 'P', 2, 'I', 3, ...
                       'D', 0, 'N', 100);
regulateur = add_line(regulateur, 'e', 'k');
resPid = sim(regulateur, 1, 1e-3);
assert(max(abs(resPid.signaux.k - (2 + 3 * resPid.temps))) < 1e-9, ...
       'proportionnel plus integral, sans derivee');
avecDerivee = set_param(regulateur, 'k', 'D', 0.1, 'I', 0);
resDeriv = sim(avecDerivee, 0.5, 1e-3);
assert(abs(resDeriv.signaux.k(1) - (2 + 0.1 * 100)) < 1e-9, ...
       'a l''instant zero, la derivee filtree vaut D*N');
assert(abs(resDeriv.signaux.k(end) - 2) < 1e-3, ...
       'la derivee d''une constante s''eteint');

% Un derivateur filtre refuse un N nul : il ne se calculerait pas.
refuseN = false;
try
    sim(add_block(new_system('n'), 'pidcontroller', 'p', 'N', 0), 1, 0.1);
catch err
    refuseN = strcmp(err.identifier, 'simulink:sim:filtreDerive');
end
assert(refuseN);

%% ------------------------------ SIMULINK : MODIFIER UN MODELE
edition = new_system('edition');
edition = add_block(edition, 'constant', 'c', 'Value', 1);
edition = add_block(edition, 'gain', 'g', 'Gain', 2);
edition = add_block(edition, 'integrator', 'i');
edition = add_line(edition, 'c', 'g');
edition = add_line(edition, 'g', 'i');
assert(strcmp(getfullname(edition, 'g'), 'edition/g'));
assert(strcmp(getfullname(edition), 'edition'));
assert(strcmp(bdroot(edition), 'edition'));

% Retirer un bloc emporte ses liens, et renumerote ceux qui restent.
sansGain = delete_block(edition, 'g');
assert(numel(sansGain.blocs) == 2 && isempty(sansGain.liens), ...
       'les deux liens touchaient au gain');
sansMilieu = delete_block(add_line(edition, 'c', 'i', 2), 'g');
assert(size(sansMilieu.liens, 1) == 1, 'le lien qui ne touche pas au gain survit');
assert(isequal(sansMilieu.liens(1, 1:2), [1 2]), ...
       'l''integrateur a recule d''un rang');

% Retirer un lien qui n'existe pas est refuse, non ignore.
sansLien = delete_line(edition, 'c', 'g');
assert(size(sansLien.liens, 1) == 1);
refuseLien = false;
try
    delete_line(edition, 'i', 'c');
catch err
    refuseLien = strcmp(err.identifier, 'simulink:delete_line:lienInconnu');
end
assert(refuseLien);

% Remplacer un type garde le cablage et les noms.
discret = replace_block(edition, 'integrator', 'discreteintegrator', ...
                        'SampleTime', 0.1);
assert(strcmp(get_param(discret, 'i', 'BlockType'), 'discreteintegrator'));
assert(get_param(discret, 'i', 'SampleTime') == 0.1);
assert(isequal(discret.liens, edition.liens), 'le cablage n''a pas bouge');

%% ------------------------------ SIMULINK : LES REGLAGES DU MODELE
regle = new_system('regle');
regle = add_block(regle, 'constant', 'c', 'Value', 3);
regle = add_param(regle, 'StopTime', 2, 'FixedStep', 0.5);
assert(get_param(regle, 'StopTime') == 2);
resRegle = sim(regle);
assert(resRegle.temps(end) == 2 && numel(resRegle.temps) == 5, ...
       'SIM lit la duree et le pas portes par le modele');
% Un argument donne l'emporte sur le reglage enregistre.
resForce = sim(regle, 1, 0.25);
assert(resForce.temps(end) == 1 && numel(resForce.temps) == 5);

regle = set_param(regle, 'StopTime', 4);
assert(get_param(regle, 'StopTime') == 4, 'SET_PARAM a un seul couple regle le modele');
regle = delete_param(regle, 'StopTime');
assert(~isfield(regle.parametres, 'StopTime'));
refuseReglage = false;
try
    delete_param(regle, 'StopTime');
catch err
    refuseReglage = strcmp(err.identifier, 'Simulink:Commands:DeleteParamAbsent');
end
assert(refuseReglage);
refuseDouble = false;
try
    add_param(add_param(new_system('d'), 'StopTime', 1), 'StopTime', 2);
catch err
    refuseDouble = strcmp(err.identifier, 'Simulink:Commands:AddParamExiste');
end
assert(refuseDouble);

% Les options de SIMSET tiennent lieu de pas, et une option non honoree
% est refusee plutot qu'acceptee sans effet.
options = simset('FixedStep', 0.25);
assert(simget(options, 'FixedStep') == 0.25);
assert(isempty(simget(simset(), 'FixedStep')));
resOptions = sim(add_block(new_system('o'), 'constant', 'c', 'Value', 1), 1, options);
assert(numel(resOptions.temps) == 5);
refuseOption = false;
try
    simset('RelTol', 1e-6);
catch err
    refuseOption = strcmp(err.identifier, 'Simulink:Commands:SimsetInconnue');
end
assert(refuseOption);

%% ------------------------------ SIMULINK : ENREGISTRER ET RELIRE
aRanger = new_system('aRanger');
aRanger = add_block(aRanger, 'constant', 'c', 'Value', 7);
aRanger = add_block(aRanger, 'gain', 'g', 'Gain', [1 2; 3 4]);
aRanger = add_block(aRanger, 'sum', 's', 'Signs', '+-');
aRanger = add_line(aRanger, 'c', 's', 1);
aRanger = add_line(aRanger, 'g', 's', 2);
aRanger = add_param(aRanger, 'StopTime', 3);
fichierModele = [tempname() '.m'];
chemin = save_system(aRanger, fichierModele);
relu = load_system(chemin);
assert(strcmp(relu.nom, aRanger.nom));
assert(numel(relu.blocs) == numel(aRanger.blocs));
assert(isequal(relu.liens, aRanger.liens), 'le cablage se relit tel quel');
assert(isequal(get_param(relu, 'g', 'Gain'), [1 2; 3 4]), ...
       'une matrice se relit matrice');
assert(strcmp(get_param(relu, 's', 'Signs'), '+-'));
assert(get_param(relu, 'StopTime') == 3, 'le reglage du modele se relit aussi');
bdclose('all');
delete(chemin);

% Ce que SAVE_SYSTEM ne sait pas ecrire, il le refuse en le nommant.
refuseValeur = false;
try
    save_system(add_block(new_system('x'), 'gain', 'g', 'Gain', {1}), ...
                [tempname() '.m']);
catch err
    refuseValeur = strcmp(err.identifier, 'Simulink:Commands:SaveUnsupported');
end
assert(refuseValeur);

%% ------------------------------ SIMULINK : LE REGISTRE DE LA SESSION
bdclose('all');
assert(isempty(gcs()), 'aucun modele ouvert, aucun nom');
inscrit = new_system('inscrit');
inscrit = add_block(inscrit, 'constant', 'c', 'Value', 1);
assert(~bdIsLoaded('inscrit'), 'construire n''est pas ouvrir');
open_system(inscrit);
assert(bdIsLoaded('inscrit') && strcmp(gcs(), 'inscrit'));
close_system(inscrit);
assert(~bdIsLoaded('inscrit') && isempty(gcs()));
open_system(inscrit);
open_system(add_block(new_system('second'), 'constant', 'c', 'Value', 1));
assert(strcmp(gcs(), 'second'), 'GCS nomme le dernier ouvert');
bdclose('all');
assert(isempty(gcs()));
close all;

%% ------------------------------ SIMULINK : LINEARISATION
% Un modele lineaire se linearise exactement : la derivee centree d'une
% fonction affine est cette fonction, a l'arrondi pres.
oscillateur = new_system('oscillateur');
oscillateur = add_block(oscillateur, 'inport', 'u', 'Port', 1);
oscillateur = add_block(oscillateur, 'sum', 's', 'Signs', '+-');
oscillateur = add_block(oscillateur, 'integrator', 'v');
oscillateur = add_block(oscillateur, 'integrator', 'p');
oscillateur = add_block(oscillateur, 'gain', 'k', 'Gain', 4);
oscillateur = add_block(oscillateur, 'outport', 'y', 'Port', 1);
oscillateur = add_line(oscillateur, 'u', 's', 1);
oscillateur = add_line(oscillateur, 'k', 's', 2);
oscillateur = add_line(oscillateur, 's', 'v');
oscillateur = add_line(oscillateur, 'v', 'p');
oscillateur = add_line(oscillateur, 'p', 'k');
oscillateur = add_line(oscillateur, 'p', 'y');
[Alin, Blin, Clin, Dlin] = linmod(oscillateur);
assert(max(max(abs(Alin - [0 -4; 1 0]))) < 1e-8, 'la matrice d''etat');
assert(max(abs(Blin - [1; 0])) < 1e-8);
assert(max(abs(Clin - [0 1])) < 1e-8);
assert(abs(Dlin) < 1e-12);

% Les valeurs propres disent la pulsation propre : deux integrateurs et
% un gain de 4 oscillent a 2 rad/s.
assert(max(abs(sort(imag(eig(Alin))) - [-2; 2])) < 1e-7);

% Une seule sortie demandee rend la structure, comme dans MATLAB.
structure = linmod(oscillateur);
assert(isstruct(structure) && isfield(structure, 'a'));
assert(isequal(structure.StateName, {'v', 'p'}));
assert(isequal(structure.InputName, {'u'}) && isequal(structure.OutputName, {'y'}));

% Un derivateur est refuse : sa linearisation dependrait du pas de calcul.
refuseDerivateur = false;
try
    linmod(add_block(oscillateur, 'derivative', 'd'));
catch err
    refuseDerivateur = strcmp(err.identifier, 'Simulink:Commands:LinmodDerivateur');
end
assert(refuseDerivateur);

% Premier ordre : x' = u - x. La discretisation exacte vaut exp(-Ts).
premier = new_system('premier');
premier = add_block(premier, 'inport', 'u', 'Port', 1);
premier = add_block(premier, 'sum', 's', 'Signs', '+-');
premier = add_block(premier, 'integrator', 'x');
premier = add_block(premier, 'outport', 'y', 'Port', 1);
premier = add_line(premier, 'u', 's', 1);
premier = add_line(premier, 'x', 's', 2);
premier = add_line(premier, 's', 'x');
premier = add_line(premier, 'x', 'y');
[Ac, Bc] = linmod(premier);
assert(abs(Ac + 1) < 1e-8 && abs(Bc - 1) < 1e-8);
[Ad, Bd, Cd, Dd] = dlinmod(premier, 0.5);
assert(abs(Ad - exp(-0.5)) < 1e-8, 'le pole continu se transporte par l''exponentielle');
assert(abs(Bd - (1 - exp(-0.5))) < 1e-8, 'et l''entree par son integrale');
assert(abs(Cd - 1) < 1e-8 && abs(Dd) < 1e-12);
assert(abs(dlinmod(premier, 0).a + 1) < 1e-8, 'une periode nulle rend le continu');

% Le point d'equilibre de x' = u - x, a u tenu a 1, est x = 1.
[xEq, uEq, yEq, dxEq] = trim(premier, 0, 1, [], [], 1, []);
assert(abs(xEq - 1) < 1e-9 && abs(uEq - 1) < 1e-12);
assert(abs(yEq - 1) < 1e-9 && abs(dxEq) < 1e-9, ...
       'un equilibre se reconnait a ce que la derivee y est nulle');

% Le nombre d'etats donne est verifie : un vecteur de la mauvaise taille
% donnerait une matrice sans rapport avec le modele.
refuseTaille = false;
try
    linmod(premier, [0 0], 0);
catch err
    refuseTaille = strcmp(err.identifier, 'Simulink:Commands:LinmodEtat');
end
assert(refuseTaille);

% Une saturation se linearise par sa pente locale : un dans la bande,
% zero au-dela.
sature = new_system('sature');
sature = add_block(sature, 'inport', 'u', 'Port', 1);
sature = add_block(sature, 'saturation', 'sat', 'UpperLimit', 1, 'LowerLimit', -1);
sature = add_block(sature, 'integrator', 'x');
sature = add_block(sature, 'outport', 'y', 'Port', 1);
sature = add_line(sature, 'u', 'sat');
sature = add_line(sature, 'sat', 'x');
sature = add_line(sature, 'x', 'y');
[~, Bdans] = linmod(sature, 0, 0.5);
[~, Bdehors] = linmod(sature, 0, 5);
assert(abs(Bdans - 1) < 1e-6, 'dans la bande, la saturation transmet');
assert(abs(Bdehors) < 1e-6, 'au-dela, elle ne transmet plus rien');

% Une fonction de transfert porte ses etats : LINMOD retrouve exactement
% la realisation de TF2SS, et donc les poles du denominateur.
transmittance = new_system('transmittance');
transmittance = add_block(transmittance, 'inport', 'u', 'Port', 1);
transmittance = add_block(transmittance, 'transferfcn', 'h', ...
                          'Numerator', 1, 'Denominator', [1 3 2]);
transmittance = add_block(transmittance, 'outport', 'y', 'Port', 1);
transmittance = add_line(transmittance, 'u', 'h');
transmittance = add_line(transmittance, 'h', 'y');
[Ah, Bh, Ch, Dh] = linmod(transmittance);
[Aref, Bref, Cref, Dref] = tf2ss(1, [1 3 2]);
assert(max(max(abs(Ah - Aref))) < 1e-8 && max(abs(Bh - Bref)) < 1e-8);
assert(max(abs(Ch - Cref)) < 1e-8 && abs(Dh - Dref) < 1e-12);
assert(max(abs(sort(eig(Ah)) - [-2; -1])) < 1e-7, 'les poles sont ceux du denominateur');

% Et son equilibre : le gain statique vaut 1/2, donc une entree de 6
% donne une sortie de 3.
[~, ~, ySortie] = trim(transmittance, [0; 0], 6, [], [], 1, []);
assert(abs(ySortie - 3) < 1e-8, 'le gain statique du transfert');

% La toile suit les proportions du schema plutot que de rester carree.
[toileLarge, toileHaute] = matlibre_sl_toile(20, 5);
assert(abs(toileLarge / toileHaute - 4) < 0.05);
[carreeL, carreeH] = matlibre_sl_toile(4, 3);
assert(carreeL == 800 && carreeH == 600, 'un petit schema garde la toile par defaut');
[borneeL, borneeH] = matlibre_sl_toile(200, 10);
assert(borneeL <= 2000 && borneeH <= 1400, 'une toile immense est ramenee a l''ecran');
assert(abs(borneeL / borneeH - 20) < 0.05, 'sans deformer le schema');

%% ------------------------------ SIMULINK : L'ESPACE DE TRAVAIL PARTAGE
% Un paramètre donne par une expression vaut ce que vaut l'espace de
% travail au moment ou l'on simule, comme dans Simulink : c'est ce qui
% fait qu'un modele et un programme partagent leurs variables.
gainPartage = 4;
partage = new_system('partage');
partage = add_block(partage, 'constant', 'un', 'Value', 1);
partage = add_block(partage, 'gain', 'k', 'Gain', 'gainPartage');
partage = add_block(partage, 'gain', 'compose', 'Gain', '2 * gainPartage + 1');
partage = add_line(partage, 'un', 'k');
partage = add_line(partage, 'un', 'compose');
resPartage = sim(partage, 0.02, 0.01);
assert(all(resPartage.signaux.k == 4), 'le gain vaut la variable');
assert(all(resPartage.signaux.compose == 9), 'et une expression s''evalue');
gainPartage = 10;
resChange = sim(partage, 0.02, 0.01);
assert(all(resChange.signaux.k == 10), ...
       'changer la variable change la simulation, sans toucher au modele');
assert(isequal(get_param(partage, 'k', 'Gain'), 'gainPartage'), ...
       'et le modele porte toujours l''expression, non sa valeur');

% L'etiquette du schema montre l'expression : elle dit d'ou vient la
% valeur, ce que le nombre ne dirait pas.
assert(strcmp(matlibre_sl_etiquette(partage.blocs{2}), 'gainPartage'));

% Une expression qui ne s'evalue pas, ou qui ne rend pas un nombre, est
% refusee en nommant le bloc et le parametre.
refusExpression = false;
try
    sim(add_block(new_system('x'), 'gain', 'g', 'Gain', 'variableQuiNExistePas'), 1, 0.5);
catch err
    refusExpression = strcmp(err.identifier, 'Simulink:Commands:ParametreNonEvalue');
end
assert(refusExpression);
texteEnGain = 'bonjour';                                        %#ok<NASGU>
refusClasse = false;
try
    sim(add_block(new_system('x'), 'gain', 'g', 'Gain', 'texteEnGain'), 1, 0.5);
catch err
    refusClasse = strcmp(err.identifier, 'Simulink:Commands:ParametreNonNumerique');
end
assert(refusClasse);

% Un bloc « vers l'espace de travail » y depose son signal.
depot = new_system('depot');
depot = add_block(depot, 'ramp', 'r', 'Slope', 3);
depot = add_block(depot, 'toworkspace', 'sortie', 'VariableName', 'releveSimulink');
depot = add_line(depot, 'r', 'sortie');
clear releveSimulink;
resDepot = sim(depot, 0.05, 0.01);
assert(exist('releveSimulink', 'var') == 1, 'la variable est creee');
assert(max(abs(releveSimulink - 3 * resDepot.temps)) < 1e-12, ...
       'et porte le signal releve');

% Et « depuis l'espace de travail » lit une variable a deux colonnes,
% reechantillonnee sur les instants de la simulation.
signalDonne = [(0:0.1:1)', (0:0.1:1)' .^ 2];
lecture = new_system('lecture');
lecture = add_block(lecture, 'fromworkspace', 'src', 'VariableName', 'signalDonne');
lecture = add_block(lecture, 'gain', 'deux', 'Gain', 2);
lecture = add_line(lecture, 'src', 'deux');
resLecture = sim(lecture, 1, 0.1);
assert(max(abs(resLecture.signaux.src - resLecture.temps .^ 2)) < 1e-12, ...
       'aux instants donnes, le signal est celui qu''on a fourni');
assert(max(abs(resLecture.signaux.deux - 2 * resLecture.signaux.src)) < 1e-12);

% Entre deux points donnes, il est interpole ; au-dela, il est tenu.
resFin = sim(lecture, 2, 0.1);
assert(all(abs(resFin.signaux.src(resFin.temps > 1) - 1) < 1e-12), ...
       'passe la fin des donnees, la derniere valeur est tenue');
milieu = sim(lecture, 0.15, 0.05);
assert(abs(milieu.signaux.src(2) - 0.005) < 1e-12, ...
       ['entre deux points donnes, la droite qui les joint : a 0,05, la ' ...
        'moitie de 0 et de 0,01 — non 0,0025, qui serait la parabole dont ' ...
        'les points sont tires']);

% Une variable absente est nommee, plutot que traitee comme un zero.
refusAbsente = false;
try
    sim(add_block(new_system('x'), 'fromworkspace', 's', ...
                  'VariableName', 'signalQuiNExistePas'), 1, 0.5);
catch err
    refusAbsente = strcmp(err.identifier, 'simulink:sim:variableAbsente');
end
assert(refusAbsente);
malForme = 1:5;                                                 %#ok<NASGU>
refusForme = false;
try
    sim(add_block(new_system('x'), 'fromworkspace', 's', 'VariableName', 'malForme'), ...
        1, 0.5);
catch err
    refusForme = strcmp(err.identifier, 'simulink:sim:signalMalForme');
end
assert(refusForme);

disp('toolboxes : toutes les verifications passent');
