% test_images.m — Image Processing Toolbox.
% Les références sont des valeurs exactes : bords calculés à la main,
% identités de transformées, définitions des descripteurs de texture.
disp('--- images ---');

%% ------------------------------------------------------------ bordures
assert(isequal(padarray([1 2; 3 4], [1 1]), ...
               [0 0 0 0; 0 1 2 0; 0 3 4 0; 0 0 0 0]));
assert(isequal(padarray([1 2; 3 4], [0 1], 'replicate'), [1 1 2 2; 3 3 4 4]));
assert(isequal(padarray([1 2; 3 4], [0 1], 'symmetric'), [1 1 2 2; 3 3 4 4]));
assert(isequal(padarray([1 2 3], [0 1], 'circular'), [3 1 2 3 1]));
assert(isequal(padarray([1 2], [0 1], 0, 'pre'), [0 1 2]));
assert(isequal(padarray([1 2], [0 1], 0, 'post'), [1 2 0]));

%% ---------------------------------------------------------- filtrage
% Par défaut, imfilter complète par des zéros : les coins valent 4/9.
assert(max(max(abs(imfilter(ones(3), ones(3)/9) - ...
    [4 6 4; 6 9 6; 4 6 4]/9))) < 1e-12);
% Avec 'replicate', l'image constante reste constante.
assert(max(max(abs(imfilter(ones(3), ones(3)/9, 'replicate') - 1))) < 1e-12);
assert(isequal(size(imfilter(ones(3), ones(3), 'full')), [5 5]));
assert(max(max(abs(imboxfilt(ones(5), 3) - 1))) < 1e-12);

% conv2 connaît les trois formes.
assert(isequal(size(conv2(ones(5), ones(3), 'valid')), [3 3]));
assert(isequal(size(conv2(ones(5), ones(3), 'same')), [5 5]));
assert(isequal(size(conv2(ones(5), ones(3))), [7 7]));

% Filtre de rang : minimum, médiane, maximum du voisinage 3x3.
a = [1 2 3; 4 5 6; 7 8 9];
assert(ordfilt2(a, 9, ones(3))(2, 2) == 9);
assert(ordfilt2(a, 1, ones(3))(2, 2) == 1);
assert(ordfilt2(a, 5, ones(3))(2, 2) == 5);
assert(rangefilt([1 2; 3 4])(1, 1) == 3);
% Une image constante a un écart-type local nul.
assert(max(max(stdfilt(ones(4)))) < 1e-12);
% Une image constante a une entropie locale nulle.
assert(max(max(entropyfilt(ones(4), ones(3)))) < 1e-12);

%% ---------------------------------------------------------- gradient
% Sur la rampe [1 2 3; 4 5 6; 7 8 9], la réponse de Sobel vaut
% (droite - gauche) = 8 en horizontal, et trois fois plus en vertical.
[gx, gy] = imgradientxy(a);
assert(abs(gx(2, 2) - 8) < 1e-12);
assert(abs(gy(2, 2) - 24) < 1e-12);
[g, d] = imgradient(a);
assert(abs(g(2, 2) - sqrt(8^2 + 24^2)) < 1e-12);
assert(abs(d(2, 2) - atan2d(-24, 8)) < 1e-9);
% 'central' est la différence centrée, sans pondération.
[gx2, gy2] = imgradientxy(a, 'central');
assert(abs(gx2(2, 2) - 1) < 1e-12);
assert(abs(gy2(2, 2) - 3) < 1e-12);

%% ------------------------------------------------------------ couleurs
rouge = cat(3, 1, 0, 0);
h = rgb2hsv(rouge);
assert(abs(h(1)) < 1e-12 && abs(h(2) - 1) < 1e-12 && abs(h(3) - 1) < 1e-12);
vert = cat(3, 0, 1, 0);
assert(abs(rgb2hsv(vert)(1) - 1/3) < 1e-12);
bleu = cat(3, 0, 0, 1);
assert(abs(rgb2hsv(bleu)(1) - 2/3) < 1e-12);
% Aller-retour exact sur une image aléatoire mais fixée.
c = cat(3, [0.2 0.7], [0.5 0.1], [0.9 0.3]);
assert(max(abs(reshape(hsv2rgb(rgb2hsv(c)) - c, [], 1))) < 1e-12);
% YCbCr : le blanc donne Y = 235/255, Cb = Cr = 128/255.
y = rgb2ycbcr(cat(3, 1, 1, 1));
assert(abs(y(1) - 235/255) < 1e-6);
assert(abs(y(2) - 128/255) < 1e-6);
assert(max(abs(reshape(ycbcr2rgb(rgb2ycbcr(c)) - c, [], 1))) < 1e-6);
assert(isequal(im2gray(a), a));
assert(isequal(imcomplement(uint8([0 255])), uint8([255 0])));
assert(max(abs(imcomplement([0 0.25 1]) - [1 0.75 0])) < 1e-12);

%% -------------------------------------------------------- arithmétique
assert(isequal(imlincomb(0.5, [1 2], 0.5, [3 4]), [2 3]));
assert(isequal(imabsdiff(uint8([10 20]), uint8([20 10])), uint8([10 10])));
assert(imadd(uint8(200), uint8(100)) == 255);       % saturation
assert(imsubtract(uint8(10), uint8(20)) == 0);      % saturation
assert(isequal(immultiply([1 2], [3 4]), [3 8]));
assert(isequal(imdivide([6 8], [3 4]), [2 2]));
assert(isequal(imtranslate([1 2; 3 4], [1 0]), [0 1; 0 3]));

%% ------------------------------------------------------------ mesures
assert(abs(mean2(magic(4)) - 8.5) < 1e-12);
assert(abs(std2(magic(4)) - std(reshape(magic(4), [], 1))) < 1e-12);
assert(abs(corr2(magic(4), magic(4)) - 1) < 1e-12);
assert(abs(corr2(magic(4), -magic(4)) + 1) < 1e-12);
assert(abs(immse([1 2], [1 3]) - 0.5) < 1e-12);
assert(isinf(psnr([0.5 0.5], [0.5 0.5])));
% PSNR d'une erreur constante de 0,1 sur du double : 20 dB.
assert(abs(psnr([0.5 0.5], [0.4 0.4]) - 20) < 1e-9);
x = double(magic(8)) / 64;
assert(abs(ssim(x, x) - 1) < 1e-9);
assert(ssim(x, 1 - x) < 0.5);

%% ------------------------------------------------------- morphologie
assert(isequal(strel('square', 3), true(3)));
assert(isequal(double(strel('diamond', 1)), [0 1 0; 1 1 1; 0 1 0]));
assert(sum(sum(strel('disk', 1))) >= 5);
assert(sum(sum(bwperim(true(3)))) == 8);
troue = true(5); troue(3, 3) = false;
assert(sum(sum(imfill(troue, 'holes'))) == 25);
assert(bweuler(troue) == 0);                 % une région, un trou
assert(bweuler(true(5)) == 1);
deux = false(7); deux(2:3, 2:3) = true; deux(5:6, 5:6) = true;
assert(bweuler(deux) == 2);
assert(bwarea([1 1; 0 1]) == 3);

point = false(3); point(2, 2) = true;
d = bwdist(point);
assert(abs(d(2, 2)) < 1e-12);
assert(abs(d(1, 1) - sqrt(2)) < 1e-12);
assert(abs(d(1, 2) - 1) < 1e-12);

cc = bwconncomp([1 1 0; 1 1 0; 0 0 1], 4);
assert(cc.NumObjects == 2);
assert(numel(cc.PixelIdxList{1}) == 4);
assert(isequal(cc.ImageSize, [3 3]));
% En connexité 8, le pixel isolé touche le bloc par la diagonale.
assert(bwconncomp([1 1 0; 1 1 0; 0 0 1], 8).NumObjects == 1);

% Chapeau haut de forme : un pic isolé ressort, le fond disparaît.
pic = zeros(5); pic(3, 3) = 5;
assert(abs(imtophat(pic, ones(3))(3, 3) - 5) < 1e-12);
assert(abs(imbothat(pic, ones(3))(1, 1)) < 1e-12);

%% ------------------------------------------------------- régions
s = regionprops(bwlabel([1 1 0; 1 1 0; 0 0 1], 4), 'Area', 'Centroid', 'BoundingBox');
assert(numel(s) == 2);
assert(s(1).Area == 4 && s(2).Area == 1);
assert(max(abs(s(1).Centroid - [1.5 1.5])) < 1e-12);
assert(max(abs(s(1).BoundingBox - [0.5 0.5 2 2])) < 1e-12);
t = regionprops(true(4), 'all');
assert(abs(t(1).Extent - 1) < 1e-12);
assert(abs(t(1).EquivDiameter - sqrt(4 * 16 / pi)) < 1e-12);
assert(t(1).Perimeter == 12);
assert(abs(t(1).Eccentricity) < 1e-9);       % un carré : ellipse presque ronde

%% --------------------------------------------------------- seuillage
assert(abs(multithresh([zeros(1, 50) ones(1, 50)], 1) - graythresh([zeros(1, 50) ones(1, 50)])) < 1e-9);
v = multithresh([zeros(1, 30) 0.5 * ones(1, 30) ones(1, 30)], 2);
assert(numel(v) == 2);
assert(v(1) > 0.1 && v(1) < 0.4);
assert(v(2) > 0.6 && v(2) < 0.9);
[idx, valeurs] = imquantize([0 0.4 0.8], 0.5);
assert(isequal(idx, [1 1 2]));
assert(max(abs(valeurs - [0 0 1])) < 1e-12);
limites = stretchlim(linspace(0, 1, 100));
assert(limites(1) >= 0 && limites(2) <= 1 && limites(2) > limites(1));

%% ----------------------------------------------------------- texture
g = graycomatrix([1 1; 1 1], 'NumLevels', 2);
assert(isequal(size(g), [2 2]));
assert(g(1, 1) == 2);                        % deux couples horizontaux
p = graycoprops(graycomatrix(ones(3), 'NumLevels', 2));
assert(abs(p.Contrast) < 1e-12);             % image uniforme : contraste nul
assert(abs(p.Energy - 1) < 1e-12);
assert(abs(p.Homogeneity - 1) < 1e-12);

%% ------------------------------------------------------- transformées
x = magic(4);
assert(max(max(abs(idct2(dct2(x)) - x))) < 1e-10);
% Le premier coefficient est la moyenne, à un facteur près.
assert(abs(dct2(ones(4))(1, 1) - 4) < 1e-10);

%% ------------------------------------------------------------ couleurs
c = label2rgb([1 0; 0 2]);
assert(isequal(size(c), [2 2 3]));
assert(max(abs(squeeze(c(1, 2, :))' - [1 1 1])) < 1e-12);   % fond blanc

%% --------------------------------------------- espaces de couleur
% La correction gamma de sRGB et son inverse se referment exactement.
assert(abs(rgb2lin(0.5) - 0.2140411) < 1e-6);
niveaux = linspace(0, 1, 101);
assert(max(abs(lin2rgb(rgb2lin(niveaux)) - niveaux)) < 1e-14);
% Le blanc sRGB tombe sur le blanc D65, donc sur L* = 100, a* = b* = 0.
assert(max(abs(rgb2xyz([1 1 1]) - whitepoint('d65'))) < 1e-6);
assert(max(abs(rgb2lab([1 1 1]) - [100 0 0])) < 1e-3);
assert(max(abs(rgb2lab([0 0 0]))) < 1e-9);
% Valeurs publiées pour les primaires sRGB sous D65.
assert(max(abs(rgb2lab([1 0 0]) - [53.24 80.09 67.20])) < 0.02);
assert(max(abs(rgb2lab([0 1 0]) - [87.73 -86.18 83.18])) < 0.02);
assert(max(abs(rgb2lab([0 0 1]) - [32.30 79.19 -107.86])) < 0.02);
% Tous les allers-retours de couleur sont exacts.
couleurs = [0.2 0.4 0.6; 0.9 0.1 0.5; 0 0.5 1];
assert(max(max(abs(lab2rgb(rgb2lab(couleurs)) - couleurs))) < 1e-12);
assert(max(max(abs(xyz2rgb(rgb2xyz(couleurs)) - couleurs))) < 1e-12);
assert(max(max(abs(lab2xyz(xyz2lab(rgb2xyz(couleurs))) - rgb2xyz(couleurs)))) < 1e-14);
assert(max(max(abs(ntsc2rgb(rgb2ntsc(couleurs)) - couleurs))) < 1e-12);
% La luminance NTSC du blanc vaut 1, ses chrominances zéro.
assert(max(abs(rgb2ntsc([1 1 1]) - [1 0 0])) < 1e-12);
% Une image à trois plans garde sa forme.
imageCouleur = reshape(couleurs, [3 1 3]);
assert(isequal(size(rgb2lab(imageCouleur)), [3 1 3]));
[planR, planV, planB] = imsplit(imageCouleur);
assert(isequal(size(planR), [3 1]));
assert(isequal(planR(:)', couleurs(:, 1)'));
% Un autre blanc de référence change le résultat, et reste inversible.
labD50 = rgb2lab(couleurs, 'WhitePoint', 'd50');
assert(max(max(abs(labD50 - rgb2lab(couleurs)))) > 1e-3);

% Images indexées.
[indices, palette] = gray2ind([0 0.5 1], 4);
assert(isequal(indices, [0 2 3]));
assert(isequal(size(palette), [4 3]));
assert(max(abs(ind2gray(indices, palette) - [0 2/3 1])) < 1e-9);
assert(isequal(size(ind2rgb(indices, palette)), [1 3 3]));
% Quatre couleurs distinctes se retrouvent exactement.
imageQuatre = zeros(2, 2, 3);
imageQuatre(1, 1, :) = [1 0 0];
imageQuatre(1, 2, :) = [0 1 0];
imageQuatre(2, 1, :) = [0 0 1];
imageQuatre(2, 2, :) = [1 1 0];
[ind4, pal4] = rgb2ind(imageQuatre, 4);
assert(isequal(size(pal4), [4 3]));
assert(max(max(max(abs(ind2rgb(ind4, pal4) - imageQuatre)))) < 1e-12);
[~, pal2] = imapprox(ind4, pal4, 2);
assert(isequal(size(pal2), [2 3]));

% Cartes de couleurs.
assert(isequal(gray(4), [0 0 0; 1/3 1/3 1/3; 2/3 2/3 2/3; 1 1 1]));
assert(isequal(size(gray()), [256 3]));
for nomCarte = {'gray', 'hot', 'cool', 'spring', 'summer', 'autumn', 'winter', ...
                'bone', 'copper', 'pink', 'jet', 'hsv', 'flag', 'prism'}
    carte = feval(nomCarte{1}, 64);
    assert(isequal(size(carte), [64 3]));
    assert(all(all(carte >= -1e-12 & carte <= 1 + 1e-12)));
end
carteJet = jet(64);
assert(max(abs(carteJet(1, :) - [0 0 0.5])) < 1e-12);
assert(max(abs(carteJet(end, :) - [0.5 0 0])) < 1e-12);
% Six teintes pures pour hsv(6).
assert(max(max(abs(hsv(6) - [1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1]))) < 1e-12);
assert(isequal(cool(2), [0 1 1; 1 0 1]));

%% ------------------------------- reconstruction morphologique
assert(isequal(double(conndef(2, 'minimal')), [0 1 0; 1 1 1; 0 1 0]));
assert(sum(sum(conndef(2, 'maximal'))) == 9);
% Un germe remplit la composante du masque qui le contient, pas les autres.
germe = zeros(5); germe(3, 3) = 1;
assert(sum(sum(imreconstruct(germe, ones(5)))) == 25);
masqueDouble = false(5, 7);
masqueDouble(2:4, 1:3) = true;
masqueDouble(2:4, 5:7) = true;
germeGauche = false(5, 7);
germeGauche(3, 2) = true;
assert(sum(sum(imreconstruct(double(germeGauche), double(masqueDouble)))) == 9);

% Maxima régionaux : un sommet isolé, puis un plateau.
assert(isequal(double(imregionalmax([1 2 1; 2 3 2; 1 2 1])), [0 0 0; 0 1 0; 0 0 0]));
plateau = [10 10 10 10; 10 22 22 10; 10 22 22 10; 10 10 10 10];
assert(sum(sum(imregionalmax(plateau))) == 4);
assert(isequal(imregionalmin(-[1 2 1; 2 3 2; 1 2 1]), imregionalmax([1 2 1; 2 3 2; 1 2 1])));
% La transformée H-maxima rabote les sommets trop bas.
assert(isequal(imhmax([1 3 1], 1), [1 2 1]));
assert(isequal(imhmin([3 1 3], 1), [3 2 3]));
% Maxima étendus : seul le sommet de hauteur 4 dépasse le seuil 2.
etendus = imextendedmax([1 1 1 1 1; 1 5 1 2 1; 1 1 1 1 1], 2);
assert(sum(sum(etendus)) == 1 && etendus(2, 2));
% Les objets qui touchent le bord disparaissent.
auBord = false(5);
auBord(1, 1) = true;
auBord(3, 3) = true;
assert(sum(sum(imclearborder(auBord))) == 1);
% Minima imposés : après imposition, il n'y en a plus d'autres.
relief = [3 3 3; 3 1 3; 3 3 3];
marqueur = false(3);
marqueur(1, 1) = true;
imposee = imimposemin(relief, marqueur);
assert(isequal(double(imregionalmin(imposee)), [1 0 0; 0 0 0; 0 0 0]));
rand('seed', 1);
deuxMarqueurs = false(5);
deuxMarqueurs(1, 1) = true;
deuxMarqueurs(5, 5) = true;
assert(sum(sum(imregionalmin(imimposemin(rand(5), deuxMarqueurs)))) == 2);

% Filtres sur composantes connexes.
objets = false(6);
objets(2, 2) = true;
objets(4:5, 4:5) = true;
assert(sum(sum(bwareaopen(objets, 2))) == 4);
[garde, aires] = bwareafilt(objets, 1);
assert(sum(garde(:)) == 4);
assert(isequal(sort(aires)', [1 4]));
assert(sum(sum(bwareafilt(objets, [1 1]))) == 1);
assert(sum(sum(bwselect(objets, 4, 4))) == 4);
assert(sum(sum(bwselect(objets, 2, 2))) == 1);
assert(sum(sum(bwpropfilt(objets, 'Area', 1))) == 4);
% La connexité change le compte : deux pixels en diagonale.
diagonale = false(3);
diagonale(1, 1) = true;
diagonale(2, 2) = true;
[~, nQuatre] = bwlabeln(diagonale, 4);
[~, nHuit] = bwlabeln(diagonale, 8);
assert(nQuatre == 2 && nHuit == 1);
% Tout ou rien : un seul coin correspond au motif.
carre = false(5);
carre(2:4, 2:4) = true;
motifCoin = [-1 -1 -1; -1 1 1; -1 1 1];
assert(sum(sum(bwhitmiss(carre, motifCoin))) == 1);
% Enveloppe convexe : elle contient les sommets et un triangle plein.
triangle = false(7);
triangle(2, 2) = true;
triangle(2, 6) = true;
triangle(6, 4) = true;
enveloppe = bwconvhull(triangle);
assert(enveloppe(2, 2) && enveloppe(2, 6) && enveloppe(6, 4));
assert(sum(enveloppe(:)) > 10);

%% --------------------------- opérations sur images binaires
isole = false(5);
isole(3, 3) = true;
assert(sum(sum(bwmorph(isole, 'clean'))) == 0);
troue = false(5);
troue(2:4, 2:4) = true;
troue(3, 3) = false;
assert(sum(sum(bwmorph(troue, 'fill'))) == 9);
coupe = false(5);
coupe(3, 2) = true;
coupe(3, 4) = true;
assert(sum(sum(bwmorph(coupe, 'bridge'))) == 3);
assert(sum(sum(bwmorph(carre, 'remove'))) == 8);
assert(sum(sum(bwmorph(carre, 'erode'))) == 1);
assert(sum(sum(bwmorph(carre, 'dilate'))) == 25);
% Le squelette d'un rectangle est un trait, et bwskel dit la même chose.
rectangle = false(11);
rectangle(4:8, 2:10) = true;
squelette = bwmorph(rectangle, 'thin', Inf);
assert(sum(squelette(:)) < sum(rectangle(:)) / 5);
assert(sum(any(squelette, 2)) == 1);           % une seule ligne occupée
assert(isequal(bwskel(rectangle), squelette));
% Une croix a quatre extrémités et un seul embranchement.
croix = false(7);
croix(4, 2:6) = true;
croix(2:6, 4) = true;
assert(sum(sum(bwmorph(croix, 'endpoints'))) == 4);
assert(sum(sum(bwmorph(croix, 'branchpoints'))) == 1);
erreurMorph = false;
try
    bwmorph(croix, 'inconnu');
catch err
    erreurMorph = strcmp(err.identifier, 'images:bwmorph:UnknownOperation');
end
assert(erreurMorph);

% Contours : celui d'un carré plein est fermé et tient sur l'objet.
contours = bwboundaries(carre);
assert(numel(contours) == 1);
premier = contours{1};
assert(isequal(premier(1, :), premier(end, :)));
for k = 1:size(premier, 1)
    assert(carre(premier(k, 1), premier(k, 2)));
end
% Un objet troué donne deux contours, mais un seul objet.
anneau = false(7);
anneau(2:6, 2:6) = true;
anneau(4, 4) = false;
[contoursAnneau, ~, nombreObjets] = bwboundaries(anneau);
assert(numel(contoursAnneau) == 2 && nombreObjets == 1);

% Ligne de partage des eaux : un sommet sépare deux bassins.
assert(isequal(watershed([1 2 3 2 1]), [1 1 0 2 2]));
reliefQuatre = [1 1 1 1 1; 1 0 1 0 1; 1 1 1 1 1; 1 0 1 0 1; 1 1 1 1 1];
assert(max(max(watershed(reliefQuatre))) == 4);

%% --------------------------------- découpage en blocs
carreMagique = magic(4);
blocsDisjoints = im2col(carreMagique, [2 2], 'distinct');
assert(isequal(size(blocsDisjoints), [4 4]));
assert(isequal(col2im(blocsDisjoints, [2 2], [4 4], 'distinct'), carreMagique));
assert(isequal(size(im2col(carreMagique, [2 2], 'sliding')), [4 9]));
% nlfilter et colfilt disent la même chose, et disent juste.
parVoisinage = nlfilter(carreMagique, [3 3], @(x) max(x(:)));
parColonnes = colfilt(carreMagique, [3 3], 'sliding', @max);
assert(isequal(parVoisinage, parColonnes));
assert(parVoisinage(2, 2) == max(max(carreMagique(1:3, 1:3))));
% blockproc : chaque bloc remplacé par sa moyenne.
moyennes = blockproc(carreMagique, [2 2], @(b) mean(b.data(:)) * ones(2));
assert(isequal(size(moyennes), [4 4]));
assert(abs(moyennes(1, 1) - mean(mean(carreMagique(1:2, 1:2)))) < 1e-12);
% conv2 accepte la forme séparable.
noyauSeparable = [1 2 1] / 4;
assert(max(max(abs(conv2(noyauSeparable, noyauSeparable, carreMagique, 'valid') - ...
                   conv2(carreMagique, noyauSeparable' * noyauSeparable, 'valid')))) < 1e-14);
% Damier et pyramide.
assert(isequal(size(checkerboard(4, 2, 2)), [16 16]));
rand('seed', 4);
imagePyramide = rand(16);
reduite = impyramid(imagePyramide, 'reduce');
assert(isequal(size(reduite), [8 8]));
assert(isequal(size(impyramid(reduite, 'expand')), [15 15]));

% convhull et inpolygon, du MATLAB de base.
[sommets, aireCarre] = convhull([0 1 1 0 0.5], [0 0 1 1 0.5]);
assert(numel(sommets) == 5 && sommets(1) == sommets(end));
assert(abs(aireCarre - 1) < 1e-12);
[~, aireTriangle] = convhull([0 4 2 2], [0 0 3 1]);
assert(abs(aireTriangle - 6) < 1e-12);
angles = linspace(0, 2*pi, 200);
angles(end) = [];
[~, aireCercle] = convhull(cos(angles), sin(angles));
assert(abs(aireCercle - pi) < 1e-3);
assert(inpolygon(0.5, 0.5, [0 1 1 0], [0 0 1 1]));
assert(~inpolygon(1.5, 0.5, [0 1 1 0], [0 0 1 1]));
[dedans, surLeBord] = inpolygon([0 0.5 1.5], [0 0.5 0.5], [0 1 1 0], [0 0 1 1]);
assert(isequal(dedans, [true true false]));
assert(isequal(surLeBord, [true false false]));

disp('images : toutes les verifications passent');
