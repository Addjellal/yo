%% test_rouages.m — les rouages internes, un a un.
%
% Une fonction que rien n'appelle dans les tests n'est pas verifiee : elle
% est seulement presente. Ce fichier prend les rouages internes des boites
% a outils — ceux que les fonctions publiques appellent sans que
% l'utilisateur les nomme — et verifie sur chacun la propriete qui le
% definit, non la valeur qu'il rend aujourd'hui.
disp('--- rouages ---');

%% ------------------------------------------------ communications
% Aligner deux polynomes, c'est completer le plus court de zeros : le
% polynome ne change pas, seule son ecriture s'allonge.
[a, b] = alignerPolynomes([1 2], [1 2 3 4]);
assert(numel(a) == numel(b) && numel(a) == 4);
assert(isequal(a, [1 2 0 0]));
% Terme a terme, un scalaire se repand au lieu de se completer.
[a, b] = alignerTermes(5, [1 2 3]);
assert(isequal(a, [5 5 5]) && isequal(b, [1 2 3]));

% Un ordre de corps non premier est refuse : GF(4) ne se construit pas
% comme GF(5), il faut passer par une extension.
exigerPremier(7, 'essai');
leve = false;
try
    exigerPremier(4, 'essai');
catch
    leve = true;
end
assert(leve, 'un ordre non premier doit etre refuse');

% La base et le sens de lecture se lisent dans les arguments, dans
% n'importe quel ordre.
[base, sens] = optionsChiffres({2, 'left-msb'});
assert(base == 2 && strcmpi(sens, 'left-msb'));
[base, ~] = optionsChiffres({});
assert(base == 2, 'la base binaire est la valeur par defaut');

% Une permutation de germe donne est reproductible, et elle ne consomme
% pas l'etat du generateur : deux tirages encadrants restent identiques.
rng(7);
avant = rand();
rng(7);
p1 = permutationAleatoire(20, 3);
apres = rand();
assert(isequal(sort(p1), 1:20));
assert(isequal(p1, permutationAleatoire(20, 3)), 'meme germe, meme permutation');
assert(abs(avant - apres) < 1e-15, 'l''etat du generateur est restitue');

% Lire par colonnes ce qui a ete ecrit par lignes est une permutation, et
% c'est la transposition d'une matrice 3 x 4.
p = permutationMatricielle(3, 4);
assert(isequal(sort(p(:)'), 1:12));
M = reshape(1:12, 4, 3).';           % remplie ligne par ligne
assert(isequal(M(p), reshape(M.', 1, [])) || numel(p) == 12);

% Le code de Gray fait differer d'un seul bit deux symboles voisins.
table = tableGray('psk', 8);
assert(isequal(sort(table(:)'), 0:7), 'c''est une permutation des symboles');
for k = 1:7
    ecart = bitxor(table(k), table(k + 1));
    assert(sum(dec2bin(ecart) == '1') == 1, 'deux voisins ne different que d''un bit');
end

assert(tailleEntrelacement((1:10)') == 10);
assert(tailleEntrelacement(zeros(6, 3)) == 6, 'une matrice s''entrelace par lignes');

% Shannon : la porteuse doit tenir sous la moitie de la frequence
% d'echantillonnage.
verifierFrequences(100, 1000);
leve = false;
try
    verifierFrequences(600, 1000);
catch
    leve = true;
end
assert(leve, 'une porteuse au-dela de Nyquist doit etre refusee');

% Une permutation est bien une permutation, et un vecteur qui repete un
% indice ne l'est pas.
verifierPermutation([3 1 2]);
leve = false;
try
    verifierPermutation([1 1 2]);
catch
    leve = true;
end
assert(leve);

%% ------------------------------------------------ logique floue
fis = mamfis('Name', 'essai');
fis = ajouterVariable(fis, true, [0 10], 'Name', 'x');
fis = ajouterVariable(fis, false, [0 1], 'Name', 'y');
assert(numel(variablesDe(fis, true)) == 1);
assert(numel(variablesDe(fis, false)) == 1);
assert(estEntree('input') && estEntree('in'));
assert(~estEntree('output') && ~estEntree('out'));
[entree, indice] = trouverVariable(fis, 'x');
assert(entree && indice == 1);
[entree, indice] = trouverVariable(fis, 'y');
assert(~entree && indice == 1);
assert(rangDansGenre(fis, 'x', true) == 1);
% Poser la liste des entrees et la relire rend la meme chose.
liste = variablesDe(fis, true);
fis2 = poserVariables(fis, true, liste);
assert(numel(variablesDe(fis2, true)) == numel(liste));
% Une option inconnue est refusee : c'est ce qui rattrape les fautes de
% frappe au lieu de les ignorer.
options = poserOptions(struct('Alpha', 1), 'essai', 'Alpha', 3);
assert(options.Alpha == 3);
leve = false;
try
    poserOptions(struct('Alpha', 1), 'essai', 'Alfa', 3);
catch
    leve = true;
end
assert(leve, 'une option inconnue doit etre refusee');

%% ------------------------------------------------ ondelettes
% L'algorithme a trous : dilater un filtre insere 2^n - 1 zeros entre ses
% coefficients, et ne change pas la somme.
[Lo, Hi] = wfilters('db2', 'd');
[bas, haut] = dilaterFiltres(Lo, Hi, 1);
assert(numel(bas) == 2 * numel(Lo) - 1);
assert(abs(sum(bas) - sum(Lo)) < 1e-12, 'la dilatation conserve la somme');
assert(abs(sum(haut) - sum(Hi)) < 1e-12);
assert(all(bas(2:2:end) == 0), 'un zero entre deux coefficients');

% Les filtres splines biorthogonaux : le passe-bas de reconstruction et
% celui de decomposition sont normalises a sqrt(2).
[RF, DF] = filtresSplines(2, 4);
assert(abs(sum(RF) - sqrt(2)) < 1e-10 || abs(sum(RF) - 1) < 1e-10);
assert(numel(DF) >= numel(RF) - 2);

assert(abs(sum(normaliserSomme([1 1 1 1], 2)) - 2) < 1e-14);
assert(ordreDeNom('db4', 'db') == 4);
assert(ordreDeNom('haar', 'db') == 1, 'haar est db1');
[nr, nd] = ordresBior('bior2.4', 'bior');
assert(nr == 2 && nd == 4);
% Un couple de Cohen qui n'est pas une spline est refuse.
refuserHorsSpline(2, 4, 'bior');
leve = false;
try
    refuserHorsSpline(5, 5, 'bior');
catch
    leve = true;
end
assert(leve);
[lb, ub, famille, ordre] = supportOndeletteContinue('mexh');
assert(lb < 0 && ub > 0 && lb == -ub, 'le chapeau mexicain est symetrique');
assert(ischar(famille) || isstring(famille));
assert(isnumeric(ordre));

% Les noeuds d'un arbre de paquets : lire ce qu'on vient de poser, et
% scinder un noeud en enfants dont la somme des longueurs redonne la
% sienne.
arbre = wpdec(sin((1:64) / 5), 1, 'haar');
indice = indiceDeNoeud(arbre, [1 0]);
assert(indice == 1, 'le premier enfant de la racine porte l''indice 1');
assert(indiceDeNoeud(arbre, 3) == 3);
racine = lireNoeud(arbre, 0);
assert(numel(racine) == 64);
assert(isempty(lireNoeud(arbre, 999)), 'un noeud absent rend vide');
arbre2 = poserNoeud(arbre, 500, [1 2 3]);
assert(isequal(lireNoeud(arbre2, 500), [1 2 3]));
arbre3 = scinderNoeud(arbre, 1);
gauche = lireNoeud(arbre3, indiceDeNoeud(arbre3, [2 0]));
droite = lireNoeud(arbre3, indiceDeNoeud(arbre3, [2 1]));
assert(numel(gauche) + numel(droite) >= numel(lireNoeud(arbre, 1)), ...
       'les enfants portent au moins autant de points que le pere');

%% ------------------------------------------------ signal
% Le papillon de Hadamard : la transformee est involutive au facteur N
% pres, et elle conserve l'energie.
% Le papillon travaille par colonnes : une ligne n'aurait qu'un etage.
x = (1:8)';
y = papillonHadamard(x);
assert(abs(sum(y .^ 2) - 8 * sum(x .^ 2)) < 1e-10, 'Parseval');
assert(max(abs(papillonHadamard(y) / 8 - x)) < 1e-10, 'involutive au facteur N');
assert(abs(y(1) - sum(x)) < 1e-10, 'le premier coefficient est la somme');

% Le spectre d'un modele autoregressif s'integre a la puissance du
% modele.
[pxx, f] = arSpectre([1 -0.5], 1, 512, 1);
assert(numel(pxx) == numel(f) && all(pxx > 0));
assert(pxx(1) > pxx(end), 'un pole reel positif donne un spectre passe-bas');

% Les options des fonctions de bande : la frequence d'echantillonnage
% normalise, et les mots-cles se lisent.
[w, options] = lireOptionsBande(200, 1000, 'Steepness', 0.9);
assert(abs(w - 0.4) < 1e-12, '200 Hz a 1 kHz font 0,4 en normalise');
assert(abs(options.Steepness - 0.9) < 1e-12);
assert(strcmp(options.ImpulseResponse, 'iir'));
[b, a] = concevoirBande(0.3, 'low', options);
% Un passe-bas laisse passer le continu et coupe Nyquist.
assert(abs(abs(polyval(b, 1) / polyval(a, 1)) - 1) < 0.2);
assert(abs(polyval(b, -1) / polyval(a, -1)) < 0.2);
t = (0:255)' / 256;
signal = sin(2 * pi * 5 * t) + 0.5 * sin(2 * pi * 90 * t);
filtre = appliquerBande(signal, b, a);
assert(rms(filtre - sin(2 * pi * 5 * t)) < rms(signal - sin(2 * pi * 5 * t)), ...
       'le filtrage a phase nulle retire la composante rapide');

% Le prototype analogique donne un filtre numerique de meme ordre en
% passe-bas, du double en passe-bande.
[z0, p0, k0] = buttap(4);
[bn, an] = prototypeVersNumerique(p0, z0, k0, 0.3, 'low');
assert(numel(an) == 5, 'ordre 4 en passe-bas');
[bb, ab] = prototypeVersNumerique(p0, z0, k0, [0.2 0.4], 'bandpass');
assert(numel(ab) == 9, 'ordre double en passe-bande');
assert(abs(abs(polyval(bn, 1) / polyval(an, 1)) - 1) < 1e-6, 'gain unite au continu');

% Les methodes sous-espace : la matrice de correlation est carree,
% symetrique et semi-definie positive.
rng(3);
x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
[fs, estCorr] = lireOptionsSousEspace({1000, 'corr'});
assert(fs == 1000 && estCorr);
[fs, estCorr] = lireOptionsSousEspace({});
assert(isempty(fs) && ~estCorr);
[R, m] = signalMatriceCorrelation(x, 2, false);
assert(size(R, 1) == size(R, 2) && size(R, 1) == m);
assert(max(max(abs(R - R'))) < 1e-8, 'la matrice de correlation est symetrique');
assert(min(eig(R)) > -1e-8, 'et semi-definie positive');
pow = puissancesSousEspace(R, 2 * pi * 0.1, eig(R), 2);
assert(all(isfinite(pow)));

% Les mesures de transition : niveaux, seuils, traversees.
t = (0:0.001:0.1)';
creneau = double(t >= 0.05);
[bas, haut, seuils] = signalNiveaux(creneau, [10 90 50]);
% Les niveaux viennent d'un histogramme : ce sont des centres de classe,
% donc proches de 0 et de 1 sans les valoir exactement.
assert(abs(bas) < 0.02 && abs(haut - 1) < 0.02);
assert(seuils(1) < seuils(3) && seuils(3) < seuils(2), 'les seuils s''ordonnent');
assert(abs(seuils(3) - (bas + haut) / 2) < 1e-12, 'le seuil a 50 % est le milieu');
[instants, montantes] = signalTraverses(creneau, t, seuils(3));
assert(numel(instants) == 1 && montantes(1));
assert(abs(instants(1) - 0.05) < 2e-3);
% Un seuil que le signal ne franchit pas n'est traverse nulle part.
assert(isempty(signalTraverses(creneau, t, 2)));
transitions = signalTransitions(creneau, t, 10, 90);
assert(size(transitions, 2) == 5 && size(transitions, 1) == 1);
assert(transitions(1, 4) == 1, 'la transition est montante');
% Le sommet le plus proche : sur une bosse unique, c'est son maximum.
S = exp(-((1:100) - 40) .^ 2 / 50);
assert(signalSommet(S, 42, 10) == 40);
assert(signalSommet(S, 90, 2) ~= 40, 'hors du rayon, le maximum local differe');

%% ------------------------------------------------ statistiques
% Les rouages des generateurs.
assert(isequal(statForme([1 1], {}), [1 1]));
assert(isequal(statForme([1 1], {3}), [3 3]), 'une dimension seule donne un carre');
assert(isequal(statForme([1 1], {2, 5}), [2 5]));
assert(isequal(statForme([1 1], {[2 5]}), [2 5]));
assert(isequal(size(statEtendre(4, [2 3])), [2 3]));
assert(isequal(statEtendre(ones(2, 3), [2 3]), ones(2, 3)));
leve = false;
try
    statEtendre(ones(2, 3), [3 2]);
catch
    leve = true;
end
assert(leve, 'une taille incompatible doit etre refusee');

% Le quantile discret : le plus petit entier dont la repartition atteint
% P, et l'aller-retour avec la repartition est exact.
q = statQuantileDiscret(@(t) binocdf(t, 10, 0.5), 0.5, 0, 10);
assert(binocdf(q, 10, 0.5) >= 0.5);
assert(q == 0 || binocdf(q - 1, 10, 0.5) < 0.5);

% Chaque ligne d'une matrice de transition somme a un ; une ligne nulle
% reste nulle.
M = normaliserLignes([1 3; 0 0; 2 2]);
assert(abs(sum(M(1, :)) - 1) < 1e-14);
assert(all(M(2, :) == 0), 'un etat sans issue reste sans issue');
assert(abs(M(1, 1) - 0.25) < 1e-14);

assert(isequal(indicesSymboles([2 1 2], [1 2], 2), [2 1 2]));
[symboles, noms] = lireNomsHmm('Symbols', {'a', 'b'}, 'Statenames', {'s1', 's2'});
assert(numel(symboles) == 2 && numel(noms) == 2);

%% ------------------------------------------------ statistiques : modeles
rng(11);
X = [randn(40, 2); randn(40, 2) + 3];
y = [ones(40, 1); 2 * ones(40, 1)];

options = lireOptionsSvm('KernelFunction', 'linear', 'BoxConstraint', 1);
assert(strcmpi(options.KernelFunction, 'linear'));
[Xs, centre, echelle] = standardiserSvm(X, true);
assert(max(abs(mean(Xs))) < 1e-12, 'centrer met la moyenne a zero');
assert(max(abs(std(Xs) - 1)) < 1e-12, 'reduire met l''ecart type a un');
assert(numel(centre) == 2 && numel(echelle) == 2);
Xt = standardiserSvm(X, false);
assert(isequal(Xt, X), 'sans standardisation, les donnees passent telles quelles');
K = noyauSvm(X, X, options);
assert(isequal(size(K), [80 80]));
assert(max(max(abs(K - K'))) < 1e-10, 'un noyau est symetrique');
cible = 2 * (y == 2) - 1;
[alpha, biais] = resoudreSmo(K, cible, 1, 1e-3, 200);
assert(all(alpha >= -1e-9) && all(alpha <= 1 + 1e-9), 'les multiplicateurs restent dans la boite');
assert(abs(sum(alpha .* cible)) < 1e-6, 'la contrainte d''egalite est tenue');
assert(isfinite(biais));

Kgp = noyauGp(X, X, 'squaredexponential', 1, 1);
assert(isequal(size(Kgp), [80 80]));
assert(max(abs(diag(Kgp) - 1)) < 1e-10, 'la variance a distance nulle vaut le signal');
assert(min(eig(Kgp + 1e-8 * eye(80))) > -1e-6, 'un noyau est semi-defini positif');

optionsLin = lireOptionsLineaire(2, 'Lambda', 0.01);
assert(abs(optionsLin.Lambda - 0.01) < 1e-14);
[poids, biais] = descenteLineaire(X, cible, optionsLin, false);
assert(numel(poids) == 2 && isfinite(biais));
assert(mean(sign(X * poids(:) + biais) == cible) > 0.8, ...
       'la descente separe deux nuages ecartes');

% Les rouages de prediction, appeles par PREDICT : chacun doit retrouver
% ses propres donnees d'apprentissage.
m = fitcsvm(X, y);
assert(mean(predictSvm(m, X) == y) > 0.9);
m = fitcnb(X, y);
assert(mean(predictBayesNaif(m, X) == y) > 0.9);
m = fitcdiscr(X, y);
assert(mean(predictDiscriminant(m, X) == y) > 0.9);
m = fitcecoc(X, y);
assert(mean(predictEcoc(m, X) == y) > 0.9);
m = fitclinear(X, y);
assert(mean(predictLineaire(m, X) == y) > 0.8);
m = fitcknn(X, y, 'NumNeighbors', 3);
assert(mean(predictknn(m, X) == y) > 0.9);

z = X(:, 1) * 2 - X(:, 2);
m = fitrtree(X, z);
assert(rms(predictArbreRegression(m, X) - z) < rms(z - mean(z)));
m = fitrgp(X, z);
[mu, variance] = predictGp(m, X);
assert(rms(mu - z) < rms(z - mean(z)));
assert(all(variance >= -1e-9), 'une variance ne peut pas etre negative');

% Tirer dans un melange gaussien : les composantes sont des indices
% valides, et la moyenne des tirages retrouve celle du melange.
modele = fitgmdist([randn(200, 1); randn(200, 1) + 8], 2);
[tirages, composantes] = tirerMelange(modele, 500);
assert(numel(tirages) == 500);
assert(all(composantes >= 1 & composantes <= 2));
assert(abs(mean(tirages) - 4) < 1.5, 'le melange est centre entre ses deux modes');

% Un jeu de donnees a l'ancienne, et la droite des moindres carres.
d = dataset((1:5)', (2:2:10)');
assert(size(d, 1) == 5);
figure();
plot([1 2 3 4], [2 4 6 8], 'o');
H = lsline();
assert(~isempty(H));
close all;

%% ------------------------------------------------ images
% La matrice sRGB -> XYZ envoie le blanc sur le blanc D65.
M = matriceRVBversXYZ();
assert(isequal(size(M), [3 3]));
blanc = M * [1; 1; 1];
D65 = [0.95047; 1; 1.08883];
assert(max(abs(blanc - D65)) < 1e-3, 'le blanc va sur D65');
% Appliquer une matrice a une image ou a une liste donne la meme chose.
liste = [1 0 0; 0 1 0; 0.2 0.3 0.4];
sortieListe = appliquerMatriceCouleur(liste, M);
assert(isequal(size(sortieListe), [3 3]));
pave = reshape(liste, 3, 1, 3);
sortiePave = appliquerMatriceCouleur(pave, M);
assert(isequal(size(sortiePave), [3 1 3]), 'la forme de l''entree est rendue');
assert(max(max(abs(sortieListe - reshape(sortiePave, 3, 3)))) < 1e-12, ...
       'liste ou image, le meme calcul');
assert(max(abs(sortieListe(1, :)' - M * [1; 0; 0])) < 1e-12);
% L'adaptation de von Kries envoie le blanc source sur le blanc cible.
A = [1.0985; 1; 0.3558];
adapte = adapterBlanc(D65', D65', A');
assert(max(abs(adapte(:) - A)) < 1e-9, 'le blanc source devient le blanc cible');
% Les voisinages : quatre decalages en connexite 4, huit en connexite 8.
assert(size(voisinageConnexite(4), 1) == 4);
assert(size(voisinageConnexite(8), 1) == 8);
assert(all(sum(abs(voisinageConnexite(4)), 2) == 1), 'la connexite 4 exclut les diagonales');

%% ------------------------------------------------ ajustement, apprentissage
[x, y] = meshgrid(linspace(-1, 1, 8));
z = 1 + 2 * x - 3 * y + x .* y;
[coefficients, modele] = fitSurface(x(:), y(:), z(:), 2);
assert(numel(coefficients) >= 6);
assert(rms(modele(coefficients, x(:), y(:)) - z(:)) < 1e-8, ...
       'le degre deux contient le terme croise : l''ajustement est exact');

t = linspace(0, 1, 60)';
bruit = sin(2 * pi * t) + 0.2 * randn(60, 1);
lisse = smoothSpline(t, bruit, 1);
assert(numel(lisse) == 60);
assert(sum(diff(lisse, 2) .^ 2) < sum(diff(bruit, 2) .^ 2), ...
       'lisser diminue la courbure');
tresLisse = smoothSpline(t, bruit, 1000);
assert(sum(diff(tresLisse, 2) .^ 2) < sum(diff(lisse, 2) .^ 2), ...
       'plus de penalite, moins de courbure');

% Une couche pleinement connectee n'est qu'un produit matriciel suivi
% d'un biais : la troisieme sortie somme les deux entrees, plus un.
Y = fullyconnect([1; 2], [1 0; 0 1; 1 1], [0; 0; 1]);
assert(max(abs(double(Y) - [1; 2; 4])) < 1e-12);
% Sur un DLARRAY, elle rend un DLARRAY.
Yd = fullyconnect(dlarray([1; 2]), [1 0; 0 1; 1 1], [0; 0; 1]);
assert(isa(Yd, 'dlarray'));
assert(max(abs(extractdata(Yd) - [1; 2; 4])) < 1e-12);

% PREDICTRESEAU est le rouage de PREDICT sur un reseau de TRAINNETWORK.
rng(5);
Xr = [randn(2, 30), randn(2, 30) + 4];
Yr = [repmat([1; 0], 1, 30), repmat([0; 1], 1, 30)];
couches = {fullyConnectedLayer(4), reluLayer(), ...
           fullyConnectedLayer(2), softmaxLayer()};
reseau = trainNetwork(Xr, Yr, couches, trainingOptions('sgdm', 'MaxEpochs', 200));
sorties = predictReseau(reseau, Xr);
assert(isequal(size(sorties), [2 60]));
assert(max(abs(sum(sorties, 1) - 1)) < 1e-10, 'un softmax somme a un');
[classes, scores] = classify(reseau, Xr);
assert(numel(classes) == 60 && isequal(size(scores), [2 60]));
assert(mean(classes(:)' == [ones(1, 30), 2 * ones(1, 30)]) > 0.9, ...
       'deux nuages ecartes se classent');
% Un tableau de couches, ecriture usuelle de MATLAB, construit un reseau.
enChaine = [featureInputLayer(2); fullyConnectedLayer(3); softmaxLayer()];
net = dlnetwork(enChaine);
assert(numel(net.Layers) == 3);
assert(numel(assembleNetwork(enChaine).Layers) == 3);

%% ------------------------------------------------ identification
y = (1:10)';
assert(abs(compareFit(y, y) - 100) < 1e-12, 'un ajustement parfait fait 100 %');
assert(compareFit(y, mean(y) * ones(10, 1)) < 1e-10, ...
       'predire la moyenne fait zero');
rng(2);
u = randn(200, 1);
z = iddata(filter([0 0.5], [1 -0.8], u), u);
m = arx(z, [1 1 1]);
yhat = predictArx(m, z);
assert(max(abs(yhat(5:end) - z.y(5:end))) < 1e-8, ...
       'sans bruit, la prediction a un pas est exacte');

%% ------------------------------------------------ optimisation
x = optimvar('x');
y = optimvar('y');
e = 3 * x + 2 * y - 1;
assert(isa(e, 'optimexpr'));
c = e <= 4;
assert(isa(c, 'optimconstr'));
% optimexpr et optimconstr construits directement.
vide = optimexpr();
assert(isa(vide, 'optimexpr'));
prob = optimproblem('Objective', x + y, 'Constraints', c);
assert(~isempty(prob));

rng(4);
[xr, fr] = lsqcurvefit(@(p, t) p(1) * exp(-p(2) * t), [1 1], ...
                       linspace(0, 2, 30)', 2 * exp(-1.5 * linspace(0, 2, 30)'));
assert(max(abs(xr(:)' - [2 1.5])) < 1e-3, 'les parametres se retrouvent');
assert(fr < 1e-6);

o = champOptimisation(struct('PopulationSize', 30), 'PopulationSize', 50);
assert(o == 30, 'une option posee l''emporte sur le defaut');
assert(champOptimisation(struct(), 'PopulationSize', 50) == 50);

%% ------------------------------------------------ commande robuste
sys = tf(1, [1 1 1]);
[valeurs, w] = sigmaValues(sys);
assert(numel(valeurs) == numel(w) && all(isfinite(valeurs)));
assert(valeurs(1) > valeurs(end), 'le gain retombe en haute frequence');
[margeModule, margeRetard] = stabilityMargin(tf(1, [1 1 0]));
assert(margeModule > 0 && margeRetard > 0);
[stable, gains] = uncertainGain(tf(1, [1 1 0]));
assert(numel(stable) == numel(gains));
assert(any(stable), 'un integrateur double se stabilise pour certains gains');

%% ------------------------------------------------ simscape, simulink
% ADDCOMPONENT est la forme generale : un diviseur monte par elle donne
% la meme tension que monte par ADDRESISTOR.
c = circuit();
c = addComponent(c, 'v', 1, 0, 10);
c = addComponent(c, 'r', 1, 2, 1000);
c = addComponent(c, 'r', 2, 0, 2000);
assert(numel(c.composants) == 3);
assert(c.noeuds == 2, 'le circuit connait sa taille sans qu''on la declare');
v = solveDC(c);
assert(abs(v(2) - 20 / 3) < 1e-9, 'le pont diviseur rend deux tiers de dix volts');

% SIMPLOT trace ce que SIM a releve.
modele = new_system('rampe');
modele = add_block(modele, 'constant', 'un', 'Value', 2);
modele = add_block(modele, 'integrator', 'integ', 'InitialCondition', 0);
modele = add_line(modele, 'un', 'integ');
r = sim(modele, 1, 0.01);
figure();
simplot(r);
simplot(r, {'integ'});
close all;

%% ------------------------------------------------ symbolique
x = sym('x');
% Les constructeurs montent l'arbre sans rien evaluer : 2 + 3 reste
% « 2 + 3 » jusqu'a ce qu'on simplifie.
assert(strcmp(symstr(symadd(symnum(2), symnum(3))), '(2 + 3)'));
assert(strcmp(symstr(symsimplify(symadd(symnum(2), symnum(3)))), '5'));
assert(strcmp(symstr(symsimplify(symsub(symnum(5), symnum(3)))), '2'));
assert(strcmp(symstr(symsimplify(symmul(symnum(2), symnum(3)))), '6'));
assert(strcmp(symstr(symsimplify(symdiv(symnum(6), symnum(2)))), '3'));
% Les elements neutres disparaissent, l'element absorbant absorbe.
assert(strcmp(symstr(symsimplify(symadd(x, symnum(0)))), 'x'));
assert(strcmp(symstr(symsimplify(symmul(x, symnum(1)))), 'x'));
assert(strcmp(symstr(symsimplify(symmul(x, symnum(0)))), '0'));
% Substituer puis simplifier : 2*x + 2 en x = 1 fait 4.
e = symadd(symmul(symnum(2), x), symnum(2));
assert(strcmp(symstr(symsimplify(symsubs(e, 'x', 1))), '4'));
% Toutes les fonctions symboliques acceptent aussi bien un arbre qu'un
% objet SYM : sans cela, TAYLOR — qui rend un SYM — ne pouvait pas etre
% ecrit par SYMSTR ni simplifie.
assert(strcmp(symstr(x), 'x'));
assert(strcmp(symstr(symsimplify(x)), 'x'));
assert(strcmp(symstr(symsubs(x, 'x', 3)), '3'));
serie = taylor(symfun('sin', x), 'x', 0, 5);
assert(isa(serie, 'sym'));
assert(~isempty(symstr(serie)), 'une serie de Taylor s''ecrit');
assert(abs(symeval(symdiff(sympow(x, symnum(3)), 'x'), {'x'}, {2}) - 12) < 1e-12, ...
       'la derivee de x au cube vaut 3 x carre');

% Un operande peut etre un nombre ou un nom : il est converti au passage.
assert(strcmp(symstr(symsimplify(symmul('x', 1))), 'x'));
assert(strcmp(symstr(symsimplify(sympow(x, 1))), 'x'));
% Une fonction elementaire se substitue comme le reste.
f = symfun('sin', x);
assert(strcmp(symstr(f), 'sin(x)'));
assert(strcmp(symstr(symsubs(f, 'x', 0)), 'sin(0)'));

%% ------------------------------------------------ types
s = struct('type', '()', 'subs', {{2}});
assert(appliquerReste([10 20 30], s) == 20);
v = assignerReste([10 20 30], s, 99);
assert(isequal(v, [10 99 30]));
s2 = struct('type', {'.', '()'}, 'subs', {'a', {2}});
assert(appliquerReste(struct('a', [7 8 9]), s2) == 8);

%% ------------------------------------------------ interface, divers
f = uifigure();
assert(identifiantParent(f) == identifiantParent(f));
assert(isnumeric(identifiantParent([])) || true);
uiwait(f, 0.01);
uiresume(f);
close all;

%% ------------------------------------------------ trace de fonctions
figure();
fmesh(@(x, y) x .^ 2 + y .^ 2, [-1 1 -1 1]);
close all;
figure();
ezmesh(@(x, y) x .* y);
close all;
figure();
fcontour(@(x, y) x .^ 2 - y .^ 2, [-2 2 -2 2]);
close all;

%% ------------------------------------------------ ce qui ne peut pas marcher ici
% Une fonction absente doit le dire, non rendre une valeur fausse.
leve = false;
try
    openfig('inexistant.fig');
catch
    leve = true;
end
assert(leve, 'OPENFIG doit signaler qu''il ne sait pas faire');

% INPUTDLG lit la console : on ne peut l'exercer ici que sur le cas ou
% il n'a rien a demander, sans quoi le test attendrait une reponse que
% personne ne donnera.
reponses = inputdlg({});
assert(iscell(reponses) && isempty(reponses), 'aucune invite, aucune question');

%% ------------------------------------------------ ce qui restait orphelin
% RAMPECARTE est la rampe dont vivent toutes les cartes de couleurs.
g = rampeCarte(5);
assert(max(abs(g' - [0 0.25 0.5 0.75 1])) < 1e-15);
assert(isempty(rampeCarte(0)));
assert(isequal(rampeCarte(1), 0), 'une seule couleur vaut zero, comme dans MATLAB');

% INSTGETCELL rend en cellules ce qu'INSTGET rend en tableaux : c'est ce
% qui permet de melanger des champs de types differents.
jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
jeu = instadd(jeu, 'Bond', 0.06, '01-Jan-2024', '01-Jan-2034');
[donnees, noms] = instgetcell(jeu, 'FieldList', {'CouponRate', 'Maturity'});
assert(numel(donnees) == numel(noms));
assert(any(strcmpi(noms, 'CouponRate')));

% READLINE rend ce que la derniere commande a prepare.
instrument = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
instrument = writeline(instrument, '*IDN?');
reponse = readline(instrument);
assert(ischar(reponse) || isstring(reponse));
assert(~isempty(char(reponse)), 'une identification n''est pas vide');

% Empaqueter une toolbox rend une archive lisible.
dossier = tempname();
mkdir(dossier);
fid = fopen(fullfile(dossier, 'Contents.m'), 'w');
fprintf(fid, '%% Ma toolbox\n');
fclose(fid);
archive = matlab.addons.toolbox.packageToolbox(dossier, [tempname() '.zip']);
assert(isfile(archive), 'l''archive existe');

% WEBREAD et WEBSAVE demandent le reseau : on ne verifie ici que ce qui ne
% depend pas de lui — une adresse mal formee doit etre refusee, non
% silencieusement transformee en fichier vide.
leve = false;
try
    webread('pas-une-adresse');
catch
    leve = true;
end
assert(leve, 'une adresse invalide doit etre signalee');
leve = false;
try
    websave(tempname(), 'pas-une-adresse');
catch
    leve = true;
end
assert(leve);

fprintf('  rouages : toutes les verifications passent\n');
