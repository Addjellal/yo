%% Réseaux d'antennes : former des voies, trouver les directions
% Plusieurs capteurs alignés ne mesurent pas seulement plus fort : ils
% mesurent une direction. Un front d'onde incliné arrive décalé d'un
% capteur à l'autre, et ce décalage porte toute l'information angulaire.
%
% Voir aussi STEERINGVECTOR, ARRAYGAIN, BEAMFORMERDAS, MUSICSPECTRUM.

fprintf('=== Reseaux d''antennes ===\n');

%% 1. Le vecteur de pointage
% C'est la signature d'une direction sur le réseau : le déphasage que
% subit chaque élément quand l'onde arrive de cet angle. Tout le reste en
% découle.
n = 8;
d = 0.5;
a0 = steeringVector(n, d, 0);
fprintf('\nReseau de %d elements espaces de %g lambda :\n', n, d);
fprintf('  au zenith (theta = 0) : tous les elements en phase\n');
assert(max(abs(a0 - 1)) < 1e-15, ...
       'perpendiculairement, aucun element n''est en retard');

% À trente degrés, le déphasage entre voisins vaut 2 pi d sin(theta).
a30 = steeringVector(n, d, deg2rad(30));
dephasage = angle(a30(2) / a30(1));
fprintf('  a 30 degres : dephasage voisin a voisin %.4f rad (predit %.4f)\n', ...
        dephasage, 2 * pi * d * sind(30));
assert(abs(dephasage - 2 * pi * d * sind(30)) < 1e-12, ...
       'le dephasage suit 2 pi d sin(theta)');
% Le module est constant : le vecteur de pointage ne change que les phases.
assert(max(abs(abs(a30) - 1)) < 1e-15, 'un vecteur de pointage est unimodulaire');
assert(abs(norm(a30) - sqrt(n)) < 1e-14, 'de norme racine de N');

%% 2. Le gain du réseau et son ambiguïté
% Pointé dans une direction, le réseau y donne un gain de un — toute la
% puissance — et bien moins ailleurs. C'est ce contraste qui sépare deux
% sources voisines.
angles = linspace(-pi/2, pi/2, 36001);
g = arrayGain(n, d, angles, 0);
fprintf('\nGain du reseau pointe au zenith :\n');
fprintf('  dans la direction visee : %.6f\n', arrayGain(n, d, 0, 0));
assert(abs(arrayGain(n, d, 0, 0) - 1) < 1e-15, ...
       'dans la direction visee le gain vaut un');
[~, imax] = max(g);
assert(abs(angles(imax)) < 1e-3, 'et c''est bien le maximum');
% Le gain n'excède jamais un : c'est une moyenne de termes de module un.
assert(max(g) <= 1 + 1e-12, 'le gain ne peut pas depasser un');

% L'ouverture du faisceau se resserre comme l'inverse de la longueur du
% réseau : c'est la résolution angulaire, et elle ne s'achète qu'en
% étendue physique.
fprintf('  ouverture a -3 dB selon la taille :\n');
precedente = inf;
for nn = [4 8 16 32]
    gg = arrayGain(nn, d, angles, 0);
    o = beamwidth(angles, gg);
    fprintf('    %2d elements (%.1f lambda) : %.2f degres\n', ...
            nn, (nn - 1) * d, rad2deg(o));
    assert(o < precedente, 'un reseau plus long resout mieux');
    precedente = o;
end
o8 = beamwidth(angles, arrayGain(8, d, angles, 0));
o32 = beamwidth(angles, arrayGain(32, d, angles, 0));
fprintf('  quadrupler la taille divise l''ouverture par %.2f\n', o8 / o32);
assert(abs(o8 / o32 - 4) < 0.3, 'l''ouverture varie comme l''inverse de la taille');

% Ambiguïté spatiale : au-delà d'un demi-pas d'onde, deux directions
% distinctes donnent le même jeu de phases, et le réseau ne peut plus les
% distinguer. C'est le repliement d'échantillonnage, transposé en espace.
gLarge = arrayGain(n, 1.0, angles, 0);
ailleurs = gLarge(abs(angles) > deg2rad(20));
fprintf('  espacement lambda : gain max hors du faisceau %.4f\n', max(ailleurs));
assert(max(ailleurs) > 0.99, ...
       'a lambda d''espacement, une autre direction est confondue avec la visee');
gDemi = arrayGain(n, 0.5, angles, 0);
ailleurs = gDemi(abs(angles) > deg2rad(20));
fprintf('  espacement lambda/2 : gain max hors du faisceau %.4f\n', max(ailleurs));
assert(max(ailleurs) < 0.3, 'a lambda/2, aucune ambiguite');

%% 3. La formation de voies par retard et somme
% Le plus simple des traitements : remettre les capteurs en phase pour la
% direction voulue, puis sommer. Le signal de cette direction s'additionne
% de façon cohérente, le bruit non — d'où un gain de N en puissance.
rng(11);
nEch = 4000;
theta0 = deg2rad(20);
signal = randn(1, nEch);
propre = steeringVector(n, d, theta0) * signal;
bruit = (randn(n, nEch) + 1i * randn(n, nEch)) / sqrt(2);
recu = propre + bruit;

sortie = beamformerDAS(recu, d, theta0);
rsbAvant = var(signal) / var(bruit(1, :));
rsbApres = var(signal) / var(sortie(:).' - signal);
fprintf('\nFormation de voies sur %d elements :\n', n);
fprintf('  RSB sur un capteur : %.2f dB\n', 10 * log10(rsbAvant));
fprintf('  RSB apres sommation : %.2f dB\n', 10 * log10(rsbApres));
fprintf('  gain de traitement %.2f dB (predit %.2f dB)\n', ...
        10 * log10(rsbApres / rsbAvant), 10 * log10(n));
assert(abs(10 * log10(rsbApres / rsbAvant) - 10 * log10(n)) < 1, ...
       'sommer N capteurs gagne 10 log N decibels');

% Pointer ailleurs perd le signal : c'est bien une direction que l'on
% choisit, non un simple moyennage.
mauvaise = beamformerDAS(recu, d, theta0 + deg2rad(30));
fprintf('  pointe a 30 degres de la source : puissance %.4f contre %.4f\n', ...
        var(mauvaise), var(sortie));
assert(var(mauvaise) < var(sortie) / 3, ...
       'mal pointe, le formateur perd la source');

%% 4. MUSIC, ou la résolution au-delà du faisceau
% Le formateur de voies ne sépare pas deux sources plus proches que son
% ouverture. MUSIC, lui, exploite la structure de la matrice de
% covariance : les directions des sources sont celles où le vecteur de
% pointage est orthogonal au sous-espace bruit. La résolution n'est plus
% bornée par l'ouverture, mais par le rapport signal à bruit.
directions = deg2rad([-10 15]);
sources = randn(numel(directions), nEch) + 1i * randn(numel(directions), nEch);
A = [steeringVector(n, d, directions(1)), steeringVector(n, d, directions(2))];
recu = A * sources + 0.1 * (randn(n, nEch) + 1i * randn(n, nEch));

[spectre, grille] = musicSpectrum(recu, d, 2);
spectre = spectre / max(spectre);
pics = find(spectre(2:end-1) > spectre(1:end-2) & ...
            spectre(2:end-1) > spectre(3:end) & spectre(2:end-1) > 0.05) + 1;
[~, ordre] = sort(spectre(pics), 'descend');
trouvees = sort(grille(pics(ordre(1:2))));
fprintf('\nMUSIC, deux sources a %g et %g degres :\n', ...
        rad2deg(directions(1)), rad2deg(directions(2)));
fprintf('  trouvees a %.2f et %.2f degres\n', ...
        rad2deg(trouvees(1)), rad2deg(trouvees(2)));
assert(max(abs(trouvees - directions)) < deg2rad(1), ...
       'MUSIC retrouve les deux directions');

% Deux sources bien plus proches que l'ouverture du réseau : le formateur
% de voies ne voit qu'une bosse, MUSIC en voit deux. C'est exactement ce
% que veut dire « super-résolution ».
ouverture = beamwidth(angles, arrayGain(n, d, angles, 0));
serrees = deg2rad([-3 3]);
A = [steeringVector(n, d, serrees(1)), steeringVector(n, d, serrees(2))];
recu = A * sources + 0.02 * (randn(n, nEch) + 1i * randn(n, nEch));
fprintf('  ouverture du reseau : %.1f degres ; sources ecartees de %.0f\n', ...
        rad2deg(ouverture), rad2deg(diff(serrees)));

das = zeros(size(grille));
for k = 1:numel(grille)
    das(k) = mean(abs(beamformerDAS(recu, d, grille(k))) .^ 2);
end
picsDAS = sum(das(2:end-1) > das(1:end-2) & das(2:end-1) > das(3:end) & ...
              das(2:end-1) > 0.5 * max(das));
[spectre, grille] = musicSpectrum(recu, d, 2);
spectre = spectre / max(spectre);
pics = find(spectre(2:end-1) > spectre(1:end-2) & ...
            spectre(2:end-1) > spectre(3:end) & spectre(2:end-1) > 0.02) + 1;
fprintf('  retard-et-somme : %d bosse(s) ; MUSIC : %d pic(s)\n', ...
        picsDAS, numel(pics));
assert(picsDAS == 1, 'le formateur ne separe pas des sources si proches');
assert(numel(pics) == 2, 'MUSIC, si');
[~, ordre] = sort(spectre(pics), 'descend');
trouvees = sort(grille(pics(ordre(1:2))));
fprintf('  MUSIC les place a %.2f et %.2f degres\n', ...
        rad2deg(trouvees(1)), rad2deg(trouvees(2)));
assert(max(abs(trouvees - serrees)) < deg2rad(1.5), 'et a la bonne place');

% Le prix : il faut connaître le nombre de sources. En annoncer un de trop
% ou un de moins fausse le résultat — c'est la faiblesse de la méthode.
[spectreFaux, ~] = musicSpectrum(recu, d, 1);
spectreFaux = spectreFaux / max(spectreFaux);
picsFaux = sum(spectreFaux(2:end-1) > spectreFaux(1:end-2) & ...
               spectreFaux(2:end-1) > spectreFaux(3:end) & ...
               spectreFaux(2:end-1) > 0.02);
fprintf('  en annoncant une seule source : %d pic(s) au lieu de deux\n', picsFaux);
assert(picsFaux < 2, 'sous-estimer le nombre de sources en fait perdre une');

fprintf('\nToutes les verifications passent.\n');
