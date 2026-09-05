% images.m — Image Processing Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/images.m
%
% Le cas : une image de pièces sur fond clair, à compter. C'est
% l'enchaînement classique du traitement d'image — seuiller, nettoyer,
% étiqueter, mesurer.

fprintf('=== Images : compter et mesurer des objets ===\n\n');

%% 1. Fabriquer l'image d'essai
% Trois disques de rayons differents sur un fond clair, plus du bruit.
n = 200;
[X, Y] = meshgrid(1:n, 1:n);
image = 0.85 * ones(n, n);
centres = [50 60; 120 70; 140 150];
rayons = [18 25 12];
for k = 1:3
    dedans = (X - centres(k, 2)) .^ 2 + (Y - centres(k, 1)) .^ 2 <= rayons(k) ^ 2;
    image(dedans) = 0.2;
end
rng(1);
image = min(max(image + 0.06 * randn(n, n), 0), 1);
fprintf('Image : %d x %d, valeurs de %.3f a %.3f\n', n, n, min(image(:)), max(image(:)));

%% 2. Débruiter
% Un filtre médian ôte le bruit impulsionnel sans étaler les contours,
% ce qu'une moyenne ferait. C'est la raison de le préférer ici.
lisse = medfilt2(image, [3 3]);
fprintf('\nDebruitage :\n');
fprintf('  ecart type du bruit de fond : %.4f -> %.4f\n', ...
        std(image(1:20, 1:20), 0, 'all'), std(lisse(1:20, 1:20), 0, 'all'));
assert(std(lisse(1:20, 1:20), 0, 'all') < std(image(1:20, 1:20), 0, 'all'));
% Le filtre gaussien, lui, floute aussi les contours.
flou = imgaussfilt(image, 2);
gradientAvant = mean(abs(diff(lisse(60, :))));
gradientApres = mean(abs(diff(flou(60, :))));
fprintf('  gradient moyen : median %.4f, gaussien %.4f\n', gradientAvant, gradientApres);

%% 3. Seuiller
% Le seuil d'Otsu sépare l'histogramme en deux classes en maximisant la
% variance entre elles. Il ne demande aucun réglage : c'est ce qui le
% rend utilisable sans connaître l'éclairage.
seuil = graythresh(lisse);
binaire = ~imbinarize(lisse, seuil);   % les pieces sont sombres
fprintf('\nSeuillage d''Otsu :\n');
fprintf('  seuil %.4f, %.2f %% de pixels retenus\n', seuil, mean(binaire(:)) * 100);
assert(seuil > 0.2 && seuil < 0.85, 'le seuil doit tomber entre les deux modes');
airesVraies = pi * rayons .^ 2;
fprintf('  aire totale : %d pixels (attendu %d)\n', ...
        sum(binaire(:)), round(sum(airesVraies)));
assert(abs(sum(binaire(:)) - sum(airesVraies)) / sum(airesVraies) < 0.1);

%% 4. Nettoyer par morphologie
% L'ouverture ôte ce qui est plus petit que l'élément structurant ; la
% fermeture bouche les trous. L'ordre compte : ouvrir puis fermer nettoie
% sans faire grossir.
elementStructurant = strel('disk', 2);
nettoye = imclose(imopen(binaire, elementStructurant), elementStructurant);
fprintf('\nMorphologie :\n');
fprintf('  pixels : %d -> %d\n', sum(binaire(:)), sum(nettoye(:)));
% Une ouverture est idempotente : la refaire ne change plus rien.
uneFois = imopen(binaire, elementStructurant);
deuxFois = imopen(uneFois, elementStructurant);
assert(isequal(uneFois, deuxFois), 'l''ouverture est idempotente');
% Et elle est incluse dans l'image de depart.
assert(all(uneFois(:) <= binaire(:)), 'l''ouverture ne peut qu''oter');

%% 5. Étiqueter et mesurer
etiquettes = bwlabel(nettoye);
nombre = max(etiquettes(:));
fprintf('\nEtiquetage : %d objets trouves (attendu 3)\n', nombre);
assert(nombre == 3);
mesures = regionprops(etiquettes, 'Area', 'Centroid');
aires = sort([mesures.Area], 'descend');
fprintf('  aires  : %s\n', mat2str(aires));
fprintf('  vraies : %s\n', mat2str(round(sort(airesVraies, 'descend'))));
assert(max(abs(aires - sort(airesVraies, 'descend')) ./ sort(airesVraies, 'descend')) < 0.15);
% Les centres retrouvés sont les vrais, à l'ordre près.
trouves = reshape([mesures.Centroid], 2, [])';
for k = 1:3
    distance = min(sqrt(sum((trouves - centres(k, [2 1])) .^ 2, 2)));
    assert(distance < 3, 'chaque centre doit etre retrouve');
end
fprintf('  centres retrouves a moins de 3 pixels pres\n');

%% 6. Contours
% Le détecteur de Canny : lisser, dériver, garder les maximums locaux du
% gradient, puis suivre les crêtes par double seuil.
perimetreVrai = sum(2 * pi * rayons);
[automatique, seuilAuto] = edge(lisse, 'canny');
fprintf('\nContours de Canny :\n');
fprintf('  seuils automatiques %s : %d pixels\n', ...
        mat2str(round(seuilAuto, 4)), sum(automatique(:)));
fprintf('  perimetre vrai des trois disques : %d pixels\n', round(perimetreVrai));
% Le seuil automatique place la coupure au septieme decile du gradient.
% Sur une image bruitee, ce decile tombe dans le bruit : Canny detecte
% alors bien plus que les contours cherches. C'est le comportement
% attendu, non un defaut — et c'est pourquoi on lui donne des seuils.
assert(sum(automatique(:)) > perimetreVrai * 3, ...
       'le seuil automatique sur-detecte sur une image bruitee');
% Deux remedes : lisser davantage, ou imposer les seuils.
plusLisse = edge(lisse, 'canny', [], 3);
impose = edge(lisse, 'canny', [0.2 0.5]);
fprintf('  avec sigma = 3            : %d pixels\n', sum(plusLisse(:)));
fprintf('  avec seuils [0.2 0.5]     : %d pixels\n', sum(impose(:)));
assert(sum(impose(:)) < sum(automatique(:)) / 3, ...
       'imposer les seuils doit reduire fortement la detection');
% Un contour est une courbe : sa longueur va comme le perimetre, non
% comme l'aire.
assert(sum(impose(:)) > perimetreVrai / 3);
assert(sum(impose(:)) < perimetreVrai * 3);

%% 7. Transformations géométriques
% Une rotation puis son inverse doit rendre l'image de départ.
tourne = imrotate(image, 30, 'bilinear', 'crop');
retour = imrotate(tourne, -30, 'bilinear', 'crop');
coeur = 60:140;
ecart = max(max(abs(retour(coeur, coeur) - image(coeur, coeur))));
fprintf('\nRotation 30 degres aller-retour : ecart max %.4f au centre\n', ecart);
assert(ecart < 0.35, 'l''interpolation degrade, mais ne detruit pas');

% Le redimensionnement conserve les proportions.
reduit = imresize(image, 0.5);
fprintf('Redimensionnement : %s -> %s\n', mat2str(size(image)), mat2str(size(reduit)));
assert(isequal(size(reduit), [n / 2, n / 2]));

%% 8. Histogramme et contraste
% Égaliser l'histogramme étale les niveaux sur toute la dynamique.
faibleContraste = image * 0.3 + 0.35;
egalise = histeq(faibleContraste);
fprintf('\nContraste :\n');
fprintf('  etendue : %.3f -> %.3f\n', ...
        max(faibleContraste(:)) - min(faibleContraste(:)), ...
        max(egalise(:)) - min(egalise(:)));
assert(max(egalise(:)) - min(egalise(:)) > ...
       max(faibleContraste(:)) - min(faibleContraste(:)));

fprintf('\nToutes les verifications passent.\n');
