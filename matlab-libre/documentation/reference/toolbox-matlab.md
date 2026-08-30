# Toolbox `matlab`

```
% MATLAB de base — fonctions écrites dans le langage lui-même.
%
% Les fonctions élémentaires (zeros, size, sum, fft, plot…) sont natives,
% écrites en C++ dans src/. Ce dossier complète le noyau par ce qui
% s'exprime plus clairement en langage MATLAB.
%
%   nextpow2      - Exposant de la puissance de deux immédiatement supérieure
%   pow2          - 2 élevé à une puissance
%   rat           - Approximation rationnelle
%   perms         - Toutes les permutations
%   vecnorm       - Norme de chaque colonne
%   rescale       - Remise à l'échelle sur [0,1]
%   bounds        - Minimum et maximum en un appel
%   uniquetol     - Valeurs distinctes à une tolérance près
%   ismembertol   - Appartenance à une tolérance près
%   validatestring- Complétion d'une option textuelle
%   iskeyword     - Mot réservé du langage ?
%   matlabroot    - Racine de l'installation
%   peaks         - Surface d'essai à trois bosses
%   humps         - Fonction d'essai à deux pics
%   fliplr2       - (interne) inversion utilisée par les démonstrations
%
% Gestion des toolboxes
%   matlab.addons.installedAddons          - Liste les toolboxes
%   matlab.addons.toolbox.installToolbox   - Installe un dossier
%   matlab.addons.toolbox.uninstallToolbox - Retire une toolbox
%   matlab.addons.toolbox.packageToolbox   - Empaquette en archive
%   matlabroot, matlibre_racine_toolbox    - Racine de l'installation
%   zip, unzip                             - Archives
%   residue     - Décomposition en éléments simples d'une fraction
%                 rationnelle, et son inverse
%   ellipke     - Intégrales elliptiques complètes
%   ellipj      - Fonctions elliptiques de Jacobi
%   convhull    - Enveloppe convexe d'un nuage de points
%   inpolygon   - Points intérieurs à un polygone
%
% Cartes de couleurs
%   gray, hot, cool, spring, summer, autumn, winter, bone, copper,
%   pink, jet, hsv, flag, prism
```

## `autumn`

```
AUTUMN Carte de couleurs rouge - jaune.
```

## `blkdiag`

```
BLKDIAG Matrice diagonale par blocs.
  M = BLKDIAG(A,B,...) place les matrices données sur la diagonale d'une
  matrice plus grande et remplit le reste de zéros. La taille du
  résultat est la somme des tailles : SUM(LIGNES) par SUM(COLONNES).

  Les blocs n'ont pas à être carrés, ni de la même taille. Un bloc vide
  n'ajoute rien. Un scalaire est un bloc 1x1.

  Exemple :
     blkdiag([1 2; 3 4], 5)
     % ans =
     %      1     2     0
     %      3     4     0
     %      0     0     5

  Voir aussi DIAG, HORZCAT, VERTCAT, KRON, EYE.
```

## `bone`

```
BONE Carte de couleurs gris à reflet bleuté.
  Sept huitièmes de gris et un huitième de HOT retourné.
```

## `bounds`

```
BOUNDS Minimum et maximum en un seul appel.
  [B,H] = BOUNDS(X) rend le plus petit et le plus grand élément.
```

## `convhull`

```
CONVHULL Enveloppe convexe d'un nuage de points du plan.
  K = CONVHULL(X,Y) rend les indices des points de l'enveloppe, dans
  le sens des aiguilles d'une montre, le premier point étant répété à
  la fin pour fermer le contour — la convention de MATLAB.

  [K,AIRE] = CONVHULL(...) rend aussi l'aire de l'enveloppe.

  L'algorithme est la chaîne monotone d'Andrew : on trie les points,
  puis on construit la moitié basse et la moitié haute en retirant
  chaque sommet qui ferait tourner du mauvais côté.

  Exemple :
     k = convhull([0 1 1 0 0.5], [0 0 1 1 0.5]);   % le carré
```

## `cool`

```
COOL Carte de couleurs cyan - magenta.
```

## `copper`

```
COPPER Carte de couleurs noir - cuivre.
```

## `ellipj`

```
ELLIPJ Fonctions elliptiques de Jacobi.
  [SN,CN,DN] = ELLIPJ(U,M) évalue les trois fonctions au point U pour
  le paramètre M = k^2.

  La méthode est celle de la transformation de Landen descendante
  (Abramowitz et Stegun 16.4) : on descend la suite arithmético-
  géométrique, puis on remonte l'angle par arcsinus. Pour M = 0 on
  retrouve le sinus et le cosinus ordinaires, pour M = 1 la tangente
  et la sécante hyperboliques.

  Exemple :
     [s, c, d] = ellipj(0.5, 0);   % sin(0.5), cos(0.5), 1
```

## `ellipke`

```
ELLIPKE Intégrales elliptiques complètes de première et seconde espèce.
  [K,E] = ELLIPKE(M) où M est le paramètre, M = k^2 avec k le module.
  Le calcul suit la moyenne arithmético-géométrique de Gauss : la suite
  converge quadratiquement, une dizaine de tours suffisent à la
  précision machine.

  Exemple :
     [K, E] = ellipke(0.5)   % 1.854074677301372 et 1.350643881047676
```

## `errorbar`

```
ERRORBAR Courbe avec barres d'erreur.
  ERRORBAR(Y,E) trace Y et, sur chaque point, une barre verticale allant
  de Y-E à Y+E.

  ERRORBAR(X,Y,E) place les points en X.

  ERRORBAR(X,Y,BAS,HAUT) donne des écarts différents vers le bas et vers
  le haut.

  ERRORBAR(...,STYLE) prend une chaîne de style, comme PLOT.

  Exemple :
     x = 1:5;
     y = [2 4 3 5 4];
     errorbar(x, y, 0.4 * ones(size(y)), 'o-');

  Voir aussi PLOT, BAR, STAIRS, STD.
```

## `flag`

```
FLAG Carte de couleurs alternant rouge, blanc, bleu et noir.
  Utile pour faire ressortir les lignes de niveau : deux valeurs
  voisines y prennent des couleurs très différentes.
```

## `gray`

```
GRAY Carte de couleurs en niveaux de gris.
  CARTE = GRAY(M) rend une matrice M x 3 allant du noir au blanc.
  M vaut 256 par défaut.

  Exemple :
     carte = gray(4)   % [0 0 0; 1/3 1/3 1/3; 2/3 2/3 2/3; 1 1 1]
```

## `hot`

```
HOT Carte de couleurs noir - rouge - jaune - blanc.
  Les trois tiers de la rampe montent tour à tour le rouge, le vert
  puis le bleu : c'est la couleur d'un corps chauffé.
```

## `hsv`

```
HSV Carte de couleurs parcourant le cercle des teintes.
  La saturation et la valeur restent à 1 : seule la teinte tourne, du
  rouge au rouge en passant par tout le spectre.
```

## `humps`

```
HUMPS Fonction d'essai à deux pics, utilisée par les démonstrations.
  Y = HUMPS(X) évalue 1/((x-0.3)^2+0.01) + 1/((x-0.9)^2+0.04) - 6.
```

## `inpolygon`

```
INPOLYGON Points intérieurs à un polygone.
  IN = INPOLYGON(XQ,YQ,XV,YV) vaut vrai pour les points de (XQ,YQ) qui
  sont dans le polygone de sommets (XV,YV), bord compris.

  [IN,ON] = INPOLYGON(...) distingue les points posés sur le bord.

  Le test est celui du nombre de traversées : on compte les côtés que
  coupe une demi-droite partant du point ; un nombre impair signifie
  que le point est dedans.

  Exemple :
     inpolygon(0.5, 0.5, [0 1 1 0], [0 0 1 1])   % vrai
```

## `iskeyword`

```
ISKEYWORD Mot réservé du langage ?
  ISKEYWORD rend la liste des mots réservés.
  ISKEYWORD(NOM) dit si NOM en fait partie.
```

## `ismembertol`

```
ISMEMBERTOL Appartenance à un ensemble, à une tolérance près.
```

## `jet`

```
JET Carte de couleurs bleu - cyan - jaune - rouge.
  Construite par interpolation linéaire entre les six teintes qui la
  définissent : bleu foncé, bleu, cyan, jaune, rouge, rouge foncé.

  Exemple :
     c = jet(64);   % c(1,:) vaut [0 0 0.5], c(end,:) vaut [0.5 0 0]
```

## `matlab.addons.installedAddons`

```
MATLAB.ADDONS.INSTALLEDADDONS Liste les toolboxes installées.
  T = MATLAB.ADDONS.INSTALLEDADDONS rend une table à colonnes Name,
  Version, Enabled et Identifier — une ligne par dossier de la racine
  des toolboxes.

  Exemple :
     t = matlab.addons.installedAddons;
     height(t)
```

## `matlab.addons.toolbox.installToolbox`

```
MATLAB.ADDONS.TOOLBOX.INSTALLTOOLBOX Installe une toolbox.
  ID = ...INSTALLTOOLBOX(DOSSIER) copie le dossier donné dans la racine
  des toolboxes et l'ajoute au chemin de recherche. Le dossier doit
  contenir un fichier Contents.m, comme toute toolbox MATLAB.

  Exemple :
     matlab.addons.toolbox.installToolbox('/tmp/maToolbox');
```

## `matlab.addons.toolbox.packageToolbox`

```
MATLAB.ADDONS.TOOLBOX.PACKAGETOOLBOX Empaquette une toolbox.
  F = ...PACKAGETOOLBOX(DOSSIER,NOM) fabrique une archive du dossier.
  MATLAB produit un .mltbx ; ici c'est une archive ZIP, lisible partout
  et réinstallable par installToolbox après décompression.
```

## `matlab.addons.toolbox.uninstallToolbox`

```
MATLAB.ADDONS.TOOLBOX.UNINSTALLTOOLBOX Retire une toolbox installée.
  ...UNINSTALLTOOLBOX(ID) efface le dossier et le retire du chemin.
```

## `matlabroot`

```
MATLABROOT Racine de l'installation de MatLibre.
  C'est le dossier qui contient les toolboxes.
```

## `matlibre_cases`

_Pas de bloc d'aide._

## `matlibre_racine_toolbox`

```
MATLIBRE_RACINE_TOOLBOX Dossier qui contient les toolboxes.
  C'est celui que l'interpréteur a trouvé au démarrage ; la variable
  d'environnement MATLIBRE_TOOLBOX le remplace quand elle est posée.
```

## `nextpow2`

```
NEXTPOW2 Exposant de la puissance de deux immédiatement supérieure.
  P = NEXTPOW2(N) rend le plus petit entier P tel que 2^P >= abs(N).
  Pour un tableau, le calcul se fait élément par élément.

  Exemple :
     nextpow2(1000)   % 10
```

## `nexttile`

```
NEXTTILE Passe à la case suivante d'un TILEDLAYOUT.
  NEXTTILE rend courante la case suivante du découpage préparé par
  TILEDLAYOUT, et rend sa poignée.

  NEXTTILE(K) va directement à la case K.

  Sans TILEDLAYOUT préalable, la figure est découpée en une seule case.

  Exemple :
     tiledlayout(1, 2);
     nexttile; plot(1:10); title('a gauche');
     nexttile; plot(10:-1:1); title('a droite');

  Voir aussi TILEDLAYOUT, SUBPLOT, AXES, GCA.
```

## `peaks`

```
PEAKS Surface d'essai à trois bosses et trois creux.
  Z = PEAKS rend la surface sur une grille 49 x 49 de [-3,3]^2.
  Z = PEAKS(N) évalue la fonction sur une grille N x N de [-3,3]^2.
  Z = PEAKS(V) utilise la grille MESHGRID(V,V), V étant un vecteur.
  Z = PEAKS(X,Y) évalue la fonction aux points donnés ; X et Y doivent
  avoir la même taille.
  [X,Y,Z] = PEAKS(...) rend aussi la grille.

  La formule est celle de la documentation :
     z = 3(1-x)^2 e^{-x^2-(y+1)^2} - 10(x/5 - x^3 - y^5) e^{-x^2-y^2}
         - 1/3 e^{-(x+1)^2 - y^2}
```

## `perms`

```
PERMS Toutes les permutations des éléments d'un vecteur.
  P = PERMS(V) rend une matrice dont chaque ligne est une permutation
  de V. L'ordre suit celui de MATLAB : lexicographique inverse.
```

## `pink`

```
PINK Carte de couleurs pastel, pour les images en sépia.
```

## `pow2`

```
POW2 Puissance de deux, ou mantisse mise à l'échelle.
  Y = POW2(X) rend 2.^X.
  Y = POW2(F,E) rend F .* 2.^E.
```

## `prism`

```
PRISM Carte de couleurs répétant les six couleurs du prisme.
```

## `rampeCarte`

```
RAMPECARTE Rampe de 0 à 1 sur M points, colonne.
  Pour M = 1 la rampe vaut zéro, comme dans MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `rat`

```
RAT Approximation rationnelle par fractions continues.
  [N,D] = RAT(X) rend deux entiers tels que N/D vaut X à la tolérance
  par défaut près (1e-6 fois la valeur).
  S = RAT(X) rend la chaîne « n/d ».
```

## `readmatrix`

```
READMATRIX Lit un fichier texte délimité et rend une matrice.
  M = READMATRIX(FICHIER) lit les nombres d'un fichier délimité — .csv,
  .txt, .dat — et les rend dans une matrice. Le séparateur est deviné
  parmi la virgule, le point-virgule, la tabulation et l'espace ; les
  lignes d'en-tête, celles qui ne portent aucun nombre, sont sautées ;
  une case vide ou non numérique devient NaN.

  M = READMATRIX(FICHIER,'Delimiter',D) impose le séparateur. D peut
  être un caractère, ou l'un des noms 'comma', 'semi', 'tab', 'space'.

  M = READMATRIX(FICHIER,'NumHeaderLines',N) saute N lignes en tête, au
  lieu de les reconnaître.

  M = READMATRIX(FICHIER,'Range','A2') commence à la ligne et à la
  colonne indiquées, dans la notation des tableurs.

  Exemple :
     f = fullfile(tempdir, 'essai.csv');
     writematrix([1 2; 3 4], f);
     readmatrix(f)      % [1 2; 3 4]

  Voir aussi WRITEMATRIX, READTABLE, DLMREAD, LOAD.
```

## `rescale`

```
RESCALE Remise à l'échelle linéaire d'un tableau.
  Y = RESCALE(X) ramène les valeurs dans [0,1].
  Y = RESCALE(X,A,B) les ramène dans [A,B].
```

## `residue`

```
RESIDUE Décomposition en éléments simples d'une fraction rationnelle.
  [R,P,K] = RESIDUE(B,A) décompose B(s)/A(s), polynômes donnés par
  leurs coefficients en puissances décroissantes, sous la forme

     B(s)     R(1)         R(n)
     ---- = -------- +...+ -------- + K(s)
     A(s)   s - P(1)       s - P(n)

  Pour un pôle de multiplicité M, les M termes qui lui correspondent
  sont consécutifs et valent R(j)/(s-P)^j, j = 1..M, comme dans MATLAB.

  [B,A] = RESIDUE(R,P,K) fait le chemin inverse et reconstitue la
  fraction.

  Exemple :
     [r,p,k] = residue([1 0], [1 3 2])   % 1/(s+1) et -... sur s+2
```

## `spring`

```
SPRING Carte de couleurs magenta - jaune.
```

## `summer`

```
SUMMER Carte de couleurs vert - jaune.
```

## `tiledlayout`

```
TILEDLAYOUT Découpe la figure en cases, comme SUBPLOT.
  TILEDLAYOUT(M,N) prépare un découpage en M lignes et N colonnes. Les
  cases se remplissent ensuite une à une par NEXTTILE, dans l'ordre de
  lecture — c'est ce qui distingue cette disposition de SUBPLOT, où l'on
  nomme la case à chaque fois.

  TILEDLAYOUT('flow') laisse le nombre de cases se décider à mesure :
  MatLibre prend alors trois colonnes.

  Les options de MATLAB — 'TileSpacing', 'Padding' — sont acceptées et
  sans effet : l'espacement des cases n'est pas réglable ici.

  Exemple :
     tiledlayout(2, 2);
     nexttile; plot(1:10);
     nexttile; plot(sin(1:10));
     nexttile; bar([3 1 2]);

  Voir aussi NEXTTILE, SUBPLOT, FIGURE, AXES.
```

## `uniquetol`

```
UNIQUETOL Valeurs distinctes à une tolérance près.
  U = UNIQUETOL(X,TOL) regroupe les valeurs dont l'écart relatif est
  inférieur à TOL (1e-6 par défaut).
```

## `unzip`

```
UNZIP Extrait une archive ZIP.
  UNZIP(ARCHIVE,DOSSIER) extrait dans le dossier donné, le dossier
  courant par défaut.
```

## `validatestring`

```
VALIDATESTRING Complète une option textuelle parmi une liste.
  S = VALIDATESTRING(CHAINE,OPTIONS) rend l'élément de OPTIONS dont
  CHAINE est un préfixe, sans distinction de casse. Une erreur est levée
  si aucun ou plusieurs éléments correspondent.
```

## `vecnorm`

```
VECNORM Norme de chaque vecteur d'un tableau.
  N = VECNORM(A) rend la norme 2 de chaque colonne.
  N = VECNORM(A,P) utilise la norme P.
  N = VECNORM(A,P,DIM) travaille le long de la dimension DIM.
```

## `winter`

```
WINTER Carte de couleurs bleu - vert.
```

## `writematrix`

```
WRITEMATRIX Écrit une matrice dans un fichier texte délimité.
  WRITEMATRIX(M,FICHIER) écrit la matrice, une ligne par ligne, les
  valeurs séparées par des virgules. C'est le format .csv, que tout
  tableur relit.

  WRITEMATRIX(M,FICHIER,'Delimiter',D) impose le séparateur : un
  caractère, ou l'un des noms 'comma', 'semi', 'tab', 'space'.

  Les nombres sont écrits avec quinze chiffres significatifs, de quoi
  les relire à l'identique. Un entier s'écrit sans décimales, un NaN
  « NaN », un infini « Inf ».

  Exemple :
     f = fullfile(tempdir, 'essai.csv');
     writematrix(magic(4), f);
     isequal(readmatrix(f), magic(4))   % vrai

  Voir aussi READMATRIX, WRITETABLE, DLMWRITE, SAVE.
```

## `zip`

```
ZIP Fabrique une archive ZIP.
  ZIP(ARCHIVE,FICHIERS) empaquette les fichiers donnés. FICHIERS peut
  être un nom, une cellule de noms ou un motif.

  L'archive est produite par la commande « zip » du système ; sans
  elle, la fonction le dit clairement plutôt que d'écrire un fichier
  incomplet.
```

