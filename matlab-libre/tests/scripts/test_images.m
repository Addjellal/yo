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

disp('images : toutes les verifications passent');
