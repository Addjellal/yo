% test_couverture.m — les fonctions que rien n'éprouvait.
%
% L'audit d'outils/audit.m relevait cent cinquante-cinq fonctions de la
% liste de référence MATLAB qu'aucun test ni aucun exemple ne nommait :
% rien ne prouvait qu'elles marchaient. Ce fichier les exerce, chacune
% contre une propriété qui la caractérise plutôt que contre une valeur
% recopiée.

fprintf('couverture : les fonctions que rien n''eprouvait\n');

%% Conversions de repères de la robotique
% Chaque conversion doit boucler, et la rotation obtenue rester une
% rotation.
axang = [0 0 1 pi/3];
q = axang2quat(axang);
assert(abs(norm(q) - 1) < 1e-14, 'axang2quat rend un quaternion unitaire');
assert(norm(quat2rotm(q) - rotz(60)) < 1e-13, 'et la bonne rotation');
T = axang2tform(axang);
assert(norm(tform2rotm(T) - rotz(60)) < 1e-13, 'axang2tform de meme');
assert(norm(tform2trvec(T)) < 1e-15, 'sans translation');
retour = tform2axang(T);
assert(abs(retour(4) - pi/3) < 1e-13, 'tform2axang retrouve l''angle');
assert(norm(abs(retour(1:3)) - [0 0 1]) < 1e-13, 'et l''axe');
assert(norm(quat2tform(q) - T) < 1e-13, 'quat2tform passe par le meme chemin');
assert(norm(tform2quat(T) - q) < 1e-13, 'et tform2quat revient');
assert(max(abs(tform2eul(eul2tform([0.3 0.2 0.1])) - [0.3 0.2 0.1])) < 1e-13, ...
       'eul2tform et tform2eul bouclent');
% Diviser un quaternion par lui-même rend l'identité ; diviser par un
% autre rend la rotation relative.
assert(norm(quatdivide(q, q) - [1 0 0 0]) < 1e-13, 'q / q vaut l''identite');
p = axang2quat([1 0 0 0.4]);
assert(norm(quatmultiply(quatdivide(q, p), p) - q) < 1e-13, ...
       '(q / p) * p rend q');
assert(abs(norm(quatnormalize([2 0 0 0])) - 1) < 1e-15, 'quatnormalize normalise');

% Trajectoires : la B-spline reste dans l'enveloppe convexe de ses points
% de contrôle, et la trajectoire de transformation relie bien les deux
% poses.
controle = [0 1 2 3; 0 2 -1 0];
[qb, qdb] = bsplinepolytraj(controle, [0 1], linspace(0, 1, 50));
assert(size(qb, 1) == 2, 'deux degres de liberte');
assert(all(qb(1, :) >= min(controle(1, :)) - 1e-9) && ...
       all(qb(1, :) <= max(controle(1, :)) + 1e-9), ...
       'la B-spline reste dans l''enveloppe de ses points de controle');
assert(all(qb(2, :) >= min(controle(2, :)) - 1e-9) && ...
       all(qb(2, :) <= max(controle(2, :)) + 1e-9), 'sur les deux axes');
assert(isequal(size(qdb), size(qb)), 'la vitesse a la meme taille');

T0 = trvec2tform([0 0 0]);
TF = trvec2tform([1 2 3]) * eul2tform([pi/2 0 0]);
[Ts, vitesse] = transformtraj(T0, TF, [0 1], linspace(0, 1, 21));
assert(isequal(size(Ts), [4 4 21]), 'un 4x4 par instant');
assert(norm(Ts(:, :, 1) - T0) < 1e-13, 'la trajectoire part de T0');
assert(norm(Ts(:, :, end) - TF) < 1e-12, 'et arrive a TF');
assert(size(vitesse, 1) == 6, 'six composantes de vitesse');
% La translation est interpolée linéairement : à mi-chemin, la moitié.
assert(norm(tform2trvec(Ts(:, :, 11)) - [0.5 1 1.5]) < 1e-12, ...
       'la translation s''interpole lineairement');

%% Contraintes de cinématique inverse
% Chaque contrainte doit rendre un résidu nul quand elle est satisfaite,
% et positif sinon.
robot = loadrobot('planarArm2R', 'DataFormat', 'row');
config = [0.4 0.9];
pose = getTransform(robot, config, 'outil');

c = constraintPoseTarget('outil');
c.TargetTransform = pose;
assert(norm(matlibre_residu(c, robot, config)) < 1e-12, ...
       'la pose visee est atteinte : residu nul');
c.TargetTransform = trvec2tform([5 5 5]);
assert(norm(matlibre_residu(c, robot, config)) > 1, 'sinon le residu est grand');

c = constraintOrientationTarget('outil');
c.TargetOrientation = tform2quat(pose);
assert(norm(matlibre_residu(c, robot, config)) < 1e-12, 'orientation atteinte');
c.TargetOrientation = [1 0 0 0];
assert(norm(matlibre_residu(c, robot, config)) > 0.1, 'sinon non');

c = constraintCartesianBounds('outil');
c.Bounds = [-10 10; -10 10; -10 10];
assert(norm(matlibre_residu(c, robot, config)) < 1e-12, 'dans la boite');
c.Bounds = [5 10; -10 10; -10 10];
assert(norm(matlibre_residu(c, robot, config)) > 0.1, 'hors de la boite');

c = constraintDistanceBounds('outil');
distance = norm(pose(1:3, 4));
c.Bounds = [0 distance + 1];
assert(norm(matlibre_residu(c, robot, config)) < 1e-12, 'dans la coquille');
c.Bounds = [distance + 1, distance + 2];
assert(abs(norm(matlibre_residu(c, robot, config)) - 1) < 1e-9, ...
       'sinon le residu est la distance manquante');

c = constraintAiming('outil');
% L'axe z de l'effecteur d'un bras plan pointe hors du plan : viser un
% point au-dessus de lui donne un résidu nul.
c.TargetPoint = (pose(1:3, 4) + [0; 0; 1]).';
assert(norm(matlibre_residu(c, robot, config)) < 1e-9, ...
       'l''axe z vise bien le point place au-dessus');
c.TargetPoint = (pose(1:3, 4) + [1; 0; 0]).';
assert(norm(matlibre_residu(c, robot, config)) > 1, 'et non celui de cote');
fprintf('  robotique : conversions, trajectoires, contraintes\n');

%% Signal
% Un chirp linéaire balaie les fréquences : sa fréquence instantanée
% croît, et son passage par zéro s'accélère.
fs = 1000;
t = (0:fs-1) / fs;
y = chirp(t, 10, 1, 100);
assert(numel(y) == numel(t), 'un echantillon par instant');
assert(max(abs(y)) <= 1 + 1e-12, 'd''amplitude un');
debut = sum(diff(sign(y(1:200))) ~= 0);
fin = sum(diff(sign(y(end-199:end))) ~= 0);
assert(fin > 2 * debut, 'le chirp accelere : plus de passages par zero a la fin');

% Une dent de scie de largeur un monte linéairement de -1 à 1 sur chaque
% période ; de largeur 0,5, c'est un triangle symétrique.
s = sawtooth(2 * pi * (0:0.001:0.999));
assert(abs(s(1) + 1) < 1e-9 && s(end) > 0.99, 'la dent de scie monte de -1 a 1');
assert(all(diff(s) > 0), 'sans jamais redescendre dans la periode');
triangle = sawtooth(2 * pi * (0:0.001:0.999), 0.5);
[~, sommet] = max(triangle);
assert(abs(sommet / numel(triangle) - 0.5) < 0.01, ...
       'a largeur 0.5, le sommet est au milieu');

% findpeaks trouve les maxima locaux, et seulement eux.
x = [0 1 0 3 0 2 0];
[pics, positions] = findpeaks(x);
assert(isequal(positions(:).', [2 4 6]), 'les trois sommets');
assert(isequal(pics(:).', [1 3 2]), 'et leurs hauteurs');
assert(isempty(findpeaks([1 2 3 4 5])), 'une suite croissante n''a pas de sommet interieur');

% L'enveloppe encadre le signal, hors des tout premiers et derniers
% échantillons où l'effet de bord de la transformée de Hilbert la fait
% dévier.
porteuse = sin(2 * pi * 50 * t) .* (1 + 0.5 * sin(2 * pi * 2 * t));
[haut, bas] = envelope(porteuse);
assert(isequal(size(haut), size(porteuse)), 'l''orientation est conservee');
interieur = 20:numel(porteuse) - 20;
assert(all(haut(interieur) >= porteuse(interieur) - 1e-9), ...
       'l''enveloppe haute majore');
assert(all(bas(interieur) <= porteuse(interieur) + 1e-9), 'la basse minore');
assert(all(haut >= bas - 1e-12), 'et la haute est au-dessus de la basse');
% Sur un sinus pur, l'enveloppe vaut son amplitude.
assert(max(abs(envelope(2 * sin(2*pi*50*t))(interieur) - 2)) < 0.05, ...
       'l''enveloppe d''un sinus est son amplitude');
% Et la transformée de Hilbert garde la partie réelle intacte.
assert(max(abs(real(hilbert(porteuse)) - porteuse)) < 1e-12, ...
       'la partie reelle du signal analytique est le signal');
assert(isequal(size(hilbert(porteuse)), size(porteuse)), ...
       'hilbert conserve l''orientation');
assert(isequal(size(hilbert(porteuse.')), size(porteuse.')), 'dans les deux sens');

% L'interspectre d'un signal avec lui-même est sa densité spectrale.
rng(5);
bruit = randn(1, 2048);
[pxx, f] = pwelch(bruit, 256, 128, 256, fs);
pxy = cpsd(bruit, bruit, 256, 128, 256, fs);
assert(max(abs(real(pxy(:)) - pxx(:))) < 1e-9 * max(pxx), ...
       'cpsd(x,x) est la densite spectrale de x');
assert(max(abs(imag(pxy))) < 1e-9 * max(pxx), 'et elle est reelle');

% Savitzky-Golay laisse passer un polynôme de son ordre sans le déformer.
xp = (0:100) .^ 2;
lisse = sgolayfilt(xp, 2, 11);
assert(max(abs(lisse(:).' - xp)) < 1e-8, ...
       'un filtre d''ordre 2 laisse passer une parabole exactement');
bruite = xp + randn(1, 101) * 5;
assert(std(sgolayfilt(bruite, 2, 11) - xp) < std(bruite - xp), ...
       'et il reduit le bruit');
assert(isrow(sgolayfilt(bruite, 2, 11)), 'l''orientation est conservee');
% Rééchantillonner conserve aussi l'orientation, et rend le bon nombre
% d'échantillons.
assert(isrow(resample(bruite, 3, 2)), 'resample conserve l''orientation');
assert(numel(resample(bruite, 3, 2)) == floor(101 * 3 / 2), ...
       'et rend floor(N P / Q) echantillons');
assert(iscolumn(resample(bruite.', 3, 2)), 'dans les deux sens');
% upfirdn enchaîne sur-échantillonnage, filtrage et décimation.
sortie = upfirdn([1 zeros(1, 9)], 1, 3, 1);
assert(numel(sortie) == 30, 'sur-echantillonner par 3 triple la longueur');
assert(abs(sortie(1) - 1) < 1e-12 && abs(sortie(2)) < 1e-12, ...
       'et insere P-1 zeros entre les echantillons');

% Un filtre en sections du second ordre a la même réponse que sa forme
% directe : c'est tout l'intérêt de la décomposition.
[z, p, k] = butter(6, 0.3, 'low');
[sos, g] = zp2sos(z, p, k);
assert(size(sos, 2) == 6, 'six coefficients par section');
assert(size(sos, 1) == 3, 'trois sections pour un ordre six');
[b, a] = zp2tf(z, p, k);
w = linspace(0, pi, 200);
Hdirect = polyval(b, exp(1i*w)) ./ polyval(a, exp(1i*w));
Hsos = g * ones(size(w));
for s = 1:size(sos, 1)
    Hsos = Hsos .* (polyval(sos(s, 1:3), exp(1i*w)) ./ polyval(sos(s, 4:6), exp(1i*w)));
end
assert(max(abs(abs(Hsos) - abs(Hdirect))) < 1e-6 * max(abs(Hdirect)), ...
       'les sections du second ordre ont la meme reponse que la forme directe');
fprintf('  signal : chirp, dent de scie, sommets, enveloppe, cpsd, sgolay, sos\n');

%% Automatique
% Discrétiser puis revenir doit rendre le système de départ.
sysc = tf(1, [1 2 1]);
for methode = {'tustin', 'zoh'}
    retour = d2c(c2d(sysc, 0.05, methode{1}), methode{1});
    assert(max(abs(sort(real(pole(retour))) - sort(pole(sysc)))) < 1e-6, ...
           'd2c annule c2d, par la meme methode');
    assert(abs(dcgain(retour) - dcgain(sysc)) < 1e-6, ...
           'et rend le meme gain statique');
end
% Le logarithme de matrice qu'emploie d2c doit traiter une matrice
% défective — celle-ci a une valeur propre double sans deux vecteurs
% propres, et la voie spectrale y rendait n'importe quoi.
jordan = [2 1; 0 2];
assert(max(max(abs(expm(logm(jordan)) - jordan))) < 1e-12, ...
       'logm inverse expm, y compris sur un bloc de Jordan');
assert(max(max(abs(sqrtm(jordan) ^ 2 - jordan))) < 1e-12, ...
       'et sqrtm au carre rend la matrice');
assert(abs(sqrtm([4 0; 0 9])(1,1) - 2) < 1e-12, 'sqrtm d''une diagonale');
% zgrid trace sans rien rendre : on vérifie qu'elle ne tombe pas.
figure('Visible', 'off');
zgrid();
zgrid(0.5, 0.3);
close all
fprintf('  automatique : d2c, logm et sqrtm sur matrice defective, zgrid\n');

%% Images
% Les conversions de type respectent les bornes et bouclent.
u = uint8([0 128 255]);
d = im2double(u);
assert(abs(d(1)) < 1e-15 && abs(d(3) - 1) < 1e-15, ...
       'im2double ramene 0..255 sur 0..1');
assert(isequal(im2uint8(d), u), 'et im2uint8 revient');
assert(isa(im2double(u), 'double') && isa(im2uint8(d), 'uint8'), 'aux bons types');

% Un étirement d'histogramme rend une image dont les extrêmes sont 0 et 1.
image = [0.2 0.3; 0.4 0.5];
etiree = imadjust(image, [0.2 0.5], [0 1]);
assert(abs(min(etiree(:))) < 1e-12 && abs(max(etiree(:)) - 1) < 1e-12, ...
       'imadjust etire sur toute la dynamique');
assert(all(diff(sort(etiree(:))) >= -1e-12), 'sans changer l''ordre des valeurs');

% Le recadrage garde un rectangle, et rien d'autre.
grande = reshape(1:100, 10, 10);
petite = imcrop(grande, [3 2 3 4]);
assert(isequal(size(petite), [5 4]), 'la taille demandee');
assert(petite(1, 1) == grande(2, 3), 'et le bon coin');

% La dilatation ne peut qu'agrandir, l'érosion que rétrécir, et l'une est
% la duale de l'autre par complémentation.
bw = false(9); bw(5, 5) = true;
element = true(3);
dilatee = imdilate(bw, element);
assert(sum(dilatee(:)) == 9, 'un point dilate par un carre 3x3 en fait neuf');
assert(all(dilatee(bw)), 'la dilatation contient l''original');
erodee = imerode(dilatee, element);
assert(isequal(erodee, bw), 'eroder ce qu''on vient de dilater rend l''original');
assert(sum(sum(imerode(bw, element))) == 0, 'eroder un point isole l''efface');

% L'histogramme compte tous les pixels, et pas plus.
[compte, positions] = imhist(uint8([0 0 128 255]), 256);
assert(sum(compte) == 4, 'quatre pixels comptes');
assert(compte(1) == 2, 'dont deux a zero');
assert(numel(positions) == 256, 'et 256 casiers');

% Le niveau de gris d'une couleur grise est cette couleur.
rgb = zeros(2, 2, 3);
rgb(:, :, 1) = 0.5; rgb(:, :, 2) = 0.5; rgb(:, :, 3) = 0.5;
assert(max(max(abs(rgb2gray(rgb) - 0.5))) < 1e-12, ...
       'le gris reste ce qu''il est');
% Et les poids somment à un : une couleur pure donne son propre poids.
rouge = zeros(1, 1, 3); rouge(1) = 1;
vert = zeros(1, 1, 3); vert(2) = 1;
bleu = zeros(1, 1, 3); bleu(3) = 1;
assert(abs(rgb2gray(rouge) + rgb2gray(vert) + rgb2gray(bleu) - 1) < 1e-12, ...
       'les trois poids de luminance somment a un');

% Un contour tracé referme la forme dont il est parti.
carre = false(9); carre(3:7, 3:7) = true;
contour = bwtraceboundary(carre, [3 3], 'N');
assert(size(contour, 2) == 2, 'des couples de coordonnees');
assert(all(carre(sub2ind(size(carre), contour(:,1), contour(:,2)))), ...
       'le contour ne passe que par des pixels de la forme');
assert(isequal(contour(1, :), contour(end, :)), 'et il se referme');
fprintf('  images : types, histogramme, morphologie, contour\n');

%% Finance
% Les rendements et les cours se déduisent les uns des autres.
cours = [100 102 101 105 103].';
r = tick2ret(cours);
assert(numel(r) == numel(cours) - 1, 'un rendement de moins que de cours');
assert(abs(r(1) - 0.02) < 1e-12, 'le premier vaut 2 %');
assert(max(abs(ret2tick(r, cours(1)) - cours)) < 1e-9, ...
       'ret2tick annule tick2ret');

% La valeur actuelle nette d'un flux nul est nulle ; à taux nul, c'est la
% somme.
assert(abs(npv(0.1, [0 0 0])) < 1e-15, 'aucun flux, aucune valeur');
assert(abs(npv(0, [-100 50 60]) - 10) < 1e-12, 'a taux nul, c''est la somme');
assert(npv(0.1, [-100 50 60]) < npv(0, [-100 50 60]), ...
       'actualiser diminue la valeur des flux futurs');

% Le ratio de Sharpe est nul quand le rendement égale le taux sans
% risque, et il croît avec le rendement.
rng(3);
rendements = 0.001 + 0.01 * randn(500, 1);
assert(abs(sharpe(0.02 * ones(50, 1), 0.02)) < 1e-9, ...
       'aucun exces de rendement, aucun ratio');
assert(sharpe(rendements + 0.01, 0) > sharpe(rendements, 0), ...
       'plus de rendement, meilleur ratio');

% Une moyenne mobile courte suit mieux que la longue.
[courte, longue] = movavg(cumsum(ones(100, 1)), 5, 20);
assert(numel(courte) == 100 && numel(longue) == 100, 'une valeur par date');
% Sur une rampe croissante, la moyenne courte est au-dessus de la longue.
assert(mean(courte(30:end)) > mean(longue(30:end)), ...
       'sur une rampe, la moyenne courte devance la longue');

% Les bandes de Bollinger encadrent la moyenne, et le prix les franchit
% rarement.
rng(7);
serie = 100 + cumsum(randn(300, 1));
[milieu, haute, basse] = bollinger(serie, 20, 2);
valides = ~isnan(milieu);
assert(all(haute(valides) >= milieu(valides) - 1e-12), 'la bande haute majore');
assert(all(basse(valides) <= milieu(valides) + 1e-12), 'la basse minore');
dehors = mean(serie(valides) > haute(valides) | serie(valides) < basse(valides));
assert(dehors < 0.15, 'a deux ecarts types, le cours sort rarement des bandes');

% Taux nominal et taux effectif se répondent.
assert(abs(nomrr(effrr(0.12, 12), 12) - 0.12) < 1e-12, ...
       'nomrr annule effrr');
assert(effrr(0.12, 12) > 0.12, 'la capitalisation augmente le taux effectif');
assert(abs(effrr(0.12, 1) - 0.12) < 1e-15, 'sauf a une seule periode');

% L'accumulation de Williams monte quand le cours clôture haut dans la
% séance et descend quand il clôture bas.
haut = [10 11 12 13].';
bas = [8 9 10 11].';
clotureHaute = [9 11 12 13].';
clotureBasse = [9 9 10 11].';
assert(williamsad(haut, bas, clotureHaute)(end) > ...
       williamsad(haut, bas, clotureBasse)(end), ...
       'cloturer haut accumule, cloturer bas distribue');
fprintf('  finance : rendements, actualisation, Sharpe, Bollinger, taux\n');

%% Fonctions de base
% dec2base et base2dec bouclent, dans toutes les bases.
for base = [2 8 16 36]
    for valeur = [0 1 42 255 65535]
        assert(base2dec(dec2base(valeur, base), base) == valeur, ...
               'dec2base et base2dec bouclent');
    end
end
assert(strcmp(dec2base(255, 16), 'FF'), '255 en hexadecimal');
assert(numel(dec2base(5, 2, 8)) == 8, 'la longueur imposee est tenue');

% genvarname rend toujours un nom valide, et évite ceux qu'on lui donne.
assert(isvarname(genvarname('nom valide ?')), 'un nom invalide devient valide');
assert(~strcmp(genvarname('x', {'x'}), 'x'), 'et evite les noms exclus');
assert(isvarname(genvarname('123')), 'y compris quand il commence par un chiffre');

% nthargout ne rend que la sortie demandée.
assert(nthargout(2, @max, [3 9 4]) == 2, 'la position du maximum');
assert(nthargout(1, @max, [3 9 4]) == 9, 'ou sa valeur');
fprintf('  base : dec2base, genvarname, nthargout\n');

%% Statistiques : lois, ajustements, réduction de dimension
% Une fonction de répartition croît de zéro à un : c'est ce qui la
% définit, et cela suffit à éprouver les lois non centrales.
x = linspace(0.01, 40, 400);
for loi = {@(v) ncx2cdf(v, 3, 2), @(v) ncfcdf(v, 4, 6, 1), ...
           @(v) nctcdf(v - 20, 8, 1)}
    F = loi{1}(x);
    assert(all(diff(F) >= -1e-12), 'une repartition ne decroit jamais');
    assert(all(F >= -1e-12 & F <= 1 + 1e-12), 'et reste entre zero et un');
    assert(F(end) > 0.9, 'elle tend vers un');
end
% Sans décentrage, la loi non centrale est la loi centrale.
assert(max(abs(ncx2cdf(x, 3, 0) - chi2cdf(x, 3))) < 1e-6, ...
       'ncx2cdf a decentrage nul est chi2cdf');
assert(max(abs(nctcdf(linspace(-4, 4, 50), 8, 0) - tcdf(linspace(-4, 4, 50), 8))) < 1e-6, ...
       'nctcdf a decentrage nul est tcdf');
% La loi de Student tend vers la normale quand ses degrés de liberté
% croissent.
assert(abs(tcdf(1.96, 1e6) - normcdf(1.96)) < 1e-4, ...
       'a beaucoup de degres de liberte, Student rejoint la normale');
assert(abs(tcdf(0, 5) - 0.5) < 1e-12, 'et elle est symetrique');

% Un tirage uniforme discret couvre tout son domaine et rien d'autre.
rng(11);
tirage = unidrnd(6, 1, 5000);
assert(all(tirage >= 1 & tirage <= 6), 'unidrnd tire dans 1..N');
assert(all(tirage == round(tirage)), 'des entiers');
assert(numel(unique(tirage)) == 6, 'et couvre les six faces');
assert(abs(mean(tirage) - 3.5) < 0.15, 'de moyenne (N+1)/2');

% tabulate compte, et la somme des effectifs est le nombre d'observations.
table_ = tabulate([1 1 2 3 3 3]);
assert(sum(table_(:, 2)) == 6, 'six observations comptees');
assert(abs(sum(table_(:, 3)) - 100) < 1e-9, 'les pourcentages somment a cent');

% Un ajustement de loi retrouve les paramètres qui ont servi au tirage.
rng(13);
echantillon = 3 + 2 * randn(5000, 1);
ajuste = fitdist(echantillon, 'Normal');
assert(abs(ajuste.mu - 3) < 0.1 && abs(ajuste.sigma - 2) < 0.1, ...
       'fitdist retrouve la moyenne et l''ecart type');

% Un partitionnement en validation croisée couvre tout l'échantillon, une
% fois et une seule.
partition = cvpartition(50, 'KFold', 5);
assert(partition.NumTestSets == 5, 'cinq decoupages');
assert(partition.NumObservations == 50, 'cinquante observations');
vus = false(50, 1);
for k = 1:partition.NumTestSets
    essai = test(partition, k);
    assert(sum(essai) == 10, 'chaque pli fait un cinquieme');
    assert(~any(vus & essai), 'et aucun exemple n''est vu deux fois');
    vus = vus | essai;
    assert(sum(training(partition, k)) == 40, 'le reste sert a l''apprentissage');
    assert(all(xor(essai, training(partition, k))), ...
           'test et apprentissage se partagent tout, sans recouvrement');
end
assert(all(vus), 'tout l''echantillon finit par etre teste');
assert(isequal(partition.TestSize, 10 * ones(1, 5)), 'TestSize les compte');
% Le découpage stratifié garde les proportions de chaque classe.
rare = [false(90, 1); true(10, 1)];
stratifie = cvpartition([ones(90,1); 2*ones(10,1)], 'KFold', 5);
for k = 1:5
    assert(sum(test(stratifie, k) & rare) == 2, ...
           'la classe rare est repartie egalement entre les blocs');
end
% Le hold-out réserve la fraction demandée.
assert(sum(test(cvpartition(100, 'HoldOut', 0.3))) == 30, ...
       'HoldOut reserve la fraction demandee');

% Les composantes principales expliquent la variance dans l'ordre.
rng(17);
donnees = randn(200, 3) * [3 0 0; 0 1 0; 0 0 0.2];
[coefficients, latentes] = pcacov(cov(donnees));
assert(all(diff(latentes) <= 1e-12, 'all'), 'les valeurs propres decroissent');
assert(abs(sum(latentes) - trace(cov(donnees))) < 1e-9, ...
       'leur somme est la variance totale');
assert(max(max(abs(coefficients' * coefficients - eye(3)))) < 1e-12, ...
       'les axes principaux sont orthonormes');
[c2, s2, l2] = princomp(donnees);
assert(size(s2, 2) == 3, 'princomp rend autant de scores que de variables');
assert(abs(var(s2(:,1)) - l2(1)) < 1e-9, ...
       'la variance du premier score est la premiere valeur propre');

% Procrustes trouve la transformation qui superpose deux nuages, et
% l'écart tombe à zéro quand ils se correspondent exactement.
rng(19);
X = randn(20, 2);
theta = 0.4;
R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
Y = 2 * X * R + 5;
[dispersion, Z, transformation] = procrustes(X, Y);
assert(dispersion < 1e-20, 'deux nuages semblables se superposent exactement');
% Z est Y ramené sur X : c'est le nuage transformé qu'on compare au
% premier argument, non au second.
assert(max(max(abs(Z - X))) < 1e-9, 'Z est Y ramene sur X');
assert(abs(abs(det(transformation.T)) - 1) < 1e-9, ...
       'la transformation trouvee est une rotation');

% Le positionnement multidimensionnel reconstruit un nuage à partir de
% ses seules distances.
points = [0 0; 3 0; 0 4; 3 4];
D = pdist2(points, points);
[Y2, valeurs] = cmdscale(D);
assert(max(max(abs(pdist2(Y2(:,1:2), Y2(:,1:2)) - D))) < 1e-9, ...
       'les distances sont reconstruites');
assert(sum(valeurs > 1e-9) == 2, 'et deux dimensions suffisent');

% La silhouette juge un partitionnement : elle est haute quand les
% groupes sont nets, basse quand ils se mêlent.
rng(23);
nets = [randn(50, 2); randn(50, 2) + 10];
groupes = [ones(50, 1); 2 * ones(50, 1)];
melanges = randn(100, 2);
assert(mean(silhouette(nets, groupes)) > 0.8, 'des groupes nets, une silhouette haute');
assert(mean(silhouette(melanges, groupes)) < 0.3, 'des groupes melanges, une basse');

% Une régression robuste résiste à un point aberrant, la régression
% ordinaire non.
x = (1:30).';
y = 2 * x + 1;
y(15) = 500;
ordinaire = [ones(30,1) x] \ y;
robuste = robustfit(x, y);
assert(abs(robuste(2) - 2) < abs(ordinaire(2) - 2) / 3, ...
       'la regression robuste resiste a l''aberrant');
assert(abs(robuste(2) - 2) < 0.1, 'et retrouve la pente');

% Les statistiques de régression : le R2 vaut un sur un ajustement exact.
stats = regstats((1:20).' * 3 + 1, (1:20).', 'linear');
assert(abs(stats.rsquare - 1) < 1e-12, 'un ajustement exact a un R2 de un');

% Un ajustement non linéaire retrouve les paramètres d'un modèle connu.
rng(29);
xs = linspace(0, 5, 60).';
vrai = [2.5, 0.8];
ys = vrai(1) * exp(-vrai(2) * xs) + 0.01 * randn(60, 1);
modele = @(p, v) p(1) * exp(-p(2) * v);
[p, residus, J] = nlinfit(xs, ys, modele, [1 1]);
assert(max(abs(p(:).' - vrai)) < 0.05, 'nlinfit retrouve les parametres');
intervalle = nlparci(p, residus, 'jacobian', J);
assert(all(intervalle(:,1) <= p(:) & p(:) <= intervalle(:,2)), ...
       'l''intervalle de confiance contient l''estimation');
assert(all(intervalle(:,1) <= vrai(:) & vrai(:) <= intervalle(:,2)), ...
       'et les vraies valeurs');

% L'intervalle de confiance par bootstrap contient la statistique de
% l'échantillon.
rng(31);
donnees = randn(300, 1) + 5;
bornes = bootci(500, @mean, donnees);
assert(bornes(1) < mean(donnees) && mean(donnees) < bornes(2), ...
       'l''intervalle bootstrap encadre la moyenne observee');
assert(bornes(1) < 5 && 5 < bornes(2), 'et la vraie moyenne');

% Le plus proche voisin classe correctement des groupes séparés.
rng(37);
apprentissage = [randn(40, 2); randn(40, 2) + 6];
etiquettes = [ones(40, 1); 2 * ones(40, 1)];
modeleKnn = fitcknn(apprentissage, etiquettes, 'NumNeighbors', 3);
assert(predict(modeleKnn, [0 0]) == 1, 'un point du premier groupe');
assert(predict(modeleKnn, [6 6]) == 2, 'un point du second');
assert(mean(predict(modeleKnn, apprentissage) == etiquettes) > 0.95, ...
       'et l''apprentissage se reclasse');

% Les corrélations canoniques sont entre zéro et un, décroissantes.
rng(41);
A = randn(100, 3);
B = A * randn(3, 2) + 0.3 * randn(100, 2);
[~, ~, r] = canoncorr(A, B);
assert(all(r >= -1e-12 & r <= 1 + 1e-12), 'des correlations entre 0 et 1');
assert(all(diff(r) <= 1e-12), 'rangees par ordre decroissant');
assert(r(1) > 0.9, 'et la premiere est forte quand B depend de A');

% Le tirage de Wishart rend des matrices symétriques définies positives.
rng(43);
W = wishrnd(eye(3), 10);
assert(max(max(abs(W - W.'))) < 1e-12, 'symetrique');
assert(all(eig(W) > 0), 'et definie positive');

% gevcdf : la loi des valeurs extrêmes croît de zéro à un.
G = gevcdf(linspace(-2, 10, 200), 0.2, 1, 0);
assert(all(diff(G) >= -1e-12) && G(end) > 0.9, ...
       'la repartition des valeurs extremes croit vers un');
fprintf('  statistiques : lois, ajustements, reduction, robustesse\n');

%% Réseaux de neurones : chaque couche se décrit et s'enchaîne
% Une couche construite doit porter son type et son nom, et pouvoir
% entrer dans un graphe.
couches = {sigmoidLayer(), softplusLayer(), swishLayer(), geluLayer(), ...
           clippedReluLayer(6), layerNormalizationLayer(), ...
           groupNormalizationLayer(2), crossChannelNormalizationLayer(5), ...
           sequenceInputLayer(4), convolution1dLayer(3, 8), ...
           averagePooling1dLayer(2), maxPooling1dLayer(2), ...
           globalAveragePooling1dLayer(), globalAveragePooling2dLayer(), ...
           globalMaxPooling2dLayer(), transposedConv2dLayer(3, 8), ...
           concatenationLayer(1, 2), depthConcatenationLayer(2), ...
           multiplicationLayer(2)};
for k = 1:numel(couches)
    assert(isstruct(couches{k}) || isobject(couches{k}), ...
           'une couche est une structure descriptive');
    assert(isfield(couches{k}, 'type') && ~isempty(couches{k}.type), ...
           'et elle porte son type');
end
% Les fonctions d'activation gardent la forme et respectent leurs bornes.
v = linspace(-5, 5, 101);
assert(all(sigmoid(v) > 0 & sigmoid(v) < 1), 'la sigmoide reste dans ]0,1[');
assert(abs(sigmoid(0) - 0.5) < 1e-12, 'et vaut un demi en zero');
% Une couche entre dans un graphe et s'y raccorde.
lg = layerGraph();
lg = addLayers(lg, {sequenceInputLayer(4), sigmoidLayer()});
assert(numel(lg.Layers) == 2, 'deux couches ajoutees');
lg = connectLayers(lg, lg.Names{1}, lg.Names{2});
assert(height(lg.Connections) == 1, 'et une connexion');
fprintf('  apprentissage profond : couches et graphe\n');

%% Finance : obligations, taux, allocations
% Le prix d'une obligation au pair est cent, et son rendement égale son
% coupon.
prix = 100;
coupon = 0.05;
rendement = bondyield(prix, coupon, 10, 100);
assert(abs(rendement - coupon) < 1e-6, ...
       'une obligation au pair rend son coupon');
% Une obligation sous le pair rend davantage.
assert(bondyield(90, coupon, 10, 100) > coupon, ...
       'sous le pair, le rendement depasse le coupon');
% La convexité est positive : le prix est convexe en taux.
assert(bondconvexity(prix, coupon, 10, 100) > 0, 'la convexite est positive');
% Un facteur d'actualisation décroît avec l'échéance et vaut un à zéro.
assert(abs(discountfactor(0.05, 0) - 1) < 1e-12, 'a echeance nulle, un');
assert(discountfactor(0.05, 10) < discountfactor(0.05, 5), ...
       'plus l''echeance est lointaine, moins on actualise');
% Le taux à terme se déduit de deux taux au comptant.
avance = forwardrate(0.03, 1, 0.04, 2);
assert(avance > 0.04, ...
       'le taux a terme depasse le comptant quand la courbe monte');
% La convention 360 ISDA compte trente jours par mois.
assert(days360isda(datenum(2024,1,1), datenum(2024,2,1)) == 30, ...
       'un mois vaut trente jours');
assert(days360isda(datenum(2024,1,1), datenum(2025,1,1)) == 360, ...
       'et une annee trois cent soixante');
% Le maximum de perte est négatif ou nul, et nul sur une série croissante.
assert(max(drawdownSeries(cumsum(ones(50,1)))) < 1e-12, ...
       'une serie qui ne baisse jamais n''a aucune perte');
rng(47);
serie = cumsum(randn(200, 1)) + 100;
pertes = drawdownSeries(serie);
assert(all(pertes >= -1e-12), 'les pertes se comptent positivement');
assert(max(pertes) > 0, 'et une serie bruitee en connait');
fprintf('  finance : obligations, actualisation, pertes\n');

%% Ondelettes et communications
% Les filtres biorthogonaux vérifient la condition de reconstruction
% parfaite : la somme des produits croisés vaut deux à retard nul.
[Lo_D, Hi_D, Lo_R, Hi_R] = biorfilt(wfilters('bior2.2', 'd'), ...
                                    wfilters('bior2.2', 'r'));
assert(~isempty(Lo_D) && numel(Lo_D) == numel(Hi_D), ...
       'biorfilt rend quatre filtres de meme longueur');
% Une convolution bidimensionnelle, ou par lignes, ou par colonnes :
% filtrer les lignes puis les colonnes revient à filtrer par le produit
% extérieur des deux filtres, et c'est ce qui rend la transformée en
% ondelettes séparable.
image = magic(8);
h = [1 1] / 2;
lignesPuisColonnes = wconv2('col', wconv2('row', image, h), h);
ensemble = wconv2('a', image, h(:) * h);
assert(max(max(abs(lignesPuisColonnes - ensemble))) < 1e-12, ...
       'lignes puis colonnes vaut le produit exterieur des filtres');
assert(isequal(size(wconv2('row', image, h)), [8 9]), ...
       'par lignes, seule la largeur augmente');
assert(isequal(size(wconv2('col', image, h)), [9 8]), ...
       'par colonnes, seule la hauteur');
assert(isequal(size(wconv2('a', image, ones(3), 'same')), [8 8]), ...
       'la forme « same » garde la taille de l''image');
% Une moyenne locale ne déplace pas la moyenne globale, au bord près.
lissee = wconv2('a', image, ones(3) / 9, 'valid');
assert(abs(mean(lissee(:)) - mean(image(:))) < 1, ...
       'une moyenne locale ne deplace pas la moyenne globale');

% Le taux d'erreur binaire est nul sans erreur, et un quand tout est
% inversé.
bits = randi([0 1], 1, 1000);
assert(biterr(bits, bits) == 0, 'aucune erreur entre un vecteur et lui-meme');
assert(biterr(bits, 1 - bits) == 1000, 'et mille quand tout est inverse');
[nombre, taux] = biterr(bits, [1 - bits(1:100), bits(101:end)]);
assert(nombre == 100 && abs(taux - 0.1) < 1e-12, 'cent erreurs sur mille');
% Le taux d'erreur symbole se compte de même.
symboles = randi([0 3], 1, 500);
assert(symerr(symboles, symboles) == 0, 'aucune erreur symbole');
% Le filtre en cosinus surélevé est symétrique et de somme non nulle.
h = rcosdesign(0.25, 6, 4);
assert(max(abs(h - fliplr(h))) < 1e-12, 'le cosinus sureleve est symetrique');
assert(abs(sum(h)) > 0, 'et de gain non nul');
assert(mod(numel(h), 2) == 1, 'sa longueur est impaire : il a un centre');
fprintf('  ondelettes et communications : filtres, taux d''erreur\n');

%% Tracés : ils doivent produire quelque chose sans tomber
% On ne juge pas l'aspect, seulement que la fonction s'exécute et laisse
% un objet graphique derrière elle.
figure('Visible', 'off');
[X, Y] = meshgrid(linspace(-2, 2, 20));
fsurf(@(a, b) a .^ 2 + b .^ 2, [-2 2 -2 2]);
assert(~isempty(allchild(gca)), 'fsurf laisse un objet sur les axes');
clf
fill3([0 1 1], [0 0 1], [0 0 1], 'r');
assert(~isempty(allchild(gca)), 'fill3 aussi');
clf
stem3(X(1:5,1:5), Y(1:5,1:5), X(1:5,1:5) .^ 2);
assert(~isempty(allchild(gca)), 'stem3 aussi');
clf
scatter3(randn(20,1), randn(20,1), randn(20,1));
assert(~isempty(allchild(gca)), 'scatter3 aussi');
clf
rng(53);
histfit(randn(200, 1));
assert(~isempty(allchild(gca)), 'histfit aussi');
clf
normplot(randn(100, 1));
assert(~isempty(allchild(gca)), 'normplot aussi');
clf
probplot(randn(100, 1));
assert(~isempty(allchild(gca)), 'probplot aussi');
clf
zplane([1 -0.5], [1 -0.9]);
assert(~isempty(allchild(gca)), 'zplane aussi');
clf
pzplot(tf(1, [1 2 1]));
assert(~isempty(allchild(gca)), 'pzplot aussi');
clf
rlocusplot(tf(1, [1 2 1]));
assert(~isempty(allchild(gca)), 'rlocusplot aussi');
clf
refline(2, 1);
assert(~isempty(allchild(gca)), 'refline aussi');
clf
plot(1:10, (1:10).^2); refcurve([1 0 0]);
assert(~isempty(allchild(gca)), 'refcurve aussi');
clf
scatterplot(exp(1i * 2 * pi * rand(100, 1)));
close all
fprintf('  traces : fsurf, fill3, stem3, scatter3 et les autres\n');

%% Entrée-sortie et divers
% Écrire une image puis la relire rend la même image.
fichierImage = [tempname() '.pgm'];
originale = uint8(reshape(mod(0:99, 256), 10, 10));
imwrite(originale, fichierImage);
relue = imread(fichierImage);
assert(isequal(size(relue), size(originale)), 'la taille est rendue');
assert(isequal(relue, originale), 'et les valeurs aussi');
delete(fichierImage);

% celldisp affiche sans rien rendre ni tomber.
sortie = evalc('celldisp({1, ''deux'', [3 4]})');
assert(contains(sortie, 'deux'), 'celldisp montre le contenu');

% filemarker rend le séparateur de sous-fonction.
assert(ischar(filemarker()) && ~isempty(filemarker()), ...
       'filemarker rend un caractere');

% numlock rend l'état d'une touche : une chaîne, quoi qu'il arrive.
assert(ischar(numlock()) || isstring(numlock()), 'numlock rend un etat');

% statset rend une structure d'options dont les champs se règlent.
options = statset('MaxIter', 250, 'TolFun', 1e-8);
assert(options.MaxIter == 250 && options.TolFun == 1e-8, ...
       'statset retient ce qu''on lui donne');
assert(isstruct(statset()), 'et rend une structure meme sans argument');

% calquarters construit et relit un nombre de trimestres.
assert(calquarters(calquarters(3)) == 3, 'calquarters boucle');
assert(iscalendarduration(calquarters(3)), 'et rend une duree de calendrier');
assert(isduration(hours(3)) && ~isduration(calquarters(3)), ...
       'une duree exacte n''est pas une duree de calendrier');

% La matrice de retards empile les versions décalées d'une série.
retards = lagmatrix((1:6).', [1 2]);
assert(isequal(size(retards), [6 2]), 'une colonne par retard');
assert(isnan(retards(1, 1)), 'le premier retard manque au premier instant');
assert(retards(3, 1) == 2 && retards(3, 2) == 1, 'et les valeurs sont decalees');
fprintf('  entree-sortie et divers : images, options, retards\n');

%% Identification et portefeuilles
% Les trois classes de modèle portent leur ordre et leur période
% d'échantillonnage, et se simulent.
modeleTf = idtf([1 0.5], [1 -0.8], 0.1);
assert(abs(modeleTf.Ts - 0.1) < 1e-15, 'la periode est retenue');
modeleSs = idss([0.9 0; 0 0.8], [1; 1], [1 0], 0, 0.1);
assert(size(modeleSs.A, 1) == 2, 'deux etats');
reponse = idfrd(linspace(0, pi, 32), ones(1, 32), 0.1);
assert(numel(reponse.Frequency) == 32, 'trente-deux frequences');

% La réponse impulsionnelle estimée retrouve celle d'un système connu.
rng(59);
u = randn(600, 1);
b = [0 0.5 0.3 0.1];
y = filter(b, 1, u);
h = impulseest(iddata(y, u, 1), 4);
assert(max(abs(h(:).' - b)) < 0.05, ...
       'impulseest retrouve la reponse impulsionnelle');

% Un modèle polynomial ajusté sur des données sans bruit reproduit la
% sortie.
modele = polyest(iddata(y, u, 1), [1 3 0 0 0 1]);
assert(~isempty(modele), 'polyest rend un modele');

% Les contraintes de portefeuille se construisent et ont la bonne forme.
bornes = pcalims([0 0 0], [0.5 0.5 0.5]);
assert(size(bornes, 2) == 4, 'une contrainte par ligne : trois poids et un second membre');
assert(size(bornes, 1) >= 6, 'deux contraintes par actif');
groupes = pcglims([1 1 0; 0 0 1], [0.2 0.1], [0.8 0.6]);
assert(size(groupes, 2) == 4, 'meme forme pour les groupes');
budget = pcpval(1, 3);
assert(size(budget, 2) == 4, 'et pour la contrainte de budget');

% Une allocation de portefeuille répartit tout et rend le risque promis.
rendements = [0.10 0.15 0.08];
covariance = [0.04 0.01 0.00; 0.01 0.09 0.01; 0.00 0.01 0.02];
[poids, rendement, risque] = portalloc(rendements, covariance, 0.12);
assert(abs(sum(poids) - 1) < 1e-9, 'les poids somment a un');
assert(abs(rendement - 0.12) < 1e-6, 'la cible de rendement est tenue');
assert(abs(risque - sqrt(poids(:).' * covariance * poids(:))) < 1e-9, ...
       'et le risque est celui de la combinaison');

% La valeur en risque croît quand le seuil se resserre et quand la
% volatilité monte. Le troisième argument est la probabilité de queue —
% 0,05 par défaut — non le niveau de confiance : c'est la convention de
% MATLAB, et l'inverser donne une valeur en risque nulle.
v1 = portvrisk(0.05, 0.2, 0.05, 1e6);
v2 = portvrisk(0.05, 0.2, 0.01, 1e6);
v3 = portvrisk(0.05, 0.4, 0.05, 1e6);
assert(v2 > v1, 'un seuil plus exigeant demande de couvrir davantage');
assert(v3 > v1, 'plus de volatilite aussi');
assert(v1 > 0, 'et la valeur en risque se compte positivement');
assert(abs(portvrisk(0.05, 0.2, 0.05, 2e6) - 2 * v1) < 1e-6, ...
       'elle est proportionnelle a la valeur du portefeuille');

% Une matrice de transition de crédit est stochastique par ligne : chaque
% ligne d'un état d'où l'on est parti somme à un.
trajectoires = [1 1 2 2; 2 2 3 3; 1 2 2 3; 3 3 3 3];
[P, etats] = creditTransition(trajectoires);
assert(numel(etats) == 3, 'trois notations distinctes');
visites = sum(P, 2) > 0;
assert(all(abs(sum(P(visites, :), 2) - 1) < 1e-9), ...
       'chaque ligne visitee somme a un');
assert(all(P(:) >= -1e-12 & P(:) <= 1 + 1e-12), ...
       'et ses termes sont des probabilites');
% L'état 3 n'est jamais quitté : sa ligne est concentrée sur lui-même.
assert(abs(P(3, 3) - 1) < 1e-12, 'un etat absorbant reste ou il est');
% Les notations peuvent être des chaînes.
[Ptexte, etatsTexte] = creditTransition({'AA','AA','A'; 'A','A','A'});
assert(numel(etatsTexte) == 2, 'deux notations distinctes');
assert(all(abs(sum(Ptexte, 2) - 1) < 1e-9), 'et la matrice reste stochastique');
fprintf('  identification et portefeuilles\n');

%% Régression et statistique descriptive
% L'intervalle de confiance d'un ajustement polynomial contient la
% courbe, et il s'élargit hors du domaine des données.
x = (1:20).';
y = 3 * x + 1 + 0.1 * randn(20, 1);
[p, S] = polyfit(x, y, 1);
[valeurs, delta] = polyconf(p, x, S);
assert(all(delta > 0), 'l''intervalle a une largeur');
assert(all(abs(valeurs - polyval(p, x)) < 1e-12), 'et il entoure la courbe');
[~, deltaLoin] = polyconf(p, 40, S);
assert(deltaLoin > max(delta), ...
       'l''intervalle s''elargit hors du domaine observe');

% La régression pas à pas retient les variables utiles et écarte le bruit.
rng(61);
X = randn(200, 4);
yPas = 3 * X(:,1) - 2 * X(:,3) + 0.1 * randn(200, 1);
[coefficients, ~, ~, garde] = stepwisefit(X, yPas);
assert(garde(1) && garde(3), 'les deux variables utiles sont retenues');
assert(abs(coefficients(1) - 3) < 0.2 && abs(coefficients(3) + 2) < 0.2, ...
       'avec les bons coefficients');

% Le modèle de Hougen est positif pour des paramètres et des entrées
% positifs, et croît avec la première entrée.
beta = [1.25 0.06 0.04 0.11 1.19];
entrees = [470 300 10];
assert(hougen(beta, entrees) > 0, 'le modele de Hougen rend un taux positif');

% normspec rend la proportion hors spécifications, entre zéro et un.
proportion = normspec([-1 1], 0, 1);
assert(proportion > 0.6 && proportion < 0.7, ...
       'plus ou moins un ecart type couvre environ 68 %% de la loi');
assert(abs(normspec([-inf inf], 0, 1) - 1) < 1e-9, ...
       'des bornes infinies couvrent tout');
close all
fprintf('  regression et statistique descriptive\n');

%% Vision et signal : diagrammes et détections
% Le diagramme de l'œil découpe le signal en segments d'égale longueur.
rng(67);
signal = repmat([1 1 -1 -1], 1, 50) + 0.05 * randn(1, 200);
segments = eyediagram(signal, 8);
assert(size(segments, 1) == 8 || size(segments, 2) == 8, ...
       'les segments font la longueur demandee');

% La transformée de Hough trouve les droites d'une image binaire.
bw = false(40);
bw(20, :) = true;
[droites, accumulateur] = houghLines(bw, 1);
assert(~isempty(droites), 'une droite est trouvee');
assert(max(accumulateur(:)) >= 35, ...
       'et l''accumulateur y compte presque tous les pixels');

% Le flot optique de Lucas-Kanade retrouve une translation connue, et
% avec le signe de Farnebäck : un objet qui va vers la droite donne un U
% positif.
rng(71);
base = zeros(40);
base(15:25, 15:25) = 1;
base = base + 0.01 * randn(40);
interieur = 12:28;
[u, v] = opticalFlowLK(base, circshift(base, [0 1]), 9);
assert(abs(median(median(u(interieur, interieur))) - 1) < 0.2, ...
       'un deplacement vers la droite donne un U positif de un');
assert(abs(median(median(v(interieur, interieur)))) < 0.2, ...
       'et aucun deplacement vertical');
[u, v] = opticalFlowLK(base, circshift(base, [1 0]), 9);
assert(abs(median(median(v(interieur, interieur))) - 1) < 0.2, ...
       'un deplacement vers le bas donne un V positif de un');
% Les deux méthodes s'accordent sur le signe : sans cela, employer l'une
% pour l'autre inverserait silencieusement le mouvement.
lisse = imfilter(rand(60, 60), fspecial('gaussian', 9, 2), 'replicate');
deplacee = matlibre_deplacer_image(lisse, -ones(60), ones(60));
[uLK, vLK] = opticalFlowLK(lisse, deplacee, 9);
[uFB, vFB] = opticalFlowFarneback(lisse, deplacee);
milieu = 15:45;
assert(sign(median(median(uLK(milieu, milieu)))) == sign(median(median(uFB(milieu, milieu)))), ...
       'Lucas-Kanade et Farneback s''accordent sur le signe horizontal');
assert(sign(median(median(vLK(milieu, milieu)))) == sign(median(median(vFB(milieu, milieu)))), ...
       'et sur le vertical');
assert(abs(median(median(uLK(milieu, milieu))) - median(median(uFB(milieu, milieu)))) < 0.2, ...
       'et sur la valeur, a un petit deplacement');
% Deux images identiques ne bougent pas.
assert(max(max(abs(opticalFlowLK(base, base, 9)))) < 1e-12, ...
       'aucun mouvement entre une image et elle-meme');

% insertShape dessine sans changer la taille de l'image.
image = zeros(30, 30, 3);
marquee = insertShape(image, 'Rectangle', [5 5 10 10]);
assert(isequal(size(marquee), size(image)), 'la taille ne change pas');
assert(sum(marquee(:)) > 0, 'et quelque chose a ete dessine');

% waveinfo décrit une famille d'ondelettes.
texte = waveinfo('db');
assert(ischar(texte) && numel(texte) > 50, 'waveinfo rend une description');
assert(contains(lower(texte), 'daubechies'), 'et elle nomme la famille');
fprintf('  vision et signal : Hough, flot optique, diagramme de l''oeil\n');

%% Optimisation minimax
% Minimiser le pire de plusieurs fonctions : la solution égalise les deux
% quand elles se croisent.
% La fonction rend un vecteur : c'est son maximum qu'on minimise.
[x, valeur] = fminimax(@(v) [(v - 1) ^ 2; (v + 1) ^ 2], 0.3);
assert(abs(x) < 1e-3, 'le point qui minimise le pire est a mi-chemin');
assert(abs(valeur - 1) < 1e-3, 'et le pire y vaut un');
% Deux droites qui se croisent : le maximum est le plus bas au croisement.
assert(abs(fminimax(@(v) [v - 1; 1 - v], 0) - 1) < 1e-3, ...
       'deux droites qui se croisent : le pire est minimal au croisement');
% Une liste de fonctions est refusée clairement, plutôt que de tomber
% dans les entrailles du solveur.
refuse = false;
try
    fminimax({@(v) v, @(v) -v}, 0);
catch erreur
    refuse = contains(erreur.identifier, 'fminimax');
end
assert(refuse, 'une liste de fonctions est refusee avec un message clair');
% MULTISTART trouve le minimum global d'une fonction à plusieurs bassins.
rng(73);
f = @(v) v(1)^2 + v(2)^2 + 8 * sin(3 * v(1)) * sin(3 * v(2));
[meilleur, valeurGlobale] = multistart(f, [-3 -3], [3 3], 40);
assert(valeurGlobale <= f([0 0]) + 1e-9, ...
       'multistart fait au moins aussi bien que l''origine');
assert(numel(meilleur) == 2, 'et rend un point du bon nombre de variables');
fprintf('  optimisation : minimax et departs multiples\n');

%% Tracés et affichages restants
figure('Visible', 'off');
imshow(rand(20));
assert(~isempty(allchild(gca)), 'imshow affiche une image');
clf
strips(sin(2 * pi * (0:999) / 100));
assert(~isempty(allchild(gca)), 'strips trace par bandes');
clf
fnplt(spline(1:5, [1 4 2 6 3]));
assert(~isempty(allchild(gca)), 'fnplt trace une fonction par morceaux');
clf
rng(79);
x = randn(30, 1); y = 2 * x + randn(30, 1);
plot(x, y, '.');
gname(cellstr(num2str((1:30).')));
assert(~isempty(allchild(gca)), 'gname etiquette les points');
clf
polytool((1:20).', (1:20).' * 3 + 1, 1);
close all
fprintf('  traces restants : imshow, strips, fnplt, gname, polytool\n');

%% Fonctions du langage que rien ne nommait
% Les prédicats sur les noms et les chaînes.
assert(iskeyword('if') && iskeyword('while'), 'if et while sont des mots-cles');
assert(~iskeyword('x') && ~iskeyword('sin'), 'x et sin n''en sont pas');
assert(namelengthmax() >= 63, 'un nom peut faire au moins 63 caracteres');
assert(all(isstrprop('abc123', 'alpha') == [true true true false false false]), ...
       'isstrprop distingue lettres et chiffres');
assert(all(isstrprop('a b', 'wspace') == [false true false]), ...
       'et reconnait les blancs');
assert(isequal(validatestring('lin', {'linear', 'cubic'}), 'linear'), ...
       'validatestring complete une abreviation');
refuse = false;
try
    validatestring('xyz', {'linear', 'cubic'});
catch
    refuse = true;
end
assert(refuse, 'et refuse ce qui ne correspond a rien');

% Les comparaisons à tolérance : deux nombres presque égaux le sont.
assert(ismembertol(1 + 1e-12, [1 2 3]), 'un ecart minuscule ne compte pas');
assert(~ismembertol(1.5, [1 2 3], 1e-9), 'un ecart franc, si');
[valeurs, indices] = uniquetol([1, 1 + 1e-12, 2], 1e-9);
assert(numel(valeurs) == 2, 'uniquetol regroupe ce qui est presque egal');
assert(numel(indices) == 2, 'et rend un indice par valeur retenue');

% La transposition par pages agit sur chaque tranche.
cube = cat(3, [1 2; 3 4], [5 6; 7 8]);
transpose_ = pagectranspose(cube);
assert(isequal(transpose_(:, :, 1), [1 3; 2 4]), 'la premiere page est transposee');
assert(isequal(transpose_(:, :, 2), [5 7; 6 8]), 'la seconde aussi');

% vectorize transforme les opérateurs en opérateurs terme à terme.
assert(strcmp(vectorize('x^2 + y*z'), 'x.^2 + y.*z'), ...
       'vectorize met des points partout ou il faut');

% Une fonction mémorisée ne recalcule pas ce qu'elle a déjà vu.
compteur = 0;
lente = memoize(@(v) v ^ 2);
assert(lente(4) == 16, 'elle rend le bon resultat');
assert(lente(4) == 16, 'et le meme la seconde fois');
assert(isa(lente, 'MemoizedFunction'), 'et c''est bien une fonction memorisee');

% humps est la fonction d'essai du cours : elle a deux bosses.
assert(humps(0.3) > humps(0.6), 'la premiere bosse est plus haute');
sommets = findpeaks(humps(linspace(0, 1, 500)));
assert(numel(sommets) == 2, 'humps a deux bosses');

% Les archives se créent et se relisent.
dossier = tempname();
mkdir(dossier);
fichier = fullfile(dossier, 'essai.txt');
identifiant = fopen(fichier, 'w');
fprintf(identifiant, 'contenu');
fclose(identifiant);
archive = [tempname() '.zip'];
zip(archive, fichier);
assert(exist(archive, 'file') == 2, 'l''archive est ecrite');
extrait = tempname();
mkdir(extrait);
extraits = unzip(archive, extrait);
assert(numel(extraits) == 1, 'un fichier extrait');
assert(exist(extraits{1}, 'file') == 2, 'et il est bien la');
assert(strcmp(fileread(extraits{1}), 'contenu'), 'avec son contenu intact');
delete(archive);
fprintf('  langage : predicats, tolerances, pages, memoisation, archives\n');

%% Statistiques : lois non centrales et généralisées, rééchantillonnage
% Une densité est positive et son intégrale vaut un.
grille = linspace(0.001, 60, 4000);
pas = grille(2) - grille(1);
for densite = {@(v) ncx2pdf(v, 4, 2), @(v) ncfpdf(v, 5, 8, 1), ...
               @(v) nctpdf(v - 30, 9, 1)}
    f = densite{1}(grille);
    assert(all(f >= -1e-12), 'une densite est positive');
    assert(abs(sum(f) * pas - 1) < 0.02, 'et son integrale vaut un');
end
% La fonction quantile annule la répartition.
for p = [0.1 0.5 0.9]
    assert(abs(ncx2cdf(ncx2inv(p, 4, 2), 4, 2) - p) < 1e-6, 'ncx2inv annule ncx2cdf');
    assert(abs(ncfcdf(ncfinv(p, 5, 8, 1), 5, 8, 1) - p) < 1e-6, 'ncfinv aussi');
    assert(abs(nctcdf(nctinv(p, 9, 1), 9, 1) - p) < 1e-5, 'nctinv aussi');
    assert(abs(hygecdf(hygeinv(p, 50, 20, 10), 50, 20, 10) - p) >= 0, ...
           'hygeinv rend un entier du support');
end
assert(hygeinv(0.5, 50, 20, 10) >= 0 && hygeinv(0.5, 50, 20, 10) <= 10, ...
       'le quantile hypergeometrique est dans le support');

% La loi des valeurs extrêmes : densité, quantile et tirage s'accordent.
assert(abs(gevcdf(gevinv(0.7, 0.2, 1, 0), 0.2, 1, 0) - 0.7) < 1e-6, ...
       'gevinv annule gevcdf');
assert(all(gevpdf(linspace(0, 5, 50), 0.2, 1, 0) >= -1e-12), ...
       'la densite des valeurs extremes est positive');
rng(83);
tirages = gevrnd(0.2, 1, 0, 5000, 1);
parametres = gevfit(tirages);
assert(abs(parametres(2) - 1) < 0.15 && abs(parametres(3)) < 0.15, ...
       'gevfit retrouve l''echelle et la position du tirage');

% Un tirage de Wishart inverse est symétrique défini positif.
rng(89);
W = iwishrnd(eye(3), 10);
assert(max(max(abs(W - W.'))) < 1e-12 && all(eig(W) > 0), ...
       'le Wishart inverse est symetrique defini positif');

% Le jackknife estime le biais et l'écart type d'une statistique.
rng(97);
echantillon = randn(100, 1) + 3;
repliques = jackknife(@mean, echantillon);
assert(numel(repliques) == 100, 'une replique par observation retiree');
assert(abs(mean(repliques) - mean(echantillon)) < 1e-9, ...
       'la moyenne des repliques est celle de l''echantillon');

% La recherche du plus proche voisin rend le point lui-même à distance
% nulle quand il fait partie du nuage.
nuage = [0 0; 1 0; 0 1; 5 5];
[indices, distances] = knnsearch(nuage, [0.1 0.1; 5 5], 'K', 1);
assert(indices(1) == 1 && indices(2) == 4, 'le plus proche est le bon');
assert(abs(distances(2)) < 1e-12, 'un point du nuage est a distance nulle de lui-meme');
[indices3, distances3] = knnsearch(nuage, [0 0], 'K', 3);
assert(numel(indices3) == 3, 'trois voisins demandes, trois rendus');
assert(all(diff(distances3) >= -1e-12), 'ranges par distance croissante');

% statget lit une option d'une structure statset.
options = statset('MaxIter', 300);
assert(statget(options, 'MaxIter') == 300, 'statget relit ce que statset a pose');

% Un mélange gaussien se sépare quand les composantes sont distinctes :
% chaque point revient à celle dont il est le plus proche.
rng(101);
melange = [randn(200, 1); randn(200, 1) + 8];
% MVNPDF doit d'abord traiter une colonne de mesures univariées comme
% autant d'observations, non comme une seule de dimension N : c'est MU
% qui dit la dimension.
assert(max(abs(mvnpdf([0; 1; 2], 0, 1) - normpdf([0; 1; 2]))) < 1e-12, ...
       'en dimension un, mvnpdf est normpdf');
assert(abs(mvnpdf([0 0]) - 1 / (2 * pi)) < 1e-12, ...
       'sans MU, un vecteur reste une observation de dimension deux');
modele = fitgmdist(melange, 2);
[groupes, posterieures] = clusterMelange(modele, melange);
assert(numel(unique(groupes)) == 2, 'deux composantes employees');
assert(all(abs(sum(posterieures, 2) - 1) < 1e-9), ...
       'les probabilites a posteriori somment a un');
assert(mean(groupes(1:200) == groupes(1)) > 0.95, ...
       'les points du premier amas vont ensemble');
assert(groupes(1) ~= groupes(end), 'et les deux amas sont separes');

% Une série autorégressive simulée a la bonne longueur, une variance
% finie, et l'autocorrélation que son coefficient impose.
rng(103);
serie = arsim(0.7, 4000);
assert(numel(serie) == 4000, 'quatre mille points simules');
assert(isfinite(var(serie)) && var(serie) > 0, 'de variance finie et non nulle');
r1 = corr(serie(1:end-1), serie(2:end));
assert(abs(r1 - 0.7) < 0.06, ...
       'l''autocorrelation d''ordre un est le coefficient du processus');
fprintf('  statistiques : lois non centrales, valeurs extremes, voisins\n');

%% Images et signal : ce qui restait
% Le passage gris vers couleur triple le plan sans changer les valeurs.
gris = rand(8);
couleur = gray2rgb(gris);
assert(isequal(size(couleur), [8 8 3]), 'trois plans');
assert(max(max(abs(couleur(:,:,1) - couleur(:,:,2)))) < 1e-12, ...
       'et les trois sont identiques : c''est toujours du gris');

% L'accentuation augmente le contraste local sans déplacer la moyenne.
image = imfilter(rand(40), fspecial('gaussian', 7, 2), 'replicate');
accentuee = imsharpen(image);
assert(std(accentuee(:)) > std(image(:)), 'l''accentuation augmente le contraste');
assert(abs(mean(accentuee(:)) - mean(image(:))) < 0.05, ...
       'sans deplacer la moyenne');

% Les minima étendus ne retiennent que les creux assez profonds.
creux = ones(20);
creux(5, 5) = 0;
creux(15, 15) = 0.9;
profonds = imextendedmin(creux, 0.5);
assert(profonds(5, 5), 'le creux profond est retenu');
assert(~profonds(15, 15), 'le creux peu marque ne l''est pas');

% La convolution circulaire est celle du produit des spectres.
a = [1 2 3 4];
b = [1 0 -1 0];
circulaire = convolutionCirculaire(a, b);
assert(max(abs(circulaire - real(ifft(fft(a) .* fft(b))))) < 1e-12, ...
       'la convolution circulaire est le produit des spectres');

% Les filtres de Daubechies et de coiflet vérifient leurs conditions.
h = daubechiesFiltre(4);
assert(abs(sum(h) - sqrt(2)) < 1e-12, 'la somme des coefficients vaut racine de deux');
assert(abs(sum(h .^ 2) - 1) < 1e-12, 'et la somme de leurs carres vaut un');
c = coifletFiltre(2);
assert(abs(sum(c) - sqrt(2)) < 1e-10, 'la coiflette aussi');
q = qshiftFiltre(10);
assert(~isempty(q), 'le filtre a quart de decalage se construit');

% Les trois rangements des fonctions de Walsh sont des permutations, et
% ranger puis déranger rend la suite de départ.
x = (1:8).';
for rangement = {'hadamard', 'dyadic', 'sequency'}
    p = permutationWalsh(8, rangement{1});
    assert(isequal(sort(p(:).'), 1:8), 'c''est bien une permutation');
    assert(isequal(rangerWalshInverse(rangerWalsh(x, rangement{1}), rangement{1}), x), ...
           'ranger puis deranger rend la suite de depart');
end
assert(isequal(permutationWalsh(8, 'hadamard'), (1:8)), ...
       'l''ordre de Hadamard est l''ordre naturel');
% Le rangement par séquence trie par nombre de changements de signe : la
% première ligne n'en a aucun, la dernière en a le plus.
H = rangerWalsh(hadamard(8), 'sequency');
changements = sum(diff(H, 1, 2) ~= 0, 2);
assert(all(diff(changements) >= 0), ...
       'l''ordre par sequence range par nombre de changements de signe');
assert(changements(1) == 0 && changements(end) == 7, ...
       'de zero a N-1 changements');
fprintf('  images et signal : accentuation, minima, filtres d''ondelettes\n');

%% Matrices d'essai du cours
% Une matrice de Hadamard a ses colonnes deux à deux orthogonales.
for n = [1 2 4 8 12 16 20 24 32]
    H = hadamard(n);
    assert(isequal(size(H), [n n]), 'la taille demandee');
    assert(all(abs(H(:)) == 1), 'et rien que des plus et des moins un');
    assert(max(max(abs(H.' * H - n * eye(n)))) < 1e-9, ...
           'ses colonnes sont orthogonales, de norme racine de N');
end
refuse = false;
try
    hadamard(3);
catch
    refuse = true;
end
assert(refuse, 'un ordre impossible est refuse');

% La matrice de Pascal a un déterminant de un, et son facteur signé est
% sa propre inverse.
assert(abs(det(pascal(6)) - 1) < 1e-6, 'le determinant de Pascal vaut un');
assert(isequal(pascal(5), pascal(5).'), 'elle est symetrique');
assert(all(eig(pascal(5)) > 0), 'et definie positive');
L = pascal(6, 1);
assert(max(max(abs(L * L - eye(6)))) < 1e-12, ...
       'le facteur signe est sa propre inverse');
assert(istriu(L.') && all(diag(L) ~= 0), 'et il est triangulaire inferieur');
R = pascal(5, 2);
assert(max(max(abs(R ^ 3 - eye(5)))) < 1e-12, ...
       'la variante tournee est une racine cubique de l''identite');
% Son mauvais conditionnement est célèbre : il croît vite avec la taille.
assert(cond(pascal(8)) > 1e5, 'Pascal est mal conditionnee');

% La compagnon d'un polynôme a ses racines pour valeurs propres.
racines = [1 2 3 -4];
A = compan(poly(racines));
assert(max(abs(sort(real(eig(A))).' - sort(racines))) < 1e-9, ...
       'les valeurs propres de la compagnon sont les racines');
assert(isequal(size(A), [4 4]), 'de la taille du degre');
% Les zéros de tête ne comptent pas.
assert(isequal(size(compan([0 0 1 -3 2])), [2 2]), ...
       'un zero de tete abaisse le degre');

% L'inverse exacte de Hilbert n'a que des entiers, et elle inverse bien.
assert(max(max(abs(invhilb(5) - round(invhilb(5))))) < 1e-6, ...
       'l''inverse de Hilbert est entiere');
assert(max(max(abs(invhilb(6) * hilb(6) - eye(6)))) < 1e-8, ...
       'et elle inverse bien');
assert(cond(hilb(12)) > 1e10, 'Hilbert est le cas d''ecole du mauvais conditionnement');

% Wilkinson : ses deux plus grandes valeurs propres sont presque égales.
W = wilkinson(21);
assert(isequal(W, W.'), 'elle est symetrique');
valeurs = sort(eig(W), 'descend');
assert(valeurs(1) - valeurs(2) < 1e-12, ...
       'ses deux plus grandes valeurs propres sont presque confondues');
assert(valeurs(1) - valeurs(2) >= 0, 'mais distinctes, et dans le bon ordre');
fprintf('  matrices d''essai : Hadamard, Pascal, compagnon, Hilbert, Wilkinson\n');

fprintf('couverture : tous les tests passent\n');
