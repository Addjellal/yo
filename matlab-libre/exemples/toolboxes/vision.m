% vision.m — Computer Vision Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/vision.m
%
% Le cas : deux vues d'une même scène. C'est le problème fondateur de la
% vision par ordinateur — trouver ce qui se correspond entre deux images,
% et en déduire la géométrie.

fprintf('=== Vision : detecter, apparier, reconstruire ===\n\n');

%% 1. Une image synthétique
% Un damier partiel avec quelques carrés pleins : des coins nets, faciles
% à détecter et à suivre.
n = 160;
image = 0.9 * ones(n, n);
carres = [30 30; 30 100; 100 30; 100 100; 65 65];
for k = 1:size(carres, 1)
    i = carres(k, 1);
    j = carres(k, 2);
    image(i:i + 20, j:j + 20) = 0.1;
end
% Une texture douce par-dessus. Sans elle les cinq carres seraient
% rigoureusement identiques, et l'appariement de la section 3 serait
% impossible : le test du rapport rejette a juste titre un point dont
% plusieurs candidats se valent. Un motif repetitif est le pire cas de
% l'appariement, et c'est un vrai probleme, pas un defaut de la methode.
[colonnes, lignes] = meshgrid(1:n, 1:n);
image = image + 0.12 * sin(lignes / 23) .* cos(colonnes / 17);
fprintf('Image d''essai : %d x %d, %d carres, plus une texture\n', ...
        n, n, size(carres, 1));

%% 2. Détecter des points d'intérêt
% Un coin est un point où l'image change dans deux directions à la fois :
% c'est ce qui le rend localisable, alors qu'un point sur un bord glisse
% le long de ce bord.
%
% MatLibre rend les points sous forme de matrices — une ligne [x y] par
% point, la force en second argument — là où MATLAB rend un objet
% cornerPoints. Le code qui suit montre la convention à employer ici.
[coinsHarris, forceHarris] = detectHarrisFeatures(image);
coinsFast = detectFASTFeatures(image);
fprintf('\nDetection :\n');
fprintf('  Harris : %d points\n', size(coinsHarris, 1));
fprintf('  FAST   : %d points\n', size(coinsFast, 1));
% Chaque carre a quatre coins : on doit en trouver au moins autant.
assert(size(coinsHarris, 1) >= 4 * size(carres, 1) * 0.8);
assert(size(coinsHarris, 1) == numel(forceHarris));
% Les points les mieux notes tombent sur les coins des carres.
forts = selectStrongest(coinsHarris, forceHarris, 20);
vraisCoins = [];
for k = 1:size(carres, 1)
    i = carres(k, 1);
    j = carres(k, 2);
    vraisCoins = [vraisCoins; j i; j + 20 i; j i + 20; j + 20 i + 20];   %#ok<AGROW>
end
distances = zeros(size(forts, 1), 1);
for k = 1:size(forts, 1)
    distances(k) = min(sqrt(sum((vraisCoins - forts(k, :)) .^ 2, 2)));
end
fprintf('  distance mediane aux vrais coins : %.2f pixel\n', median(distances));
assert(median(distances) < 3);

%% 3. Décrire et apparier
% Un descripteur résume le voisinage d'un point de façon à le reconnaître
% ailleurs. Ici : la même image décalée.
decalage = [12 7];
imageDecalee = circshift(image, decalage);
[pA, fA] = detectHarrisFeatures(image);
[pB, fB] = detectHarrisFeatures(imageDecalee);
pointsA = selectStrongest(pA, fA, 40);
pointsB = selectStrongest(pB, fB, 40);
[descripteursA, valablesA] = extractFeatures(image, pointsA);
[descripteursB, valablesB] = extractFeatures(imageDecalee, pointsB);
paires = matchFeatures(descripteursA, descripteursB);
fprintf('\nAppariement :\n');
fprintf('  %d points a gauche, %d a droite, %d paires\n', ...
        size(descripteursA, 1), size(descripteursB, 1), size(paires, 1));
assert(size(paires, 1) >= 8, 'un simple decalage doit donner beaucoup de paires');
% Le décalage se lit sur les paires : il est le même pour toutes.
depuis = valablesA(paires(:, 1), :);
vers = valablesB(paires(:, 2), :);
decalageTrouve = median(vers - depuis, 1);
fprintf('  decalage median : %s (vrai %s)\n', ...
        mat2str(decalageTrouve), mat2str([decalage(2) decalage(1)]));
assert(max(abs(decalageTrouve - [decalage(2) decalage(1)])) < 2);

%% 4. Estimer une transformation
% Deux paires suffisent pour une similitude ; en pratique on en prend
% davantage et on rejette les fausses par consensus.
[matrice, retenues] = estimateGeometricTransform2D(depuis, vers, 'similarity');
fprintf('\nTransformation estimee :\n');
fprintf('  %d paires retenues sur %d\n', sum(retenues), numel(retenues));
% La convention est celle de MATLAB : les points sont des lignes et la
% transformation s'applique a droite, [x y 1] * T. La translation est
% donc la troisieme ligne, non la troisieme colonne.
fprintf('  translation : %s\n', mat2str(round(matrice(3, 1:2), 2)));
assert(max(abs(matrice(3, 1:2) - [decalage(2) decalage(1)])) < 2);
% Et la transformation renvoie bien les points de gauche sur ceux de droite.
reprojete = [depuis, ones(size(depuis, 1), 1)] * matrice;
assert(max(max(abs(reprojete(:, 1:2) - vers))) < 2);
% Une similitude conserve les angles : sa partie lineaire est un multiple
% d'une rotation.
lineaire = matrice(1:2, 1:2);
assert(max(max(abs(lineaire' * lineaire - eye(2) * det(lineaire)))) < 0.1);

%% 5. Géométrie de la caméra
% Le modèle sténopé : un point du monde se projette en divisant par sa
% profondeur. C'est de cette division que vient toute la difficulté — et
% toute la richesse — de la vision.
focale = 800;
centre = [320 240];
K = [focale 0 0; 0 focale 0; centre 1];
parametres = cameraParameters('IntrinsicMatrix', K);
pointsMonde = [0 0 4; 1 0 4; 0 1 4; 1 1 4];
projection = worldToImage(parametres, eye(3), [0 0 0], pointsMonde);
fprintf('\nProjection stenope :\n');
fprintf('  un point sur l''axe optique se projette en %s\n', ...
        mat2str(round(projection(1, :), 2)));
assert(max(abs(projection(1, :) - centre)) < 1e-9);
% Un decalage de un metre a quatre metres de distance donne focale/4
% pixels : c'est la division par la profondeur.
assert(abs(projection(2, 1) - projection(1, 1) - focale / 4) < 1e-9);
% Deux fois plus loin, deux fois plus petit.
loin = worldToImage(parametres, eye(3), [0 0 0], [1 0 8]);
assert(abs(loin(1) - centre(1) - focale / 8) < 1e-9);

%% 6. Stéréovision
% Deux caméras côte à côte : la différence de position d'un même point
% entre les deux images — la disparité — donne la profondeur.
gauche = 0.5 + 0.4 * sin((1:200) / 7)' * cos((1:200) / 11);
disparite = 3;
droite = circshift(gauche, [0 -disparite]);
carteDisparite = disparitySGM(gauche, droite, 'DisparityRange', [0 16]);
coeur = carteDisparite(20:180, 30:170);
fprintf('\nStereovision :\n');
fprintf('  disparite mediane trouvee : %.2f (vraie %d)\n', ...
        median(coeur(:)), disparite);
assert(abs(median(coeur(:)) - disparite) < 1);
% La profondeur est inversement proportionnelle a la disparite :
%   Z = focale * base / disparite
base = 0.1;
profondeur = focale * base / disparite;
fprintf('  profondeur correspondante : %.3f m (base %g m)\n', profondeur, base);

%% 7. Segmenter
% Les superpixels regroupent les pixels voisins et semblables : on passe
% de dizaines de milliers de pixels à quelques centaines de régions, sans
% traverser les contours.
[etiquettes, nombre] = superpixels(image, 40);
fprintf('\nSuperpixels : %d regions demandees, %d obtenues\n', 40, nombre);
assert(nombre > 20 && nombre < 80);
% Aucune region ne doit chevaucher un contour : sa variance reste faible.
variances = zeros(1, nombre);
for k = 1:nombre
    variances(k) = var(image(etiquettes == k));
end
fprintf('  variance mediane dans une region : %.5f (image %.5f)\n', ...
        median(variances), var(image(:)));
assert(median(variances) < var(image(:)) / 10, ...
       'une region ne doit pas traverser un contour');

%% 8. Flot optique
% Ce qui bouge, et de combien. L'hypothèse est que la luminosité d'un
% point ne change pas quand il se déplace.
motif = 0.5 + 0.4 * sin((1:120)' / 5) * cos((1:120) / 7);
suivant = circshift(motif, [-2 3]);
[u, v] = opticalFlowFarneback(motif, suivant);
milieu = 30:90;
uMedian = median(median(u(milieu, milieu)));
vMedian = median(median(v(milieu, milieu)));
fprintf('\nFlot optique :\n');
fprintf('  deplacement estime : u %.3f (vrai 3), v %.3f (vrai -2)\n', uMedian, vMedian);
assert(abs(uMedian - 3) < 0.3);
assert(abs(vMedian + 2) < 0.3);

fprintf('\nToutes les verifications passent.\n');
