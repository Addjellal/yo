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

fprintf('couverture : tous les tests passent\n');
