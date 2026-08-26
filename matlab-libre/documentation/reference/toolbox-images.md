# Toolbox `images`

```
% Image Processing Toolbox — traitement d'images.
%
% Les images sont des matrices : un plan pour les niveaux de gris, trois
% pour la couleur. Les doubles vivent dans [0,1], les uint8 dans [0,255],
% comme dans MATLAB.
%
% Lecture, écriture, affichage
%   imread, imwrite, imshow
%
% Conversions
%   im2double, im2uint8, im2gray, rgb2gray, gray2rgb
%   rgb2hsv, hsv2rgb, rgb2ycbcr, ycbcr2rgb
%   imcomplement - Négatif
%
% Arithmétique
%   imadd, imsubtract, immultiply, imdivide, imabsdiff, imlincomb
%
% Géométrie
%   imresize, imrotate, imcrop, imtranslate, padarray
%
% Filtrage
%   imfilter    - Filtrage linéaire, avec choix du remplissage des bords
%   fspecial    - Noyaux usuels
%   imgaussfilt - Flou gaussien
%   imboxfilt   - Moyenne sur un carré
%   imsharpen   - Accentuation par masque flou
%   medfilt2    - Filtre médian
%   ordfilt2    - Filtre de rang
%   stdfilt, rangefilt, entropyfilt - Statistiques locales
%
% Gradient et contours
%   imgradientxy, imgradient - Gradient, amplitude et direction
%   edge        - Détection de contours
%
% Histogramme et contraste
%   imhist, histeq, imadjust, stretchlim
%   graythresh, imbinarize, multithresh, imquantize
%
% Morphologie
%   strel       - Élément structurant
%   imdilate, imerode, imopen, imclose
%   imtophat, imbothat - Chapeaux haut et bas de forme
%   imfill      - Bouchage des trous
%   bwperim, bwarea, bweuler, bwdist
%   bwlabel, bwconncomp, regionprops, label2rgb
%
% Texture
%   graycomatrix, graycoprops - Cooccurrence et ses descripteurs
%
% Qualité
%   mean2, std2, corr2, immse, psnr, ssim
%
% Transformées
%   dct2, idct2 - Cosinus discrète bidimensionnelle
%
% Bruit
%   imnoise
%
% Espaces de couleur
%   rgb2lin, lin2rgb   - Correction gamma de sRGB, dans les deux sens
%   rgb2xyz, xyz2rgb   - Passage à l'espace XYZ de la CIE
%   xyz2lab, lab2xyz   - Passage de XYZ à L*a*b*
%   rgb2lab, lab2rgb   - Enchaînement des deux
%   rgb2ntsc, ntsc2rgb - Espace YIQ de la télévision
%   whitepoint         - Blancs de référence normalisés
%   imsplit            - Sépare les plans d'une image
%
% Images indexées
%   gray2ind, ind2gray, ind2rgb, rgb2ind, imapprox
%
% Reconstruction morphologique
%   imreconstruct      - Dilatation géodésique jusqu'à stabilité
%   imregionalmax, imregionalmin - Extrema régionaux
%   imhmax, imhmin     - Rabote les extrema de faible relief
%   imextendedmax, imextendedmin - Extrema d'au moins H
%   imimposemin        - Impose les minima, pour la ligne de partage
%   imclearborder      - Retire ce qui touche le bord
%   conndef            - Tableau de connexité par défaut
%
% Composantes connexes
%   bwlabeln           - Étiquetage, connexité quelconque
%   bwareaopen, bwareafilt, bwpropfilt, bwselect
%   bwhitmiss          - Transformation tout ou rien
%   bwconvhull         - Enveloppe convexe des objets
%
% Squelettes et contours
%   bwmorph            - Vingt opérations sur images binaires
%   bwskel             - Squelette par amincissement
%   bwboundaries       - Contours des objets et de leurs trous
%   bwtraceboundary    - Suivi de contour de Moore
%   watershed          - Ligne de partage des eaux
%
% Découpage en blocs
%   im2col, col2im     - Blocs vers colonnes et retour
%   nlfilter, colfilt, blockproc - Filtres définis par une fonction
%   checkerboard       - Damier d'essai
%   impyramid          - Étage de pyramide gaussienne
%
% Fonctions internes (absentes de MATLAB)
%   morphologie, matriceRVBversXYZ, appliquerMatriceCouleur,
%   adapterBlanc, voisinageConnexite
```

## `adapterBlanc`

```
ADAPTERBLANC Adaptation chromatique de von Kries, en coordonnées XYZ.
  Chaque axe est mis à l'échelle du rapport des blancs. C'est la forme
  la plus simple de l'adaptation, celle que MATLAB emploie par défaut
  pour les conversions entre illuminants.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `appliquerMatriceCouleur`

```
APPLIQUERMATRICECOULEUR Combine linéairement les trois plans d'une image.
  Accepte une image H x L x 3 ou une liste N x 3 de couleurs, et rend
  la même forme.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `blockproc`

```
BLOCKPROC Applique une fonction bloc par bloc.
  B = BLOCKPROC(A,[M N],FUN) découpe A en blocs disjoints de M x N et
  applique FUN à chacun. FUN reçoit une structure dont le champ `data`
  porte le bloc, comme dans MATLAB.

  Exemple :
     blockproc(magic(4), [2 2], @(b) mean(b.data(:)) * ones(2))
```

## `bwarea`

```
BWAREA Aire d'une région binaire, en pixels.
```

## `bwareafilt`

```
BWAREAFILT Ne garde que les composantes de l'aire voulue.
  BWAREAFILT(BW,N) garde les N plus grandes ; BWAREAFILT(BW,[MIN MAX])
  garde celles dont l'aire est dans l'intervalle.
```

## `bwareaopen`

```
BWAREAOPEN Retire les composantes de moins de P pixels.

  Exemple :
     bw = false(5); bw(2,2) = true; bw(4:5,4:5) = true;
     bwareaopen(bw, 2)   % le point isolé disparaît
```

## `bwboundaries`

```
BWBOUNDARIES Contours des objets d'une image binaire.
  B = BWBOUNDARIES(BW) rend un tableau de cellules ; chaque cellule est
  une liste de couples [ligne colonne] parcourant le contour d'un
  objet, le premier point étant répété à la fin.

  [B,L,N,A] = BWBOUNDARIES(...) rend aussi l'image étiquetée, le nombre
  d'objets et la matrice d'adjacence entre objets et trous.

  BWBOUNDARIES(BW,CONN,'noholes') ignore les trous.

  Exemple :
     bw = false(5); bw(2:4, 2:4) = true;
     b = bwboundaries(bw);   % un contour de huit points plus le retour
```

## `bwconncomp`

```
BWCONNCOMP Composantes connexes d'une image binaire.
  CC = BWCONNCOMP(BW,CONNEXITE) rend une structure aux champs
  Connectivity, ImageSize, NumObjects et PixelIdxList — la même que
  celle de MATLAB.
```

## `bwconvhull`

```
BWCONVHULL Enveloppe convexe des objets d'une image binaire.
  BWCONVHULL(BW) rend l'enveloppe de l'ensemble des pixels allumés.
  BWCONVHULL(BW,'objects') traite chaque composante à part.
```

## `bwdist`

```
BWDIST Distance euclidienne au pixel vrai le plus proche.
  D = BWDIST(BW) rend, pour chaque pixel, la distance au plus proche
  pixel vrai. [D,IDX] = BWDIST(BW) rend aussi l'indice linéaire de ce
  pixel.

  Exemple :
     a = false(3); a(2,2) = true; bwdist(a)(1,1)   % sqrt(2)
```

## `bweuler`

```
BWEULER Nombre d'Euler : régions moins trous.
  E = BWEULER(BW,8) par défaut.
```

## `bwhitmiss`

```
BWHITMISS Transformation tout ou rien.
  BWHITMISS(BW,SE1,SE2) garde les pixels dont le voisinage contient
  SE1 dans l'objet et SE2 dans le fond. Avec un seul élément à trois
  valeurs, 1 impose l'objet, -1 le fond, 0 laisse libre.
```

## `bwlabel`

```
BWLABEL Étiquetage des composantes connexes d'une image binaire.
  [L,N] = BWLABEL(BW) numérote les régions de pixels vrais.
  CONNEXITE vaut 4 ou 8 (8 par défaut).
```

## `bwlabeln`

```
BWLABELN Étiquetage des composantes connexes, connexité quelconque.
  Sur une image bidimensionnelle, CONNEXITE peut valoir 4, 8 ou un
  tableau logique 3 x 3.
```

## `bwmorph`

```
BWMORPH Opérations morphologiques sur une image binaire.
  BW2 = BWMORPH(BW,OPERATION) applique une fois l'opération nommée ;
  BWMORPH(BW,OPERATION,N) la répète N fois, ou jusqu'à stabilité si N
  vaut Inf.

  Opérations reconnues : 'clean' (retire les pixels isolés), 'fill'
  (bouche les trous d'un pixel), 'bridge' (relie deux pixels séparés
  par un seul), 'remove' (ne garde que le bord), 'majority' (garde le
  pixel si cinq voisins sur neuf sont allumés), 'erode', 'dilate',
  'open', 'close', 'diag' (comble les liaisons diagonales),
  'endpoints', 'branchpoints', 'thin', 'skel', 'spur', 'thicken',
  'hbreak', 'tophat', 'bothat'.

  Exemple :
     bw = false(5); bw(3,3) = true;
     bwmorph(bw, 'clean')   % le pixel isolé disparaît
```

## `bwperim`

```
BWPERIM Contour d'une région binaire.
  P = BWPERIM(BW) garde les pixels vrais qui touchent au moins un pixel
  faux dans le voisinage à quatre voisins.

  Exemple :
     sum(sum(bwperim(true(3))))   % 8 : tout sauf le centre
```

## `bwpropfilt`

```
BWPROPFILT Ne garde que les composantes classées par une propriété.
  BWPROPFILT(BW,'Area',N) équivaut à BWAREAFILT. Toute propriété
  scalaire rendue par REGIONPROPS convient : 'Perimeter',
  'EquivDiameter', 'Eccentricity'…
```

## `bwselect`

```
BWSELECT Garde les objets qui contiennent les points désignés.
  BWSELECT(BW,C,R) où C sont les colonnes et R les lignes des points,
  dans cet ordre — c'est la convention de MATLAB.
```

## `bwskel`

```
BWSKEL Squelette d'une image binaire.
  Amincissement de Zhang et Suen jusqu'à stabilité : il ne reste qu'un
  trait d'un pixel d'épaisseur, de même topologie que l'objet.

  BWSKEL(...,'MinBranchLength',L) élague ensuite les barbes de moins de
  L pixels.

  Exemple :
     bw = false(9); bw(4:6, 2:8) = true;
     s = bwskel(bw);   % un segment horizontal
```

## `bwtraceboundary`

```
BWTRACEBOUNDARY Suit le contour d'un objet à partir d'un point.
  C = BWTRACEBOUNDARY(BW,P,DIR) part du pixel P = [ligne colonne] en
  cherchant d'abord dans la direction DIR ('N', 'NE', 'E'…) et suit le
  bord de l'objet jusqu'à revenir au départ.

  L'algorithme est celui de Moore : on tourne autour du pixel courant à
  partir du voisin d'où l'on vient, et l'on saute sur le premier pixel
  allumé rencontré.
```

## `checkerboard`

```
CHECKERBOARD Damier d'essai pour les transformations géométriques.
  I = CHECKERBOARD(N,P,Q) rend un damier dont chaque carreau fait N
  pixels de côté, avec P rangées et Q colonnes de paires de carreaux.
  La moitié droite est plus claire, ce qui permet de repérer une
  symétrie.

  Exemple :
     imshow(checkerboard(10));
```

## `col2im`

```
COL2IM Réassemble une image à partir de colonnes de blocs.
  Réciproque d'IM2COL pour le découpage disjoint ; pour le découpage
  glissant, chaque colonne fournit un pixel, comme dans MATLAB.
```

## `colfilt`

```
COLFILT Filtre par colonnes : la fonction voit tous les blocs à la fois.
  B = COLFILT(A,[M N],'sliding',FUN) passe à FUN une matrice dont
  chaque colonne est un voisinage, et attend une ligne de résultats.
  C'est la version rapide de NLFILTER.

  Exemple :
     colfilt(magic(4), [3 3], 'sliding', @max)
```

## `conndef`

```
CONNDEF Tableau de connexité par défaut.
  C = CONNDEF(N,TYPE) où TYPE vaut 'minimal' (les voisins qui partagent
  une face) ou 'maximal' (tous les voisins immédiats).

  Exemple :
     conndef(2, 'minimal')   % [0 1 0; 1 1 1; 0 1 0]
```

## `corr2`

```
CORR2 Coefficient de corrélation entre deux matrices de même taille.
  Exemple :  corr2(magic(4), magic(4))   % 1
```

## `dct2`

```
DCT2 Transformée en cosinus discrète bidimensionnelle.
  Y = DCT2(X) applique DCT aux colonnes puis aux lignes.
```

## `edge`

```
EDGE Détection de contours.
  C = EDGE(X) applique Sobel avec un seuil automatique.
  C = EDGE(X,'sobel'|'prewitt'|'log',SEUIL) choisit la méthode.
```

## `entropyfilt`

```
ENTROPYFILT Entropie locale, en bits.
  L'histogramme est calculé sur 256 niveaux, comme dans MATLAB.
```

## `fspecial`

```
FSPECIAL Noyaux de filtrage usuels.
  H = FSPECIAL('average',N)      moyenne N x N
  H = FSPECIAL('gaussian',N,SIG) gaussienne
  H = FSPECIAL('sobel')          gradient vertical
  H = FSPECIAL('prewitt')        gradient vertical
  H = FSPECIAL('laplacian')      laplacien
  H = FSPECIAL('log',N,SIG)      laplacien de gaussienne
```

## `gray2ind`

```
GRAY2IND Image en niveaux de gris vers image indexée.
  [X,MAP] = GRAY2IND(I,N) quantifie I sur N niveaux ; N vaut 64 par
  défaut. Les indices commencent à zéro, comme dans MATLAB pour les
  entiers non signés.

  Exemple :
     [x, map] = gray2ind([0 0.5 1], 4);   % x = [0 1 3]
```

## `gray2rgb`

```
GRAY2RGB Réplique une image en niveaux de gris sur trois canaux.
```

## `graycomatrix`

```
GRAYCOMATRIX Matrice de cooccurrence des niveaux de gris.
  GLCM = GRAYCOMATRIX(I) compte les couples de pixels voisins à droite,
  après quantification sur 8 niveaux. Options : 'NumLevels',
  'GrayLimits', 'Offset' (matrice de décalages [dl dc], une ligne par
  décalage).

  Exemple :
     graycomatrix([1 1 1; 1 1 1; 1 1 1], 'NumLevels', 2)
```

## `graycoprops`

```
GRAYCOPROPS Descripteurs d'une matrice de cooccurrence.
  S = GRAYCOPROPS(GLCM) rend Contrast, Correlation, Energy et
  Homogeneity, telles que les définit la documentation MathWorks.
```

## `graythresh`

```
GRAYTHRESH Seuil global par la méthode d'Otsu.
  SEUIL = GRAYTHRESH(X) maximise la variance interclasse.
```

## `histeq`

```
HISTEQ Égalisation d'histogramme.
```

## `hsv2rgb`

```
HSV2RGB Teinte, saturation, valeur vers RVB.
  R = HSV2RGB(IMAGE) où IMAGE est MxNx3, ou HSV2RGB(CARTE) où CARTE
  est une carte de couleurs Mx3. La sortie garde la forme de l'entrée.
```

## `idct2`

```
IDCT2 Transformée en cosinus discrète inverse bidimensionnelle.
```

## `im2col`

```
IM2COL Réarrange les blocs d'une image en colonnes.
  IM2COL(A,[M N],'distinct') découpe l'image en blocs disjoints ;
  'sliding' (par défaut) prend tous les blocs glissants.

  Exemple :
     im2col(magic(4), [2 2], 'distinct')   % quatre colonnes de quatre
```

## `im2double`

```
IM2DOUBLE Convertit une image en double dans [0,1].
```

## `im2gray`

```
IM2GRAY Rend une image en niveaux de gris, quelle que soit l'entrée.
  Une image déjà en niveaux de gris ressort inchangée.
```

## `im2uint8`

```
IM2UINT8 Convertit une image en uint8 (0 à 255).
```

## `imabsdiff`

```
IMABSDIFF Différence absolue de deux images, sans dépassement.
```

## `imadd`

```
IMADD Somme de deux images, avec saturation pour les entiers.
```

## `imadjust`

```
IMADJUST Étirement de contraste.
  Y = IMADJUST(X,[BAS HAUT],[NBAS NHAUT],GAMMA) applique la transformation
  affine par morceaux suivie de la correction gamma.
```

## `imapprox`

```
IMAPPROX Réduit le nombre de couleurs d'une image indexée.
  [Y,NEWMAP] = IMAPPROX(X,MAP,N) rend une image à N couleurs.
```

## `imbinarize`

```
IMBINARIZE Seuillage d'une image en niveaux de gris.
```

## `imbothat`

```
IMBOTHAT Chapeau bas de forme : la fermeture moins l'image.
  Fait ressortir les détails sombres.
```

## `imboxfilt`

```
IMBOXFILT Filtre moyenneur, à noyau carré.
  R = IMBOXFILT(I,N) moyenne sur un carré de N points de côté ; N est
  impair. C'est le filtre le moins cher, et le plus flou.
```

## `imclearborder`

```
IMCLEARBORDER Supprime les objets qui touchent le bord de l'image.
  La reconstruction part du bord : tout ce qu'elle atteint est retiré.

  Exemple :
     bw = false(5); bw(1,1) = true; bw(3,3) = true;
     imclearborder(bw)   % il ne reste que le point du centre
```

## `imclose`

```
IMCLOSE Fermeture morphologique : dilatation puis érosion.
```

## `imcomplement`

```
IMCOMPLEMENT Négatif d'une image.
  Pour un double dans [0,1], c'est 1-X ; pour un uint8, 255-X ; pour un
  logique, la négation.
```

## `imcrop`

```
IMCROP Découpe un rectangle [x y largeur hauteur] dans une image.
```

## `imdilate`

```
IMDILATE Dilatation morphologique.
```

## `imdivide`

```
IMDIVIDE Quotient terme à terme de deux images.
```

## `imerode`

```
IMERODE Érosion morphologique.
```

## `imextendedmax`

```
IMEXTENDEDMAX Maxima étendus : les sommets d'au moins H de hauteur.
```

## `imextendedmin`

```
IMEXTENDEDMIN Minima étendus : les cuvettes d'au moins H de profondeur.
```

## `imfill`

```
IMFILL Bouche les trous d'une image binaire.
  R = IMFILL(BW,'holes') remplit les régions de faux qui ne touchent pas
  le bord. C'est une reconstruction morphologique depuis le bord, prise
  par complément.

  Exemple :
     a = true(5); a(3,3) = false; sum(sum(imfill(a,'holes')))   % 25
```

## `imfilter`

```
IMFILTER Filtrage linéaire d'une image.
  Y = IMFILTER(X,H) corrèle X avec le noyau H et rend une image de même
  taille. Les options, dans n'importe quel ordre :
     'conv' | 'corr'          convolution ou corrélation (défaut)
     'same' | 'full'          taille du résultat (défaut « same »)
     'replicate' | 'symmetric' | 'circular' | VALEUR   remplissage des
                              bords ; le défaut est zéro, comme MATLAB.

  Exemple :
     imfilter(ones(3), ones(3)/9, 'replicate')   % que des 1
```

## `imgaussfilt`

```
IMGAUSSFILT Lissage gaussien d'une image.
```

## `imgradient`

```
IMGRADIENT Amplitude et direction du gradient.
  [G,DIR] = IMGRADIENT(I) ou IMGRADIENT(GX,GY). La direction est en
  degrés, comptée depuis l'axe des x, positive dans le sens
  trigonométrique.
```

## `imgradientxy`

```
IMGRADIENTXY Composantes horizontale et verticale du gradient.
  [GX,GY] = IMGRADIENTXY(I,METHODE) où METHODE vaut 'sobel' (défaut),
  'prewitt', 'central' ou 'intermediate'.

  Les conventions sont celles de MATLAB : GX est positif quand
  l'intensité croît vers la droite, GY quand elle croît vers le bas.
  Les bords sont répliqués.

  Exemple :
     [gx, gy] = imgradientxy([1 2 3; 4 5 6; 7 8 9]);
     gx(2, 2)   % 8, la réponse de Sobel sur une rampe horizontale
     gy(2, 2)   % 24, la rampe verticale est trois fois plus raide
```

## `imhist`

```
IMHIST Histogramme d'une image.
```

## `imhmax`

```
IMHMAX Supprime les maxima de hauteur inférieure à H.
  La reconstruction de l'image depuis elle-même abaissée de H rabote
  les sommets peu marqués et laisse les autres.

  Exemple :
     imhmax([1 3 1], 5)   % [1 1 1] : le sommet ne fait que 2
```

## `imhmin`

```
IMHMIN Comble les minima de profondeur inférieure à H.
```

## `imimposemin`

```
IMIMPOSEMIN Force les minima régionaux à se trouver là où on le dit.
  Sert à contrôler la ligne de partage des eaux : sans cela, chaque
  petite cuvette du relief donne un bassin.

  La construction est celle de Soille : on creuse à moins l'infini là
  où sont les marqueurs, on remonte tout le reste d'un cran, et on
  reconstruit par en dessous. Les seuls minima qui survivent sont ceux
  qu'on a imposés.

  Exemple :
     relief = [3 3 3; 3 1 3; 3 3 3];
     m = false(3); m(1,1) = true;
     imregionalmin(imimposemin(relief, m))   % le seul minimum est en (1,1)
```

## `imlincomb`

```
IMLINCOMB Combinaison linéaire d'images.
  R = IMLINCOMB(K1,A1,K2,A2,...) calcule K1*A1 + K2*A2 + ... en double,
  puis convertit une seule fois : les arrondis intermédiaires
  disparaissent, ce qui est le but de la fonction.

  Exemple :
     imlincomb(0.5, [1 2], 0.5, [3 4])   % [2 3]
```

## `immse`

```
IMMSE Erreur quadratique moyenne entre deux images.
```

## `immultiply`

```
IMMULTIPLY Produit terme à terme de deux images.
```

## `imnoise`

```
IMNOISE Ajoute du bruit à une image.
  Y = IMNOISE(X,'gaussian',VAR) ajoute un bruit blanc gaussien.
  Y = IMNOISE(X,'salt & pepper',D) remplace une fraction D des pixels.
```

## `imopen`

```
IMOPEN Ouverture morphologique : érosion puis dilatation.
```

## `impyramid`

```
IMPYRAMID Un étage de pyramide gaussienne, vers le haut ou vers le bas.
  IMPYRAMID(A,'reduce') divise la taille par deux après lissage ;
  'expand' la double.

  Le noyau est le noyau binomial 5 x 5 de Burt et Adelson, celui que
  MATLAB emploie : [1 4 6 4 1]/16 dans chaque direction.
```

## `imquantize`

```
IMQUANTIZE Quantifie une image selon des seuils.
  IDX = IMQUANTIZE(I,SEUILS) rend l'indice de classe, de 1 à
  numel(SEUILS)+1. [IDX,V] = IMQUANTIZE(...,NIVEAUX) rend aussi l'image
  reconstruite avec les valeurs données.
```

## `imread`

```
IMREAD Lit une image aux formats PGM/PPM en texte (P2 et P3).
```

## `imreconstruct`

```
IMRECONSTRUCT Reconstruction morphologique par dilatation géodésique.
  J = IMRECONSTRUCT(MARQUEUR,MASQUE) dilate le marqueur sous le masque
  jusqu'à stabilité : chaque pixel prend le maximum de son voisinage,
  sans jamais dépasser le masque. C'est la brique de toutes les
  opérations qui suivent — extrema régionaux, remplissage de trous,
  suppression des objets touchant le bord.

  L'implémentation fait deux balayages par tour, l'un en avant, l'autre
  en arrière : la propagation traverse alors l'image en un tour au lieu
  d'un par pixel de distance.

  Exemple :
     m = zeros(5); m(3,3) = 1;
     imreconstruct(m, ones(5))   % tout à 1 : le masque est connexe
```

## `imregionalmax`

```
IMREGIONALMAX Maxima régionaux d'une image.
  Un maximum régional est un plateau connexe dont tous les voisins sont
  strictement plus bas. On le trouve en reconstruisant l'image depuis
  elle-même diminuée d'un cran : ce qui reste au-dessus est un maximum.

  Le « cran » est pris sur les rangs des valeurs, pas sur les valeurs
  elles-mêmes : les maxima régionaux ne changent pas si l'on applique
  une fonction strictement croissante, et travailler sur les rangs rend
  le calcul exact même en présence d'infinis.

  Exemple :
     imregionalmax([1 2 1; 2 3 2; 1 2 1])   % le centre seulement
```

## `imregionalmin`

```
IMREGIONALMIN Minima régionaux d'une image.
  Dual d'IMREGIONALMAX, appliqué à l'image inversée.
```

## `imresize`

```
IMRESIZE Redimensionnement par interpolation bilinéaire.
  Y = IMRESIZE(X,F) multiplie les dimensions par F.
  Y = IMRESIZE(X,[H L]) impose la taille de sortie.
```

## `imrotate`

```
IMROTATE Rotation d'une image, en degrés, autour de son centre.
```

## `imsharpen`

```
IMSHARPEN Accentue les contours par masque flou.
  R = IMSHARPEN(I,'Radius',R,'Amount',A) retranche une version floutée :
  R = I + A*(I - flou(I)). Le rayon vaut 1 et le montant 0,8 par défaut,
  comme dans MATLAB.
```

## `imshow`

```
IMSHOW Affiche une image dans les axes courants.
  Le rendu se fait en SVG : « print » écrit le fichier.
```

## `imsplit`

```
IMSPLIT Sépare les plans d'une image en autant de sorties.
  [R,V,B] = IMSPLIT(RGB).

  Exemple :
     [r, v, b] = imsplit(zeros(4, 4, 3));
```

## `imsubtract`

```
IMSUBTRACT Différence de deux images, avec saturation pour les entiers.
```

## `imtophat`

```
IMTOPHAT Chapeau haut de forme : l'image moins son ouverture.
  Fait ressortir les détails clairs plus petits que l'élément
  structurant.
```

## `imtranslate`

```
IMTRANSLATE Décale une image d'un nombre entier de pixels.
  R = IMTRANSLATE(I,[DX DY]) décale de DX colonnes et DY lignes ; les
  pixels qui entrent valent zéro. Les décalages non entiers sont
  arrondis.
```

## `imwrite`

```
IMWRITE Écrit une image au format PGM (gris) ou PPM (couleur).
  Ces deux formats sont du texte : aucune bibliothèque externe n'est
  nécessaire, et tous les visionneurs les lisent.
```

## `ind2gray`

```
IND2GRAY Image indexée vers niveaux de gris.
  La luminance suit la même pondération que RGB2GRAY.
```

## `ind2rgb`

```
IND2RGB Image indexée vers image en couleurs.
```

## `lab2rgb`

```
LAB2RGB Passage de L*a*b* à sRGB.
```

## `lab2xyz`

```
LAB2XYZ Passage de L*a*b* à XYZ.
  Réciproque exacte de XYZ2LAB.
```

## `label2rgb`

```
LABEL2RGB Colorie une image étiquetée.
  RGB = LABEL2RGB(L) donne une couleur par étiquette ; le fond (zéro)
  reste blanc. LABEL2RGB(L,CARTE,FOND) choisit la palette et la couleur
  du fond.
```

## `lin2rgb`

```
LIN2RGB Applique la correction gamma de sRGB.
  Réciproque exacte de RGB2LIN.

  Exemple :
     lin2rgb(0.214)   % 0.4999
```

## `matriceRVBversXYZ`

```
MATRICERVBVERSXYZ Matrice sRGB linéaire vers XYZ, blanc D65.
  Les coefficients sont ceux de la recommandation UIT-R BT.709, celle
  que sRGB reprend : ils envoient le blanc [1 1 1] sur le blanc D65.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `mean2`

```
MEAN2 Moyenne de tous les éléments d'une matrice.
```

## `medfilt2`

```
MEDFILT2 Filtre médian bidimensionnel.
```

## `morphologie`

```
MORPHOLOGIE Noyau commun de l'érosion et de la dilatation.
  Hors de l'image, le voisinage vaut l'élément neutre de l'opération :
  plus l'infini pour l'érosion, moins l'infini pour la dilatation. Un
  pixel dont tout le voisinage sort du cadre garde donc sa valeur
  neutre, au lieu de faire échouer le calcul sur un ensemble vide.
```

## `multithresh`

```
MULTITHRESH Seuils d'Otsu multiples.
  S = MULTITHRESH(I,N) rend N seuils qui découpent l'histogramme en N+1
  classes en maximisant la variance interclasse — la généralisation
  directe de la méthode d'Otsu.

  Exemple :
     multithresh([zeros(1,50) ones(1,50)], 1)   % proche de 0,5
```

## `nlfilter`

```
NLFILTER Filtre défini par une fonction du voisinage.
  B = NLFILTER(A,[M N],FUN) applique FUN à chaque voisinage glissant de
  M x N pixels ; le résultat prend la valeur rendue par FUN.

  Exemple :
     nlfilter(magic(4), [3 3], @(x) max(x(:)))
```

## `ntsc2rgb`

```
NTSC2RGB Passage de YIQ à RVB.
```

## `ordfilt2`

```
ORDFILT2 Filtre de rang : le ORDRE-ième plus petit du voisinage.
  R = ORDFILT2(I,N,DOMAINE) où DOMAINE est une matrice logique qui dit
  quels voisins comptent. Avec N = 1 c'est un minimum, avec N égal au
  nombre de vrais c'est un maximum, et au milieu c'est la médiane.
  Les bords sont complétés par des zéros, comme dans MATLAB ;
  ORDFILT2(...,'symmetric') les complète par symétrie.

  Exemple :
     ordfilt2(magic(4), 9, ones(3))   % maximum sur 3x3
```

## `padarray`

```
PADARRAY Ajoute une bordure à un tableau.
  B = PADARRAY(A,[M N]) ajoute M lignes et N colonnes de zéros de chaque
  côté. PADARRAY(A,T,VALEUR) remplit avec VALEUR ; VALEUR peut aussi
  valoir 'replicate' (répète le bord), 'symmetric' (miroir) ou
  'circular' (périodique). PADARRAY(A,T,VALEUR,DIRECTION) où DIRECTION
  vaut 'both' (défaut), 'pre' ou 'post'.

  Exemple :
     padarray([1 2; 3 4], [1 1])   % entouré de zéros
```

## `psnr`

```
PSNR Rapport signal sur bruit de crête, en décibels.
  P = PSNR(A,REF) ; MAXIMUM vaut 1 pour un double et 255 pour un uint8.

  Exemple :  psnr(x, x)   % Inf
```

## `rangefilt`

```
RANGEFILT Étendue locale : maximum moins minimum du voisinage.
  Les bords sont complétés par symétrie, comme dans MATLAB : une image
  constante a donc une étendue nulle partout, bords compris.

  Exemple :
     rangefilt([1 2; 3 4])(1, 1)   % 3
```

## `regionprops`

```
REGIONPROPS Mesures sur les régions d'une image étiquetée.
  S = REGIONPROPS(BW) ou REGIONPROPS(L) rend un tableau de structures,
  une par région. Mesures reconnues : 'Area', 'Centroid',
  'BoundingBox', 'PixelIdxList', 'PixelList', 'MajorAxisLength',
  'MinorAxisLength', 'Orientation', 'Perimeter', 'Eccentricity',
  'EquivDiameter', 'Extent', 'FilledArea', 'all'.

  Exemple :
     s = regionprops(bwlabel([1 1 0; 1 1 0; 0 0 1]));
     s(1).Area   % 4
```

## `rgb2gray`

```
RGB2GRAY Luminance d'une image couleur.
  G = RGB2GRAY(RGB) applique la pondération de la recommandation
  ITU-R BT.601 : 0.2989 R + 0.5870 V + 0.1140 B.
```

## `rgb2hsv`

```
RGB2HSV Couleurs RVB vers teinte, saturation, valeur.
  H = RGB2HSV(IMAGE) où IMAGE est MxNx3 dans [0,1], ou RGB2HSV(CARTE)
  où CARTE est une carte de couleurs Mx3. Les trois plans du résultat
  sont la teinte (0 à 1), la saturation et la valeur.

  Exemple :
     c = rgb2hsv(cat(3, 1, 0, 0));   % rouge pur : teinte 0, S = V = 1
```

## `rgb2ind`

```
RGB2IND Image en couleurs vers image indexée.
  [X,MAP] = RGB2IND(RGB,N) réduit l'image à N couleurs par les
  k-moyennes sur les pixels, initialisées régulièrement pour que le
  résultat ne dépende pas du tirage.

  [X,MAP] = RGB2IND(RGB,MAP) utilise la palette donnée et affecte
  chaque pixel à sa couleur la plus proche.

  Exemple :
     [x, map] = rgb2ind(cat(3, [0 1], [0 1], [0 1]), 2);
```

## `rgb2lab`

```
RGB2LAB Passage de sRGB à L*a*b*.
  L* va de 0 à 100, a* et b* sont centrés sur zéro. C'est l'espace où
  les distances euclidiennes correspondent le mieux aux différences
  perçues.

  Exemple :
     rgb2lab([1 1 1])   % [100 0 0]
```

## `rgb2lin`

```
RGB2LIN Défait la correction gamma d'une image sRGB.
  U = RGB2LIN(V) applique la fonction de transfert inverse de sRGB :
  une droite près de zéro, une puissance 2,4 au-delà. Les valeurs
  entrent et sortent entre 0 et 1.

  Exemple :
     rgb2lin(0.5)   % 0.2140
```

## `rgb2ntsc`

```
RGB2NTSC Passage de RVB à l'espace YIQ de la télévision NTSC.
  Y porte la luminance, I et Q la chrominance. La première ligne de la
  matrice est celle de RGB2GRAY.

  Exemple :
     rgb2ntsc([1 1 1])   % [1 0 0]
```

## `rgb2xyz`

```
RGB2XYZ Passage de sRGB à l'espace XYZ de la CIE.
  XYZ = RGB2XYZ(RGB) linéarise d'abord l'image, puis applique la
  matrice de la recommandation BT.709.

  RGB2XYZ(...,'WhitePoint',W) adapte le résultat à un autre blanc que
  le D65 de sRGB, par la mise à l'échelle de von Kries.

  Exemple :
     rgb2xyz([1 1 1])   % le blanc D65
```

## `rgb2ycbcr`

```
RGB2YCBCR Couleurs RVB vers luminance et chrominances.
  Y = RGB2YCBCR(IMAGE) applique la matrice de la recommandation
  ITU-R BT.601, avec les plages 16..235 et 16..240 de MATLAB pour les
  entiers 8 bits, et les mêmes valeurs ramenées à [0,1] pour un double.
```

## `ssim`

```
SSIM Indice de similarité structurelle.
  S = SSIM(A,REF) rend l'indice global, entre -1 et 1 ; 1 signifie que
  les deux images sont identiques. La fenêtre est une gaussienne de
  11 points et d'écart-type 1,5, comme dans l'article de Wang et al.
  et dans MATLAB.

  Exemple :  ssim(x, x)   % 1
```

## `std2`

```
STD2 Écart-type de tous les éléments d'une matrice.
```

## `stdfilt`

```
STDFILT Écart-type local.
  R = STDFILT(I,VOISINAGE) rend l'écart-type des pixels du voisinage,
  normalisé par n-1 comme le fait MATLAB.
```

## `strel`

```
STREL Élément structurant pour la morphologie.
  S = STREL('square',N), STREL('rectangle',[M N]), STREL('disk',R),
  STREL('line',LONGUEUR,ANGLE), STREL('diamond',R), STREL('arbitrary',M).
  Le résultat est une matrice logique, directement utilisable par
  IMDILATE, IMERODE, IMOPEN et IMCLOSE.

  Exemple :
     strel('square', 3)   % 3x3 de vrais
```

## `stretchlim`

```
STRETCHLIM Bornes de contraste, pour IMADJUST.
  L = STRETCHLIM(I,TOL) rend [bas; haut] tels que la proportion TOL(1)
  des pixels soit sous « bas » et TOL(2) au-dessus de « haut ». TOL vaut
  [0.01 0.99] par défaut.
```

## `voisinageConnexite`

```
VOISINAGECONNEXITE Décalages [di dj] d'une connexité 2-D.
  Accepte 4, 8 ou un tableau logique 3 x 3.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `watershed`

```
WATERSHED Ligne de partage des eaux.
  L = WATERSHED(A) inonde le relief A depuis ses minima régionaux : les
  pixels reçoivent le numéro du bassin qui les a atteints, et ceux où
  deux bassins se rejoignent restent à zéro — c'est la ligne de
  partage.

  L'inondation suit l'algorithme de Meyer : on traite les pixels par
  altitude croissante, en propageant l'étiquette du voisin déjà
  inondé, et l'on marque la crête quand deux étiquettes se disputent
  le même pixel.

  Exemple :
     relief = [1 2 3 2 1];
     watershed(relief)   % deux bassins séparés par le sommet
```

## `whitepoint`

```
WHITEPOINT Coordonnées XYZ d'un blanc de référence.
  XYZ = WHITEPOINT(NOM) où NOM vaut 'ICC' (par défaut), 'D50', 'D55',
  'D65', 'A' ou 'C'. Le blanc est normalisé à Y = 1.

  Exemple :
     whitepoint('d65')   % [0.9504 1.0000 1.0888]
```

## `xyz2lab`

```
XYZ2LAB Passage de XYZ à L*a*b*.
  Le blanc de référence est le D65 par défaut ; l'option 'WhitePoint'
  en choisit un autre.

  Exemple :
     xyz2lab(whitepoint('d65'))   % [100 0 0], le blanc parfait
```

## `xyz2rgb`

```
XYZ2RGB Passage de l'espace XYZ à sRGB.
  Réciproque de RGB2XYZ. Les valeurs hors du domaine affichable sont
  ramenées entre 0 et 1, comme le fait MATLAB.
```

## `ycbcr2rgb`

```
YCBCR2RGB Luminance et chrominances vers RVB.
```

