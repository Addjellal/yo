% imagerie-medicale.m — Medical Imaging Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/imagerie-medicale.m
%
% Le cas : la tomographie. Un scanner ne photographie pas une coupe : il
% en mesure les projections sous tous les angles, et la coupe se
% reconstruit ensuite. C'est le problème inverse fondateur de l'imagerie
% médicale.

fprintf('=== Imagerie medicale : projeter, reconstruire, mesurer ===\n\n');

%% 1. Une coupe d'essai
% Deux disques de densités différentes dans un fond vide.
n = 64;
[X, Y] = meshgrid(linspace(-1, 1, n), linspace(-1, 1, n));
coupe = zeros(n, n);
coupe((X + 0.25) .^ 2 + (Y + 0.1) .^ 2 < 0.09) = 1;
coupe((X - 0.3) .^ 2 + (Y - 0.25) .^ 2 < 0.04) = 0.6;
fprintf('Coupe %dx%d, deux structures de densites %g et %g\n', ...
        n, n, 1, 0.6);
assert(max(coupe(:)) == 1);

%% 2. La projection
% Sous un angle donné, le détecteur mesure l'intégrale de la densité le
% long de chaque rayon. L'ensemble de ces mesures, pour tous les angles,
% forme le sinogramme.
angles = 0:2:178;
[sinogramme, anglesRendus] = radonTransform(coupe, angles);
fprintf('\nSinogramme : %d detecteurs x %d angles\n', ...
        size(sinogramme, 1), size(sinogramme, 2));
assert(size(sinogramme, 2) == numel(angles));
assert(numel(anglesRendus) == numel(angles));
% Chaque colonne totalise la meme masse, quel que soit l'angle : une
% integrale ne depend pas de la direction sous laquelle on la prend.
masses = sum(sinogramme, 1);
fprintf('  masse par angle : de %.4f a %.4f (ecart relatif %.4f)\n', ...
        min(masses), max(masses), (max(masses) - min(masses)) / mean(masses));
assert((max(masses) - min(masses)) / mean(masses) < 0.06, ...
       'la masse totale ne depend pas de l''angle de projection');
% Et cette masse vaut celle de la coupe, a la discretisation pres.
fprintf('  masse de la coupe : %.4f, moyenne des projections : %.4f\n', ...
        sum(coupe(:)), mean(masses));
assert(abs(mean(masses) / sum(coupe(:)) - 1) < 0.1);

%% 3. La reconstruction
% Le problème inverse : retrouver la coupe depuis ses projections. La
% rétroprojection filtrée étale chaque projection sur toute l'image, mais
% après l'avoir filtrée en rampe — sans ce filtre, les basses fréquences
% s'accumulent et l'image sort floue.
reconstruite = iradonTransform(sinogramme, anglesRendus, n);
fprintf('\nReconstruction %dx%d\n', size(reconstruite, 1), size(reconstruite, 2));
assert(isequal(size(reconstruite), [n n]));
% Les structures se retrouvent au bon endroit.
seuil = max(reconstruite(:)) / 2;
masqueVrai = coupe > 0.3;
masqueTrouve = reconstruite > seuil;
recouvrement = diceIndex(masqueVrai, masqueTrouve);
fprintf('  indice de Dice entre la verite et la reconstruction : %.4f\n', ...
        recouvrement);
assert(recouvrement > 0.6, 'les structures doivent etre retrouvees');
% Le centre du gros disque se retrouve la ou il est.
[~, indice] = max(reconstruite(:));
[ligneTrouvee, colonneTrouvee] = ind2sub(size(reconstruite), indice);
[~, indiceVrai] = max(coupe(:));
[ligneVraie, colonneVraie] = ind2sub(size(coupe), indiceVrai);
fprintf('  maximum : reconstruit en (%d,%d), attendu vers (%d,%d)\n', ...
        ligneTrouvee, colonneTrouvee, ligneVraie, colonneVraie);
assert(abs(ligneTrouvee - ligneVraie) < n / 4);

%% 4. Le nombre d'angles
% Moins d'angles, moins d'information : la reconstruction se dégrade et
% des artefacts en étoile apparaissent. C'est la raison pour laquelle un
% scanner tourne.
fprintf('\nEffet du nombre d''angles :\n');
qualites = zeros(1, 4);
nombres = [6 18 45 90];
for k = 1:4
    anglesPeu = linspace(0, 178, nombres(k));
    [sinoPeu, anglesPeuRendus] = radonTransform(coupe, anglesPeu);
    imagePeu = iradonTransform(sinoPeu, anglesPeuRendus, n);
    qualites(k) = diceIndex(masqueVrai, imagePeu > max(imagePeu(:)) / 2);
    fprintf('  %2d angles : Dice %.4f\n', nombres(k), qualites(k));
end
assert(qualites(end) > qualites(1), ...
       'plus d''angles donne une meilleure reconstruction');

%% 5. Comparer deux segmentations
% L'indice de Dice mesure le recouvrement de deux masques : deux fois
% l'intersection sur la somme des tailles. Il vaut un pour deux masques
% identiques, zéro pour deux masques disjoints.
a = false(20, 20);
a(5:14, 5:14) = true;
b = false(20, 20);
b(8:17, 8:17) = true;
fprintf('\nIndice de Dice :\n');
fprintf('  un masque avec lui-meme : %.6f\n', diceIndex(a, a));
assert(abs(diceIndex(a, a) - 1) < 1e-12);
disjoint = false(20, 20);
disjoint(1:3, 1:3) = true;
fprintf('  deux masques disjoints  : %.6f\n', diceIndex(a, disjoint));
assert(diceIndex(a, disjoint) == 0);
recouvrementPartiel = diceIndex(a, b);
fprintf('  deux carres decales     : %.6f\n', recouvrementPartiel);
% Verification par la definition.
intersection = sum(a(:) & b(:));
attendu = 2 * intersection / (sum(a(:)) + sum(b(:)));
assert(abs(recouvrementPartiel - attendu) < 1e-12);
assert(recouvrementPartiel > 0 && recouvrementPartiel < 1);
% Il est symetrique.
assert(abs(diceIndex(a, b) - diceIndex(b, a)) < 1e-12);

%% 6. La distance de Hausdorff
% Dice mesure le volume commun ; Hausdorff mesure la pire erreur de
% contour. Deux segmentations peuvent avoir un excellent Dice et une
% mauvaise distance de Hausdorff — une seule excroissance suffit — et
% c'est pourquoi on rapporte les deux.
[lignesA, colonnesA] = find(a);
[lignesB, colonnesB] = find(b);
distance = hausdorffDist([lignesA colonnesA], [lignesB colonnesB]);
fprintf('\nDistance de Hausdorff entre les deux carres : %.4f\n', distance);
assert(distance > 0);
% Un ensemble est a distance nulle de lui-meme.
assert(hausdorffDist([lignesA colonnesA], [lignesA colonnesA]) == 0);
% Elle est symetrique.
assert(abs(hausdorffDist([lignesA colonnesA], [lignesB colonnesB]) - ...
           hausdorffDist([lignesB colonnesB], [lignesA colonnesA])) < 1e-12);
% Un seul point tres loin la fait exploser, alors que Dice bouge a peine.
avecExcroissance = b;
avecExcroissance(20, 20) = true;
[lignesC, colonnesC] = find(avecExcroissance);
fprintf('  Dice avec une excroissance : %.4f -> %.4f\n', ...
        diceIndex(a, b), diceIndex(a, avecExcroissance));
fprintf('  Hausdorff : %.4f -> %.4f\n', distance, ...
        hausdorffDist([lignesA colonnesA], [lignesC colonnesC]));
assert(abs(diceIndex(a, avecExcroissance) - diceIndex(a, b)) < 0.02, ...
       'Dice ne voit presque pas une excroissance d''un pixel');
assert(hausdorffDist([lignesA colonnesA], [lignesC colonnesC]) > distance, ...
       'Hausdorff, si : c''est ce qui les rend complementaires');

%% 7. Le fenêtrage
% Une image scanner porte des milliers de niveaux, un écran en montre
% deux cent cinquante-six. Le fenêtrage choisit la tranche à regarder :
% c'est le réglage que le radiologue manipule en permanence.
brut = linspace(-1000, 3000, 400);
fenetre = windowLevel(brut, 40, 400);      % fenetre des tissus mous
fprintf('\nFenetrage centre sur 40, largeur 400 :\n');
fprintf('  entree de %g a %g, sortie de %.4f a %.4f\n', ...
        min(brut), max(brut), min(fenetre), max(fenetre));
assert(min(fenetre) >= 0 && max(fenetre) <= 1, 'la sortie est normalisee');
% Tout ce qui est sous la fenetre sature en bas, tout ce qui est au-dessus
% sature en haut : c'est le principe meme, et c'est ce qui fait
% disparaitre l'os quand on regarde les tissus mous.
assert(fenetre(1) == 0, 'bien en dessous de la fenetre');
assert(fenetre(end) == 1, 'bien au-dessus');
% Le centre de la fenetre tombe a mi-hauteur.
[~, kCentre] = min(abs(brut - 40));
fprintf('  au centre de la fenetre : %.4f (attendu 0.5)\n', fenetre(kCentre));
assert(abs(fenetre(kCentre) - 0.5) < 0.01);
% Une fenetre plus large aplatit le contraste.
large = windowLevel(brut, 40, 2000);
dansTissus = brut > -160 & brut < 240;
fprintf('  contraste dans les tissus mous : %.4f (fenetre 400) contre %.4f (2000)\n', ...
        max(fenetre(dansTissus)) - min(fenetre(dansTissus)), ...
        max(large(dansTissus)) - min(large(dansTissus)));
assert(max(large(dansTissus)) - min(large(dansTissus)) < ...
       max(fenetre(dansTissus)) - min(fenetre(dansTissus)), ...
       'elargir la fenetre reduit le contraste local');

fprintf('\nToutes les verifications passent.\n');
