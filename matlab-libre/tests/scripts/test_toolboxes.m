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
assert(isequal(medfilt1([1 5 2], 3), [3 2 3.5]));
assert(max(abs(idct(dct([1 2 3 4])) - [1; 2; 3; 4])) < 1e-10);
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
x = symvar('x');
f = sympow(x, symnum(3));
assert(abs(symeval(symdiff(f, 'x'), {'x'}, 2) - 12) < 1e-12);
assert(strcmp(symstr(symint(x, 'x')), '((x ^ 2) / 2)'));

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

disp('toolboxes : toutes les verifications passent');
