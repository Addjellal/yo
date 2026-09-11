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
%
% Matrices d'essai
%   hadamard      - Colonnes orthogonales de plus et moins un
%   pascal        - Coefficients binomiaux ; déterminant un, très mal
%                   conditionnée
%   compan        - Compagnon d'un polynôme : ses valeurs propres en sont
%                   les racines
%   invhilb       - Inverse exacte de Hilbert, en entiers
%   wilkinson     - Valeurs propres presque confondues deux à deux
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
% Tableaux : formes, ensembles, répétitions
%   repelem       - Répétition élément par élément
%   setxor        - Différence symétrique de deux ensembles
%   shiftdim      - Décalage des dimensions
%   issorted      - Le tableau est-il trié ?
%   issortedrows  - Les lignes sont-elles triées ?
%   convn         - Convolution à N dimensions
%   pagemtimes    - Produit matriciel page par page
%   pagetranspose, pagectranspose - Transposée de chaque page
%   swapbytes     - Inversion de l'ordre des octets
%   celldisp      - Affiche le contenu d'un tableau de cellules
%   namelengthmax - Longueur maximale d'un nom
%   genvarname    - Fabrique des noms de variables valides
%   nthargout     - Ne garder qu'une sortie d'une fonction
%
% Données : classes, groupes, manquants
%   discretize    - Range des valeurs dans des classes
%   histcounts2   - Comptage sur un quadrillage à deux dimensions
%   histogram2    - Histogramme à deux dimensions
%   ismissing     - Repère les valeurs manquantes
%   rmmissing     - Retire les valeurs manquantes
%   fillmissing   - Comble les valeurs manquantes
%   isoutlier     - Repere les valeurs aberrantes
%   filloutliers  - Les remplace
%   rmoutliers    - Les retire
%   standardizeMissing - Traduit un code d'absence en vrai manquant
%   findgroups    - Numérote les groupes d'un classement
%   splitapply    - Applique une fonction groupe par groupe
%   pivot         - Tableau croisé d'une table
%
% Texte et JSON
%   split, splitlines - Découpe du texte
%   jsonencode, jsondecode - Écriture et lecture du JSON
%
% Fichiers et web
%   readcell, writecell - Fichier délimité et tableau de cellules
%   readvars      - Les colonnes d'un fichier, une par sortie
%   importdata    - Charge un fichier sans dire de quel genre il est
%   matfile       - Accès à un fichier .mat variable par variable
%   genpath       - Chemin d'un dossier et de ses sous-dossiers
%   what          - Inventaire des fichiers MATLAB d'un dossier
%   fileattrib    - Attributs d'un fichier
%   webread, websave - Lecture d'une adresse
%   filemarker    - Séparateur d'un fichier et de sa sous-fonction
%
% Dates
%   eomday        - Dernier jour du mois
%   calendar      - Calendrier d'un mois
%   weeknum       - Numéro de la semaine
%   yyyymmdd      - Date écrite AAAAMMJJ
%   months        - Nombre de mois entre deux dates
%
% Appels et interface
%   inputParser   - Contrôle des arguments d'une fonction
%   memoize       - Garde les résultats d'une fonction
%   MemoizedFunction - L'objet que rend memoize
%   inputdlg      - Demande des valeurs à l'utilisateur
%   allchild      - Enfants d'un objet graphique, cachés compris
%   numlock       - État du verrouillage numérique
%
% Cartes de couleurs
%   gray, hot, cool, spring, summer, autumn, winter, bone, copper,
%   pink, jet, hsv, flag, prism
%
% Interpolation et texte
%   griddata            - Interpolation de donnees dispersees
%   isstrprop           - Nature de chaque caractere d'un texte
%   vectorize           - Rend une expression applicable terme a terme
%   empty               - Tableau vide d'une classe donnee
```

## `MemoizedFunction`

```
MEMOIZEDFUNCTION Fonction qui retient ses résultats.
  C'est l'objet que rend MEMOIZE. Il s'appelle comme la fonction
  d'origine ; les arguments déjà vus ne sont pas recalculés.

  Exemple :
     f = memoize(@(x) x ^ 2);
     f(4)                        % 16
     f(4)                        % 16, sans recalculer

  Voir aussi MEMOIZE, CLEARCACHE, STATS.
```

## `allchild`

```
ALLCHILD Enfants d'un objet graphique, y compris les cachés.
  E = ALLCHILD(H) rend les objets dont H est le parent. À la
  différence de get(H,'Children'), les objets marqués cachés y
  figurent aussi.

  Avec plusieurs poignées, E est un tableau de cellules, un par
  poignée.

  Exemple :
     plot(1:3);
     numel(allchild(gca))     % 1

  Voir aussi FINDOBJ, GET, GCA, GCF, FINDALL.
```

## `alpha`

```
ALPHA Transparence (acceptée, sans effet).
  ALPHA(A) règle, dans MATLAB, la transparence des objets de l'axe
  courant : A va de 0 — transparent — à 1 — opaque.
  ALPHA('clear'), ALPHA('opaque') et ALPHA('flat') sont les formes
  nommées.

  Le rendu de MatLibre ne gère pas la transparence : l'appel est
  accepté pour qu'un programme tourne sans retouche et ne change rien à
  l'image.

  Exemple :
     surf(peaks(30)); alpha(0.5);

  Voir aussi SHADING, COLORMAP, LIGHTING, PATCH, FILL.
```

## `alphaShape`

```
ALPHASHAPE Forme alpha d'un nuage de points du plan.
  SHP = ALPHASHAPE(X,Y) construit la forme alpha des points, avec un
  rayon choisi tout seul. SHP = ALPHASHAPE(X,Y,ALPHA) impose le rayon.
  SHP = ALPHASHAPE(P,...) où P a deux colonnes fait la même chose.

  Une forme alpha est ce qu'on obtient en triangulant le nuage, puis en
  retirant les triangles dont le cercle circonscrit dépasse le rayon
  ALPHA. Elle interpole entre le nuage lui-même — ALPHA nul, plus rien
  ne reste — et son enveloppe convexe — ALPHA infini, tout reste. Entre
  les deux, elle épouse le nuage, et peut y creuser des baies et des
  trous que l'enveloppe convexe ne voit pas.

  Ce qu'on lui demande : AREA, PERIMETER, BOUNDARYFACETS, INSHAPE,
  ALPHATRIANGULATION, CRITICALALPHA, NUMREGIONS.

  Exemple :
     t = linspace(0, 2*pi, 41)'; t(end) = [];
     shp = alphaShape(cos(t), sin(t), 2);
     abs(area(shp) - polyarea(cos(t), sin(t))) < 1e-9
     inShape(shp, 0, 0)              % 1 : le centre est dedans

  Voir aussi BOUNDARY, CONVHULL, DELAUNAY, POLYAREA.
```

## `ancestor`

```
ANCESTOR Ancêtre d'un objet graphique, d'un type donné.
  P = ANCESTOR(H,TYPE) rend la poignée de l'ancêtre de H dont le type
  est TYPE — 'axes' ou 'figure'. Si H est déjà de ce type, c'est H qui
  est rendu. S'il n'y a pas d'ancêtre de ce type, P est vide.

  TYPE peut être une cellule : le premier type rencontré en remontant
  l'emporte.

  Remonter l'arbre est ce qui permet d'agir sur la figure d'une courbe
  sans l'avoir gardée : « set(ancestor(h,'figure'),'Name','x') ».

  Exemple :
     figure; courbe = plot(1:3);
     strcmp(get(ancestor(courbe, 'axes'), 'Type'), 'axes')     % 1
     strcmp(get(ancestor(courbe, 'figure'), 'Type'), 'figure') % 1

  Voir aussi GCA, GCF, FINDOBJ, GET.
```

## `annotation`

```
ANNOTATION Flèche, trait, rectangle ou texte posé sur la figure.
  ANNOTATION('arrow',[X1 X2],[Y1 Y2]) trace une flèche.
  ANNOTATION('line',[X1 X2],[Y1 Y2]) trace un trait.
  ANNOTATION('doublearrow',...) trace une flèche à deux pointes.
  ANNOTATION('rectangle',[X Y L H]) trace un rectangle.
  ANNOTATION('ellipse',[X Y L H]) trace l'ellipse inscrite.
  ANNOTATION('textbox',[X Y L H],'String',T) écrit un texte.
  ANNOTATION('textarrow',[X1 X2],[Y1 Y2],'String',T) trace une flèche
  et écrit le texte à sa base.

  Dans MATLAB, les coordonnées sont celles de la figure entière, de 0 à
  1. MatLibre n'a pas d'axe superposé à la figure : il les prend pour
  des fractions de l'axe courant, et l'annotation suit donc le tracé
  plutôt que le cadre. C'est la seule différence.

  ANNOTATION(...,'Color',C) et ANNOTATION(...,'LineWidth',E) règlent le
  trait.

  H = ANNOTATION(...) rend les poignées.

  Exemples :
     plot(1:10);
     annotation('arrow', [0.3 0.5], [0.3 0.6]);
     annotation('textbox', [0.2 0.7 0.2 0.1], 'String', 'le sommet');
     annotation('ellipse', [0.4 0.4 0.2 0.2]);

  Voir aussi TEXT, LINE, RECTANGLE, GTEXT, TITLE.
```

## `arrayDatastore`

```
ARRAYDATASTORE Magasin de données bâti sur un tableau déjà en mémoire.
  DS = ARRAYDATASTORE(A) parcourt A par morceaux, ligne par ligne par
  défaut. DS = ARRAYDATASTORE(A,'ReadSize',N) prend N lignes à la fois.
  DS = ARRAYDATASTORE(A,'IterationDimension',D) parcourt suivant D.

  Il n'économise aucune mémoire — le tableau y est déjà. Son emploi est
  d'écrire une seule fois le code qui parcourt un magasin, et de le
  faire marcher aussi bien sur un fichier que sur ce qu'on a sous la
  main : c'est utile pour essayer, et pour les tests.

  Exemple :
     ds = arrayDatastore([1 2; 3 4; 5 6], 'ReadSize', 2);
     size(read(ds))                  % 2 lignes prises
     hasdata(ds)                     % 1 : il en reste une

  Voir aussi DATASTORE, TABULARTEXTDATASTORE, READ, READALL.
```

## `autumn`

```
AUTUMN Carte de couleurs rouge - jaune.
  CARTE = AUTUMN() rend une carte de 256 couleurs allant du rouge au
  jaune. CARTE = AUTUMN(M) en rend M. Chaque ligne est un triplet
  rouge-vert-bleu dans [0,1].

  Le rouge reste à un, le vert monte de zéro à un, le bleu est nul. La
  luminance croît donc de façon monotone d'un bout à l'autre : la carte
  garde un ordre lisible même imprimée en niveaux de gris, ce qui n'est
  pas le cas de toutes. Elle n'atteint ni le noir ni le blanc, si bien
  que les deux extrêmes restent visibles sur un fond blanc.

  Exemple :
     carte = autumn(8);
     size(carte)

  Voir aussi SPRING, SUMMER, WINTER, COLORMAP, PARULA.
```

## `bar3`

```
BAR3 Diagramme en barres à trois dimensions.
  BAR3(Z) trace une barre par élément de Z, rangées en lignes et en
  colonnes. BAR3(Y,Z) place les rangées aux ordonnées Y.
  BAR3(...,LARGEUR) donne aux barres une largeur relative.

  H = BAR3(...) rend les poignées.

  Le rendu de MatLibre est plan : les colonnes de Z sont tracées côte à
  côte en groupes de barres, ce qui montre la même chose sans la
  perspective — laquelle, sur un diagramme en barres, cache
  régulièrement les barres du fond.

  Exemples :
     bar3(magic(4));
     bar3(rand(5, 3));

  Voir aussi BAR, BARH, BAR3H, WATERFALL, HEATMAP.
```

## `bar3h`

```
BAR3H Diagramme en barres horizontales à trois dimensions.
  BAR3H(Z) fait ce que fait BAR3, les barres couchées.

  H = BAR3H(...) rend les poignées.

  Le rendu de MatLibre est plan, comme pour BAR3.

  Exemples :
     bar3h(magic(4));

  Voir aussi BAR3, BARH, BAR, HEATMAP.
```

## `barh`

```
BARH Diagramme en barres horizontales.
  BARH(Y) trace une barre horizontale par élément de Y, la première en
  bas. BARH(X,Y) place les barres aux ordonnées X.

  BARH(...,LARGEUR) donne aux barres une largeur relative, 0.8 par
  défaut. Une largeur de 1 les fait se toucher.

  BARH(...,STYLE) accepte une chaîne de style comme PLOT, dont seule la
  couleur est employée.

  H = BARH(...) rend les poignées des barres.

  Une barre horizontale se lit mieux qu'une verticale quand les
  étiquettes sont longues : c'est le seul motif de préférer BARH à BAR.

  Exemples :
     barh([3 5 2 7]);
     yticklabels({'nord', 'sud', 'est', 'ouest'});

     barh([10 20 30], 0.5);

  Voir aussi BAR, BAR3, PARETO, STAIRS, FILL, YTICKLABELS.
```

## `bicg`

```
BICG Résolution itérative par méthode de Krylov.
  X = BICG(A,B) résout A*X = B. X = BICG(A,B,TOL,MAXIT) impose la
  tolérance relative — 1e-6 par défaut — et le nombre maximal
  d'itérations. X = BICG(A,B,TOL,MAXIT,M1,M2,X0) ajoute un
  préconditionneur et un point de départ. A peut être une poignée de
  fonction rendant A*x.

  [X,DRAPEAU,RES,K,RESIDUS] = BICG(...) rend le drapeau de sortie, le
  résidu relatif, le nombre d'itérations et leur historique.

  Contrairement à PCG, la matrice n'a pas à être définie positive : ces
  méthodes valent pour un système quelconque. Le prix est la garantie —
  le gradient conjugué converge de façon monotone en norme A, celles-ci
  peuvent stagner ou osciller.

  Exemple :
     A = [4 1 0; 1 3 1; 0 1 2];
     b = [1; 2; 3];
     x = bicg(A, b, 1e-10, 50);
     norm(A * x - b) / norm(b) < 1e-9

  Voir aussi PCG, GMRES, MINRES, BICG, MLDIVIDE.
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

  Exemple :
     carte = bone(8);
     size(carte)                 % 8 3

  Voir aussi GRAY, PINK, COPPER.
```

## `boundary`

```
BOUNDARY Contour d'un nuage de points, plus ou moins serré.
  K = BOUNDARY(X,Y) rend les indices des points du contour, le premier
  répété à la fin. K = BOUNDARY(X,Y,S) règle le serrage : S = 0 donne
  l'enveloppe convexe, S = 1 le contour le plus serré qui enferme encore
  tous les points. Par défaut S vaut 0,5.
  K = BOUNDARY(P,...) où P a deux colonnes fait la même chose.

  [K,A] = BOUNDARY(...) rend aussi l'aire enfermée.

  Le contour est celui d'une forme alpha : on triangule les points,
  puis on retire les triangles trop étirés — ceux dont le cercle
  circonscrit est plus grand qu'un seuil —, et le bord de ce qui reste
  est le contour. Le seuil vient de S : à S = 0 il est infini, donc
  aucun triangle ne part et le bord est l'enveloppe convexe ; plus S
  monte, plus le contour épouse le nuage et peut y creuser des baies.

  Exemple :
     t = linspace(0, 2*pi, 41)'; t(end) = [];
     x = cos(t); y = sin(t);
     k = boundary(x, y, 0);
     isequal(unique(k), unique(convhull(x, y)))   % a zero, c'est l'enveloppe
     [~, a] = boundary(x, y, 0);
     abs(a - polyarea(x, y)) < 1e-12

  Voir aussi ALPHASHAPE, CONVHULL, DELAUNAY, POLYAREA.
```

## `bounds`

```
BOUNDS Minimum et maximum en un seul appel.
  [B,H] = BOUNDS(X) rend le plus petit et le plus grand élément.

  Exemple :
     [bas, haut] = bounds([3 1 4 1 5]);
     [bas haut]                  % 1 5

  Voir aussi MIN, MAX, RANGE.
```

## `boxchart`

```
BOXCHART Boîtes à moustaches (forme moderne).
  BOXCHART(Y) dessine une boîte à moustaches par colonne de Y.
  BOXCHART(GROUPE,Y) dessine une boîte par groupe, GROUPE prenant la
  forme qu'accepte GRP2IDX.

  BOXCHART(...,'BoxFaceColor',C) et les autres propriétés de MATLAB
  sont acceptées ; MatLibre n'emploie pas encore la couleur.

  H = BOXCHART(...) rend les poignées.

  BOXCHART a remplacé BOXPLOT depuis R2020a. Les deux dessinent la même
  chose ; BOXCHART se distingue par une syntaxe où le groupe vient en
  premier, et par sa place dans la boîte à outils de base plutôt que
  dans celle des statistiques.

  Exemples :
     boxchart(randn(100, 3));
     boxchart([1 1 1 2 2 2]', [1 2 3 10 11 12]');

  Voir aussi BOXPLOT, HISTOGRAM, PRCTILE, GRPSTATS.
```

## `brush`

```
BRUSH Sélection de points à la souris (acceptée, sans effet).
  BRUSH ON permet, dans MATLAB, de surligner des points d'un tracé à la
  souris et de retrouver les données correspondantes ; BRUSH OFF
  l'interdit.

  Les figures de MatLibre ne sont pas manipulables à la souris :
  l'appel est accepté pour qu'un programme tourne sans retouche.

  Exemple :
     plot(randn(100, 1), 'o'); brush('on');

  Voir aussi DATACURSORMODE, ZOOM, PAN, FINDOBJ.
```

## `bubblechart`

```
BUBBLECHART Nuage de points dont la taille porte une troisième variable.
  BUBBLECHART(X,Y,TAILLES) dessine un disque en chaque point, dont
  l'aire suit TAILLES. BUBBLECHART(X,Y,TAILLES,COULEUR) donne les
  couleurs. Les propriétés de SCATTER sont acceptées.
  H = BUBBLECHART(...) rend la poignée.

  L'aire, non le rayon : l'œil compare des surfaces, et coder la donnée
  dans le rayon la ferait paraître quadratique. C'est la faute la plus
  commune des graphiques à bulles, et la raison pour laquelle cette
  fonction existe à côté de SCATTER, qui prend une aire en points carrés
  sans rien normaliser.

  Les tailles sont ramenées à une plage lisible : la plus petite donnée
  devient un petit disque, la plus grande un gros, et les autres entre
  les deux proportionnellement à la donnée.

  Exemple :
     figure();
     bubblechart(1:5, rand(1, 5), [1 4 9 16 25]);
     close all;

  Voir aussi SCATTER, BUBBLELEGEND, SWARMCHART, PLOT.
```

## `bvp4c`

```
BVP4C Problème aux limites en deux points, par collocation.
  SOL = BVP4C(ODEFUN,BCFUN,SOLINIT) résout y' = ODEFUN(x,y) sous les
  conditions BCFUN(ya,yb) = 0, en partant de la devinette SOLINIT que
  rend BVPINIT.
  SOL = BVP4C(...,OPTIONS) accepte 'RelTol' et 'NMax' via BVPSET.

  SOL porte le maillage dans SOL.X et la solution dans SOL.Y, une
  colonne par point. DEVAL l'évalue entre les points.

  Un problème aux limites ne s'intègre pas : on ne connaît pas tout
  l'état d'un bout, donc on ne peut pas partir. La méthode discrétise
  tout l'intervalle à la fois et résout le grand système non linéaire
  qui en résulte — d'où le nom de collocation.

  La formule employée est celle de Lobatto IIIa à trois points, d'ordre
  quatre : sur chaque maille on impose que la solution vérifie
  l'équation aux deux bouts et au milieu, le point milieu étant lui-même
  déduit d'un développement d'Hermite. C'est la formule de MATLAB, et
  c'est ce que le « 4c » du nom désigne — ordre quatre, collocation.

  Le système est résolu par la méthode de Newton, dont la jacobienne est
  calculée par différences finies. Une devinette trop lointaine fait
  diverger : un problème aux limites peut avoir plusieurs solutions, et
  c'est la devinette qui choisit.

  Exemple :
     % y'' + y = 0, y(0) = 0, y(pi/2) = 1 : la solution est sin.
     f = @(x, y) [y(2); -y(1)];
     cl = @(ya, yb) [ya(1); yb(1) - 1];
     sol = bvp4c(f, cl, bvpinit(linspace(0, pi/2, 11), [0 1]));
     max(abs(sol.y(1, :) - sin(sol.x))) < 1e-6

  Voir aussi BVPINIT, BVPSET, DEVAL, ODE45.
```

## `bvpinit`

```
BVPINIT Devinette initiale pour BVP4C.
  SOLINIT = BVPINIT(X,YINIT) construit la structure que BVP4C attend :
  un maillage X et une première estimation de la solution. YINIT peut
  être un vecteur constant — la même valeur partout — ou une poignée de
  fonction rendant la valeur en un point.
  SOLINIT = BVPINIT(X,YINIT,PARAMETRES) ajoute des paramètres inconnus.

  Un problème aux limites n'a pas toujours une solution, et peut en
  avoir plusieurs. La devinette n'est donc pas un détail de mise en
  route : c'est elle qui décide vers laquelle des solutions le solveur
  converge, et si le poutre flambé se courbe d'un côté ou de l'autre.

  Exemple :
     solinit = bvpinit(linspace(0, 1, 11), [0 0]);
     size(solinit.y)                 % 2 11
     s2 = bvpinit(linspace(0, pi, 5), @(x) [sin(x); cos(x)]);

  Voir aussi BVP4C, DEVAL, ODE45.
```

## `bvpset`

```
BVPSET Réglages de BVP4C.
  OPTIONS = BVPSET('Nom',VALEUR,...) construit la structure de réglages.
  Reconnus : 'RelTol' (1e-6), 'AbsTol' (1e-6), 'NMax' (nombre maximal
  d'itérations de Newton, 50), 'Stats'.
  OPTIONS = BVPSET(ANCIENNES,'Nom',VALEUR,...) part d'une structure.

  Exemple :
     o = bvpset('RelTol', 1e-8);
     o.RelTol                        % 1e-08
     o2 = bvpset(o, 'NMax', 100);
     o2.RelTol                       % 1e-08 : l'ancienne valeur est gardee

  Voir aussi BVP4C, BVPINIT, ODESET.
```

## `calendar`

```
CALENDAR Calendrier d'un mois.
  C = CALENDAR(A,M) rend une matrice 6x7 : une colonne par jour de la
  semaine, dimanche en premier, une ligne par semaine. Les cases hors
  du mois valent zéro.

  C = CALENDAR(D) prend le mois de la date D, donnée en numéro de
  série ou en texte. Sans argument, c'est le mois courant.

  Sans sortie, le calendrier s'affiche.

  Exemple :
     calendar(2024, 2)

  Voir aussi EOMDAY, WEEKDAY, DATENUM, DATESTR.
```

## `caxis`

```
CAXIS Bornes de l'échelle de couleurs.
  CAXIS([CMIN CMAX]) fixe les valeurs qui correspondent aux deux bouts
  de la carte de couleurs : tout ce qui est sous CMIN prend la première
  couleur, tout ce qui est au-dessus de CMAX la dernière.

  CAXIS('auto') revient au choix automatique, qui prend le minimum et
  le maximum des données.

  BORNES = CAXIS rend les bornes courantes.

  Depuis R2022a, MATLAB nomme cette fonction CLIM ; CAXIS reste valable.

  Fixer les bornes sert quand on compare plusieurs images : sans cela,
  chacune emploie toute l'échelle et deux couleurs identiques
  représentent des valeurs différentes.

  Exemples :
     subplot(1,2,1); imagesc(peaks(30)); caxis([-8 8]);
     subplot(1,2,2); imagesc(2 * peaks(30)); caxis([-8 8]);
     % les deux images se comparent maintenant couleur pour couleur

  Voir aussi CLIM, COLORMAP, COLORBAR, IMAGESC, XLIM, YLIM.
```

## `celldisp`

```
CELLDISP Affiche le contenu d'un tableau de cellules.
  CELLDISP(C) affiche chaque élément de C précédé de son indice.
  CELLDISP(C,NOM) emploie NOM au lieu du nom de la variable.

  Exemple :
     celldisp({1, 'deux'})

  Voir aussi DISP, CELL.
```

## `cgs`

```
CGS Résolution itérative par méthode de Krylov.
  X = CGS(A,B) résout A*X = B. X = CGS(A,B,TOL,MAXIT) impose la
  tolérance relative — 1e-6 par défaut — et le nombre maximal
  d'itérations. X = CGS(A,B,TOL,MAXIT,M1,M2,X0) ajoute un
  préconditionneur et un point de départ. A peut être une poignée de
  fonction rendant A*x.

  [X,DRAPEAU,RES,K,RESIDUS] = CGS(...) rend le drapeau de sortie, le
  résidu relatif, le nombre d'itérations et leur historique.

  Contrairement à PCG, la matrice n'a pas à être définie positive : ces
  méthodes valent pour un système quelconque. Le prix est la garantie —
  le gradient conjugué converge de façon monotone en norme A, celles-ci
  peuvent stagner ou osciller.

  Exemple :
     A = [4 1 0; 1 3 1; 0 1 2];
     b = [1; 2; 3];
     x = cgs(A, b, 1e-10, 50);
     norm(A * x - b) / norm(b) < 1e-9

  Voir aussi PCG, GMRES, MINRES, BICG, MLDIVIDE.
```

## `clabel`

```
CLABEL Étiquette les lignes de niveau.
  CLABEL(C) écrit la valeur du niveau sur chaque ligne de la matrice de
  contours C — celle que rendent CONTOUR et CONTOURC.

  CLABEL(C,H) accepte aussi les poignées que rend CONTOUR ; elles ne
  servent pas au placement, mais la forme est celle de MATLAB.

  CLABEL(C,NIVEAUX) n'étiquette que les niveaux donnés.

  CLABEL(...,'FontSize',N) change la taille des étiquettes.
  CLABEL(...,'manual') attend un clic dans MATLAB ; MatLibre place les
  étiquettes automatiquement et accepte l'option sans effet.

  H = CLABEL(...) rend les poignées des textes.

  L'étiquette est posée au milieu de chaque courbe : c'est là qu'elle a
  le plus de chances de tomber sur une portion droite et lisible.

  Exemples :
     [X, Y] = meshgrid(-2:0.1:2);
     Z = X.^2 + Y.^2;
     C = contour(X, Y, Z, [0.5 1 2 3]);
     clabel(C);

     [C, h] = contour(peaks(40));
     clabel(C, h, 'FontSize', 8);

  Voir aussi CONTOUR, CONTOURF, CONTOURC, TEXT.
```

## `clearAllMemoizedCaches`

```
CLEARALLMEMOIZEDCACHES Vide les caches de toutes les fonctions mémoïsées.
  Une fonction mémoïsée retient ses résultats. Si ce dont elle dépend
  change sans que ses arguments changent — un fichier relu, une
  variable globale —, ce qu'elle retient devient faux : c'est le seul
  défaut de la mémoïsation, et vider le cache est le remède.

  Vider le cache d'un seul objet se fait par CLEARCACHE.

  Exemple :
     f = memoize(@(x) x + 1);
     f(1); f(1);
     clearAllMemoizedCaches();
     f(1);
     s = stats(f);
     s.CacheOccupancyPercent         % le cache s'est rempli a nouveau

  Voir aussi MEMOIZE, CLEARCACHE, STATS.
```

## `clim`

```
CLIM Bornes de l'échelle de couleurs.
  CLIM([CMIN CMAX]) fixe les valeurs qui correspondent aux deux bouts
  de la carte de couleurs.

  CLIM('auto') revient au choix automatique.

  BORNES = CLIM rend les bornes courantes.

  C'est le nom que MATLAB donne à CAXIS depuis R2022a. MatLibre garde
  les deux ; les bornes sont retenues et rendues, mais son rendu des
  images emploie encore l'étendue des données, si bien que les fixer ne
  change pas encore les couleurs.

  Exemples :
     imagesc(peaks(30));
     clim([-8 8]);
     clim

  Voir aussi CAXIS, COLORMAP, COLORBAR, IMAGESC.
```

## `colamd`

```
COLAMD Renumérotation des colonnes par degré minimal.
  P = COLAMD(A) rend une permutation des colonnes qui réduit le
  remplissage de la factorisation LU de A(:,P), sans supposer A
  symétrique ni carrée.

  L'ordre est celui du degré minimal appliqué au graphe de A'*A, dont la
  structure est exactement celle qui gouverne le remplissage de la
  factorisation par colonnes. On ne forme pas A'*A pour ses valeurs,
  seulement pour son motif.

  Exemple :
     A = [1 1 1; 1 0 0; 1 0 0; 0 1 0];
     p = colamd(A);
     isequal(sort(p), 1:3)                    % 1 : c'est une permutation

  Voir aussi SYMAMD, SYMRCM, LU, QR.
```

## `combine`

```
COMBINE Réunit plusieurs magasins en un seul, lu en parallèle.
  DS = COMBINE(DS1,DS2,...) rend un magasin dont chaque lecture prend
  un morceau de chacun et les rend côte à côte, dans une cellule.

  C'est ainsi qu'on apparie des données et leurs étiquettes quand elles
  vivent dans deux magasins : les lire séparément ne garantirait pas
  qu'on avance du même pas.

  La lecture s'arrête dès que l'un des magasins est épuisé : apparier
  au-delà n'aurait pas de sens, et continuer sur le plus long
  produirait des paires boiteuses.

  Exemple :
     a = arrayDatastore([1; 2; 3]);
     b = arrayDatastore([10; 20; 30]);
     c = combine(a, b);
     paire = read(c);
     paire{1} == 1 && paire{2} == 10

  Voir aussi DATASTORE, TRANSFORM, READ, HASDATA.
```

## `comet`

```
COMET Trace une courbe comme si elle se dessinait.
  COMET(Y) trace Y point à point ; COMET(X,Y) place les points en X.
  COMET(X,Y,P) donne à la traînée la longueur P, en fraction de la
  courbe ; 0.1 par défaut.

  Dans MATLAB, l'animation se voit : la tête avance et la traînée la
  suit. MatLibre n'anime pas ses figures — elles sont rendues une fois
  pour toutes — et COMET dessine donc la courbe entière, avec sa
  dernière traînée en évidence et un point à la tête. Ce que l'on garde
  d'une animation quand on l'imprime, c'est exactement cela.

  Exemples :
     t = linspace(0, 10*pi, 500);
     comet(t .* cos(t), t .* sin(t));

  Voir aussi COMET3, PLOT, ANIMATEDLINE, DRAWNOW.
```

## `comet3`

```
COMET3 Trace une courbe de l'espace comme si elle se dessinait.
  COMET3(X,Y,Z) fait ce que fait COMET, pour une courbe de l'espace.
  COMET3(Z) place les points aux indices.
  COMET3(X,Y,Z,P) donne à la traînée la longueur P.

  Le rendu de MatLibre est plan : la courbe est projetée en laissant
  tomber la troisième coordonnée, comme le fait PLOT3, et l'animation
  n'est pas jouée — voir COMET.

  Exemples :
     t = linspace(0, 10*pi, 500);
     comet3(cos(t), sin(t), t);

  Voir aussi COMET, PLOT3, ANIMATEDLINE.
```

## `compan`

```
COMPAN Matrice compagnon d'un polynôme.
  A = COMPAN(P) rend la matrice dont le polynôme caractéristique est P,
  donné par ses coefficients du degré le plus haut au plus bas. Ses
  valeurs propres sont donc les racines de P.

  C'est ainsi que ROOTS trouve les racines : plutôt que de chercher les
  zéros du polynôme, il calcule les valeurs propres de sa compagnon.
  Le détour paraît absurde et ne l'est pas — les algorithmes de valeurs
  propres sont bien plus stables que la recherche directe de racines,
  qui perd toute précision dès que deux racines sont proches.

  Le polynôme est normalisé par son coefficient de tête : un polynôme
  dont ce coefficient est nul n'a pas de compagnon de cette taille.

  Exemple :
     p = poly([1 2 3]);              % (x-1)(x-2)(x-3)
     compan(p)
     sort(eig(compan(p)).')          % [1 2 3]

  Voir aussi ROOTS, POLY, EIG, PASCAL.
```

## `compass`

```
COMPASS Flèches partant de l'origine.
  COMPASS(U,V) trace, pour chaque couple (U,V), une flèche qui part de
  l'origine et va au point. C'est la rose des vents : elle montre d'un
  coup où pointent des vecteurs et de quelle longueur ils sont.

  COMPASS(Z) où Z est complexe emploie la partie réelle et la partie
  imaginaire.

  COMPASS(...,STYLE) prend une chaîne de style, comme PLOT.

  H = COMPASS(...) rend les poignées.

  Exemples :
     compass([1 2 -1], [2 1 1]);
     compass(exp(1i * (0:pi/6:2*pi)));      % les douze directions

  Voir aussi FEATHER, QUIVER, POLARPLOT, ROSE, PLOT.
```

## `condest`

```
CONDEST Estime le conditionnement en norme 1.
  C = CONDEST(A) rend NORM(A,1) multiplié par une estimation de
  NORM(INV(A),1), obtenue par l'algorithme de Hager sans former
  l'inverse : chaque produit par l'inverse est une résolution.
  [C,V] = CONDEST(A) rend en outre un vecteur qui témoigne du mauvais
  conditionnement quand il y en a un.

  Le conditionnement mesure de combien une erreur relative sur les
  données peut être amplifiée dans le résultat : résoudre A*x = b avec
  un conditionnement de 1e8 fait perdre huit chiffres significatifs sur
  les seize que porte un double.

  L'estimation est une borne inférieure. C'est ce qu'on veut : elle ne
  promet jamais un conditionnement meilleur qu'il n'est.

  Exemple :
     condest(eye(3))                    % 1 : le mieux possible
     condest(hilb(6)) > 1e6             % la matrice de Hilbert est infame
     c = condest(magic(4));             % singuliere : c est enorme

  Voir aussi COND, NORMEST1, NORM, RCOND.
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

  Voir aussi INPOLYGON, DELAUNAY.
```

## `convhulln`

```
CONVHULLN Enveloppe convexe en dimension quelconque.
  K = CONVHULLN(P) rend les facettes de l'enveloppe convexe du nuage P,
  une ligne par facette portant les indices de ses sommets. En dimension
  deux les facettes sont des segments, en dimension trois des triangles.

  [K,V] = CONVHULLN(...) rend aussi le volume enfermé — l'aire en
  dimension deux.

  La méthode est celle du cadeau enveloppé (« gift wrapping ») : on
  part d'une facette du bord, et l'on fait pivoter un hyperplan autour
  de chacune de ses arêtes jusqu'à rencontrer le point le plus extérieur.
  Elle est plus lente qu'un balayage incrémental, mais elle ne dépend
  d'aucun ordre et ne se trompe pas sur les points alignés.

  En dimension deux, CONVHULL est plus rapide et rend un contour fermé
  plutôt que des segments.

  Exemple :
     P = [0 0; 1 0; 1 1; 0 1; 0.5 0.5];
     K = convhulln(P);
     size(K, 1)                      % 4 cotes : le point du milieu est dedans
     [~, aire] = convhulln(P);
     abs(aire - 1) < 1e-12

  Voir aussi CONVHULL, DELAUNAY, DELAUNAYTRIANGULATION, INPOLYGON.
```

## `convn`

```
CONVN Convolution à N dimensions.
  C = CONVN(A,B) rend la convolution complète de A par B : sa taille
  est size(A)+size(B)-1 suivant chaque dimension.
  C = CONVN(A,B,'same') rend la partie centrale, de la taille de A.
  C = CONVN(A,B,'valid') ne rend que la part calculée sans dépassement.

  Exemple :
     a = ones(3,3,3);
     c = convn(a, ones(2,2,2), 'valid');   % 2x2x2 de valeur 8

  Voir aussi CONV, CONV2, FILTER.
```

## `cool`

```
COOL Carte de couleurs cyan - magenta.
  CARTE = COOL() rend une carte de 256 couleurs allant du cyan au
  magenta. CARTE = COOL(M) en rend M.

  Le rouge monte de zéro à un, le vert descend de un à zéro, le bleu
  reste à un. La somme des trois canaux est constante : la carte varie
  presque uniquement en teinte, et très peu en luminance. C'est ce qui
  la rend agréable à l'écran et impropre à l'impression en niveaux de
  gris, où elle s'aplatit ; elle est également difficile à lire pour
  une vision déficiente au rouge et au vert.

  Exemple :
     carte = cool(8);
     sum(carte(1, :)) - sum(carte(end, :))

  Voir aussi AUTUMN, WINTER, COLORMAP, PARULA.
```

## `copper`

```
COPPER Carte de couleurs noir - cuivre.
  CARTE = COPPER() rend une carte de 256 couleurs allant du noir au
  cuivre. CARTE = COPPER(M) en rend M.

  Les trois canaux montent proportionnellement à la même rampe, dans le
  rapport 1,25 / 0,7812 / 0,4975 : la teinte ne change jamais, seule la
  clarté augmente. Le rouge sature à un aux quatre cinquièmes du
  parcours, ce qui donne le reflet métallique du haut de l'échelle.

  Une carte à teinte fixe et clarté monotone est celle qui trahit le
  moins : elle ne crée aucune frontière là où les données varient
  régulièrement, contrairement aux cartes arc-en-ciel dont les brusques
  changements de teinte font croire à des paliers.

  Exemple :
     carte = copper(8);
     carte(end, :)

  Voir aussi BONE, PINK, GRAY, HOT, COLORMAP.
```

## `copyobj`

```
COPYOBJ Recopie des objets graphiques dans un autre axe.
  H = COPYOBJ(POIGNEES,AX) recopie dans l'axe AX les objets désignés
  par POIGNEES, et rend les poignées des copies. C'est ainsi qu'on
  reprend une courbe déjà tracée dans une autre figure sans en
  recalculer les données.

  MatLibre recopie les courbes et les textes, avec leurs données et
  leur apparence.

  Exemples :
     figure(1); h = plot(1:10, (1:10).^2, 'r', 'LineWidth', 2);
     figure(2); ax = gca;
     copyobj(h, ax);

  Voir aussi FINDOBJ, GET, SET, GCA, SUBPLOT.
```

## `curl`

```
CURL Rotationnel d'un champ de vecteurs plan.
  Z = CURL(X,Y,U,V) rend la composante du rotationnel perpendiculaire
  au plan : dV/dx - dU/dy. Elle mesure combien le champ tourne :
  positive dans le sens direct, négative dans l'autre, nulle pour un
  champ qui dérive d'un potentiel.

  Z = CURL(U,V) prend une grille entière pour X et Y.

  [Z,AV] = CURL(...) rend en outre la vitesse angulaire, qui vaut la
  moitié du rotationnel.

  Exemples :
     [X, Y] = meshgrid(-2:0.2:2);
     curl(X, Y, -Y, X);               % 2 partout : le champ tournant
     max(max(abs(curl(X, Y, X, Y))))  % nul : le champ radial derive
                                      % d'un potentiel

  Voir aussi DIVERGENCE, GRADIENT, DEL2, QUIVER.
```

## `cylinder`

```
CYLINDER Coordonnées d'un cylindre, ou d'un solide de révolution.
  CYLINDER trace un cylindre unité de vingt mailles.
  CYLINDER(R) engendre le solide de révolution dont le rayon suit le
  profil R : R scalaire donne un cylindre droit, R vecteur donne un
  cône, un tonneau, un vase — le profil est lu de bas en haut.
  CYLINDER(R,N) emploie N mailles sur le tour.

  [X,Y,Z] = CYLINDER(...) rend les trois grilles de coordonnées, sans
  rien tracer. Z va de 0 à 1 ; on le met ensuite à l'échelle voulue.

  Le rendu de MatLibre est plan : CYLINDER sans sortie montre la
  hauteur en couleurs.

  Exemples :
     cylinder;
     cylinder([1 0]);                 % un cone
     cylinder(sin(linspace(0, pi, 20)) + 0.5);    % un tonneau
     [X, Y, Z] = cylinder(2, 10);
     size(X)                          % 2 par 11

  Voir aussi SPHERE, ELLIPSOID, SURF, MESH.
```

## `datacursormode`

```
DATACURSORMODE Curseur de données (accepté, sans effet).
  DATACURSORMODE ON permet, dans MATLAB, de cliquer sur un point d'une
  courbe pour en lire les coordonnées ; DATACURSORMODE OFF l'interdit.

  Les figures de MatLibre ne sont pas manipulables à la souris :
  l'appel est accepté pour qu'un programme tourne sans retouche. Pour
  lire les coordonnées d'un point, GET sur la poignée de la courbe rend
  XData et YData.

  Exemple :
     h = plot(1:10); datacursormode('on');
     [get(h, 'XData')', get(h, 'YData')']     % la meme information

  Voir aussi BRUSH, ZOOM, PAN, GET, GINPUT.
```

## `datastore`

```
DATASTORE Magasin de données, choisi d'après ce qu'on lui donne.
  DS = DATASTORE(CHEMIN) construit le magasin qui convient : texte
  tabulaire pour un .csv, .txt ou .dat, images pour un dossier
  d'images. DATASTORE(...,'Type',TYPE) l'impose : 'tabulartext' ou
  'image'.

  Un magasin se parcourt par morceaux : READ rend le suivant, HASDATA
  dit s'il en reste, RESET revient au début, READALL lit tout d'un coup
  et PREVIEW montre les premières lignes sans avancer.

  Ce qui n'est pas fait : la lecture réellement paresseuse. Le fichier
  est lu une fois pour toutes à la construction, puis découpé. Le
  programme qui parcourt le magasin est donc le même que sous MATLAB,
  mais la mémoire n'est pas économisée — et c'est la seule raison
  d'employer un magasin. L'annoncer vaut mieux que de le laisser
  découvrir sur un jeu qui ne tient pas.

  Exemple :
     f = [tempname '.csv'];
     writelines(["a,b"; "1,2"; "3,4"], f);
     ds = datastore(f);
     height(readall(ds))             % 2 lignes de donnees
     delete(f);

  Voir aussi TABULARTEXTDATASTORE, IMAGEDATASTORE, READ, READALL, PREVIEW.
```

## `datetick`

```
DATETICK Gradue un axe en dates.
  DATETICK remplace les graduations de l'axe des abscisses par les
  dates correspondantes, les valeurs étant lues comme des numéros de
  série DATENUM.

  DATETICK(AXE) gradue l'axe nommé : 'x', 'y' ou 'z'.
  DATETICK(AXE,FORMAT) emploie le format donné, qui peut être un numéro
  de format de DATESTR ou une chaîne comme 'yyyy-mm-dd'.

  DATETICK(...,'keeplimits') ne change pas les bornes de l'axe ;
  'keepticks' garde les graduations en place et n'en réécrit que les
  étiquettes.

  Exemples :
     t = datenum(2024, 1, 1) + (0:29);
     plot(t, cumsum(randn(1, 30)));
     datetick('x', 'dd/mm');

  Voir aussi DATENUM, DATESTR, XTICKS, XTICKLABELS, DATETIME.
```

## `decomposition`

```
DECOMPOSITION Factorisation gardée, pour résoudre plusieurs fois.
  DA = DECOMPOSITION(A) factorise A une fois pour toutes ; DA\B résout
  ensuite aussi vite qu'une substitution, sans refactoriser.
  DA = DECOMPOSITION(A,TYPE) impose la factorisation : 'lu', 'chol',
  'qr', 'ldl' ou 'auto' (défaut).

  Résoudre A\B coûte deux choses : factoriser, en N cube sur trois, et
  substituer, en N carré. Quand on résout dix fois avec la même matrice,
  l'antislash refait dix fois la factorisation ; DECOMPOSITION la fait
  une fois. Le gain est le rapport N sur trois — dix fois sur une
  matrice de trente lignes, cent sur une de trois cents.

  Le choix automatique suit la matrice : Cholesky si elle est
  symétrique définie positive, LDL si elle est symétrique, QR si elle
  n'est pas carrée, LU sinon. Cholesky coûte moitié moins que LU et
  c'est la raison de le préférer quand il s'applique.

  Propriétés : MatrixSize, Type, IsReal.

  ISILLCONDITIONED(DA) dit si la factorisation a rencontré un rapport de
  pivots négligeable. C'est la seule information que la substitution ne
  peut plus retrouver : une fois factorisé, le mauvais conditionnement
  ne se voit plus dans le résultat, il se voit dans les pivots.

  Exemple :
     A = [4 1; 1 3];
     dA = decomposition(A);
     x = dA \ [1; 2];
     norm(A * x - [1; 2]) < 1e-12
     dA.Type                         % 'chol' : A est definie positive
     isIllConditioned(dA)            % 0

  Voir aussi MLDIVIDE, LU, CHOL, QR, LDL, ISILLCONDITIONED.
```

## `del2`

```
DEL2 Laplacien discret, divisé par quatre.
  L = DEL2(U) rend le laplacien discret de U : en chaque point, la
  moyenne des voisins moins le point lui-même. C'est la convention de
  MATLAB, qui divise le laplacien par le nombre de directions fois deux
  — quatre pour une matrice, deux pour un vecteur — de sorte que

     L = (d2u/dx2 + d2u/dy2) / 4

  L = DEL2(U,H) prend un pas H entre les points.
  L = DEL2(U,HX,HY) prend un pas par direction ; HX et HY peuvent être
  des vecteurs de coordonnées.

  Aux bords, la valeur est extrapolée depuis l'intérieur, comme le fait
  MATLAB : le laplacien y est moins sûr qu'ailleurs.

  Une fonction harmonique — la partie réelle d'une fonction
  holomorphe, le potentiel dans le vide — a un laplacien nul : c'est le
  moyen de vérifier une solution d'équation de Laplace.

  Exemples :
     del2([1 4 9 16 25])              % 1 : la derivee seconde de x^2,
                                      % divisee par deux
     [X, Y] = meshgrid(-2:0.2:2);
     L = del2(X.^2 - Y.^2, 0.2);
     max(max(abs(L(2:end-1, 2:end-1))))     % nul : la fonction est
                                            % harmonique

  Voir aussi GRADIENT, DIFF, DIVERGENCE, LAPLACIAN.
```

## `delaunay`

```
DELAUNAY Triangulation de Delaunay.
  T = DELAUNAY(X,Y) rend la triangulation de Delaunay des points
  (X,Y) : une ligne par triangle, portant les indices de ses trois
  sommets. C'est la triangulation dont aucun cercle circonscrit ne
  contient de point ; c'est elle qui évite au mieux les triangles
  étirés, ce qui la rend bonne pour l'interpolation et le maillage.

  T = DELAUNAY(P) où P a deux colonnes fait la même chose.

  La construction est celle de Bowyer et Watson : on part d'un grand
  triangle qui contient tout, on insère les points un à un en
  supprimant les triangles dont le cercle circonscrit contient le
  nouveau point, et on retriangule le trou ainsi créé.

  Trois points alignés ne forment pas de triangle ; s'ils le sont tous,
  la triangulation est vide.

  Exemples :
     x = rand(20, 1); y = rand(20, 1);
     T = delaunay(x, y);
     trimesh(T, x, y);

     T = delaunay([0 1 1 0], [0 0 1 1])     % deux triangles

  Voir aussi TRIMESH, TRISURF, VORONOI, CONVHULL, GRIDDATA.
```

## `delaunayTriangulation`

```
DELAUNAYTRIANGULATION Triangulation de Delaunay, avec ses requêtes.
  DT = DELAUNAYTRIANGULATION(P) triangule les points P, une ligne par
  point. DT = DELAUNAYTRIANGULATION(X,Y) accepte les coordonnées
  séparées.

  C'est la triangulation dont aucun cercle circonscrit ne contient de
  point — la propriété du cercle vide. Elle maximise le plus petit
  angle, ce qui évite les triangles étirés, et c'est pour cela qu'elle
  sert de base à l'interpolation et au maillage.

  La classe dérive de TRIANGULATION : EDGES, FREEBOUNDARY, NEIGHBORS,
  CIRCUMCENTER, INCENTER et les autres s'appliquent telles quelles. Elle
  y ajoute ce qu'on ne peut demander qu'à une triangulation de Delaunay :
  CONVEXHULL rend l'enveloppe convexe, POINTLOCATION dit dans quel
  triangle tombe un point, NEARESTNEIGHBOR quel sommet en est le plus
  proche.

  Le bord libre d'une triangulation de Delaunay est l'enveloppe convexe
  des points : c'est une conséquence directe de la propriété du cercle
  vide, et les tests s'en servent pour la vérifier.

  Exemple :
     P = [0 0; 1 0; 1 1; 0 1; 0.5 0.5];
     dt = delaunayTriangulation(P);
     size(dt.ConnectivityList, 1)    % quatre triangles
     isa(dt, 'triangulation')        % 1 : elle en derive
     pointLocation(dt, [0.6 0.4])    % le triangle qui contient ce point

  Voir aussi TRIANGULATION, DELAUNAY, CONVHULL, VORONOI.
```

## `digraph`

```
DIGRAPH Graphe orienté.
  G = DIGRAPH(S,T) construit le graphe dont les arcs vont de S(k) vers
  T(k). G = DIGRAPH(S,T,W) leur donne des poids.
  G = DIGRAPH(A) prend une matrice d'adjacence : A(i,j) non nul décrit
  un arc de i vers j, et la matrice n'a pas à être symétrique.
  G = DIGRAPH(S,T,W,NOMS) nomme les nœuds.

  L'orientation change tout ce qui suit. Un chemin de 1 vers 4 n'est pas
  un chemin de 4 vers 1 ; la connexité se décline en forte et faible ;
  un tri topologique n'existe que s'il n'y a pas de cycle. C'est pour
  cela que DIGRAPH et GRAPH sont deux classes et non une seule avec un
  drapeau.

  Propriétés : Edges, une table des arcs et de leurs poids ; Nodes, une
  table des nœuds.

  Ce qu'on lui fait : NUMNODES, NUMEDGES, ADJACENCY, INDEGREE, OUTDEGREE,
  SUCCESSORS, PREDECESSORS, SHORTESTPATH, DISTANCES, CONNCOMP, TOPOSORT,
  BFSEARCH, DFSEARCH, ADDEDGE, ADDNODE, RMEDGE, RMNODE, SUBGRAPH, PLOT.

  Exemple :
     g = digraph([1 2 3], [2 3 4]);
     shortestpath(g, 1, 4)           % 1 2 3 4
     isempty(shortestpath(g, 4, 1))  % 1 : on ne remonte pas un arc
     toposort(g)                     % 1 2 3 4

  Voir aussi GRAPH, SHORTESTPATH, TOPOSORT, CONNCOMP.
```

## `discretize`

```
DISCRETIZE Range des valeurs dans des classes.
  BINS = DISCRETIZE(X,BORDS) rend, pour chaque valeur de X, le numéro
  de la classe qui la contient : BINS(i) vaut j quand BORDS(j) <= X(i)
  < BORDS(j+1). La dernière classe est fermée des deux côtés. Une
  valeur hors des bords donne NaN.

  BINS = DISCRETIZE(X,N) découpe l'étendue de X en N classes égales.

  BINS = DISCRETIZE(X,BORDS,VALEURS) rend la valeur associée à la
  classe au lieu de son numéro ; VALEURS peut être un tableau de
  cellules de noms.

  DISCRETIZE(...,'IncludedEdge','right') ferme les classes à droite.
  DISCRETIZE(...,'categorical',NOMS) rend un tableau catégoriel.

  [BINS,BORDS] = DISCRETIZE(...) rend aussi les bords employés.

  Exemple :
     discretize([1 2 3 4 5], [1 3 5])    % [1 1 2 2 2]

  Voir aussi HISTCOUNTS, HISTOGRAM, INTERP1, CATEGORICAL.
```

## `divergence`

```
DIVERGENCE Divergence d'un champ de vecteurs.
  D = DIVERGENCE(X,Y,U,V) rend la divergence du champ (U,V) défini aux
  points (X,Y) : la somme des dérivées partielles dU/dx et dV/dy. Elle
  mesure ce qui sort d'un petit volume : positive là où le champ jaillit,
  négative là où il converge, nulle pour un champ incompressible.

  D = DIVERGENCE(U,V) prend une grille entière pour X et Y.

  Exemples :
     [X, Y] = meshgrid(-2:0.2:2);
     divergence(X, Y, X, Y);          % 2 partout : le champ radial
     max(max(abs(divergence(X, Y, -Y, X))))   % nul : le champ tournant

  Voir aussi GRADIENT, CURL, DEL2, QUIVER.
```

## `eigs`

```
EIGS Quelques valeurs propres seulement.
  D = EIGS(A) rend les six valeurs propres de plus grand module.
  D = EIGS(A,K) en rend K. D = EIGS(A,K,CHOIX) précise lesquelles :
     'largestabs'   plus grand module (défaut)
     'smallestabs'  plus petit module
     'largestreal'  plus grande partie réelle
     'smallestreal' plus petite partie réelle
  [V,D] = EIGS(...) rend les vecteurs propres en colonnes et les valeurs
  propres sur la diagonale de D.

  MATLAB emploie ici une méthode de Krylov, qui ne demande que des
  produits matrice-vecteur et convient donc aux très grandes matrices
  creuses. MatLibre calcule la décomposition complète et en retient ce
  qui est demandé : le résultat est le même, mais le coût est celui de
  EIG. Sur une matrice de quelques milliers de lignes, cela reste
  praticable ; au-delà, c'est la limite à connaître.

  Le tri par module est celui qui compte pour la stabilité : la
  dynamique d'un système discret est gouvernée par sa valeur propre de
  plus grand module, et c'est elle qu'on demande d'abord.

  Exemple :
     A = diag([1 2 3 10]);
     eigs(A, 2)'                         % 10 3
     eigs(A, 2, 'smallestabs')'          % 1 2
     [V, D] = eigs(A, 1);
     norm(A * V - V * D) < 1e-12

  Voir aussi EIG, SVDS, NORMEST, CONDEST.
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

  Voir aussi ELLIPKE, PROTOTYPEELLIPTIQUE.
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

  Voir aussi ELLIPJ, PROTOTYPEELLIPTIQUE.
```

## `ellipsoid`

```
ELLIPSOID Coordonnées d'un ellipsoïde.
  ELLIPSOID(XC,YC,ZC,RX,RY,RZ) trace l'ellipsoïde centré en
  (XC,YC,ZC) et de demi-axes RX, RY et RZ.
  ELLIPSOID(...,N) emploie N mailles ; vingt par défaut.

  [X,Y,Z] = ELLIPSOID(...) rend les trois grilles sans rien tracer.

  L'ellipsoïde sert à représenter une covariance : les demi-axes sont
  les racines des valeurs propres, à un facteur près qui fixe la
  probabilité couverte.

  Le rendu de MatLibre est plan, comme pour SPHERE.

  Exemples :
     ellipsoid(0, 0, 0, 3, 1, 2);
     [X, Y, Z] = ellipsoid(1, 2, 3, 1, 1, 1, 10);
     size(X)                          % 11 par 11

  Voir aussi SPHERE, CYLINDER, SURF, MESH, COV.
```

## `empty`

```
EMPTY Tableau vide d'une classe donnée.
  X = EMPTY() rend le tableau vide 0 sur 0 de type double.
  X = EMPTY(CLASSE) rend le tableau vide 0 sur 0 de cette classe.
  X = EMPTY(CLASSE,M,N,...) rend un tableau vide de ces dimensions ;
  l'une d'elles au moins doit valoir zéro.

  En MATLAB, EMPTY est une méthode statique que toute classe porte, et
  qu'on appelle par CLASSE.EMPTY(...) — DOUBLE.EMPTY, STRING.EMPTY,
  MACLASSE.EMPTY(0,3). Cette forme marche dans MatLibre. La forme
  fonction ci-dessus lui sert de compagne : elle rend le même tableau
  quand le nom de la classe est dans une variable, ce que la notation à
  point ne permet pas.

  Un tableau vide n'est pas rien : il a une classe et des dimensions,
  et c'est ce qui le rend utile pour amorcer une concaténation ou pour
  rendre un résultat de la bonne forme quand il n'y a rien à rendre.

  Exemple :
     empty()                        % 0 sur 0, double
     size(empty('double', 0, 3))    % 0 3
     classe = 'single';
     class(empty(classe))           % single

  Voir aussi ISEMPTY, ZEROS, CLASS, SIZE.
```

## `eomday`

```
EOMDAY Dernier jour du mois.
  D = EOMDAY(A,M) rend le numéro du dernier jour du mois M de l'année
  A : 28 ou 29 pour février selon que l'année est bissextile.

  Exemple :
     eomday(2024, 2)     % 29

  Voir aussi CALENDAR, DATENUM, WEEKDAY, DAYSACT.
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

## `exportgraphics`

```
EXPORTGRAPHICS Enregistre un graphique dans un fichier.
  EXPORTGRAPHICS(OBJET,FICHIER) écrit le contenu de l'axe ou de la
  figure donnée dans FICHIER, dont l'extension choisit le format.
  EXPORTGRAPHICS(FICHIER) exporte la figure courante.
  EXPORTGRAPHICS(...,'Resolution',R) et les autres propriétés sont
  acceptées.

  Elle a remplacé PRINT et SAVEAS depuis R2020a. La différence tient à
  ce qui est exporté : SAVEAS enregistre la figure entière, avec ses
  marges ; EXPORTGRAPHICS n'exporte que le contenu, rogné au plus près.
  C'est ce qu'on veut pour insérer une figure dans un document.

  Exemple :
     figure();
     plot(1:10);
     fichier = [tempname() '.svg'];
     exportgraphics(gca, fichier);
     isfile(fichier)                 % 1
     close all;

  Voir aussi SAVEAS, PRINT, FIGURE, GCA.
```

## `ezcontour`

```
EZCONTOUR Lignes de niveau d'une fonction (nom historique).
  EZCONTOUR(F) trace les lignes de niveau de F sur
  [-2*pi 2*pi] x [-2*pi 2*pi]. F est une poignée de deux variables, ou
  une chaîne comme 'x^2 + y^2'.

  EZCONTOUR(F,[A B]) ou EZCONTOUR(F,[A B C D]) fixe le domaine.

  H = EZCONTOUR(...) rend la poignée.

  Depuis R2016b, MATLAB recommande FCONTOUR ; MatLibre garde les deux.

  Exemples :
     ezcontour('x^2 + y^2');
     ezcontour(@(x, y) sin(x) + cos(y), [-pi pi]);

  Voir aussi FCONTOUR, CONTOUR, EZSURF, EZPLOT.
```

## `ezmesh`

```
EZMESH Trace le maillage d'une surface (nom historique).
  EZMESH(F) fait ce que fait EZSURF, en dessinant le quadrillage. Le
  rendu de MatLibre étant plan, les deux donnent la même image.

  EZMESH(F,[A B]) ou EZMESH(F,[A B C D]) fixe le domaine.

  H = EZMESH(...) rend la poignée.

  Exemples :
     ezmesh('x^2 - y^2');
     ezmesh(@(x, y) exp(-x.^2 - y.^2), [-2 2]);

  Voir aussi EZSURF, FMESH, EZCONTOUR, MESH.
```

## `ezplot`

```
EZPLOT Trace une fonction ou une courbe implicite (nom historique).
  EZPLOT(F) trace F sur [-2*pi 2*pi]. F est une poignée d'une variable,
  ou une chaîne comme 'sin(x)/x'.

  EZPLOT(F,[A B]) fixe l'intervalle.

  EZPLOT(F) où F est une poignée de deux variables trace la courbe
  implicite F(x,y) = 0 : c'est ainsi qu'on dessine un cercle,
  'x^2 + y^2 - 1'.

  EZPLOT(FX,FY) trace la courbe paramétrée.

  H = EZPLOT(...) rend la poignée.

  EZPLOT est l'ancien nom ; depuis R2016b, MATLAB recommande FPLOT pour
  une fonction d'une variable et FIMPLICIT pour une courbe implicite.
  MatLibre garde les trois.

  Exemples :
     ezplot('sin(x)/x');
     ezplot(@(x) x.^2 - 2, [-3 3]);
     ezplot(@(x, y) x.^2 + y.^2 - 1);       % le cercle unite

  Voir aussi FPLOT, FIMPLICIT, FCONTOUR, EZSURF, EZCONTOUR.
```

## `ezsurf`

```
EZSURF Trace une surface (nom historique).
  EZSURF(F) trace F sur [-2*pi 2*pi] x [-2*pi 2*pi]. F est une poignée
  de deux variables, ou une chaîne comme 'x^2 - y^2'.

  EZSURF(F,[A B]) ou EZSURF(F,[A B C D]) fixe le domaine.

  H = EZSURF(...) rend la poignée.

  Depuis R2016b, MATLAB recommande FSURF ; MatLibre garde les deux.

  Exemples :
     ezsurf('x^2 - y^2');
     ezsurf(@(x, y) sin(x) .* cos(y), [-pi pi]);

  Voir aussi FSURF, EZMESH, EZCONTOUR, EZPLOT, SURF.
```

## `fcontour`

```
FCONTOUR Lignes de niveau d'une fonction donnée par une poignée.
  FCONTOUR(F) trace les lignes de niveau de F sur [-5 5] x [-5 5].

  FCONTOUR(F,[A B]) emploie le carré [A B] x [A B].
  FCONTOUR(F,[A B C D]) emploie le rectangle donné.

  FCONTOUR(...,'LevelList',L) impose les niveaux.
  FCONTOUR(...,'MeshDensity',N) change la finesse de la grille, 80 par
  défaut. Une grille trop grossière donne des lignes anguleuses.

  H = FCONTOUR(...) rend la poignée.

  Exemples :
     fcontour(@(x, y) x.^2 + y.^2, [-2 2]);
     fcontour(@(x, y) sin(x) + cos(y), [-pi pi], 'LevelList', -1:0.5:1);

  Voir aussi CONTOUR, FSURF, FMESH, FPLOT, EZCONTOUR.
```

## `feather`

```
FEATHER Flèches réparties le long de l'axe des abscisses.
  FEATHER(U,V) trace la k-ième flèche à partir du point (k,0). C'est le
  diagramme des vents en météorologie : il montre comment un vecteur
  tourne au fil du temps.

  FEATHER(Z) où Z est complexe emploie la partie réelle et la partie
  imaginaire.

  FEATHER(...,STYLE) prend une chaîne de style.

  H = FEATHER(...) rend les poignées.

  Exemples :
     t = 0:pi/8:2*pi;
     feather(cos(t), sin(t));           % le vecteur fait un tour
     feather(exp(1i * t) .* (1:numel(t)) / 10);

  Voir aussi COMPASS, QUIVER, POLARPLOT, PLOT.
```

## `fileattrib`

```
FILEATTRIB Lit ou change les attributs d'un fichier.
  [OK,MSG,A] = FILEATTRIB(F) rend une structure décrivant F : son nom
  complet, s'il est un dossier, et les droits de lecture, d'écriture et
  d'exécution de l'utilisateur.

  FILEATTRIB(F,MODE) change les droits. MODE s'écrit comme dans un
  terminal : '+w' donne le droit d'écriture, '-w' le retire, '+x'
  rend exécutable.

  Exemple :
     f = fullfile(tempdir, 'essai.txt');
     fid = fopen(f, 'w'); fclose(fid);
     [ok, ~, a] = fileattrib(f);

  Voir aussi DIR, EXIST, ISFILE, ISFOLDER, DELETE.
```

## `filemarker`

```
FILEMARKER Le caractère qui sépare un fichier de sa sous-fonction.
  M = FILEMARKER rend le caractère employé dans les noms qualifiés du
  genre « monfichier>masousfonction », que rendent WHICH et les piles
  d'erreurs.

  Exemple :
     ['essai' filemarker() 'aide']     % 'essai>aide'

  Voir aussi WHICH, PATHSEP, FILESEP, DBSTACK.
```

## `fill3`

```
FILL3 Polygones remplis dans l'espace.
  FILL3(X,Y,Z,C) trace le polygone dont les sommets sont (X,Y,Z),
  rempli de la couleur C. Si X, Y et Z sont des matrices, chaque
  colonne donne un polygone.

  FILL3(...,'Name',valeur) accepte les mêmes propriétés que FILL.

  H = FILL3(...) rend les poignées.

  Le rendu de MatLibre est plan : Z est laissé de côté, et le polygone
  est dessiné dans le plan des X et des Y, comme le fait PLOT3.

  Exemples :
     fill3([0 1 1 0], [0 0 1 1], [0 0 1 1], 'c');
     fill3([0 1 0.5], [0 0 1], [0 0 1], [0.9 0.7 0.2]);

  Voir aussi FILL, PATCH, PLOT3, SURF, AREA.
```

## `fillmissing`

```
FILLMISSING Comble les valeurs manquantes.
  B = FILLMISSING(A,METHODE) remplace les valeurs manquantes de A —
  NaN pour un tableau numérique, la chaîne vide pour du texte, la
  catégorie indéfinie pour une catégorielle.

  METHODE vaut :
     'constant'   remplace par la valeur donnée en troisième argument
     'previous'   reprend la dernière valeur connue
     'next'       prend la prochaine valeur connue
     'nearest'    prend la plus proche des deux
     'linear'     interpole entre les deux voisines connues
     'spline'     interpole par une spline cubique
     'pchip'      interpole en préservant la monotonie
     'movmean'    moyenne mobile de la fenêtre donnée
     'movmedian'  médiane mobile de la fenêtre donnée

  B = FILLMISSING(A,'constant',V) donne la constante ; V peut porter
  une valeur par colonne.
  B = FILLMISSING(A,'movmean',K) donne la largeur de fenêtre.
  B = FILLMISSING(...,'EndValues',E) dit quoi faire des trous en bout,
  là où l'interpolation n'a pas de voisin des deux côtés : 'extrap'
  (défaut) prolonge, 'none' les laisse, ou une constante les comble.

  [B,MARQUE] = FILLMISSING(...) rend aussi les positions comblées.

  Un trou en bout n'est pas un trou comme un autre : il n'est pas
  encadré. C'est pourquoi il a son option à lui — et pourquoi la
  prolongation qu'on en fait est toujours une extrapolation, c'est-à-dire
  une hypothèse, non une mesure.

  Exemple :
     fillmissing([1 NaN 3], 'linear')        % [1 2 3]
     fillmissing([1 NaN 3], 'constant', 0)   % [1 0 3]
     fillmissing([NaN 2 3], 'previous')      % [NaN 2 3] : rien avant

  Voir aussi ISMISSING, RMMISSING, STANDARDIZEMISSING, INTERP1.
```

## `filloutliers`

_Pas de bloc d'aide._

## `fimplicit`

```
FIMPLICIT Courbe implicite F(x,y) = 0.
  FIMPLICIT(F) trace l'ensemble des points où F s'annule, sur
  [-5 5] x [-5 5]. F est une poignée de deux variables.

  FIMPLICIT(F,[A B]) emploie le carré [A B] x [A B].
  FIMPLICIT(F,[A B C D]) emploie le rectangle donné.

  H = FIMPLICIT(...) rend la poignée.

  La courbe est obtenue comme la ligne de niveau zéro de F, par la même
  méthode que CONTOUR : c'est exactement ce qu'est une courbe
  implicite.

  Exemples :
     fimplicit(@(x, y) x.^2 + y.^2 - 1);              % le cercle unite
     fimplicit(@(x, y) x.^3 + y.^3 - 3*x.*y, [-3 3]); % le folium
     fimplicit(@(x, y) y.^2 - x.^3 + x, [-2 3]);      % une cubique

  Voir aussi FCONTOUR, CONTOUR, FPLOT, EZPLOT, FSURF.
```

## `fimplicit3`

```
FIMPLICIT3 Surface implicite F(x,y,z) = 0.
  FIMPLICIT3(F) trace la surface où F s'annule, sur [-5 5]^3. F est une
  poignée de trois variables.
  FIMPLICIT3(F,[A B]) emploie le cube [A B]^3.
  FIMPLICIT3(F,[A B C D E G]) emploie le pavé donné.

  H = FIMPLICIT3(...) rend la poignée.

  La surface est obtenue en découpant le pavé en tranches et en traçant
  la ligne de niveau zéro de chacune. C'est la même idée qu'en deux
  dimensions, empilée : une surface implicite est la réunion de ses
  coupes, et chacune est une courbe implicite.

  Une surface qui ne coupe aucune tranche ne se voit pas : serrer les
  tranches est le remède, comme serrer la grille l'est pour une courbe.

  Exemple :
     fimplicit3(@(x, y, z) x.^2 + y.^2 + z.^2 - 4, [-3 3]);   % la sphere

  Voir aussi FIMPLICIT, FSURF, ISOSURFACE, CONTOUR3, FPLOT3.
```

## `findall`

```
FINDALL Cherche des objets graphiques, y compris ceux qui se cachent.
  H = FINDALL(...) prend les mêmes arguments que FINDOBJ et rend les
  mêmes objets, en plus de ceux dont la poignée est masquée.

  Dans MatLibre, aucune poignée n'est masquée : FINDALL et FINDOBJ y
  rendent donc exactement la même chose. La fonction existe pour que le
  programme écrit pour MATLAB tourne sans retouche, et la différence
  est dite ici plutôt que laissée à découvrir.

  Exemple :
     figure; plot(1:3);
     numel(findall(gca, 'Type', 'line'))   % 1

  Voir aussi FINDOBJ, GCA, GCF, ALLCHILD.
```

## `findgroups`

```
FINDGROUPS Numérote les groupes d'un tableau de classement.
  G = FINDGROUPS(A) rend, pour chaque élément de A, le numéro de son
  groupe : les valeurs distinctes de A sont numérotées dans l'ordre
  croissant. Une valeur manquante donne NaN.

  [G,ID] = FINDGROUPS(A) rend en outre la valeur qui définit chaque
  groupe.

  [G,ID1,ID2] = FINDGROUPS(A1,A2) croise deux classements.

  Exemple :
     [g, noms] = findgroups({'b','a','b'})   % g = [2 1 2]

  Voir aussi SPLITAPPLY, UNIQUE, ACCUMARRAY, GROUPSUMMARY.
```

## `findobj`

```
FINDOBJ Cherche des objets graphiques par leurs propriétés.
  H = FINDOBJ rend toutes les courbes de l'axe courant.

  H = FINDOBJ('Type','line') ne rend que les courbes ; 'text' ne rend
  que les textes.

  H = FINDOBJ('Nom',VALEUR) ne garde que les objets dont la propriété
  nommée vaut VALEUR — par exemple FINDOBJ('Color','#D95319') ou
  FINDOBJ('LineWidth',2).

  H = FINDOBJ(AX,...) cherche dans l'axe AX plutôt que dans l'axe
  courant.

  MATLAB cherche dans tout l'arbre des objets graphiques, figures
  comprises ; MatLibre s'en tient au contenu d'un axe, qui est ce que
  son modèle porte.

  Exemples :
     plot(1:10, 'r'); hold on; plot((1:10).^2, 'b'); hold off
     rouges = findobj('Color', '#D95319');
     set(rouges, 'LineWidth', 3);

     textes = findobj('Type', 'text');

  Voir aussi GCA, GCF, GET, SET, GCO, ALLCHILD.
```

## `flag`

```
FLAG Carte de couleurs alternant rouge, blanc, bleu et noir.
  Utile pour faire ressortir les lignes de niveau : deux valeurs
  voisines y prennent des couleurs très différentes.

  Exemple :
     carte = flag(8);
     size(carte)                 % 8 3

  Voir aussi PRISM.
```

## `fmesh`

```
FMESH Trace le maillage d'une surface donnée par une poignée.
  FMESH(F) fait ce que fait FSURF, en dessinant le quadrillage plutôt
  que la surface pleine. Le rendu de MatLibre étant plan, les deux
  donnent la même image.

  FMESH(F,[A B]) et FMESH(F,[A B C D]) fixent le domaine, comme FSURF.
  FMESH(...,'MeshDensity',N) change la finesse de la grille.

  H = FMESH(...) rend la poignée.

  Exemples :
     fmesh(@(x, y) x.^2 - y.^2, [-2 2]);

  Voir aussi FSURF, FCONTOUR, MESH, FPLOT, EZMESH.
```

## `fplot`

```
FPLOT Trace une fonction donnée par une poignée.
  FPLOT(F) trace F sur l'intervalle [-5 5]. F est une poignée qui
  accepte un vecteur et rend un vecteur de même taille.

  FPLOT(F,[A B]) trace sur l'intervalle donné.

  FPLOT(FX,FY) trace la courbe paramétrée dont l'abscisse est FX(t) et
  l'ordonnée FY(t), t parcourant [-5 5].
  FPLOT(FX,FY,[A B]) fixe l'intervalle du paramètre.

  FPLOT(...,STYLE) prend une chaîne de style, comme PLOT.
  FPLOT(...,'MeshDensity',N) change le nombre de points, 400 par
  défaut.

  H = FPLOT(...) rend la poignée de la courbe.

  MATLAB affine le pas là où la courbe tourne vite ; MatLibre emploie
  un pas constant, assez fin pour que la différence ne se voie pas sur
  les fonctions usuelles. Une fonction à variation très rapide demande
  d'augmenter 'MeshDensity'.

  Exemples :
     fplot(@(x) sin(x) ./ x, [-20 20]);
     fplot(@sin, [0 2*pi], 'r--');
     fplot(@(t) cos(3*t), @(t) sin(2*t), [0 2*pi]);   % une Lissajous

  Voir aussi PLOT, FSURF, FCONTOUR, EZPLOT, FIMPLICIT.
```

## `fplot3`

```
FPLOT3 Courbe paramétrée de l'espace.
  FPLOT3(FX,FY,FZ) trace la courbe (FX(t),FY(t),FZ(t)) pour t allant de
  -5 à 5. Les trois arguments sont des poignées d'une variable.
  FPLOT3(FX,FY,FZ,[A B]) emploie l'intervalle donné.
  FPLOT3(...,OPTIONS) passe les options de tracé à PLOT3.

  H = FPLOT3(...) rend la poignée.

  L'échantillonnage est régulier en paramètre, non en longueur d'arc :
  une courbe qui accélère est donc moins finement décrite là où elle va
  vite. Serrer l'intervalle est le remède.

  Exemple :
     fplot3(@(t) sin(t), @(t) cos(t), @(t) t, [0 6*pi]);   % une helice

  Voir aussi FPLOT, PLOT3, FSURF, FIMPLICIT3.
```

## `fsurf`

```
FSURF Trace une surface donnée par une poignée.
  FSURF(F) trace F sur le carré [-5 5] x [-5 5]. F est une poignée de
  deux variables, F(X,Y).

  FSURF(F,[A B]) emploie le carré [A B] x [A B].
  FSURF(F,[A B C D]) emploie le rectangle [A B] x [C D].

  FSURF(...,'MeshDensity',N) change la finesse de la grille, 40 par
  défaut.

  H = FSURF(...) rend la poignée.

  Le rendu de MatLibre est plan : la surface est montrée comme un champ
  coloré, à la façon de PCOLOR. FCONTOUR en donne les lignes de niveau,
  souvent plus lisible.

  Exemples :
     fsurf(@(x, y) x .* exp(-x.^2 - y.^2), [-2 2]);
     fsurf(@(x, y) sin(x) .* cos(y), [-pi pi -pi pi]);

  Voir aussi SURF, FCONTOUR, FMESH, FPLOT, EZSURF, MESHGRID.
```

## `gcbo`

```
GCBO Poignée de l'objet dont le rappel s'exécute.
  H = GCBO() rend la poignée de l'objet dont le rappel est en cours ;
  [H,F] = GCBO() rend aussi sa figure.

  MatLibre n'exécute pas les rappels d'objets graphiques : hors d'un
  rappel, MATLAB rend lui aussi un tableau vide, et c'est donc la
  réponse exacte.

  Exemple :
     isempty(gcbo())                 % 1 : aucun rappel en cours

  Voir aussi GCO, GCA, GCF.
```

## `gco`

```
GCO Poignée de l'objet courant.
  H = GCO() rend la poignée de l'objet sur lequel on a cliqué en
  dernier dans la figure courante ; H = GCO(F) interroge la figure F.

  MatLibre n'a pas d'interaction à la souris : aucun objet n'a jamais
  été désigné, et GCO rend donc un tableau vide. C'est la réponse
  exacte — MATLAB rend lui aussi un tableau vide tant qu'on n'a rien
  cliqué — et non une approximation : rendre « le dernier objet tracé »
  ferait marcher un programme pour de mauvaises raisons.

  Exemple :
     figure; plot(1:3);
     isempty(gco())                  % 1 : rien n'a ete designe

  Voir aussi GCA, GCF, GCBO, FINDOBJ.
```

## `genpath`

```
GENPATH Chemin d'un dossier et de tous ses sous-dossiers.
  P = GENPATH(D) rend, séparés par PATHSEP, D et tous ses
  sous-dossiers. Les dossiers que MATLAB réserve — ceux dont le nom
  commence par un point, par « @ » ou par « + », et « private » — n'y
  figurent pas : ils ne s'ajoutent pas au chemin de recherche.

  Sans argument, GENPATH part du dossier courant.

  Exemple :
     addpath(genpath(fullfile(matlabroot, 'toolbox', 'monlot')));

  Voir aussi PATH, ADDPATH, PATHSEP, DIR.
```

## `genvarname`

```
GENVARNAME Fabrique des noms de variables valides.
  N = GENVARNAME(C) transforme C — une chaîne ou un tableau de
  cellules de chaînes — en noms de variables acceptables : les
  caractères interdits deviennent leur code, un nom vide ou commençant
  par un chiffre reçoit un préfixe, un mot réservé reçoit un suffixe.

  N = GENVARNAME(C,EXCLUS) évite en outre les noms de la liste EXCLUS
  en ajoutant un numéro.

  Exemple :
     genvarname({'a b', 'end', 'a b'})   % {'a_0x20_b', 'end1', 'a_0x20_b1'}

  Voir aussi ISVARNAME, MATLAB.LANG.MAKEVALIDNAME, ISKEYWORD.
```

## `geoplot`

```
GEOPLOT Trace une trajectoire sur des coordonnées géographiques.
  GEOPLOT(LAT,LON) trace la ligne joignant les points donnés en degrés.
  GEOPLOT(LAT,LON,STYLE) accepte le style de PLOT.
  H = GEOPLOT(...) rend la poignée.

  MATLAB dessine ici un fond de carte ; MatLibre n'en emporte pas et
  trace la longitude en abscisse, la latitude en ordonnée, avec un
  rapport d'aspect corrigé par le cosinus de la latitude moyenne. Cette
  correction est ce qui empêche une trajectoire de paraître étirée : un
  degré de longitude vaut cos(latitude) degré de latitude en distance,
  et l'ignorer déforme tout dès qu'on quitte l'équateur.

  La projection est donc une équirectangulaire locale. Elle est fausse
  sur une grande étendue, comme toute projection plane, et l'aide le dit
  plutôt que de laisser croire à une carte exacte.

  Exemple :
     figure();
     geoplot([48.85 43.30 45.76], [2.35 5.37 4.83]);
     close all;

  Voir aussi GEOSCATTER, PLOT, AXIS.
```

## `geoscatter`

```
GEOSCATTER Nuage de points sur des coordonnées géographiques.
  GEOSCATTER(LAT,LON) place un point par couple. GEOSCATTER(LAT,LON,
  TAILLE,COULEUR) suit la syntaxe de SCATTER.
  H = GEOSCATTER(...) rend la poignée.

  Comme GEOPLOT, la projection est une équirectangulaire locale, dont le
  rapport d'aspect corrige le cosinus de la latitude moyenne.

  Exemple :
     figure();
     geoscatter([48.85 43.30], [2.35 5.37]);
     close all;

  Voir aussi GEOPLOT, SCATTER, BUBBLECHART.
```

## `getframe`

```
GETFRAME Capture le contenu d'une figure.
  F = GETFRAME capture la figure courante et rend une structure de deux
  champs : F.cdata, l'image, et F.colormap, la carte de couleurs. C'est
  ainsi que MATLAB construit les vues d'une animation, qu'on rejoue
  ensuite avec MOVIE.

  F = GETFRAME(H) capture la figure ou l'axe désigné.

  MatLibre rend ses figures en SVG, non en tableau de pixels : F.cdata
  est vide, et F.svg porte le dessin sous forme de texte. C'est ce
  qu'il faut pour l'enregistrer ou le comparer ; ce qui manque est le
  tableau de pixels que MOVIE rejouerait.

  Exemples :
     plot(1:10);
     f = getframe;
     numel(f.svg) > 0

  Voir aussi MOVIE, SAVEAS, PRINT, SAVEFIG, EXPORTGRAPHICS.
```

## `ginput`

```
GINPUT Lecture de points à la souris (indisponible).
  [X,Y] = GINPUT(N) attend, dans MATLAB, que l'on clique N fois sur la
  figure et rend les coordonnées des points cliqués.

  Les figures de MatLibre ne sont pas interactives : GINPUT ne peut pas
  faire ce qu'on lui demande, et le dit plutôt que de rendre des
  coordonnées inventées. Un programme qui en a besoin doit prendre ses
  points autrement — INPUT au clavier, ou des coordonnées écrites en
  clair.

  Exemple :
     % Les figures de MatLibre ne se cliquent pas : GINPUT le dit plutot que
     % de rendre des coordonnees inventees.
     try
         ginput(1);
     catch e
         e.identifier
     end

  Voir aussi INPUT, DATACURSORMODE, GTEXT, WAITFORBUTTONPRESS.
```

## `gmres`

_Pas de bloc d'aide._

## `gplot`

```
GPLOT Dessine un graphe donné par sa matrice d'adjacence.
  GPLOT(A,XY) trace une arête entre les nœuds I et J chaque fois que
  A(I,J) n'est pas nul. XY porte les coordonnées des nœuds, une ligne
  par nœud.

  GPLOT(A,XY,STYLE) prend une chaîne de style, comme PLOT.

  [X,Y] = GPLOT(A,XY) rend les coordonnées du tracé sans rien dessiner.
  Elles portent des NaN entre les arêtes, ce qui permet de tout tracer
  d'un seul PLOT : c'est la convention de MATLAB pour lever le crayon.

  Exemples :
     A = [0 1 1; 1 0 1; 1 1 0];         % le triangle
     xy = [0 0; 1 0; 0.5 1];
     gplot(A, xy, '-o');

     % Un graphe en anneau, ses noeuds sur un cercle
     n = 8;
     A = diag(ones(n-1, 1), 1) + diag(ones(n-1, 1), -1);
     t = linspace(0, 2*pi, n+1)';
     gplot(A, [cos(t(1:n)), sin(t(1:n))], '-o');

  Voir aussi PLOT, SPY, TRIMESH, GRAPH, DIGRAPH.
```

## `gradient`

```
GRADIENT Gradient numérique.
  FX = GRADIENT(F) où F est un vecteur rend ses différences, prises au
  centre à l'intérieur et d'un seul côté aux deux bouts. C'est la
  dérivée approchée, avec le même nombre de points que F — au contraire
  de DIFF, qui en rend un de moins.

  [FX,FY] = GRADIENT(F) où F est une matrice rend les deux dérivées
  partielles. FX est la dérivée dans le sens des colonnes — l'axe des
  abscisses —, FY dans le sens des lignes.

  [...] = GRADIENT(F,H) prend un pas H entre les points.
  [...] = GRADIENT(F,HX,HY) prend un pas par direction. HX et HY
  peuvent être des vecteurs de coordonnées plutôt que des pas
  constants ; les différences sont alors prises sur les écarts réels.

  Aux deux extrémités, la différence est décentrée sur un seul
  intervalle : elle est d'ordre un, alors que l'intérieur est d'ordre
  deux. C'est la règle de MATLAB.

  Exemples :
     gradient([1 4 9 16 25])         % [3 4 6 8 9], proche de 2x
     gradient((0:0.1:1).^2, 0.1)     % proche de 2x

     [X, Y] = meshgrid(-2:0.2:2);
     Z = X .* exp(-X.^2 - Y.^2);
     [dx, dy] = gradient(Z, 0.2);
     contour(X, Y, Z); hold on; quiver(X, Y, dx, dy); hold off

  Voir aussi DIFF, DEL2, DIVERGENCE, CURL, SURFNORM, CONTOUR.
```

## `graph`

```
GRAPH Graphe non orienté.
  G = GRAPH(S,T) construit le graphe dont les arêtes relient les nœuds
  S(k) et T(k). G = GRAPH(S,T,W) leur donne des poids.
  G = GRAPH(A) prend une matrice d'adjacence carrée et symétrique ; les
  valeurs non nulles deviennent les poids.
  G = GRAPH(S,T,W,NOMS) nomme les nœuds ; S et T peuvent alors être des
  noms au lieu de numéros.

  Un graphe non orienté n'a pas de sens de parcours : l'arête entre 1 et
  2 est la même que celle entre 2 et 1, et la matrice d'adjacence est
  symétrique. C'est tout ce qui le sépare de DIGRAPH, mais cela change
  les algorithmes — un cycle, une composante connexe, un arbre couvrant
  ne veulent pas dire la même chose dans les deux cas.

  Propriétés : Edges, une table des arêtes et de leurs poids ; Nodes,
  une table des nœuds et de leurs noms.

  Ce qu'on lui fait : NUMNODES, NUMEDGES, ADJACENCY, DEGREE, NEIGHBORS,
  SHORTESTPATH, SHORTESTPATHTREE, DISTANCES, CONNCOMP, MINSPANTREE,
  BFSEARCH, DFSEARCH, ADDEDGE, ADDNODE, RMEDGE, RMNODE, SUBGRAPH,
  LAPLACIAN, INCIDENCE, PLOT.

  Exemple :
     g = graph([1 2 3], [2 3 4]);
     numnodes(g)                     % 4
     numedges(g)                     % 3
     shortestpath(g, 1, 4)           % 1 2 3 4
     degree(g)'                      % 1 2 2 1

  Voir aussi DIGRAPH, SHORTESTPATH, CONNCOMP, MINSPANTREE, ADJACENCY.
```

## `gray`

```
GRAY Carte de couleurs en niveaux de gris.
  CARTE = GRAY(M) rend une matrice M x 3 allant du noir au blanc.
  M vaut 256 par défaut.

  Exemple :
     carte = gray(4)   % [0 0 0; 1/3 1/3 1/3; 2/3 2/3 2/3; 1 1 1]

  Voir aussi BONE, PINK.
```

## `griddata`

```
GRIDDATA Interpolation de données dispersées.
  VQ = GRIDDATA(X,Y,V,XQ,YQ) interpole les valeurs V connues aux points
  dispersés (X,Y) et les évalue en (XQ,YQ). Les points sont d'abord
  triangulés ; chaque point demandé est situé dans un triangle, et sa
  valeur lue par interpolation barycentrique.

  VQ = GRIDDATA(...,METHODE) où METHODE vaut :
    'linear'   le défaut : plan par triangle, continu mais anguleux
    'nearest'  la valeur du point de données le plus proche
    'natural'  moyenne pondérée par la distance inverse, lissée
    'cubic'    interpolation par plaque mince, lisse et exacte aux
               points de données
    'v4'       comme 'cubic'

  Un point demandé hors de l'enveloppe convexe des données reçoit NaN,
  sauf avec 'nearest' : au-delà des données, il n'y a rien à
  interpoler, et extrapoler serait inventer.

  Exemple :
     [x, y] = meshgrid(0:0.25:1, 0:0.25:1);
     z = 2 * x - 3 * y;
     abs(griddata(x(:), y(:), z(:), 0.3, 0.7) - (0.6 - 2.1)) < 1e-12

  Voir aussi DELAUNAY, INTERP2, INTERP1, SCATTEREDINTERPOLANT.
```

## `griddedInterpolant`

```
GRIDDEDINTERPOLANT Interpolation sur une grille.
  F = GRIDDEDINTERPOLANT(X,V) construit un interpolant des valeurs V aux
  abscisses X, croissantes. F = GRIDDEDINTERPOLANT(X,Y,V) fait de même
  sur une grille du plan, V étant de taille NUMEL(X) par NUMEL(Y) —
  l'ordre de NDGRID, non celui de MESHGRID.
  F = GRIDDEDINTERPOLANT(...,METHODE) choisit 'linear' (par défaut),
  'nearest', 'spline' ou 'pchip'. Une seconde chaîne donne le
  prolongement : 'none' (NaN) ou 'linear'.

  La différence avec SCATTEREDINTERPOLANT tient à la grille : les points
  étant rangés, retrouver la maille qui contient la question est une
  recherche dichotomique, non un parcours de triangles. C'est pour cela
  qu'un interpolant de grille est bien plus rapide, et c'est la seule
  raison de le distinguer.

  Quel que soit le procédé, l'interpolant repasse exactement par les
  valeurs données : c'est ce qui distingue interpoler d'ajuster.

  Exemple :
     x = linspace(0, 1, 11);
     F = griddedInterpolant(x, 3 * x + 1);
     abs(F(0.35) - (3 * 0.35 + 1)) < 1e-12    % exacte sur l'affine
     max(abs(F(x) - (3 * x + 1))) < 1e-12     % et sur les noeuds

  Voir aussi SCATTEREDINTERPOLANT, INTERP1, INTERP2, NDGRID.
```

## `groupfilter`

```
GROUPFILTER Ne garde que les groupes qui satisfont une condition.
  Y = GROUPFILTER(X,G,CONDITION) applique CONDITION à chaque groupe et
  ne garde que les éléments de ceux pour lesquels elle est vraie.
  CONDITION est une poignée de fonction recevant les valeurs du groupe.
  [Y,GARDE] = GROUPFILTER(...) rend en outre le masque des éléments
  gardés.

  Le filtre porte sur le groupe entier, non sur l'élément : un groupe
  passe ou ne passe pas, et tous ses éléments avec lui. C'est ce qui la
  distingue d'une simple indexation logique — écarter les catégories
  trop peu peuplées, garder celles dont la moyenne dépasse un seuil.

  Exemple :
     x = [1 2 3 40]';
     g = {'a'; 'a'; 'b'; 'b'};
     groupfilter(x, g, @(v) mean(v) > 10)'      % 3 40
     groupfilter(x, g, @(v) numel(v) >= 2)'     % tous : deux par groupe

  Voir aussi GROUPSUMMARY, GROUPTRANSFORM, FINDGROUPS.
```

## `groupsummary`

```
GROUPSUMMARY Résume un tableau groupe par groupe.
  R = GROUPSUMMARY(X,G) compte les éléments de chaque groupe défini par
  G. R = GROUPSUMMARY(X,G,METHODE) applique la méthode nommée à chaque
  groupe : 'sum', 'mean', 'median', 'min', 'max', 'std', 'var',
  'numel', 'nnz', 'all', 'any', ou une poignée de fonction.
  [R,G,ID] = GROUPSUMMARY(...) rend en outre les numéros de groupe et
  la valeur qui définit chacun.

  G peut être un tableau de classement — les valeurs distinctes forment
  les groupes — ou une cellule de plusieurs, qui se croisent.

  C'est FINDGROUPS suivi de SPLITAPPLY, réunis en un appel. La
  différence avec ACCUMARRAY est que les groupes n'ont pas à être des
  entiers consécutifs : n'importe quelle valeur les définit, texte
  compris.

  Exemple :
     x = [1 2 3 4];
     g = {'a', 'b', 'a', 'b'};
     groupsummary(x, g, 'sum')'          % 4 6
     groupsummary(x, g)'                 % 2 2 : les effectifs
     groupsummary(x, g, @max)'           % 3 4

  Voir aussi FINDGROUPS, SPLITAPPLY, ACCUMARRAY, GROUPTRANSFORM.
```

## `grouptransform`

```
GROUPTRANSFORM Transforme un tableau groupe par groupe.
  Y = GROUPTRANSFORM(X,G,METHODE) applique la méthode à chaque groupe et
  rend un tableau de la taille de X : chaque élément reçoit la valeur
  calculée sur son groupe. METHODE vaut 'zscore', 'norm', 'center',
  'meanfill', ou une poignée de fonction rendant autant de valeurs
  qu'elle en reçoit.

  C'est ce qui la sépare de GROUPSUMMARY : celle-ci réduit chaque groupe
  à une valeur, celle-là le transforme sans changer sa taille. Centrer
  par groupe, normaliser par groupe, combler les manquants par la
  moyenne du groupe : ce sont les trois usages, et ils demandent tous
  que la sortie garde la forme de l'entrée.

  Exemple :
     x = [1 3 10 20]';
     g = {'a'; 'a'; 'b'; 'b'};
     grouptransform(x, g, 'center')'     % -1 1 -5 5
     grouptransform(x, g, @(v) v / sum(v))'

  Voir aussi GROUPSUMMARY, GROUPFILTER, FINDGROUPS, SPLITAPPLY.
```

## `gtext`

```
GTEXT Pose un texte sur la figure.
  GTEXT(TEXTE) place le texte au milieu de l'axe courant.
  GTEXT(TEXTE,X,Y) le place aux coordonnées données.

  H = GTEXT(...) rend la poignée du texte.

  Dans MATLAB, GTEXT attend que l'on clique pour savoir où poser le
  texte. MatLibre n'a pas de curseur interactif sur ses figures : sans
  coordonnées, il pose le texte au centre, et il vaut mieux les lui
  donner — ou employer TEXT directement.

  Exemples :
     plot(1:10);
     gtext('la droite', 5, 5);

  Voir aussi TEXT, TITLE, XLABEL, ANNOTATION, GNAME.
```

## `hadamard`

```
HADAMARD Matrice de Hadamard.
  H = HADAMARD(N) rend une matrice N sur N de plus ou moins un dont les
  colonnes sont deux à deux orthogonales : H' H vaut N fois l'identité.

  Une telle matrice n'existe que pour N valant 1, 2, ou un multiple de
  quatre — et l'existence pour tout multiple de quatre reste une
  conjecture ouverte. La construction employée ici est celle de
  Sylvester : elle double la taille à chaque étape, si bien qu'elle ne
  donne que les puissances de deux, ainsi que 12 et 20 par les
  constructions de Paley qui les complètent.

  Les matrices de Hadamard servent partout où l'on veut des codes
  orthogonaux : étalement de spectre, plans d'expérience, transformée de
  Walsh-Hadamard. Leur intérêt tient à ce qu'elles n'emploient que des
  additions et des soustractions — aucune multiplication.

  La première ligne et la première colonne ne comptent que des uns :
  c'est la forme normalisée, que la construction de Sylvester donne
  d'elle-même.

  Exemple :
     H = hadamard(8);
     H' * H                          % 8 * eye(8)
     unique(H(:))                    % -1 et 1, rien d'autre

  Voir aussi FWHT, IFWHT, MAGIC, TOEPLITZ.
```

## `heatmap`

```
HEATMAP Carte de chaleur d'une matrice.
  HEATMAP(M) dessine la matrice M en couleurs, une case par élément, et
  écrit la valeur dans chaque case.

  HEATMAP(NOMSX,NOMSY,M) nomme les colonnes et les lignes.

  HEATMAP(...,'ColorbarVisible','off') n'affiche pas l'échelle de
  couleurs.
  HEATMAP(...,'CellLabelFormat',F) change le format des nombres écrits
  dans les cases ; '%.2f' par exemple. La chaîne vide n'écrit rien.

  H = HEATMAP(...) rend la poignée de l'image.

  C'est la façon de montrer une matrice de corrélation, une table de
  contingence, une matrice de confusion : l'œil y voit les blocs et les
  valeurs fortes bien avant de lire les nombres.

  Exemples :
     heatmap(magic(5));

     X = randn(100, 4);
     heatmap({'a','b','c','d'}, {'a','b','c','d'}, corr(X));

  Voir aussi IMAGESC, PCOLOR, COLORMAP, COLORBAR, CONFUSIONMAT, CORR.
```

## `hidden`

```
HIDDEN Élimination des parties cachées (acceptée, sans effet).
  HIDDEN ON cache, dans MATLAB, les lignes d'un maillage qui passent
  derrière la surface ; HIDDEN OFF les laisse voir ; HIDDEN sans
  argument bascule.

  Le rendu de MatLibre est plan : il n'y a pas de parties cachées, et
  l'appel ne change rien à l'image.

  Exemple :
     mesh(peaks(30)); hidden('off');

  Voir aussi MESH, SURF, SHADING, LIGHTING.
```

## `histcounts2`

```
HISTCOUNTS2 Comptage sur un quadrillage à deux dimensions.
  N = HISTCOUNTS2(X,Y) compte les couples (X,Y) tombant dans chaque
  case d'un quadrillage automatique. N(i,j) compte la case de la
  i-ième classe en X et de la j-ième en Y.

  N = HISTCOUNTS2(X,Y,NBINS) impose le nombre de classes : un scalaire
  pour les deux axes, ou [NX NY].
  N = HISTCOUNTS2(X,Y,BORDSX,BORDSY) impose les bords.

  [N,BORDSX,BORDSY] = HISTCOUNTS2(...) rend aussi les bords employés.

  Exemple :
     [n, bx, by] = histcounts2([1 2 3], [1 1 2], [0 2 4], [0 1.5 3]);

  Voir aussi HISTCOUNTS, HISTOGRAM2, ACCUMARRAY.
```

## `histogram2`

```
HISTOGRAM2 Histogramme à deux dimensions.
  HISTOGRAM2(X,Y) compte les couples (X,Y) par case d'un quadrillage
  et trace le résultat.

  HISTOGRAM2(X,Y,NBINS) impose le nombre de classes, HISTOGRAM2(X,Y,
  BORDSX,BORDSY) les bords.

  [N,BORDSX,BORDSY] = HISTOGRAM2(...) rend les effectifs et les bords.

  Le rendu de MatLibre est le quadrillage en couleurs — le
  'DisplayStyle','tile' de MATLAB — plutôt que les barres en
  perspective : sur une densité, les barres du fond se cachent entre
  elles.

  Exemple :
     x = randn(1, 500);  y = x + 0.5 * randn(1, 500);
     histogram2(x, y, [12 12]);

  Voir aussi HISTCOUNTS2, HISTOGRAM, IMAGESC, HEATMAP.
```

## `hot`

```
HOT Carte de couleurs noir - rouge - jaune - blanc.
  Les trois tiers de la rampe montent tour à tour le rouge, le vert
  puis le bleu : c'est la couleur d'un corps chauffé.

  Exemple :
     carte = hot(8);
     all(diff(sum(carte, 2)) > 0)    % la clarte croit d'un bout a l'autre

  Voir aussi COOL, JET, AUTUMN.
```

## `hsv`

```
HSV Carte de couleurs parcourant le cercle des teintes.
  La saturation et la valeur restent à 1 : seule la teinte tourne, du
  rouge au rouge en passant par tout le spectre.

  Exemple :
     carte = hsv(6);
     size(carte)                 % 6 3

  Voir aussi JET, PRISM.
```

## `humps`

```
HUMPS Fonction d'essai à deux pics, utilisée par les démonstrations.
  Y = HUMPS(X) évalue 1/((x-0.3)^2+0.01) + 1/((x-0.9)^2+0.04) - 6.

  Exemple :
     humps(0.3)                  % environ 96 : le sommet de la courbe
     fzero(@humps, [1 2]) > 1        % elle change de signe entre 1 et 2

  Voir aussi PEAKS.
```

## `ichol`

```
ICHOL Factorisation de Cholesky incomplète.
  L = ICHOL(A) rend une matrice triangulaire inférieure telle que L*L'
  approche A, en ne remplissant que les positions déjà non nulles de A.
  A doit être symétrique définie positive.
  L = ICHOL(A,OPTIONS) accepte les champs 'type' ('nofill' seul est
  traité), 'diagcomp' et 'shape'.

  Le mot « incomplète » désigne ce qu'on abandonne : la factorisation
  exacte crée des coefficients là où A n'en avait pas — le remplissage —
  et sur une grande matrice creuse ce remplissage est ce qui coûte tout.
  On l'interdit, et la factorisation n'est plus exacte : L*L' ne vaut
  plus A, seulement quelque chose de proche.

  Cette approximation ne sert pas à résoudre, elle sert à
  préconditionner : PCG appliqué à A avec le préconditionneur L*L'
  converge en bien moins d'itérations, parce que le conditionnement
  de L\A/L' est bien meilleur que celui de A.

  L'option 'diagcomp' ajoute ALPHA*DIAG(A) avant de factoriser. Elle
  sert quand la factorisation échoue sur une racine négative : décaler
  la diagonale rend la matrice plus dominante, donc factorisable.

  Exemple :
     n = 30;
     A = full(spdiags([-ones(n,1), 2*ones(n,1), -ones(n,1)], -1:1, n, n));
     L = ichol(A);
     istril(L)                                % 1 : elle est triangulaire
     b = ones(n, 1);
     [~, ~, ~, sans] = pcg(A, b, 1e-10, 200);
     [~, ~, ~, avec] = pcg(A, b, 1e-10, 200, L * L');
     avec <= sans                             % le preconditionneur aide

  Voir aussi ILU, CHOL, PCG, MLDIVIDE.
```

## `ilu`

```
ILU Factorisation LU incomplète.
  [L,U] = ILU(A) rend deux matrices triangulaires dont le produit
  approche A, en ne remplissant que les positions déjà non nulles de A.
  [L,U,P] = ILU(A) rend en outre la permutation, ici l'identité :
  l'option 'nofill' n'en emploie pas.
  [...] = ILU(A,OPTIONS) accepte le champ 'type' ('nofill').

  C'est le pendant non symétrique d'ICHOL, et il sert à la même chose :
  préconditionner une méthode de Krylov. Sans remplissage, L et U ont
  exactement le motif de A, donc le même coût mémoire — et c'est cela
  qu'on achète en renonçant à l'exactitude.

  La diagonale de L vaut un, celle de U porte les pivots. Un pivot nul
  arrête la factorisation : sans permutation, rien ne peut le sauver, et
  c'est la limite de la variante sans remplissage.

  Exemple :
     n = 20;
     A = full(spdiags([-ones(n,1), 4*ones(n,1), -ones(n,1)], -1:1, n, n));
     [L, U] = ilu(A);
     istril(L) && istriu(U)                   % 1
     max(max(abs(diag(L) - 1))) < 1e-12       % la diagonale de L vaut un
     norm(A - L * U) < norm(A)                % l'approximation est proche

  Voir aussi ICHOL, LU, GMRES, BICG, PCG.
```

## `imageDatastore`

```
IMAGEDATASTORE Lecture par morceaux d'une collection d'images.
  DS = IMAGEDATASTORE(CHEMIN) rassemble les images d'un dossier, d'une
  liste de fichiers ou d'un motif. READ rend l'image suivante, HASDATA
  dit s'il en reste, RESET revient au début, READALL les lit toutes.

  DS.Labels peut recevoir une étiquette par image — c'est ainsi qu'on
  décrit un jeu d'apprentissage, et COUNTEACHLABEL en compte les
  classes.

  Les formats lisibles sont ceux d'IMREAD : PGM et PPM en texte. Les
  autres demandent une bibliothèque externe, et IMREAD le dit.

  Le magasin se copie par référence : READ le fait avancer sans qu'on
  ait à le réaffecter.

  Exemple :
     dossier = tempname;
     mkdir(dossier);
     imwrite(uint8(magic(4) * 15), fullfile(dossier, 'a.pgm'));
     ds = imageDatastore(dossier);
     numel(ds.Files)                 % 1 image trouvee
     size(read(ds))                  % 4 par 4

  Voir aussi DATASTORE, TABULARTEXTDATASTORE, IMREAD, READ, READALL.
```

## `import`

```
IMPORT Importe un espace de noms.
  IMPORT ESPACE.* rendrait visibles sans préfixe les fonctions et les
  classes d'un espace de noms. L = IMPORT() rend la liste des
  importations en vigueur.

  MatLibre n'a pas d'espaces de noms : toutes les fonctions sont
  visibles par leur nom, et il n'y a donc jamais rien à importer. La
  liste est vide — ce qui est la réponse exacte, non une lacune — et
  demander une importation échoue au lieu de la passer sous silence,
  car un programme qui croit avoir importé appellerait ensuite un nom
  court que rien ne définit.

  Exemple :
     isempty(import())               % 1 : aucune importation

  Voir aussi WHICH, EXIST, PATH, CLASS.
```

## `importdata`

```
IMPORTDATA Charge un fichier sans dire de quel genre il est.
  A = IMPORTDATA(FICHIER) reconnaît le fichier à son extension :
     .mat            rend une structure des variables enregistrées ;
     image           rend la matrice des pixels ;
     texte délimité  rend les nombres, ou une structure quand le
                     fichier porte aussi du texte.

  A = IMPORTDATA(FICHIER,SEP) impose le séparateur, A =
  IMPORTDATA(FICHIER,SEP,N) le nombre de lignes d'en-tête.

  [A,SEP,N] = IMPORTDATA(...) rend en outre le séparateur reconnu et le
  nombre de lignes d'en-tête sautées.

  Quand le fichier porte un en-tête, A est une structure de champs
  « data », « textdata » et « colheaders », comme dans MATLAB.

  Exemple :
     f = fullfile(tempdir, 'essai.csv');
     writecell({'x','y'; 1, 2; 3, 4}, f);
     a = importdata(f);       % a.data, a.colheaders

  Voir aussi READMATRIX, READTABLE, READCELL, LOAD, IMREAD.
```

## `inner2outer`

```
INNER2OUTER Échange les niveaux d'une table de tables.
  T2 = INNER2OUTER(T1), où chaque variable de T1 est elle-même une
  table, rend une table dont les variables portent les noms
  intérieurs. T2.a.un vaut alors T1.un.a : la donnée ne bouge pas,
  seule la façon de la nommer change.

  C'est utile quand on a rangé des mesures par capteur alors qu'on veut
  les lire par grandeur, ou l'inverse. Appliquée deux fois de suite,
  l'opération redonne la table de départ lorsque toutes les tables
  intérieures ont les mêmes variables : c'est ce qui la définit.

  Quand une table intérieure n'a pas l'une des variables, la colonne
  correspondante ne figure simplement pas dans le résultat : il n'y a
  rien à y mettre, et inventer une valeur serait pire.

  Exemple :
     un = table([1; 2], [3; 4], 'VariableNames', {'a', 'b'});
     deux = table([5; 6], [7; 8], 'VariableNames', {'a', 'b'});
     T = table(un, deux, 'VariableNames', {'un', 'deux'});
     S = inner2outer(T);
     S.Properties.VariableNames         % {'a', 'b'}
     isequal(S.a.deux, T.deux.a)        % 1 : la donnee est la meme

  Voir aussi TABLE, SPLITVARS, MERGEVARS, ROWS2VARS, STACK.
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

  Voir aussi CONVHULL.
```

## `inputParser`

```
INPUTPARSER Contrôle des arguments d'une fonction.
  P = INPUTPARSER fabrique un analyseur. On lui déclare les arguments
  attendus, puis on lui donne ceux reçus ; il les range dans P.Results
  et refuse ce qui ne convient pas.

  Déclarations :
     addRequired(P,NOM,VALIDATEUR)        argument obligatoire
     addOptional(P,NOM,DEFAUT,VALIDATEUR) argument facultatif, par rang
     addParameter(P,NOM,DEFAUT,VALIDATEUR) paire nom-valeur
     addSwitch(P,NOM)                     drapeau, vrai s'il est là

  Analyse :
     parse(P,ARGS{:})
     P.Results        structure des valeurs retenues
     P.UsingDefaults  noms restés à leur valeur par défaut
     P.Unmatched      paires non déclarées, si KeepUnmatched est vrai

  Un validateur est une fonction qui rend faux ou lève une erreur quand
  la valeur ne convient pas — @isnumeric, @(x) x > 0.

  Exemple :
     p = inputParser;
     addRequired(p, 'x', @isnumeric);
     addParameter(p, 'Ordre', 2, @(v) v > 0);
     parse(p, 3, 'Ordre', 5);
     p.Results.Ordre        % 5

  Voir aussi VALIDATEATTRIBUTES, NARGINCHK, VARARGIN, PARSE.
```

## `inputdlg`

```
INPUTDLG Demande des valeurs à l'utilisateur.
  R = INPUTDLG(INVITES) pose une question par invite et rend les
  réponses dans un tableau de cellules de chaînes. Une réponse vide
  garde la valeur par défaut ; une interruption rend un tableau vide,
  comme le bouton Annuler de MATLAB.

  R = INPUTDLG(INVITES,TITRE,LIGNES,DEFAUTS) donne un titre, un nombre
  de lignes par réponse — sans effet ici — et les valeurs proposées.

  MatLibre pose les questions dans la console plutôt que dans une
  fenêtre : l'interpréteur n'a pas de boucle d'événements modale, et
  une fausse fenêtre qui rendrait la main aussitôt tromperait le
  programme qui attend la réponse.

  Exemple :
     r = inputdlg({'Nom', 'Âge'}, 'Fiche', 1, {'', '30'});

  Voir aussi INPUT, LISTDLG, UIEDITFIELD, KEYBOARD.
```

## `invhilb`

```
INVHILB Inverse exacte de la matrice de Hilbert.
  H = INVHILB(N) rend l'inverse de HILB(N), calculée par sa formule
  fermée en coefficients binomiaux plutôt que par inversion numérique.

  La matrice de Hilbert est le cas d'école du mauvais
  conditionnement : son nombre de conditionnement croît comme e^(3,5 N),
  si bien qu'à N = 13 l'inversion numérique n'a plus un seul chiffre
  juste. La formule fermée, elle, reste exacte tant que les entiers
  qu'elle produit tiennent dans un double — jusqu'à N = 13 environ.

  Tous ses termes sont des entiers, alternés en signe. C'est ce qui
  permet de mesurer l'erreur d'un solveur : la vraie réponse est connue.

  Exemple :
     norm(invhilb(6) * hilb(6) - eye(6))     % petit
     max(max(abs(invhilb(5) - round(invhilb(5)))))   % 0 : des entiers
     cond(hilb(12))                          % plus de 1e16

  Voir aussi HILB, PASCAL, COND.
```

## `isIllConditioned`

```
ISILLCONDITIONED La factorisation a-t-elle rencontré un pivot minuscule.
  TF = ISILLCONDITIONED(D) dit si la factorisation gardée par D a
  rencontré un pivot négligeable devant la norme de la matrice.

  C'est la seule information que la substitution ne peut plus retrouver :
  une fois la factorisation faite, le mauvais conditionnement ne se voit
  plus dans le résultat, il se voit dans les pivots. La retenir est
  l'intérêt de l'objet.

  Exemple :
     isIllConditioned(decomposition([4 1; 1 3]))       % 0
     isIllConditioned(decomposition(hilb(12), 'lu'))   % 1

  Voir aussi DECOMPOSITION, COND, CONDEST, RCOND.
```

## `ischange`

```
ISCHANGE Repère les ruptures dans une série.
  TF = ISCHANGE(A) marque les points où la moyenne change brusquement.
  TF = ISCHANGE(A,'linear') cherche les ruptures de pente : chaque
  segment est ajusté par une droite au lieu d'une constante.
  TF = ISCHANGE(A,'variance') cherche les ruptures de dispersion.

  TF = ISCHANGE(...,'MaxNumChanges',K) impose au plus K ruptures.
  TF = ISCHANGE(...,'Threshold',T) fixe la pénalité : une rupture n'est
  retenue que si elle fait gagner plus de T sur le coût. Par défaut la
  pénalité vaut 3*sigma^2*log(N) — la forme du critère de Schwarz, avec
  les trois paramètres qu'ajoute une rupture : sa position et les deux
  moyennes de part et d'autre —, où
  sigma est estimé sur les différences successives — 1,4826 fois leur
  écart absolu médian, divisé par racine de deux. Cet estimateur ne voit
  pas les marches, puisqu'une marche ne touche qu'une seule différence,
  et c'est ce qui l'empêche de confondre le saut avec le bruit.

  [TF,S1,S2] = ISCHANGE(...) rend en outre, pour chaque point, les
  paramètres du segment auquel il appartient : la moyenne dans S1 et
  zéro dans S2 en mode 'mean', l'ordonnée à l'origine et la pente en
  mode 'linear'.

  Le découpage est optimal, non glouton : une programmation dynamique
  parcourt tous les découpages possibles et retient celui de moindre
  coût. C'est ce qui la distingue d'un seuillage sur la dérivée, qui
  voit une rupture partout où le bruit est fort et nulle part où la
  marche est lente.

  Le coût d'un segment est la somme des carrés des écarts au modèle. La
  pénalité empêche la solution triviale — une rupture par point, de coût
  nul — et c'est elle, et non le calcul, qui décide du nombre de
  ruptures trouvées.

  Exemple :
     x = [ones(1, 20), 5 * ones(1, 20)];
     find(ischange(x))                   % 21 : la marche
     x = [1:20, 20:-1:1];
     find(ischange(x, 'linear'))         % le sommet du toit

  Voir aussi ISLOCALMAX, ISOUTLIER, FINDCHANGEPTS, MOVMEAN.
```

## `isgraphics`

```
ISGRAPHICS Dit si une valeur est un objet graphique, d'un type donné.
  T = ISGRAPHICS(H) rend vrai pour chaque élément de H qui désigne un
  objet graphique existant. ISGRAPHICS(H,TYPE) exige en plus que son
  type soit TYPE — 'figure', 'axes', 'line', 'text'.

  Elle diffère d'ISHANDLE en ce qu'elle sait dire de quel type est
  l'objet : ISHANDLE répond seulement s'il existe encore.

  Exemple :
     figure;
     isgraphics(gca)                 % 1
     isgraphics(gca, 'axes')         % 1
     isgraphics(gca, 'figure')       % 0 : c'est un axe

  Voir aussi ISHANDLE, GCA, GCF, CLASS.
```

## `ishandle`

```
ISHANDLE Dit si une valeur est une poignée graphique encore valide.
  T = ISHANDLE(H) rend vrai pour chaque élément de H qui désigne un
  objet graphique existant. Une poignée dont l'objet a été supprimé
  rend faux : c'est tout l'intérêt de la question.

  Exemple :
     f = figure;
     ishandle(gca)                   % 1
     close(f);
     ishandle(42)                    % 0 : aucun objet de ce numero

  Voir aussi ISGRAPHICS, GCA, GCF, DELETE.
```

## `isjava`

```
ISJAVA Dit si une valeur est un objet Java.
  T = ISJAVA(A) rend vrai si A est un objet Java. MatLibre n'embarque
  pas de machine virtuelle : aucune valeur n'en est un, et la réponse
  est donc toujours faux.

  Exemple :
     isjava(42)                      % 0
     isjava('texte')                 % 0

  Voir aussi USEJAVA, ISOBJECT, CLASS, ISA.
```

## `iskeyword`

```
ISKEYWORD Mot réservé du langage ?
  ISKEYWORD rend la liste des mots réservés.
  ISKEYWORD(NOM) dit si NOM en fait partie.

  Exemple :
     iskeyword('for')            % 1
     iskeyword('toto')           % 0
     numel(iskeyword()) > 10     % la liste des mots reserves

  Voir aussi GENVARNAME.
```

## `islocalmax`

```
ISLOCALMAX Repère les maxima locaux d'un vecteur.
  M = ISLOCALMAX(A) rend un tableau logique de la taille de A, vrai aux
  maxima locaux : les points strictement plus grands que leurs deux
  voisins. Les extrémités ne sont jamais des maxima locaux, faute d'un
  voisin de chaque côté.

  M = ISLOCALMAX(A,'MinProminence',P) n'en garde que ceux dont la
  proéminence atteint P. La proéminence d'un sommet est sa hauteur
  au-dessus du col le plus haut qui le sépare d'un sommet plus élevé :
  c'est ce qui distingue un vrai pic d'une ondulation posée sur un
  flanc, et c'est la seule mesure qui ne dépende pas de l'échelle
  verticale choisie.

  M = ISLOCALMAX(A,'MinSeparation',S) impose une distance minimale entre
  deux maxima retenus ; le plus proéminent l'emporte.
  M = ISLOCALMAX(A,'MaxNumExtrema',N) n'en garde que les N plus
  proéminents.

  [M,P] = ISLOCALMAX(...) rend en outre la proéminence de chaque point,
  nulle là où il n'y a pas de maximum local.

  Un plateau ne compte que pour un maximum, placé sur son premier point :
  sans cette règle, un signal quantifié en produirait autant que le
  plateau a d'échantillons.

  Exemple :
     islocalmax([1 3 2 5 4])             % [0 1 0 1 0]
     islocalmax([1 3 2 5 4], 'MinProminence', 2)
     [m, p] = islocalmax([0 1 0 5 0]);
     p(4)                                % 5 : le grand pic dominate

  Voir aussi ISLOCALMIN, FINDPEAKS, ISCHANGE, MAX.
```

## `islocalmin`

```
ISLOCALMIN Repère les minima locaux d'un vecteur.
  M = ISLOCALMIN(A) rend un tableau logique vrai aux minima locaux :
  les points strictement plus petits que leurs deux voisins.

  Les options sont celles d'ISLOCALMAX — 'MinProminence',
  'MinSeparation' et 'MaxNumExtrema' — appliquées au signal retourné :
  un minimum de A est un maximum de -A, et il n'y a pas d'autre
  différence entre les deux fonctions.

  [M,P] = ISLOCALMIN(...) rend en outre la proéminence, comptée vers le
  bas.

  Exemple :
     islocalmin([3 1 2 0 4])             % [0 1 0 1 0]
     islocalmin([3 1 2 0 4], 'MinProminence', 2)

  Voir aussi ISLOCALMAX, FINDPEAKS, ISCHANGE, MIN.
```

## `ismembertol`

```
ISMEMBERTOL Appartenance à un ensemble, à une tolérance près.
  TF = ISMEMBERTOL(A,S) rend, pour chaque élément de A, vrai s'il existe
  dans S un élément dont il s'écarte de moins de 1e-6 fois l'échelle des
  données. TF = ISMEMBERTOL(A,S,TOL) impose la tolérance.

  L'échelle est le plus grand module rencontré dans A et dans S, borné
  par en dessous à un : la tolérance est donc relative, et une même
  valeur de TOL a le même sens sur des données en mètres et sur les
  mêmes en kilomètres.

  C'est ISMEMBER rendu utilisable sur des flottants. 0.1+0.2 n'est pas
  0.3 en binaire, et l'égalité exacte répond non là où toute autre
  considération dit oui. La contrepartie est que la relation
  « proche à TOL près » n'est pas transitive : elle ne partage pas les
  données en classes, et le résultat peut dépendre de l'ordre de S.

  Exemple :
     ismembertol(0.1 + 0.2, [0.3 0.5])

  Voir aussi ISMEMBER, UNIQUETOL, EPS.
```

## `ismissing`

```
ISMISSING Repère les valeurs manquantes.
  TF = ISMISSING(A) rend un tableau de booléens marquant les valeurs
  absentes : NaN pour un nombre, '' pour une cellule de texte, la
  chaîne vide pour un tableau de chaînes, <undefined> pour une
  catégorie, NaT pour une date.

  Une différence avec MATLAB, qui se voit sur les chaînes : MATLAB
  distingue la chaîne vide "" — qui n'est pas manquante — de la chaîne
  manquante <missing>, qui l'est. MatLibre n'a pas de chaîne manquante
  distincte de la chaîne vide, et traite donc "" comme absente. Sur des
  données où la chaîne vide est une valeur légitime, il faut employer
  ISMISSING(A,IND) avec un indicateur propre.

  TF = ISMISSING(A,IND) traite en outre comme manquantes les valeurs
  énumérées dans IND.

  Pour une table, TF a une colonne par variable.

  Exemple :
     ismissing([1 NaN 3])          % [false true false]
     ismissing([1 2 -99], -99)     % [false false true]

  Voir aussi RMMISSING, STANDARDIZEMISSING, ISNAN, ISNAT.
```

## `isoutlier`

```
ISOUTLIER Repère les valeurs aberrantes.
  M = ISOUTLIER(A) marque les éléments qui s'écartent de plus de trois
  écarts absolus médians de la médiane.
  M = ISOUTLIER(A,METHODE) choisit le critère :
     'median'    trois écarts absolus médians (défaut)
     'mean'      trois écarts types autour de la moyenne
     'quartiles' hors de [Q1 - 1.5 IQR, Q3 + 1.5 IQR]
     'grubbs'    test de Grubbs, une valeur à la fois
     'percentiles' hors des centiles donnés en troisième argument
  M = ISOUTLIER(A,METHODE,'ThresholdFactor',F) règle le facteur.

  [M,BAS,HAUT,CENTRE] = ISOUTLIER(...) rend en outre les deux seuils et
  le centre employés.

  Le critère par défaut n'emploie ni la moyenne ni l'écart type : une
  seule valeur très éloignée les déplace tous les deux, si bien qu'elle
  se cache elle-même. La médiane et l'écart absolu médian, eux, ne
  bougent pas — c'est ce qu'on appelle un estimateur robuste, et c'est
  la seule raison de les préférer ici.

  Le facteur 1.4826 qui apparaît dans l'écart absolu médian n'est pas
  arbitraire : c'est celui qui le rend égal à l'écart type quand les
  données sont gaussiennes.

  Exemple :
     isoutlier([1 2 3 4 100])        % [0 0 0 0 1]
     isoutlier([1 2 3 4 100], 'mean')

  Voir aussi FILLOUTLIERS, RMOUTLIERS, ISMISSING, MEDIAN.
```

## `issorted`

```
ISSORTED Vrai si le tableau est trié.
  TF = ISSORTED(A) est vrai si A est trié par ordre croissant.
  ISSORTED(A,SENS) teste 'ascend', 'descend', 'monotonic',
  'strictascend', 'strictdescend' ou 'strictmonotonic'.
  ISSORTED(A,'rows') teste les lignes d'une matrice ; voir ISSORTEDROWS.

  Ce qui s'ordonne se teste, même sans passer par des nombres : dates,
  durées, catégories ordonnées et textes se comparent directement.

  Exemples :
     issorted([1 2 2 5])                  % true
     issorted([1 2 2 5], 'strictascend')  % false
     issorted([datetime(2024,1,1) datetime(2024,3,1)])   % true

  Voir aussi SORT, ISSORTEDROWS, SORTROWS.
```

## `issortedrows`

```
ISSORTEDROWS Vrai si les lignes sont triées.
  TF = ISSORTEDROWS(A) est vrai si les lignes de A sont classées par
  ordre croissant, la première colonne d'abord.
  ISSORTEDROWS(A,COL) ne regarde que les colonnes COL, dans l'ordre
  donné ; une colonne négative se lit en ordre décroissant.
  ISSORTEDROWS(A,COL,SENS) impose 'ascend' ou 'descend'.

  Exemple :
     issortedrows([1 2; 1 3; 2 0])   % true

  Voir aussi SORTROWS, ISSORTED.
```

## `isstrprop`

```
ISSTRPROP Nature de chaque caractère d'un texte.
  M = ISSTRPROP(TEXTE,PROPRIETE) rend un tableau logique de la taille du
  texte, vrai là où le caractère a la propriété demandée.

  Propriétés reconnues : 'alpha', 'alphanum', 'digit', 'xdigit',
  'lower', 'upper', 'punct', 'wspace', 'cntrl', 'graphic', 'print'.

  TEXTE peut être un tableau de caractères, un tableau de cellules de
  chaînes — le résultat est alors une cellule de masques — ou un
  tableau de nombres, lus comme des codes de caractères.

  Exemple :
     isstrprop('a1 ', 'digit')      % 0 1 0

  Voir aussi ISLETTER, ISSPACE, REGEXP.
```

## `istall`

```
ISTALL Dit si une valeur est un tableau différé.
  T = ISTALL(X) rend vrai si X est un tableau dont le calcul est
  différé, celui que rend TALL.

  Exemple :
     istall(tall([1 2 3]))           % 1
     istall([1 2 3])                 % 0
     istall(gather(tall(7)))         % 0 : rassemblé, il est ordinaire

  Voir aussi TALL, GATHER.
```

## `javaArray`

```
JAVAARRAY Crée un tableau Java.
  JAVAARRAY(CLASSE,DIMS...) construirait un tableau Java.

  MatLibre n'embarque pas de machine virtuelle Java : l'appel échoue
  avec l'identifiant « MATLAB:Java:NoJVM ». Échouer clairement vaut
  mieux que rendre un objet factice, dont la première méthode appelée
  trahirait l'illusion loin de sa cause.

  Exemple :
     try, javaArray('java.lang.String'); catch e, disp(e.identifier); end

  Voir aussi USEJAVA, ISJAVA, JAVACLASSPATH.
```

## `javaMethod`

```
JAVAMETHOD Appelle une méthode Java.
  JAVAMETHOD(NOM,OBJET,ARGS...) appellerait une méthode dun objet Java.

  MatLibre n'embarque pas de machine virtuelle Java : l'appel échoue
  avec l'identifiant « MATLAB:Java:NoJVM ». Échouer clairement vaut
  mieux que rendre un objet factice, dont la première méthode appelée
  trahirait l'illusion loin de sa cause.

  Exemple :
     try, javaMethod('java.lang.String'); catch e, disp(e.identifier); end

  Voir aussi USEJAVA, ISJAVA, JAVACLASSPATH.
```

## `javaMethodEDT`

```
JAVAMETHODEDT Appelle une méthode Java sur le fil graphique.
  JAVAMETHODEDT(NOM,OBJET,ARGS...) appellerait une méthode sur le fil de distribution des événements.

  MatLibre n'embarque pas de machine virtuelle Java : l'appel échoue
  avec l'identifiant « MATLAB:Java:NoJVM ». Échouer clairement vaut
  mieux que rendre un objet factice, dont la première méthode appelée
  trahirait l'illusion loin de sa cause.

  Exemple :
     try, javaMethodEDT('java.lang.String'); catch e, disp(e.identifier); end

  Voir aussi USEJAVA, ISJAVA, JAVACLASSPATH.
```

## `javaObject`

```
JAVAOBJECT Crée un objet Java.
  JAVAOBJECT(CLASSE,ARGS...) construirait un objet de la classe donnée.

  MatLibre n'embarque pas de machine virtuelle Java : l'appel échoue
  avec l'identifiant « MATLAB:Java:NoJVM ». Échouer clairement vaut
  mieux que rendre un objet factice, dont la première méthode appelée
  trahirait l'illusion loin de sa cause.

  Exemple :
     try, javaObject('java.lang.String'); catch e, disp(e.identifier); end

  Voir aussi USEJAVA, ISJAVA, JAVACLASSPATH.
```

## `javaObjectEDT`

```
JAVAOBJECTEDT Crée un objet Java sur le fil graphique.
  JAVAOBJECTEDT(CLASSE,ARGS...) construirait un objet sur le fil de distribution des événements.

  MatLibre n'embarque pas de machine virtuelle Java : l'appel échoue
  avec l'identifiant « MATLAB:Java:NoJVM ». Échouer clairement vaut
  mieux que rendre un objet factice, dont la première méthode appelée
  trahirait l'illusion loin de sa cause.

  Exemple :
     try, javaObjectEDT('java.lang.String'); catch e, disp(e.identifier); end

  Voir aussi USEJAVA, ISJAVA, JAVACLASSPATH.
```

## `javaaddpath`

```
JAVAADDPATH Ajoute au chemin de classes Java.
  JAVAADDPATH(CHEMIN) ajouterait CHEMIN au chemin de classes. MatLibre
  n'embarque pas de machine virtuelle Java : l'appel échoue au lieu de
  faire croire que la classe sera trouvée plus tard.

  Exemple :
     try, javaaddpath('/tmp/x.jar'); catch e, disp(e.identifier); end

  Voir aussi JAVACLASSPATH, USEJAVA, JAVAOBJECT.
```

## `javaclasspath`

```
JAVACLASSPATH Chemin de classes Java.
  C = JAVACLASSPATH() rend, dans une cellule, le chemin de classes
  dynamique. MatLibre n'embarque pas de machine virtuelle Java : le
  chemin est donc toujours vide.

  C'est la réponse exacte, et non une approximation : un chemin vide
  décrit fidèlement un interpréteur sans Java, et un programme qui
  parcourt le résultat n'a rien de particulier à prévoir.

  Exemple :
     isempty(javaclasspath())        % 1 : aucune classe Java

  Voir aussi USEJAVA, JAVAADDPATH, JAVAOBJECT.
```

## `javarmpath`

```
JAVARMPATH Retire du chemin de classes Java.
  JAVARMPATH(CHEMIN) retirerait CHEMIN du chemin de classes. MatLibre
  n'embarque pas de machine virtuelle Java : l'appel échoue.

  Exemple :
     try, javarmpath('/tmp/x.jar'); catch e, disp(e.identifier); end

  Voir aussi JAVACLASSPATH, JAVAADDPATH, USEJAVA.
```

## `jet`

```
JET Carte de couleurs bleu - cyan - jaune - rouge.
  Construite par interpolation linéaire entre les six teintes qui la
  définissent : bleu foncé, bleu, cyan, jaune, rouge, rouge foncé.

  Exemple :
     c = jet(64);   % c(1,:) vaut [0 0 0.5], c(end,:) vaut [0.5 0 0]

  Voir aussi HSV, HOT.
```

## `join`

```
JOIN Réunit des éléments de texte en une seule chaîne.
  S = JOIN(TEXTE) réunit les éléments de TEXTE — un tableau de chaînes
  ou une cellule de textes — en les séparant par une espace.
  S = JOIN(TEXTE,SEPARATEUR) emploie le séparateur donné.
  S = JOIN(TEXTE,SEPARATEUR,DIM) réunit suivant la dimension DIM.

  La réunion se fait suivant la dernière dimension non singleton : un
  vecteur donne une chaîne unique, une matrice donne une colonne de
  chaînes, une par ligne.

  Le séparateur peut être unique, ou en compter un de moins que les
  éléments à réunir — un séparateur différent entre chaque paire.

  JOIN est l'inverse de SPLIT : réunir puis découper avec le même
  séparateur rend le tableau de départ, tant que le séparateur
  n'apparaît pas dans les éléments.

  Sur des tables, JOIN désigne tout autre chose — la jointure de deux
  tables par une clé — et c'est la méthode de la classe qui s'applique.

  Exemple :
     join(["a" "b" "c"])                 % "a b c"
     join(["a"; "b"], "-")               % "a-b"
     join(["x" "y"; "z" "w"], ", ")      % ["x, y"; "z, w"]
     split(join(["a" "b" "c"], "-"), "-")

  Voir aussi SPLIT, STRJOIN, STRSPLIT, PLUS.
```

## `jsondecode`

```
JSONDECODE Lit du JSON et rend la valeur MATLAB correspondante.
  V = JSONDECODE(TEXTE) traduit un document JSON :
     un objet        devient une structure ;
     un tableau      devient une matrice colonne s'il ne porte que des
                     nombres de même forme, un tableau de cellules
                     sinon ;
     une chaîne      devient du texte ;
     true, false     deviennent des booléens ;
     null            devient [].

  Les noms de champs qui ne sont pas des noms de variables valides sont
  corrigés comme le fait MATLAB, par GENVARNAME.

  Exemple :
     s = jsondecode('{"nom":"a","valeurs":[1,2,3]}');
     s.valeurs(2)      % 2

  Voir aussi JSONENCODE, WEBREAD, READSTRUCT.
```

## `jsonencode`

```
JSONENCODE Écrit une valeur MATLAB en JSON.
  T = JSONENCODE(V) rend le texte JSON de V : une structure devient un
  objet, un tableau de cellules un tableau, une matrice un tableau de
  tableaux, du texte une chaîne, [] la valeur null.

  JSONENCODE(V,'PrettyPrint',true) met en forme sur plusieurs lignes.

  Exemple :
     jsonencode(struct('a', 1, 'b', 'deux'))

  Voir aussi JSONDECODE, WEBWRITE.
```

## `light`

```
LIGHT Source de lumière (acceptée, sans effet).
  LIGHT crée une source de lumière dans l'axe courant.
  LIGHT('Position',[X Y Z]) la place ; 'Color' et 'Style' règlent sa
  couleur et son genre — 'infinite' pour une source à l'infini, 'local'
  pour une source ponctuelle.

  Le rendu de MatLibre est plan et ne calcule pas d'éclairage. LIGHT
  est acceptée pour qu'un programme écrit pour MATLAB tourne sans
  retouche ; elle ne change rien à l'image. LIGHTING et MATERIAL sont
  dans le même cas.

  Ce qui manque est documenté dans documentation/manques.md, au
  chapitre du rendu tridimensionnel.

  Exemple :
     surf(peaks(30));
     light('Position', [1 1 1]);       % accepte, sans effet

  Voir aussi LIGHTING, MATERIAL, SURFL, SURF, SHADING.
```

## `lighting`

```
LIGHTING Modèle d'éclairage (accepté, sans effet).
  LIGHTING FLAT, LIGHTING GOURAUD et LIGHTING NONE choisissent, dans
  MATLAB, comment la lumière est répartie sur une surface.

  Le rendu de MatLibre est plan et ne calcule pas d'éclairage :
  l'appel est accepté pour qu'un programme tourne sans retouche, et
  ne change rien à l'image.

  Exemple :
     surf(peaks(30)); lighting('gouraud');

  Voir aussi LIGHT, MATERIAL, SHADING, SURFL.
```

## `lsqminnorm`

```
LSQMINNORM Solution de moindre norme au sens des moindres carrés.
  X = LSQMINNORM(A,B) rend, parmi toutes les solutions qui minimisent
  NORM(A*X-B), celle de plus petite norme. X = LSQMINNORM(A,B,TOL)
  impose le seuil sous lequel une valeur singulière est tenue pour nulle.

  Quand A est de rang plein en colonnes, il n'y a qu'une solution et
  LSQMINNORM rend la même chose que l'antislash. La différence apparaît
  quand A est déficiente : l'antislash rend alors une solution à
  coefficients épars, obtenue par la décomposition QR, tandis que
  LSQMINNORM rend celle de norme minimale, qui est unique. La première
  met des zéros là où la seconde répartit.

  Aucune des deux n'est meilleure en soi. La solution de moindre norme
  est la seule continue en A : une perturbation infime des données ne la
  déplace que d'autant, alors qu'elle peut faire sauter la solution
  éparse d'un jeu de colonnes à un autre.

  Le seuil par défaut est max(size(A))*eps(norm(A)) : c'est celui qui
  sépare les valeurs singulières nulles de celles que l'arrondi a
  simplement rendues petites.

  Exemple :
     A = [1 1; 1 1];
     b = [2; 2];
     x = lsqminnorm(A, b);              % [1; 1], de norme minimale
     norm(A * x - b) < 1e-12
     norm(x) <= norm(A \ b) + 1e-12     % jamais plus grande

  Voir aussi PINV, MLDIVIDE, RANK, SVD.
```

## `material`

```
MATERIAL Propriétés de réflexion d'une surface (acceptées, sans effet).
  MATERIAL SHINY, MATERIAL DULL, MATERIAL METAL et MATERIAL DEFAULT
  règlent, dans MATLAB, la façon dont une surface renvoie la lumière.

  Le rendu de MatLibre est plan et ne calcule pas d'éclairage :
  l'appel est accepté et ne change rien à l'image.

  Exemple :
     surf(peaks(30)); material('dull');

  Voir aussi LIGHT, LIGHTING, SHADING, SURFL.
```

## `matfile`

```
MATFILE Accès à un fichier .mat sans tout charger.
  M = MATFILE(F) ouvre le fichier F et rend un objet dont chaque
  propriété est une variable du fichier : M.x lit la variable x, et
  M.x = 3 l'écrit sans toucher aux autres.

  M = MATFILE(F,'Writable',true) autorise l'écriture ; par défaut,
  comme dans MATLAB, un fichier existant s'ouvre en lecture seule et
  un fichier absent s'ouvre en écriture.

  MatLibre relit le fichier à chaque accès plutôt que d'en indexer le
  contenu : la syntaxe est celle de MATLAB, la lecture partielle
  d'une grande matrice — M.x(1:10,:) — coûte la lecture entière.

  Exemple :
     f = fullfile(tempdir, 'essai.mat');
     m = matfile(f, 'Writable', true);
     m.x = magic(4);
     m.x(1,:)

  Voir aussi LOAD, SAVE, WHOS, WHO.
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

  Voir aussi MATLAB.ADDONS.TOOLBOX.INSTALLTOOLBOX,
  MATLAB.ADDONS.TOOLBOX.UNINSTALLTOOLBOX.
```

## `matlab.addons.toolbox.installToolbox`

```
MATLAB.ADDONS.TOOLBOX.INSTALLTOOLBOX Installe une toolbox.
  ID = ...INSTALLTOOLBOX(DOSSIER) copie le dossier donné dans la racine
  des toolboxes et l'ajoute au chemin de recherche. Le dossier doit
  contenir un fichier Contents.m, comme toute toolbox MATLAB.

  Exemple :
     % Une toolbox est un dossier qui porte un Contents.m. On la
     % desinstalle aussitot : installer, c'est copier dans l'arborescence
     % des toolboxes, et un essai n'a pas a y laisser de trace.
     dossier = tempname();
     mkdir(dossier);
     f = fopen(fullfile(dossier, 'Contents.m'), 'w');
     fprintf(f, '%% Ma toolbox\n');
     fclose(f);
     identifiant = matlab.addons.toolbox.installToolbox(dossier);
     matlab.addons.toolbox.uninstallToolbox(identifiant);

  Voir aussi MATLAB.ADDONS.TOOLBOX.UNINSTALLTOOLBOX,
  MATLAB.ADDONS.TOOLBOX.PACKAGETOOLBOX.
```

## `matlab.addons.toolbox.packageToolbox`

```
MATLAB.ADDONS.TOOLBOX.PACKAGETOOLBOX Empaquette une toolbox.
  F = ...PACKAGETOOLBOX(DOSSIER,NOM) fabrique une archive du dossier.
  MATLAB produit un .mltbx ; ici c'est une archive ZIP, lisible partout
  et réinstallable par installToolbox après décompression.

  Exemple :
     dossier = tempname();
     mkdir(dossier);
     f = fopen(fullfile(dossier, 'Contents.m'), 'w');
     fprintf(f, '%% Ma toolbox\n');
     fclose(f);
     fichier = matlab.addons.toolbox.packageToolbox(dossier, 'ma.zip');
     isfile(fichier)             % 1

  Voir aussi MATLAB.ADDONS.TOOLBOX.INSTALLTOOLBOX, ZIP.
```

## `matlab.addons.toolbox.uninstallToolbox`

```
MATLAB.ADDONS.TOOLBOX.UNINSTALLTOOLBOX Retire une toolbox installée.
  ...UNINSTALLTOOLBOX(ID) efface le dossier et le retire du chemin.

  Exemple :
     % Desinstaller ce qui n'est pas installe ne fait rien de mal.
     try
         matlab.addons.toolbox.uninstallToolbox('inconnue');
     catch
     end

  Voir aussi MATLAB.ADDONS.TOOLBOX.INSTALLTOOLBOX.
```

## `matlabroot`

```
MATLABROOT Racine de l'installation de MatLibre.
  C'est le dossier qui contient les toolboxes.

  Exemple :
     isfolder(matlabroot())      % 1 : la racine existe

  Voir aussi PATH, WHICH, EXIST.
```

## `matlibre_aberrantes`

_Pas de bloc d'aide._

## `matlibre_arguments_barres`

```
MATLIBRE_ARGUMENTS_BARRES Décode les arguments de BARH et de PARETO.
  Fonction interne : elle n'existe pas dans MATLAB. Elle applique la
  règle de BAR — Y seul, ou X et Y, puis une largeur, puis un style —
  pour que les diagrammes en barres de MatLibre s'accordent tous.
```

## `matlibre_aspect_geographique`

```
MATLIBRE_ASPECT_GEOGRAPHIQUE Corrige le rapport d'aspect d'une carte plane.
  Un degré de longitude vaut cos(latitude) degré de latitude en
  distance : sans cette correction, une trajectoire paraît étirée dès
  qu'on quitte l'équateur, et d'autant plus qu'on s'en éloigne.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure();
     plot([2 5], [48 43]);
     matlibre_aspect_geographique([48 43]);
     close all;

  Voir aussi GEOPLOT, GEOSCATTER, DASPECT.
```

## `matlibre_bary_poids`

```
MATLIBRE_BARY_POIDS Coordonnées barycentriques d'un point dans un triangle.
  Les trois poids somment à un et sont tous positifs précisément quand
  le point est dans le triangle, bord compris. C'est le test
  d'appartenance le plus sûr : il ne dépend pas de l'orientation.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     p = matlibre_bary_poids([0 0; 1 0; 0 1], [0.25 0.25]);
     abs(sum(p) - 1) < 1e-12

  Voir aussi DELAUNAYTRIANGULATION, TRIANGULATION, INPOLYGON.
```

## `matlibre_barycentriques`

```
MATLIBRE_BARYCENTRIQUES Coordonnées barycentriques dans un triangle.
  P = MATLIBRE_BARYCENTRIQUES(XS,YS,X,Y) rend les trois poids qui
  écrivent le point comme moyenne des sommets. Ils somment à un ; ils
  sont tous positifs exactement quand le point est dans le triangle.

  Un triangle dégénéré — trois sommets alignés — n'en a pas : le
  résultat est alors vide.

  Exemple :
     matlibre_barycentriques([0 1 0], [0 0 1], 0.25, 0.25)      % 0.5 0.25 0.25

  Voir aussi MATLIBRE_GRILLE_LINEAIRE, GRIDDATA.
```

## `matlibre_cases`

_Pas de bloc d'aide._

## `matlibre_chainer_aretes`

```
MATLIBRE_CHAINER_ARETES Chaîne les arêtes de bord en un contour fermé.
  On part de la première arête et l'on suit : à chaque pas, l'arête
  restante qui touche le point courant donne le point suivant. Le
  contour est rendu premier point répété à la fin.

  Les arêtes sont traitées comme non orientées. C'est nécessaire : les
  triangles d'une triangulation ne tournent pas tous dans le même sens,
  donc l'arête de bord peut être rangée dans un sens ou dans l'autre, et
  suivre l'orientation ferait s'arrêter le contour au premier
  changement.

  Si le bord a plusieurs composantes — un nuage en deux amas —, seule
  celle qui part de la première arête est rendue.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     k = matlibre_chainer_aretes([1 2; 3 2; 3 1]);
     isequal(k([1 end]), [1; 1])     % le contour se referme
     numel(k)                        % 4 : trois sommets et le retour

  Voir aussi BOUNDARY, ALPHASHAPE, FREEBOUNDARY.
```

## `matlibre_clip_booleen`

```
MATLIBRE_CLIP_BOOLEEN Réunion, intersection ou différence de polygones.
  Les deux entrées sont des cellules de contours, chacun une matrice à
  deux colonnes. L'opération vaut 'union', 'intersection' ou
  'difference'.

  L'algorithme est celui de Greiner et Hormann. On calcule d'abord
  toutes les intersections des arêtes des deux polygones, et on les
  insère dans les deux contours à leur place le long de l'arête. Chaque
  intersection est alors marquée « entrante » ou « sortante » selon que
  le sommet qui la précède est dedans ou dehors — c'est ce que veut
  dire traverser une frontière. Il ne reste qu'à suivre : on part d'une
  intersection, on avance le long d'un polygone jusqu'à la suivante, on
  saute sur l'autre polygone, et l'on repart. Le sens dans lequel on
  avance dépend de l'opération, et c'est tout ce qui les distingue.

  Les cas dégénérés — un sommet posé exactement sur une arête de
  l'autre, deux arêtes confondues — font échouer la marche, parce
  qu'il n'y a alors ni entrée ni sortie franche. On les défait en
  déplaçant l'un des deux polygones d'un cheveu : un milliardième de
  son étendue, dans une direction qui ne retombe sur rien. Le résultat
  est alors juste à ce déplacement près, ce qui est bien au-dessous de
  ce qu'on peut lire, et c'est le prix à payer pour répondre là où
  l'algorithme ne sait pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     a = {[0 0; 2 0; 2 2; 0 2]};
     b = {[1 1; 3 1; 3 3; 1 3]};
     c = matlibre_clip_booleen(a, b, 'intersection');
     abs(polyarea(c{1}(:,1), c{1}(:,2)) - 1) < 1e-9

  Voir aussi POLYSHAPE, UNION, INTERSECT, SUBTRACT.
```

## `matlibre_comparer_textes`

```
MATLIBRE_COMPARER_TEXTES Compare deux textes, comme le fait un tri.
  Rend -1 si A vient avant B, 0 s'ils sont égaux, 1 sinon. La
  comparaison est celle des codes de caractères, position par position ;
  à préfixe égal, le plus court vient d'abord.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_comparer_textes('a', 'b')      % -1
     matlibre_comparer_textes('ab', 'a')     % 1
     matlibre_comparer_textes('a', 'a')      % 0

  Voir aussi ISSORTED, SORT, STRCMP.
```

## `matlibre_composantes_triangles`

```
MATLIBRE_COMPOSANTES_TRIANGLES Nombre de morceaux d'un ensemble de triangles.
  Deux triangles sont du même morceau s'ils partagent au moins un
  sommet, et de proche en proche. On parcourt en largeur depuis chaque
  triangle non encore visité, et l'on compte les départs.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_composantes_triangles([1 2 3; 2 3 4])   % 1 : ils se touchent
     matlibre_composantes_triangles([1 2 3; 4 5 6])   % 2 : separes

  Voir aussi ALPHASHAPE, BOUNDARY.
```

## `matlibre_contient_variable`

```
MATLIBRE_CONTIENT_VARIABLE Vrai si le nom apparaît comme variable seule.
  Fonction interne : elle n'existe pas dans MATLAB. Elle sert à
  MATLIBRE_POIGNEE_DEPUIS_TEXTE, qui doit distinguer le « y » de
  « x + y » de celui de « ylabel ».
```

## `matlibre_contour_segments`

```
MATLIBRE_CONTOUR_SEGMENTS Découpe une matrice de contour en morceaux.
  La matrice que rend CONTOUR range ses courbes bout à bout, chacune
  précédée d'un en-tête portant sa hauteur et son nombre de points.
  C'est ce format qu'il faut défaire pour tracer les courbes une à une.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     s = matlibre_contour_segments([0 0 1; 2 0 1]);
     size(s{1}, 2)                   % 2 points

  Voir aussi CONTOUR, FIMPLICIT3, CONTOURC.
```

## `matlibre_couleur_secteur`

```
MATLIBRE_COULEUR_SECTEUR La k-ième couleur de la palette des secteurs.
  Fonction interne : elle n'existe pas dans MATLAB. PIE, PIE3 et ROSE
  s'en servent pour que deux secteurs voisins se distinguent, sans
  dépendre de la palette des courbes, qui n'a que sept tons.
```

## `matlibre_datastore_deviner`

```
MATLIBRE_DATASTORE_DEVINER Le genre de magasin qui convient à un chemin.
  L'extension décide : .csv, .txt et .dat donnent un magasin de texte
  tabulaire ; .pgm, .ppm, .png et .jpg un magasin d'images. Un dossier
  est jugé d'après ce qu'il contient.

  Deviner vaut mieux qu'exiger, mais pas toujours : quand rien ne
  tranche, on rend le texte tabulaire, qui est le cas courant, et
  'Type' permet de dire autre chose.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     strcmp(matlibre_datastore_deviner('mesures.csv'), 'tabulartext')

  Voir aussi DATASTORE.
```

## `matlibre_datastore_fichiers`

```
MATLIBRE_DATASTORE_FICHIERS Les fichiers désignés par un chemin.
  Accepte un fichier, une cellule ou un tableau de chaînes de fichiers,
  un dossier — dont on prend les fichiers dont l'extension convient —,
  ou un motif à joker.

  Les fichiers d'un dossier sont rendus en ordre alphabétique : sans
  cela, le contenu d'un magasin dépendrait de l'ordre où le système de
  fichiers les rend, qui n'est pas le même partout.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     f = [tempname '.csv'];
     writelines("a,b", f);
     numel(matlibre_datastore_fichiers(f, {'.csv'}))   % 1
     delete(f);

  Voir aussi TABULARTEXTDATASTORE, DATASTORE, DIR.
```

## `matlibre_datastore_typeSeul`

```
MATLIBRE_DATASTORE_TYPESEUL Repère le couple 'Type',VALEUR dans des options.
  DATASTORE lit 'Type' pour choisir le magasin, et passe tout le reste
  au constructeur choisi. Il faut donc séparer les deux, sans quoi le
  constructeur refuserait une option qu'il ne connaît pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = matlibre_datastore_typeSeul({'Type', 'image', 'ReadSize', 3});
     isequal(m, [true true false false])

  Voir aussi DATASTORE.
```

## `matlibre_decomp_choisir`

```
MATLIBRE_DECOMP_CHOISIR Choisit la factorisation la mieux adaptée.
  Cholesky si la matrice est symétrique définie positive — il coûte
  moitié moins que LU —, LDL si elle est symétrique sans être définie,
  QR si elle n'est pas carrée, LU sinon.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_decomp_choisir([4 1; 1 3])       % 'chol'
     matlibre_decomp_choisir([1 2; 3 4])       % 'lu'

  Voir aussi DECOMPOSITION, CHOL, LU, QR, LDL.
```

## `matlibre_decomp_factoriser`

```
MATLIBRE_DECOMP_FACTORISER Calcule et range la factorisation demandée.
  Le drapeau « malConditionne » retient ce que la factorisation a vu
  passer : le rapport du plus petit pivot au plus grand. C'est une
  estimation du conditionnement qui ne coûte rien, et c'est la seule
  information que la substitution ne peut plus retrouver ensuite.

  Le seuil est la racine de la précision machine, soit 1,5e-8 : un
  rapport plus petit signifie que plus de la moitié des chiffres
  significatifs sont perdus, ce qui est le moment de prévenir.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     f = matlibre_decomp_factoriser([4 1; 1 3], 'chol');
     f.malConditionne                % 0
     matlibre_decomp_factoriser(hilb(12), 'lu').malConditionne     % 1

  Voir aussi DECOMPOSITION, ISILLCONDITIONED.
```

## `matlibre_decomp_resoudre`

```
MATLIBRE_DECOMP_RESOUDRE Substitution dans une factorisation gardée.
  Chaque type se résout par ses propres substitutions : deux
  triangulaires pour LU et Cholesky, une projection puis une
  triangulaire pour QR.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     d = decomposition([4 1; 1 3]);
     norm(matlibre_decomp_resoudre(d, [1; 2]) - [4 1; 1 3] \ [1; 2]) < 1e-12

  Voir aussi DECOMPOSITION, MLDIVIDE.
```

## `matlibre_degre_minimal`

```
MATLIBRE_DEGRE_MINIMAL Ordre d'élimination par degré minimal exact.
  À chaque pas on élimine le nœud de plus petit degré et l'on relie
  entre eux ses voisins : c'est exactement ce que fait un pas de
  factorisation, et le graphe suffit à prévoir le remplissage.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     p = matlibre_degre_minimal(ones(3));
     isequal(sort(p), 1:3)          % 1

  Voir aussi SYMAMD, COLAMD, SYMRCM.
```

## `matlibre_distance_inverse`

```
MATLIBRE_DISTANCE_INVERSE Moyenne pondérée par l'inverse du carré de la distance.
  VQ = MATLIBRE_DISTANCE_INVERSE(X,Y,V,XQ,YQ) rend, en chaque point
  demandé, la moyenne des valeurs pondérée par l'inverse du carré de la
  distance. La surface obtenue passe par les points de données et est
  définie partout.

  Exemple :
     matlibre_distance_inverse([0;1], [0;0], [0;1], 0.5, 0)      % 0.5

  Voir aussi GRIDDATA.
```

## `matlibre_element_poignee`

```
MATLIBRE_ELEMENT_POIGNEE Un élément d'un tableau de poignées.
  E = MATLIBRE_ELEMENT_POIGNEE(H,K) rend le K-ième élément, que H soit
  un tableau de poignées, une cellule ou un scalaire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_element_poignee([10 20], 2)   % 20

  Voir aussi ISHANDLE, ISGRAPHICS.
```

## `matlibre_encodage_nom`

```
MATLIBRE_ENCODAGE_NOM Nom canonique d'un encodage de caractères.
  NOM = MATLIBRE_ENCODAGE_NOM(E) rend 'UTF-8', 'US-ASCII' ou
  'ISO-8859-1', en acceptant les orthographes usuelles. Un encodage
  non pris en charge est refusé par son nom : convertir en silence vers
  un encodage voisin donnerait un texte presque juste, ce qui est la
  pire des issues.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_encodage_nom('utf8')        % 'UTF-8'
     matlibre_encodage_nom('latin1')      % 'ISO-8859-1'

  Voir aussi UNICODE2NATIVE, NATIVE2UNICODE.
```

## `matlibre_enveloppe3d`

```
MATLIBRE_ENVELOPPE3D Facettes de l'enveloppe convexe d'un nuage de l'espace.
  La construction est incrémentale. On part d'un tétraèdre formé de
  quatre points non coplanaires, puis on ajoute les points un à un :
  celui qui est à l'extérieur voit certaines facettes — celles dont il
  est du côté de la normale —, on les retire, et le trou laissé est un
  contour fermé, l'horizon, que l'on referme en reliant chacune de ses
  arêtes au nouveau point.

  Un point posé exactement sur le plan d'une facette ne la voit pas : il
  ne change donc rien à l'enveloppe, ce qui est juste, et c'est ainsi
  que les points coplanaires — les quatre coins d'une face de cube — ne
  produisent pas de facettes qui se recouvrent.

  Chaque facette est orientée vers l'extérieur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     F = matlibre_enveloppe3d([0 0 0; 1 0 0; 0 1 0; 0 0 1]);
     size(F, 1)                      % 4 : le tetraedre a quatre faces

  Voir aussi CONVHULLN, CONVHULL.
```

## `matlibre_essaimer`

```
MATLIBRE_ESSAIMER Écarte latéralement les points de même abscisse.
  Les points partageant une abscisse sont répartis symétriquement autour
  d'elle, dans l'ordre de leur ordonnée. L'écartement est déterministe :
  deux appels sur les mêmes données donnent le même dessin, ce qu'un
  tirage aléatoire ne garantirait pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     xs = matlibre_essaimer([1; 1; 1], [1; 2; 3]);
     numel(unique(xs))               % 3 : ils ne se recouvrent plus

  Voir aussi SWARMCHART, SCATTER.
```

## `matlibre_est_nom_option`

```
MATLIBRE_EST_NOM_OPTION Une valeur peut-elle être le nom d'une option ?
  T = MATLIBRE_EST_NOM_OPTION(V) rend vrai si V est un vecteur de
  caractères d'une seule ligne, ou une chaîne unique.

  Cela distingue « 'VariableNames' » d'une colonne de texte. Sans la
  distinction, une colonne de deux lignes de caractères serait
  examinée comme un nom d'option — ce qui n'a pas de sens, et ce qui a
  déjà coûté une comparaison hors des bornes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_est_nom_option('VariableNames')    % 1
     matlibre_est_nom_option(["a"; "b"])         % 0 : deux textes
     matlibre_est_nom_option(['a'; 'b'])         % 0 : deux lignes

  Voir aussi TABLE, TIMETABLE, DATETIME.
```

## `matlibre_evaluer_courbe`

```
MATLIBRE_EVALUER_COURBE Évalue une poignée sur un vecteur de paramètres.
  Une poignée vectorisée est appelée une fois ; une poignée qui ne l'est
  pas est appelée point par point. On essaie la première façon et l'on
  se rabat sur la seconde si le résultat n'a pas la bonne taille — c'est
  plus sûr que d'exiger de l'appelant qu'il vectorise.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     v = matlibre_evaluer_courbe(@(t) t.^2, [1 2 3]);
     isequal(v, [1 4 9])

  Voir aussi FPLOT3, FPLOT, ARRAYFUN.
```

## `matlibre_evaluer_grille`

```
MATLIBRE_EVALUER_GRILLE Évalue une fonction de deux variables sur une grille.
  Fonction interne : elle n'existe pas dans MATLAB. FSURF, FMESH et
  FCONTOUR s'en servent ; comme pour une variable, une poignée non
  vectorisée est appelée point par point plutôt que de faire échouer le
  tracé.
```

## `matlibre_evaluer_grille3`

```
MATLIBRE_EVALUER_GRILLE3 Évalue une poignée de trois variables sur une tranche.
  La troisième coordonnée est fixée : on obtient la coupe de la
  fonction à cette altitude, dont la ligne de niveau zéro est la trace
  de la surface implicite.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [X, Y] = meshgrid(-1:1, -1:1);
     Z = matlibre_evaluer_grille3(@(x,y,z) x + y + z, X, Y, 1);
     Z(2, 2)                         % 1 : au centre, x et y sont nuls

  Voir aussi FIMPLICIT3, MATLIBRE_EVALUER_GRILLE.
```

## `matlibre_evaluer_sur`

```
MATLIBRE_EVALUER_SUR Évalue une fonction sur un vecteur, vectorisée ou non.
  Fonction interne : elle n'existe pas dans MATLAB. FPLOT, FSURF,
  EZPLOT et FCONTOUR s'en servent : une poignée écrite avec « * » au
  lieu de « .* » ne se vectorise pas, et il faut alors l'appeler point
  par point plutôt que d'echouer.
```

## `matlibre_extrema_locaux`

```
MATLIBRE_EXTREMA_LOCAUX Rouage commun d'ISLOCALMAX et d'ISLOCALMIN.
  Un minimum de A est un maximum de -A : la fonction ne traite que le
  cas du maximum, et le retournement suffit pour l'autre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_extrema_locaux([1 3 2], {}, true)     % [0 1 0]

  Voir aussi ISLOCALMAX, ISLOCALMIN.
```

## `matlibre_fleche`

```
MATLIBRE_FLECHE Le tracé d'une flèche, hampe et pointe d'un seul trait.
  Fonction interne : elle n'existe pas dans MATLAB. QUIVER, COMPASS et
  FEATHER s'en servent ; la flèche est rendue comme une seule polyligne,
  ce qui la fait tenir en une courbe et non en trois.
```

## `matlibre_forme_alpha`

```
MATLIBRE_FORME_ALPHA Contour fermé de la forme alpha d'un nuage.
  On triangule, on garde les triangles dont le cercle circonscrit tient
  sous le seuil, puis on suit le bord de ce qui reste : les arêtes qui
  n'appartiennent qu'à un triangle. Ces arêtes se chaînent en un
  contour, rendu premier point répété à la fin.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     k = matlibre_forme_alpha([0 1 1 0]', [0 0 1 1]', inf);
     numel(k)                        % 5 : quatre coins et le retour

  Voir aussi BOUNDARY, ALPHASHAPE, DELAUNAY.
```

## `matlibre_gbs_pas`

```
MATLIBRE_GBS_PAS Un pas de Gragg-Bulirsch-Stoer.
  On traverse le pas H avec 2, 4, 6, 8 puis 10 sous-pas par la règle du
  point milieu modifiée, et l'on extrapole les cinq résultats vers un
  sous-pas nul par le tableau d'Aitken-Neville.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  L'erreur de la règle du point milieu modifiée est une série en
  puissances paires du sous-pas. C'est ce qui rend l'extrapolation
  efficace : chaque colonne du tableau supprime le terme suivant de la
  série, et l'ordre monte de deux à chaque fois au lieu d'un.

  L'écart entre les deux dernières colonnes estime l'erreur : c'est le
  procédé habituel, celui qui évite de calculer une seconde solution.

  Exemple :
     [y, e] = matlibre_gbs_pas(@(t, v) -v, 0, 1, 0.1);
     abs(y - exp(-0.1)) < 1e-12

  Voir aussi ODE89, ODE113, ODE45.
```

## `matlibre_glissant`

```
MATLIBRE_GLISSANT Applique une fonction sur une fenêtre glissante.
  Y = MATLIBRE_GLISSANT(X,K,OPTIONS,F) parcourt X avec une fenêtre de K
  points et applique F à chacune. K peut valoir [AVANT APRES].

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Les fonctions MOV... natives sont écrites en C++ ; celle-ci sert aux
  quelques-unes qui demandent un calcul non incrémental — l'écart absolu
  médian en est une, puisqu'une médiane ne se met pas à jour d'un point
  à l'autre.

  Exemple :
     matlibre_glissant(1:5, 3, {}, @max)     % 2 3 4 5 5

  Voir aussi MOVMAD, MOVMEAN, MOVMEDIAN.
```

## `matlibre_graphe_acyclique`

```
MATLIBRE_GRAPHE_ACYCLIQUE Le graphe orienté est-il sans circuit ?
  [T,ORDRE] = MATLIBRE_GRAPHE_ACYCLIQUE(G) rend vrai si G n'a aucun
  circuit, et l'ordre topologique qui le prouve. C'est l'algorithme de
  Kahn, mais sans erreur : ne pas pouvoir trier est ici la réponse, non
  un échec.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_acyclique(digraph([1 2], [2 3]))    % 1
     matlibre_graphe_acyclique(digraph([1 2], [2 1]))    % 0

  Voir aussi ISDAG, TOPOSORT, HASCYCLES.
```

## `matlibre_graphe_aretes_entrantes`

```
MATLIBRE_GRAPHE_ARETES_ENTRANTES Arêtes qui aboutissent à un nœud.
  INDICES = MATLIBRE_GRAPHE_ARETES_ENTRANTES(G,N) rend les rangs des
  arêtes arrivant sur N. Sur un graphe non orienté, une arête n'a pas
  de sens : ce sont les mêmes que les sortantes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_aretes_entrantes(digraph([1 2], [3 3]), 3)   % [1 2]

  Voir aussi INEDGES, OUTEDGES.
```

## `matlibre_graphe_aretes_sortantes`

```
MATLIBRE_GRAPHE_ARETES_SORTANTES Arêtes qu'on peut emprunter depuis un nœud.
  INDICES = MATLIBRE_GRAPHE_ARETES_SORTANTES(G,N) rend les rangs des
  arêtes partant de N. Sur un graphe non orienté, une arête se parcourt
  dans les deux sens : toutes celles qui touchent N en font partie.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_aretes_sortantes(graph([1 2], [2 3]), 2)   % [1 2]

  Voir aussi OUTEDGES, INEDGES, ALLPATHS.
```

## `matlibre_graphe_autre_bout`

```
MATLIBRE_GRAPHE_AUTRE_BOUT Nœud atteint en empruntant une arête.
  B = MATLIBRE_GRAPHE_AUTRE_BOUT(G,ARETE,COURANT) rend le nœud où l'on
  arrive. Sur un graphe orienté c'est toujours la cible ; sur un graphe
  non orienté, c'est l'autre extrémité que celle d'où l'on vient.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_autre_bout(graph([1 2], [2 3]), 1, 2)   % 1

  Voir aussi ALLPATHS, ALLCYCLES.
```

## `matlibre_graphe_base_cycles`

```
MATLIBRE_GRAPHE_BASE_CYCLES Base de cycles fondamentaux.
  [CYCLES,ARETES] = MATLIBRE_GRAPHE_BASE_CYCLES(G) rend une base de
  l'espace des cycles : une forêt couvrante est construite, et chaque
  arête restée hors de la forêt ferme exactement un cycle.

  La base compte E - N + C éléments, où C est le nombre de composantes.
  Tout cycle du graphe est une somme, arête par arête et modulo deux,
  de ces cycles-là : c'est ce qui en fait une base, et la raison pour
  laquelle on n'a pas besoin de les énumérer tous.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numel(matlibre_graphe_base_cycles(graph([1 2 3], [2 3 1])))   % 1

  Voir aussi CYCLEBASIS, ALLCYCLES, MINSPANTREE.
```

## `matlibre_graphe_chemins`

```
MATLIBRE_GRAPHE_CHEMINS Tous les chemins simples d'un nœud à un autre.
  [CHEMINS,ARETES] = MATLIBRE_GRAPHE_CHEMINS(G,S,T) rend, dans deux
  cellules, la suite des nœuds et la suite des arêtes de chaque chemin
  ne repassant jamais par le même nœud.

  L'énumération se fait en profondeur, en marquant les nœuds du chemin
  courant : c'est ce marquage, et lui seul, qui distingue un chemin
  simple d'une promenade sans fin dans un cycle.

  Le nombre de chemins peut croître très vite ; MAXIMUM, s'il est
  donné, arrête l'énumération là.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     c = matlibre_graphe_chemins(digraph([1 1 2], [2 3 3]), 1, 3);
     numel(c)                        % 2 : direct, et par le noeud 2

  Voir aussi ALLPATHS, ALLCYCLES, SHORTESTPATH.
```

## `matlibre_graphe_composantes`

```
MATLIBRE_GRAPHE_COMPOSANTES Composantes connexes d'un graphe.
  Sur un GRAPH, la connexité est unique. Sur un DIGRAPH il y en a deux :
  forte — chaque nœud atteint chaque autre en suivant le sens des arcs —
  et faible, où l'on ignore l'orientation. La forte est celle par
  défaut, comme dans MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  La composante forte se trouve par la double accessibilité : deux nœuds
  sont dans la même si chacun atteint l'autre. C'est plus lent que
  Tarjan, mais c'est la définition même, et l'on voit ce qu'on calcule.

  Exemple :
     matlibre_graphe_composantes(graph([1 3], [2 4]), {})   % 1 1 2 2

  Voir aussi CONNCOMP, GRAPH, DIGRAPH.
```

## `matlibre_graphe_compter_aretes`

```
MATLIBRE_GRAPHE_COMPTER_ARETES Nombre d'arêtes entre deux nœuds.
  N = MATLIBRE_GRAPHE_COMPTER_ARETES(G,S,T) compte les arêtes joignant
  S à T. Sur un graphe non orienté, le sens ne compte pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_compter_aretes(graph([1 1], [2 2]), 1, 2)   % 2

  Voir aussi EDGECOUNT, FINDEDGE, ISMULTIGRAPH.
```

## `matlibre_graphe_condensation`

```
MATLIBRE_GRAPHE_CONDENSATION Graphe des composantes fortement connexes.
  [H,GROUPES] = MATLIBRE_GRAPHE_CONDENSATION(G) rend le graphe dont
  chaque nœud est une composante fortement connexe de G, et GROUPES le
  numéro de composante de chaque nœud de G.

  La condensation est toujours sans circuit : s'il en restait un, les
  composantes qu'il relie n'en feraient qu'une. C'est ce qui permet de
  ramener une question d'accessibilité sur un graphe quelconque à la
  même question sur un graphe sans circuit.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numnodes(matlibre_graphe_condensation(digraph([1 2 3], [2 1 3])))   % 2

  Voir aussi CONDENSATION, CONNCOMP, ISDAG.
```

## `matlibre_graphe_construire`

```
MATLIBRE_GRAPHE_CONSTRUIRE Lit les arguments de GRAPH et de DIGRAPH.
  Les deux classes acceptent les mêmes formes : deux listes de nœuds,
  avec ou sans poids, ou une matrice d'adjacence. Le seul écart tient à
  l'orientation : sur un graphe non orienté, une matrice d'adjacence ne
  donne qu'une arête par couple, la moitié supérieure suffisant.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [a, p, n, m] = matlibre_graphe_construire({[1 2], [2 3]}, false);
     m                               % 3

  Voir aussi GRAPH, DIGRAPH.
```

## `matlibre_graphe_cycles`

```
MATLIBRE_GRAPHE_CYCLES Tous les cycles simples d'un graphe.
  [CYCLES,ARETES] = MATLIBRE_GRAPHE_CYCLES(G) rend, dans deux cellules,
  les nœuds et les arêtes de chaque cycle ne repassant ni par un nœud
  ni par une arête.

  Chaque cycle est énuméré une fois. Deux précautions y suffisent : on
  n'explore qu'à partir de son plus petit nœud, et sur un graphe non
  orienté on ne garde qu'un des deux sens de parcours. Sans elles, un
  triangle se compterait six fois.

  MAXIMUM, s'il est donné, arrête l'énumération : le nombre de cycles
  d'un graphe dense croît plus vite que toute fonction polynomiale de
  sa taille.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numel(matlibre_graphe_cycles(graph([1 2 3], [2 3 1])))   % 1

  Voir aussi ALLCYCLES, HASCYCLES, CYCLEBASIS.
```

## `matlibre_graphe_depuis`

```
MATLIBRE_GRAPHE_DEPUIS Construit un graphe du même genre qu'un autre.
  H = MATLIBRE_GRAPHE_DEPUIS(MODELE,ARCS,POIDS,NOMS,NOMBRE) rend un
  GRAPH ou un DIGRAPH selon MODELE, portant les arêtes données.

  Passer par les propriétés plutôt que par le constructeur permet de
  garder les nœuds isolés : deux listes d'extrémités ne disent pas
  combien de nœuds le graphe compte, et un nœud sans arête y
  disparaîtrait.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     h = matlibre_graphe_depuis(graph(), [1 2], 1, {}, 3);
     numnodes(h)                     % 3 : le troisieme noeud reste

  Voir aussi GRAPH, DIGRAPH, REORDERNODES.
```

## `matlibre_graphe_dijkstra`

```
MATLIBRE_GRAPHE_DIJKSTRA Plus court chemin par l'algorithme de Dijkstra.
  L'algorithme retient à chaque pas le nœud non visité le plus proche de
  la source et le déclare définitif. Ce raisonnement n'est valable que
  pour des poids positifs : un poids négatif pourrait rendre plus court,
  plus tard, un chemin déjà tenu pour optimal.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     g = graph([1 2], [2 3]);
     matlibre_graphe_dijkstra(g, 1, 3, {})     % 1 2 3

  Voir aussi SHORTESTPATH, DISTANCES, GRAPH, DIGRAPH.
```

## `matlibre_graphe_distances`

```
MATLIBRE_GRAPHE_DISTANCES Longueur du plus court chemin entre tous les couples.
  Un Dijkstra par source. Sur un graphe dense, Floyd-Warshall serait
  préférable ; sur un graphe creux, c'est l'inverse — et un graphe est
  presque toujours creux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     D = matlibre_graphe_distances(graph([1 2], [2 3]), {});
     D(1, 3)                         % 2

  Voir aussi DISTANCES, SHORTESTPATH.
```

## `matlibre_graphe_fermeture`

```
MATLIBRE_GRAPHE_FERMETURE Fermeture transitive d'un graphe orienté.
  H = MATLIBRE_GRAPHE_FERMETURE(G) rend le graphe où un arc joint U à V
  dès que V est accessible depuis U par un chemin quelconque. Les
  boucles sur un nœud ne sont pas conservées.

  L'accessibilité se calcule par un parcours depuis chaque nœud : c'est
  en O(N*(N+E)), là où l'élévation répétée de la matrice d'adjacence
  serait en O(N^3) sans être plus claire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numedges(matlibre_graphe_fermeture(digraph([1 2], [2 3])))   % 3

  Voir aussi TRANSCLOSURE, TRANSREDUCTION, CONDENSATION.
```

## `matlibre_graphe_indices`

```
MATLIBRE_GRAPHE_INDICES Traduit des noms de nœuds en numéros.
  Un nœud se désigne par son rang ou par son nom ; toutes les méthodes
  des graphes acceptent les deux, et c'est ici que la traduction se fait.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     g = graph([1 2], [2 3]);
     matlibre_graphe_indices(g, 2)      % 2

  Voir aussi GRAPH, DIGRAPH.
```

## `matlibre_graphe_isomorphe`

```
MATLIBRE_GRAPHE_ISOMORPHE Deux graphes se correspondent-ils ?
  [OK,P] = MATLIBRE_GRAPHE_ISOMORPHE(G,H) cherche une permutation des
  nœuds de G qui donne H : P(i) est le nœud de H auquel correspond le
  nœud i de G. OK est faux s'il n'en existe aucune.

  La recherche est un retour sur trace, guidé par les degrés : deux
  nœuds ne peuvent se correspondre que s'ils ont le même degré, ce qui
  élague l'arbre avant de l'explorer. Aucun algorithme polynomial n'est
  connu pour ce problème ; sur de grands graphes réguliers, la
  recherche peut donc être longue.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_isomorphe(graph([1 2], [2 3]), graph([2 3], [3 1]))

  Voir aussi ISISOMORPHIC, ISOMORPHISM.
```

## `matlibre_graphe_multiple`

```
MATLIBRE_GRAPHE_MULTIPLE Deux nœuds sont-ils joints plusieurs fois ?
  T = MATLIBRE_GRAPHE_MULTIPLE(G) rend vrai si une même paire de nœuds
  porte plus d'une arête. Une boucle unique ne suffit pas : ce qui fait
  un multigraphe est la répétition, non le retour sur soi.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_multiple(graph([1 1], [2 2]))   % 1 : deux fois 1-2
     matlibre_graphe_multiple(graph([1], [1]))       % 0 : une boucle

  Voir aussi ISMULTIGRAPH, SIMPLIFY.
```

## `matlibre_graphe_parcours`

```
MATLIBRE_GRAPHE_PARCOURS Parcours en largeur ou en profondeur.
  Les deux ne diffèrent que par la structure d'attente : une file pour
  la largeur, une pile pour la profondeur. C'est tout, et cela suffit à
  changer complètement l'ordre de visite — la largeur trouve les plus
  courts chemins en nombre d'arêtes, la profondeur descend d'abord.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_parcours(graph([1 1], [2 3]), 1, true)     % 1 2 3

  Voir aussi BFSEARCH, DFSEARCH, GRAPH, DIGRAPH.
```

## `matlibre_graphe_prim`

```
MATLIBRE_GRAPHE_PRIM Arbre couvrant de poids minimal.
  L'algorithme de Prim fait croître un arbre depuis un nœud, en lui
  ajoutant chaque fois l'arête la moins chère qui mène hors de lui.
  Le choix glouton est ici optimal : c'est la propriété de coupe — la
  plus légère arête traversant une coupe appartient à un arbre minimal.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [t, c] = matlibre_graphe_prim(graph([1 2 1], [2 3 3], [1 1 5]));
     c                               % 2 : la grande arete est evitee

  Voir aussi MINSPANTREE, GRAPH.
```

## `matlibre_graphe_proches`

```
MATLIBRE_GRAPHE_PROCHES Nœuds à portée d'un nœud donné.
  [N,D] = MATLIBRE_GRAPHE_PROCHES(G,S,R) rend les nœuds dont la
  distance à S ne dépasse pas R, classés par distance croissante, et
  ces distances. Le nœud S lui-même n'y figure pas.

  La distance est celle des poids d'arêtes, comme pour DISTANCES ;
  R infini rend donc tous les nœuds accessibles.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_proches(graph([1 2], [2 3]), 1, 1)   % 2

  Voir aussi NEAREST, DISTANCES, SHORTESTPATH.
```

## `matlibre_graphe_reduction`

```
MATLIBRE_GRAPHE_REDUCTION Réduction transitive d'un graphe sans circuit.
  H = MATLIBRE_GRAPHE_REDUCTION(G) retire les arcs qu'un chemin plus
  long rend inutiles : U->V disparaît s'il existe un autre chemin de U
  à V. H a la même accessibilité que G, avec le moins d'arcs possible.

  Sur un graphe sans circuit, cette réduction est unique. Elle ne l'est
  plus dès qu'il y a un circuit — n'importe lequel de ses arcs peut
  être celui qu'on garde — et MatLibre refuse alors, plutôt que de
  choisir en silence.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numedges(matlibre_graphe_reduction(digraph([1 1 2], [2 3 3])))   % 2

  Voir aussi TRANSREDUCTION, TRANSCLOSURE, ISDAG.
```

## `matlibre_graphe_reordonner`

```
MATLIBRE_GRAPHE_REORDONNER Renumérote les nœuds d'un graphe.
  H = MATLIBRE_GRAPHE_REORDONNER(G,ORDRE) rend le même graphe dont le
  nœud k est celui qui portait le numéro ORDRE(k). ORDRE doit être une
  permutation de 1 à N : renuméroter n'est pas trier, et il ne doit ni
  manquer ni se répéter un nœud.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     h = matlibre_graphe_reordonner(graph([1 2], [2 3]), [3 2 1]);
     h.Arcs                          % les aretes suivent les noeuds

  Voir aussi REORDERNODES, SUBGRAPH.
```

## `matlibre_graphe_retirer`

```
MATLIBRE_GRAPHE_RETIRER Retire des nœuds et renumérote les autres.
  Retirer un nœud décale tous ceux qui le suivent : c'est la partie
  délicate, et la seule raison pour laquelle cette fonction existe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numnodes(matlibre_graphe_retirer(graph([1 2], [2 3]), 3))   % 2

  Voir aussi RMNODE, SUBGRAPH.
```

## `matlibre_graphe_retourner`

```
MATLIBRE_GRAPHE_RETOURNER Retourne le sens de certains arcs.
  H = MATLIBRE_GRAPHE_RETOURNER(G,S,T) rend le graphe où les arcs
  allant de S à T ont été retournés ; les autres ne bougent pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     h = matlibre_graphe_retourner(digraph([1 2], [2 3]), 1, 2);
     h.Arcs(1, :)                    % 2 1 : l'arc a change de sens

  Voir aussi FLIPEDGE, DIGRAPH.
```

## `matlibre_graphe_sous`

```
MATLIBRE_GRAPHE_SOUS Sous-graphe induit par un ensemble de nœuds.
  Ne sont gardées que les arêtes dont les deux extrémités survivent, et
  les nœuds restants sont renumérotés dans l'ordre où ils sont donnés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numedges(matlibre_graphe_sous(graph([1 2], [2 3]), [1 2]))   % 1

  Voir aussi SUBGRAPH, RMNODE.
```

## `matlibre_graphe_toposort`

```
MATLIBRE_GRAPHE_TOPOSORT Tri topologique par l'algorithme de Kahn.
  On retire à chaque pas un nœud sans prédécesseur. S'il n'en reste
  aucun alors que des nœuds subsistent, c'est qu'il y a un cycle — et un
  graphe cyclique n'admet aucun ordre topologique.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_graphe_toposort(digraph([1 2], [2 3]))      % 1 2 3

  Voir aussi TOPOSORT, DIGRAPH, CONNCOMP.
```

## `matlibre_graphe_tracer`

```
MATLIBRE_GRAPHE_TRACER Dessine un graphe, les nœuds répartis sur un cercle.
  La disposition circulaire n'est pas un choix esthétique : elle est
  déterministe et sans paramètre, là où les dispositions par forces
  dépendent d'un tirage et d'une convergence. Un même graphe se dessine
  donc toujours pareil.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure();
     matlibre_graphe_tracer(graph([1 2], [2 3]), {});
     close all;

  Voir aussi PLOT, GRAPH, DIGRAPH.
```

## `matlibre_graphe_voisins`

```
MATLIBRE_GRAPHE_VOISINS Nœuds atteignables depuis N, et le coût pour y aller.
  Sur un GRAPH, une arête se parcourt dans les deux sens ; sur un
  DIGRAPH, seulement dans le sien. AREBOURS remonte les arcs, ce dont a
  besoin la recherche de composantes fortement connexes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     g = digraph([1 2], [2 3]);
     matlibre_graphe_voisins(g, 1, false)'     % 2

  Voir aussi GRAPH, DIGRAPH, SHORTESTPATH.
```

## `matlibre_grille_lineaire`

```
MATLIBRE_GRILLE_LINEAIRE Interpolation linéaire sur une triangulation.
  VQ = MATLIBRE_GRILLE_LINEAIRE(X,Y,V,XQ,YQ) triangule les points, situe
  chaque point demandé dans un triangle, et y interpole linéairement par
  les coordonnées barycentriques.

  Les coordonnées barycentriques d'un point sont les poids qui
  l'écrivent comme moyenne des trois sommets ; elles sont toutes
  positives si et seulement si le point est dans le triangle, ce qui
  sert à la fois à le situer et à l'interpoler.

  Hors de l'enveloppe des données, la valeur est NaN.

  Exemple :
     [x, y] = meshgrid(0:1, 0:1);
     matlibre_grille_lineaire(x(:), y(:), x(:), 0.5, 0.5)      % 0.5

  Voir aussi GRIDDATA, DELAUNAY.
```

## `matlibre_grille_plus_proche`

```
MATLIBRE_GRILLE_PLUS_PROCHE Valeur du point de données le plus proche.
  VQ = MATLIBRE_GRILLE_PLUS_PROCHE(X,Y,V,XQ,YQ) rend, pour chaque point
  demandé, la valeur du point de données dont il est le plus près.

  Exemple :
     matlibre_grille_plus_proche([0;1], [0;0], [10;20], 0.9, 0)      % 20

  Voir aussi GRIDDATA.
```

## `matlibre_grille_polaire`

```
MATLIBRE_GRILLE_POLAIRE Les cercles et les rayons d'un tracé polaire.
  Fonction interne : elle n'existe pas dans MATLAB, qui a de vrais axes
  polaires. POLARPLOT, COMPASS et ROSE la posent sous leur courbe pour
  que les rayons se lisent.
```

## `matlibre_groupe_fonction`

```
MATLIBRE_GROUPE_FONCTION Traduit un nom de méthode en poignée de fonction.
  GROUPSUMMARY, GROUPTRANSFORM et GROUPFILTER acceptent les mêmes noms ;
  la traduction se fait ici une fois pour toutes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     f = matlibre_groupe_fonction('sum');
     f([1 2 3])                      % 6

  Voir aussi GROUPSUMMARY, GROUPTRANSFORM, GROUPFILTER.
```

## `matlibre_hadamard_noyau`

```
MATLIBRE_HADAMARD_NOYAU Noyaux de la construction de Hadamard.
  Les ordres 1 et 2 sont immédiats ; 12 et 20 viennent des
  constructions de Paley, qui bordent une matrice circulante bâtie sur
  les résidus quadratiques modulo un nombre premier.

  Fonction interne : elle n'existe pas dans MATLAB.
```

## `matlibre_heriter`

```
MATLIBRE_HERITER Appelle le constructeur d'un parent et en verse la part.
  C'est ce que « obj@Parent(args) » veut dire dans le constructeur d'une
  classe dérivée : construire la part de parent, puis la déposer dans
  l'objet en cours. L'analyseur réécrit la ligne en un appel à cette
  fonction ; on ne l'écrit pas soi-même.

  Les propriétés que le parent a fixées sont copiées ; celles qu'il ne
  connaît pas restent telles quelles. C'est pour cela que l'appel se
  place en tête du constructeur : ce qui vient après l'emporte.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     s = matlibre_heriter(struct('a', 0), 'struct');
     s.a                             % 0 : rien a verser

  Voir aussi CLASSDEF, ISA, PROPERTIES.
```

## `matlibre_interp_arguments`

```
MATLIBRE_INTERP_ARGUMENTS Démêle les arguments d'un interpolant dispersé.
  Les points peuvent venir en une matrice ou en coordonnées séparées, et
  les deux dernières places peuvent porter la méthode et le mode de
  prolongement. On reconnaît ces derniers à ce qu'ils sont du texte.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [P, v] = matlibre_interp_arguments({[0 0; 1 1], [3; 4]});
     isequal(v, [3; 4])

  Voir aussi SCATTEREDINTERPOLANT, GRIDDEDINTERPOLANT.
```

## `matlibre_interp_disperse`

```
MATLIBRE_INTERP_DISPERSE Valeur interpolée en un point, données dispersées.
  En linéaire, on cherche le triangle de Delaunay qui contient le point
  et l'on y prend la combinaison barycentrique des trois valeurs. En
  'nearest', la valeur du point de donnée le plus proche.

  Hors de l'enveloppe convexe, aucun triangle ne contient le point : la
  valeur est NaN, sauf si le prolongement demandé est 'nearest'.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     F = scatteredInterpolant([0;1;0], [0;0;1], [1;2;3]);
     abs(matlibre_interp_disperse(F, [0.5 0]) - 1.5) < 1e-12

  Voir aussi SCATTEREDINTERPOLANT.
```

## `matlibre_krylov`

_Pas de bloc d'aide._

## `matlibre_krylov_produit`

```
MATLIBRE_KRYLOV_PRODUIT Le produit A*v, que A soit une matrice ou une poignée.
  Les méthodes de Krylov ne demandent jamais la matrice, seulement son
  action sur un vecteur : c'est ce qui leur permet de résoudre un système
  dont la matrice ne tiendrait pas en mémoire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_krylov_produit(@(v) 2 * v, [1; 2])     % [2; 4]
     matlibre_krylov_produit(eye(2), [1; 2])         % [1; 2]

  Voir aussi PCG, BICG, GMRES.
```

## `matlibre_largeur_bande`

```
MATLIBRE_LARGEUR_BANDE Distance maximale d'un coefficient non nul à la diagonale.
  C'est la quantité que SYMRCM cherche à réduire : la factorisation
  d'une matrice de bande B coûte O(N*B^2) et n'en sort jamais.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_largeur_bande(eye(4))       % 0
     matlibre_largeur_bande(ones(4))      % 3

  Voir aussi SYMRCM, SYMAMD, BANDWIDTH.
```

## `matlibre_lire_options`

```
MATLIBRE_LIRE_OPTIONS Lit une suite de couples nom-valeur.
  Les valeurs par défaut viennent d'une structure ; chaque couple
  présent dans les arguments remplace la sienne. Un nom inconnu est
  refusé plutôt qu'ignoré : une option mal orthographiée qui ne fait
  rien est plus coûteuse qu'une erreur.

  La comparaison des noms ignore la casse, comme dans MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     o = matlibre_lire_options({'Seuil', 3}, struct('Seuil', 1));
     o.Seuil                         % 3

  Voir aussi INPUTPARSER, VARARGIN.
```

## `matlibre_magasin_combine`

```
MATLIBRE_MAGASIN_COMBINE Magasin qui lit plusieurs magasins de front.
  C'est l'objet que rend COMBINE. Chaque lecture prend un morceau de
  chacun des magasins réunis et les rend dans une cellule ; la lecture
  s'arrête dès que l'un d'eux est épuisé.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
  qui nomme cet objet CombinedDatastore.

  Exemple :
     c = matlibre_magasin_combine({arrayDatastore([1;2]), arrayDatastore([3;4])});
     numel(read(c))                  % 2 : un morceau par magasin

  Voir aussi COMBINE, TRANSFORM, DATASTORE.
```

## `matlibre_magasin_transforme`

```
MATLIBRE_MAGASIN_TRANSFORME Magasin dont chaque morceau passe par une fonction.
  C'est l'objet que rend TRANSFORM. La fonction n'est appliquée qu'à la
  lecture : décrire un prétraitement ne coûte donc rien tant qu'on ne
  lit pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
  qui nomme cet objet TransformedDatastore.

  Exemple :
     t = matlibre_magasin_transforme(arrayDatastore([1;2]), @(x) x * 2);
     read(t)                         % 2

  Voir aussi TRANSFORM, COMBINE, DATASTORE.
```

## `matlibre_memoire_globale`

```
MATLIBRE_MEMOIRE_GLOBALE Registre des fonctions mémoïsées vivantes.
  Chaque MEMOIZEDFUNCTION s'y inscrit à sa construction, ce qui permet
  à CLEARALLMEMOIZEDCACHES de toutes les vider d'un coup. C'est
  possible parce que MEMOIZEDFUNCTION est une classe à poignée : le
  registre garde la même chose que l'appelant, non une copie.

  Le registre retient donc ses objets aussi longtemps que la session
  dure. C'est le prix à payer pour pouvoir les atteindre, et MATLAB
  fait de même.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     avant = matlibre_memoire_globale('compter');
     f = memoize(@(x) x);
     matlibre_memoire_globale('compter') > avant

  Voir aussi MEMOIZE, CLEARALLMEMOIZEDCACHES, MEMOIZEDFUNCTION.
```

## `matlibre_nom_valide`

```
MATLIBRE_NOM_VALIDE Fait d'un texte un nom de champ acceptable.
  Les caractères qui ne peuvent pas figurer dans un nom deviennent des
  soulignés, et un nom qui commence par un chiffre reçoit un « x » en
  tête : un champ de structure ne peut pas commencer par un chiffre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB —
  c'est MATLAB.LANG.MAKEVALIDNAME qui y répond.

  Exemple :
     matlibre_nom_valide('a-b')      % 'a_b'
     matlibre_nom_valide('2x')       % 'x2x'

  Voir aussi MATLIBRE_XML_BALISE, GENVARNAME, ISVARNAME.
```

## `matlibre_noyau_plaque`

```
MATLIBRE_NOYAU_PLAQUE Noyau radial de la plaque mince.
  K = MATLIBRE_NOYAU_PLAQUE(X,Y,XQ,YQ) rend la matrice des r²log(r)
  entre les points demandés et les points de données. La valeur en zéro
  est zéro, prolongée par continuité.

  Exemple :
     matlibre_noyau_plaque(0, 0, 1, 0)      % 0, car log(1) est nul

  Voir aussi MATLIBRE_PLAQUE_MINCE.
```

## `matlibre_nuage_entree`

```
MATLIBRE_NUAGE_ENTREE Démêle les arguments d'un nuage de mots.
  Accepte une liste de mots et leurs tailles, ou un texte brut dont les
  mots sont comptés. Dans ce dernier cas, les mots d'une lettre et les
  plus courants sont écartés : ils domineraient le nuage sans rien en
  dire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [m, t] = matlibre_nuage_entree({["a" "b"], [2 1]});
     numel(m) == 2 && t(1) == 2

  Voir aussi WORDCLOUD.
```

## `matlibre_nuage_place`

```
MATLIBRE_NUAGE_PLACE Trouve une place libre sur une spirale.
  On part du centre et l'on tourne en s'éloignant, en s'arrêtant au
  premier endroit où le rectangle du mot ne recouvre aucun de ceux déjà
  posés. C'est le placement usuel d'un nuage de mots : il met au centre
  ce qu'on pose en premier, donc ce qui domine.

  Deux rectangles alignés sur les axes se recouvrent si et seulement si
  leurs projections se recouvrent sur les deux axes : le test est donc
  immédiat, et c'est ce qui rend la recherche praticable.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [x, y] = matlibre_nuage_place(zeros(0, 4), 0.1, 0.1);
     x == 0 && y == 0                % le premier va au centre

  Voir aussi WORDCLOUD.
```

## `matlibre_ode_option`

```
MATLIBRE_ODE_OPTION Lit une option d'ODESET, ou rend la valeur par défaut.
  Les structures d'ODESET portent des champs absents quand l'option
  n'est pas posée, et parfois vides quand elle l'est sans valeur : les
  deux cas retombent sur le défaut.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_ode_option(struct('RelTol', 1e-8), 'RelTol', 1e-6)

  Voir aussi ODESET, ODEGET, ODE89.
```

## `matlibre_parent_graphique`

```
MATLIBRE_PARENT_GRAPHIQUE Objet qui contient une poignée graphique.
  P = MATLIBRE_PARENT_GRAPHIQUE(H) rend l'axe d'une courbe ou d'un
  texte, la figure d'un axe, et un tableau vide au-dessus d'une figure.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure; courbe = plot(1:3);
     strcmp(get(matlibre_parent_graphique(courbe), 'Type'), 'axes')   % 1

  Voir aussi ANCESTOR, GCA, GCF.
```

## `matlibre_parquet_classe`

```
MATLIBRE_PARQUET_CLASSE Classe MATLAB d'une colonne Parquet.
  CLASSE = MATLIBRE_PARQUET_CLASSE(PHYSIQUE,CONVERTI) rend le nom de la
  classe à restituer. Le type converti l'emporte quand il est présent :
  c'est lui qui distingue un int8 d'un int32, que Parquet range tous
  deux en INT32.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_parquet_classe(1, 15)  % 'int8'
     matlibre_parquet_classe(5, -1)  % 'double'

  Voir aussi PARQUETREAD, MATLIBRE_PARQUET_TYPES.
```

## `matlibre_parquet_decoder`

```
MATLIBRE_PARQUET_DECODER Décodage « PLAIN » d'une colonne.
  VALEURS = MATLIBRE_PARQUET_DECODER(OCTETS,PHYSIQUE,NOMBRE) rend les
  NOMBRE valeurs écrites bout à bout dans OCTETS. C'est l'inverse exact
  de MATLIBRE_PARQUET_ENCODER.

  MATLIBRE_PARQUET_DECODER(...,CLASSE) dit comment relire les entiers :
  les mêmes 32 ou 64 bits valent un nombre signé ou non selon ce que le
  type converti annonçait, et s'en remettre au type physique seul
  ramènerait un grand uint32 à sa borne signée.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     o = matlibre_parquet_encoder([1 2 3], 5);
     matlibre_parquet_decoder(o, 5, 3)          % [1; 2; 3]

  Voir aussi PARQUETREAD, MATLIBRE_PARQUET_ENCODER.
```

## `matlibre_parquet_encoder`

```
MATLIBRE_PARQUET_ENCODER Encodage « PLAIN » d'une colonne.
  OCTETS = MATLIBRE_PARQUET_ENCODER(COLONNE,PHYSIQUE) rend les valeurs
  écrites bout à bout, sans compression ni dictionnaire : c'est
  l'encodage PLAIN, que toute implémentation de Parquet sait lire.

  Les nombres partent en petit-boutien ; les booléens sont tassés à
  raison de huit par octet, bit de poids faible d'abord ; une chaîne
  est précédée de sa longueur sur quatre octets.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     numel(matlibre_parquet_encoder([1 2 3], 5))    % 24 : trois doubles

  Voir aussi PARQUETWRITE, MATLIBRE_PARQUET_DECODER.
```

## `matlibre_parquet_niveaux`

```
MATLIBRE_PARQUET_NIVEAUX Décode les niveaux de définition d'une page.
  NIVEAUX = MATLIBRE_PARQUET_NIVEAUX(OCTETS,LARGEUR,NOMBRE) décode le
  codage hybride « série ou groupes tassés » que Parquet emploie pour
  les niveaux. Un en-tête en varint dit lequel : pair, c'est une valeur
  répétée ; impair, ce sont des groupes de huit valeurs tassées à
  LARGEUR bits, bits de poids faible d'abord.

  Ces niveaux disent, colonne par colonne, quelles lignes portent une
  valeur. Sans eux, on ne saurait pas où sont les trous, et les valeurs
  présentes se retrouveraient décalées.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     % une série de quatre fois la valeur 1 : en-tête 8 (4 << 1), puis 1
     matlibre_parquet_niveaux(uint8([8 1]), 1, 4)'   % [1 1 1 1]

  Voir aussi PARQUETREAD, MATLIBRE_PARQUET_DECODER.
```

## `matlibre_parquet_pied`

```
MATLIBRE_PARQUET_PIED Lit le fichier et en extrait les métadonnées.
  [M,OCTETS] = MATLIBRE_PARQUET_PIED(FICHIER) rend la structure des
  métadonnées, telle que le protocole compact la transporte — champs
  nommés c1, c2, ... d'après leurs identifiants — et tous les octets du
  fichier.

  Un fichier Parquet se lit par la fin : « PAR1 » ferme le fichier,
  précédé de la longueur du pied sur quatre octets, elle-même précédée
  du pied. C'est ce qui permet d'écrire les données avant de savoir où
  elles finiront.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     f = fullfile(tempdir, 'matlibre_pied.parquet');
     parquetwrite(f, table([1; 2]));
     m = matlibre_parquet_pied(f);
     m.c3                            % 2 lignes

  Voir aussi PARQUETREAD, PARQUETINFO.
```

## `matlibre_parquet_textes`

```
MATLIBRE_PARQUET_TEXTES Colonne de texte ramenée à une cellule de chaînes.
  TEXTES = MATLIBRE_PARQUET_TEXTES(COLONNE) accepte une cellule, un
  tableau de chaînes, une matrice de caractères ou une catégorielle, et
  rend une cellule de vecteurs de caractères — une ligne par élément.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_parquet_textes(["a"; "b"])    % {'a', 'b'}

  Voir aussi PARQUETWRITE, MATLIBRE_PARQUET_ENCODER.
```

## `matlibre_parquet_types`

```
MATLIBRE_PARQUET_TYPES Correspondance entre classes MATLAB et types Parquet.
  [P,C,L] = MATLIBRE_PARQUET_TYPES(CLASSE) rend le type physique
  Parquet, le type converti qui le précise, et le nom de la classe à
  restituer à la lecture.

  Parquet n'a que quatre types numériques physiques : INT32, INT64,
  FLOAT et DOUBLE. Les entiers plus étroits s'y rangent en INT32, et
  c'est le type converti — INT_8, UINT_16, ... — qui garde la largeur
  d'origine. Sans lui, un int8 reviendrait en int32 : le fichier serait
  valide, l'aller-retour ne le serait pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [p, c] = matlibre_parquet_types('int8');
     p == 1 && c == 15               % INT32, converti en INT_8

  Voir aussi PARQUETWRITE, PARQUETREAD.
```

## `matlibre_pas_grille`

```
MATLIBRE_PAS_GRILLE La distance typique entre deux points voisins.
  Fonction interne : elle n'existe pas dans MATLAB. QUIVER s'en sert
  pour mettre les flèches à l'échelle, de sorte que la plus longue
  tienne dans une maille sans empiéter sur la voisine.
```

## `matlibre_pdepe_derivee`

_Pas de bloc d'aide._

## `matlibre_plaque_mince`

```
MATLIBRE_PLAQUE_MINCE Interpolation lisse par plaque mince.
  VQ = MATLIBRE_PLAQUE_MINCE(X,Y,V,XQ,YQ) construit la surface qui passe
  par tous les points et minimise l'énergie de flexion d'une plaque
  mince — l'intégrale du carré des dérivées secondes.

  La solution s'écrit comme une somme de fonctions radiales r²log(r),
  plus un plan. Les coefficients sortent d'un système linéaire, avec
  trois conditions d'orthogonalité qui empêchent la partie radiale
  d'absorber le plan.

  Contrairement à l'interpolation par triangles, la surface obtenue est
  lisse partout, et elle s'étend hors de l'enveloppe des données.

  Exemple :
     [x, y] = meshgrid(0:0.5:1, 0:0.5:1);
     z = 2 * x - 3 * y;
     abs(matlibre_plaque_mince(x(:), y(:), z(:), 0.3, 0.7) - (0.6 - 2.1)) < 1e-8

  Voir aussi GRIDDATA, MATLIBRE_GRILLE_LINEAIRE.
```

## `matlibre_poignee_depuis_texte`

```
MATLIBRE_POIGNEE_DEPUIS_TEXTE Une poignée bâtie sur une expression écrite.
  Fonction interne : elle n'existe pas dans MATLAB. EZPLOT, EZSURF et
  EZCONTOUR acceptent leur argument sous forme de chaîne — c'est
  l'usage de ces fonctions anciennes — et cette fonction en fait une
  poignée.

  Les variables sont devinées : « x » seul donne une fonction d'une
  variable, « x » et « y » une fonction de deux. Les opérateurs sont
  vectorisés au passage, de sorte que « x^2 » travaille sur un tableau.
```

## `matlibre_poignee_valide`

```
MATLIBRE_POIGNEE_VALIDE Une poignée désigne-t-elle un objet vivant ?
  T = MATLIBRE_POIGNEE_VALIDE(H) rend vrai si H est une poignée
  graphique dont l'objet existe encore, ou un numéro de figure ouverte.

  La vérification se fait en lisant le type de l'objet : une poignée
  dont la figure a été fermée lève, et c'est cette levée qui répond.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_poignee_valide(gca)    % 1

  Voir aussi ISHANDLE, ISGRAPHICS.
```

## `matlibre_points_utf8`

```
MATLIBRE_POINTS_UTF8 Écriture UTF-8 d'une suite de points de code.
  OCTETS = MATLIBRE_POINTS_UTF8(POINTS) rend la suite d'octets. C'est
  l'inverse exact de MATLIBRE_UTF8_POINTS.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     double(matlibre_points_utf8(233))   % [195 169]

  Voir aussi UNICODE2NATIVE, NATIVE2UNICODE, MATLIBRE_UTF8_POINTS.
```

## `matlibre_poly_aire_signee`

```
MATLIBRE_POLY_AIRE_SIGNEE Aire d'un contour, signe du sens de parcours compris.
  La formule du lacet rend une aire positive pour un contour parcouru
  dans le sens direct et négative dans l'autre. C'est ce signe qui
  distingue un plein d'un trou, sans rien avoir à ajouter à la
  structure.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_poly_aire_signee([0 0; 1 0; 1 1; 0 1])   % +1
     matlibre_poly_aire_signee([0 0; 0 1; 1 1; 1 0])   % -1

  Voir aussi POLYAREA, POLYSHAPE.
```

## `matlibre_poly_assembler`

```
MATLIBRE_POLY_ASSEMBLER Réunit des contours en une liste séparée par des NaN.
  Un contour est orienté dans le sens direct s'il est à profondeur
  paire — dehors, ou dans un trou —, et dans l'autre s'il est à
  profondeur impaire — c'est alors un trou. C'est ainsi qu'un trou se
  distingue d'un plein, et la seule information que porte
  l'orientation.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     V = matlibre_poly_assembler({[0 0; 2 0; 2 2; 0 2]});
     size(V, 1)                      % 4 sommets, aucun NaN

  Voir aussi POLYSHAPE, MATLIBRE_POLY_SEPARER.
```

## `matlibre_poly_booleen`

```
MATLIBRE_POLY_BOOLEEN Opération booléenne entre deux régions.
  Réunit les deux listes de contours, passe au découpage, et rassemble
  le résultat en une région dont les orientations sont refaites.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     a = polyshape([0 2 2 0], [0 0 2 2]);
     b = polyshape([1 3 3 1], [1 1 3 3]);
     abs(area(matlibre_poly_booleen(a, b, 'intersection')) - 1) < 1e-9

  Voir aussi POLYSHAPE, UNION, INTERSECT, SUBTRACT, XOR.
```

## `matlibre_poly_contenu`

```
MATLIBRE_POLY_CONTENU Le contour C est-il à l'intérieur du contour D ?
  Les deux contours ne se coupent pas — c'est le cas dans un POLYSHAPE
  bien formé —, donc il suffit de regarder où tombe un seul sommet de
  C : s'il est dans D, tous le sont.

  On prend un sommet, non le centre de gravité : le centre d'un contour
  extérieur tombe volontiers dans le trou qu'il entoure, ce qui ferait
  croire que le grand est dans le petit. Un sommet, lui, ne ment pas.

  Un sommet posé exactement sur le bord de D ne tranche pas : on passe
  au suivant.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     petit = [4 4; 6 4; 6 6; 4 6];
     grand = [0 0; 10 0; 10 10; 0 10];
     matlibre_poly_contenu(petit, grand)      % 1
     matlibre_poly_contenu(grand, petit)      % 0

  Voir aussi POLYSHAPE, INPOLYGON, MATLIBRE_POLY_ASSEMBLER.
```

## `matlibre_poly_entree`

```
MATLIBRE_POLY_ENTREE Démêle les arguments d'un POLYSHAPE.
  Accepte une matrice à deux colonnes, deux vecteurs de coordonnées, ou
  deux cellules de vecteurs — un contour par élément. Les contours
  séparés par des NaN sont découpés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     c = matlibre_poly_entree({[0 1 1 0], [0 0 1 1]});
     size(c{1})                      % 4 sommets, 2 colonnes

  Voir aussi POLYSHAPE.
```

## `matlibre_poly_enveloppe`

```
MATLIBRE_POLY_ENVELOPPE Indices de l'enveloppe convexe d'un nuage.
  Un simple relais vers CONVHULL. Il existe parce que POLYSHAPE porte
  une méthode du même nom : à l'intérieur de la classe, écrire
  « convhull(x, y) » appellerait la méthode, non la fonction. Passer
  par un nom que la classe ne porte pas lève l'ambiguïté.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     k = matlibre_poly_enveloppe([0 0; 1 0; 1 1; 0 1; 0.5 0.5]);
     numel(k)                        % 5 : quatre coins et le retour

  Voir aussi CONVHULL, POLYSHAPE.
```

## `matlibre_poly_moments`

```
MATLIBRE_POLY_MOMENTS Aire signée et centre de gravité d'un contour.
  Le centre de gravité d'une surface polygonale s'obtient de la même
  somme que son aire : chaque côté contribue par le produit croisé de
  ses deux extrémités, pondéré par leur somme. C'est l'intégrale de x
  sur la surface, ramenée au bord par la formule de Green.

  L'aire rendue garde son signe, ce qui permet à un trou de contribuer
  en négatif et de déplacer le centre du bon côté.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [a, x, y] = matlibre_poly_moments([0 0; 2 0; 2 2; 0 2]);
     abs(a - 4) < 1e-12 && abs(x - 1) < 1e-12 && abs(y - 1) < 1e-12

  Voir aussi CENTROID, POLYAREA, POLYSHAPE.
```

## `matlibre_poly_point_interieur`

```
MATLIBRE_POLY_POINT_INTERIEUR Un point strictement dans un contour.
  Le barycentre des sommets convient pour un contour convexe, mais pas
  pour un contour en croissant, où il peut tomber dehors. On l'essaie,
  et s'il ne va pas, on prend le milieu d'une diagonale qui reste
  dedans — il en existe toujours une.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     p = matlibre_poly_point_interieur([0 0; 2 0; 2 2; 0 2]);
     inpolygon(p(1), p(2), [0 2 2 0], [0 0 2 2])

  Voir aussi INPOLYGON, POLYSHAPE.
```

## `matlibre_poly_separer`

```
MATLIBRE_POLY_SEPARER Découpe une liste de sommets sur les NaN.
  Un NaN sépare deux contours. Les contours de moins de trois sommets
  sont écartés : ils n'enferment rien.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     c = matlibre_poly_separer([0 0; 1 0; 1 1; NaN NaN; 2 2; 3 2; 3 3]);
     numel(c)                        % 2 contours

  Voir aussi POLYSHAPE, MATLIBRE_POLY_ASSEMBLER.
```

## `matlibre_racine_toolbox`

```
MATLIBRE_RACINE_TOOLBOX Dossier qui contient les toolboxes.
  C'est celui que l'interpréteur a trouvé au démarrage ; la variable
  d'environnement MATLIBRE_TOOLBOX le remplace quand elle est posée.
```

## `matlibre_rayon_circonscrit`

```
MATLIBRE_RAYON_CIRCONSCRIT Rayon du cercle circonscrit d'un triangle.
  R = abc / 4A, où a, b et c sont les côtés et A l'aire. Un triangle
  aplati a une aire qui tend vers zéro et donc un rayon qui explose :
  c'est ce qui permet de reconnaître les triangles étirés et de les
  retirer d'une forme alpha.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     r = matlibre_rayon_circonscrit([0 0; 1 0; 0 1]);
     abs(r - sqrt(2)/2) < 1e-12      % le cercle passe par les trois

  Voir aussi BOUNDARY, ALPHASHAPE, CIRCUMCENTER.
```

## `matlibre_seuil_alpha`

```
MATLIBRE_SEUIL_ALPHA Rayon au-delà duquel un triangle est retiré.
  Le serrage S va de zéro — aucun triangle retiré, donc l'enveloppe
  convexe — à un — le contour le plus serré qui enferme encore tous les
  points. Entre les deux, le seuil descend depuis l'infini jusqu'au
  plus grand rayon circonscrit qu'on peut retirer sans perdre un point.

  Le seuil est pris sur les quantiles des rayons circonscrits : c'est ce
  qui rend le réglage indépendant de l'échelle du nuage.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     x = [0 1 1 0]'; y = [0 0 1 1]';
     isinf(matlibre_seuil_alpha(x, y, 0))     % 1 : a zero, rien ne part

  Voir aussi BOUNDARY, ALPHASHAPE.
```

## `matlibre_structure_en_xml`

```
MATLIBRE_STRUCTURE_EN_XML Écrit une valeur en XML, récursivement.
  Un champ dont le nom finit par « Attribute » devient un attribut de
  l'élément qui le porte ; les autres deviennent des éléments enfants.
  Un tableau de structures devient une suite d'éléments frères de même
  nom, ce qui est la façon dont le XML exprime une liste.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     t = matlibre_structure_en_xml(struct('a', 1), 'racine', 0);
     ~isempty(strfind(t, '<a>1</a>'))

  Voir aussi WRITESTRUCT, READSTRUCT.
```

## `matlibre_tall_appliquer`

```
MATLIBRE_TALL_APPLIQUER Applique une fonction après avoir tout matérialisé.
  V = MATLIBRE_TALL_APPLIQUER(F,ARGUMENTS) rend F appliquée aux
  arguments, chacun ramené à sa valeur. C'est le corps de tout calcul
  différé : il n'est exécuté qu'au GATHER.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_tall_appliquer(@plus, {tall(1), 2})   % 3

  Voir aussi TALL, GATHER, MATLIBRE_TALL_VALEUR.
```

## `matlibre_tall_differer`

```
MATLIBRE_TALL_DIFFERER Décrit un calcul sans l'exécuter.
  R = MATLIBRE_TALL_DIFFERER(F,ARGUMENTS) rend un tableau différé qui,
  au GATHER, vaudra F appliquée aux arguments. Rien n'est calculé ici :
  c'est ce qui permet d'enchaîner des opérations puis de ne payer
  qu'une fois.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     r = matlibre_tall_differer(@plus, {tall(1), 2});
     gather(r)                       % 3

  Voir aussi TALL, GATHER, MATLIBRE_TALL_APPLIQUER.
```

## `matlibre_tall_indexer`

```
MATLIBRE_TALL_INDEXER Indexation d'une valeur matérialisée.
  V = MATLIBRE_TALL_INDEXER(VALEUR,I,...) rend VALEUR(I,...). Elle
  existe pour que l'indexation d'un tableau différé soit elle-même
  différée : « t(t > 5) » décrit un filtre, il ne le fait pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_tall_indexer([10 20 30], [3 1])   % [30 10]

  Voir aussi TALL, GATHER.
```

## `matlibre_tall_valeur`

```
MATLIBRE_TALL_VALEUR Valeur d'un argument, différée ou non.
  V = MATLIBRE_TALL_VALEUR(X) rend X tel quel, ou le résultat du calcul
  qu'il décrit si X est un tableau différé. Mêler un tableau différé et
  un tableau ordinaire dans une même opération doit marcher : c'est
  cette fonction qui le permet, en ramenant les deux au même plan au
  moment où l'on calcule enfin.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_tall_valeur(3)                  % 3
     matlibre_tall_valeur(tall([1 2 3]))      % [1 2 3]

  Voir aussi TALL, GATHER, ISTALL.
```

## `matlibre_texte_ou_nombre`

```
MATLIBRE_TEXTE_OU_NOMBRE Convertit un texte en nombre s'il en est un.
  Un texte qui s'écrit entièrement comme un nombre est rendu en nombre ;
  tout autre reste du texte. C'est ce qui permet à un aller-retour par
  WRITESTRUCT et READSTRUCT de rendre les nombres tels qu'on les a
  donnés, sans rien reconvertir à la main.

  La conversion exige que tout le texte soit consommé : « 12abc » reste
  du texte, là où une conversion laxiste rendrait douze.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_texte_ou_nombre('42')       % 42, en nombre
     matlibre_texte_ou_nombre('42abc')    % "42abc", en texte

  Voir aussi READSTRUCT, STR2DOUBLE, STR2NUM.
```

## `matlibre_thrift_dezigzag`

```
MATLIBRE_THRIFT_DEZIGZAG Retour du codage en zigzag.
  N = MATLIBRE_THRIFT_DEZIGZAG(U) annule MATLIBRE_THRIFT_ZIGZAG.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_thrift_dezigzag(matlibre_thrift_zigzag(-7))   % -7

  Voir aussi MATLIBRE_THRIFT_ZIGZAG, MATLIBRE_THRIFT_VARINT.
```

## `matlibre_thrift_lire`

```
MATLIBRE_THRIFT_LIRE Lecture d'une valeur en protocole compact.
  [V,P] = MATLIBRE_THRIFT_LIRE(OCTETS,POSITION,TYPE) rend la valeur lue
  et la position qui suit. Une structure devient une structure MATLAB
  dont les champs se nomment c1, c2, ... d'après les identifiants du
  protocole : le protocole ne transporte pas les noms, seulement les
  numéros, et inventer des noms serait leur prêter un sens qu'ils
  n'ont pas ici.

  TYPE omis vaut 12, celui d'une structure.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     o = matlibre_thrift_structure({{1, 5, matlibre_thrift_varint(2)}});
     s = matlibre_thrift_lire(o, 1);
     s.c1                            % 1

  Voir aussi PARQUETREAD, MATLIBRE_THRIFT_STRUCTURE.
```

## `matlibre_thrift_liste`

```
MATLIBRE_THRIFT_LISTE Écriture d'une liste en protocole compact.
  OCTETS = MATLIBRE_THRIFT_LISTE(TYPE,ELEMENTS) rend l'en-tête de liste
  — le nombre d'éléments et leur type — suivi des éléments, déjà
  écrits. Au-delà de quatorze éléments, le nombre passe en varint après
  l'en-tête.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     double(matlibre_thrift_liste(5, {matlibre_thrift_varint(2)}))

  Voir aussi MATLIBRE_THRIFT_STRUCTURE, PARQUETWRITE.
```

## `matlibre_thrift_structure`

```
MATLIBRE_THRIFT_STRUCTURE Écriture d'une structure en protocole compact.
  OCTETS = MATLIBRE_THRIFT_STRUCTURE(CHAMPS) rend l'écriture d'une
  structure. CHAMPS est une cellule de triplets {identifiant, type,
  charge} donnés dans l'ordre croissant des identifiants : le protocole
  ne code que l'écart au champ précédent, ce qui tient sur un demi-octet
  tant que l'écart ne dépasse pas quinze.

  La charge est déjà écrite : un entier y est un varint en zigzag, une
  chaîne une longueur suivie de ses octets, une structure imbriquée ses
  propres octets, terminaison comprise.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     o = matlibre_thrift_structure({{1, 5, matlibre_thrift_varint(2)}});
     double(o)                       % [21 2 0] : champ 1, i32, valeur 1

  Voir aussi PARQUETWRITE, MATLIBRE_THRIFT_VARINT.
```

## `matlibre_thrift_varint`

```
MATLIBRE_THRIFT_VARINT Entier de longueur variable, sept bits à la fois.
  OCTETS = MATLIBRE_THRIFT_VARINT(N) rend l'écriture de l'entier positif
  N : sept bits de charge par octet, du poids faible au poids fort, le
  bit de tête marquant qu'un octet suit.

  C'est ce qui rend l'en-tête d'un fichier Parquet compact : les petits
  nombres — et ils le sont presque tous — tiennent sur un octet.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     double(matlibre_thrift_varint(1))     % 1
     double(matlibre_thrift_varint(300))   % [172 2]

  Voir aussi PARQUETWRITE, PARQUETREAD, MATLIBRE_THRIFT_ZIGZAG.
```

## `matlibre_thrift_zigzag`

```
MATLIBRE_THRIFT_ZIGZAG Entier signé ramené aux entiers positifs.
  U = MATLIBRE_THRIFT_ZIGZAG(N) rend 2*N pour N positif et -2*N-1 pour N
  négatif : les petits nombres restent petits des deux côtés de zéro,
  ce qu'un simple complément à deux ne donnerait pas — -1 y tiendrait
  sur dix octets de varint.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_thrift_zigzag(0)       % 0
     matlibre_thrift_zigzag(-1)      % 1
     matlibre_thrift_zigzag(1)       % 2

  Voir aussi MATLIBRE_THRIFT_VARINT, MATLIBRE_THRIFT_DEZIGZAG.
```

## `matlibre_tri_aretes`

```
MATLIBRE_TRI_ARETES Les faces de chaque élément, une ligne par face.
  Pour un triangle, la face opposée au sommet J est l'arête formée par
  les deux autres ; pour un tétraèdre, c'est le triangle des trois
  autres. Les faces sont rangées élément par élément, dans l'ordre des
  sommets opposés — ce qui fait correspondre la ligne K de la sortie à
  la colonne de NEIGHBORS.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     A = matlibre_tri_aretes([1 2 3]);
     size(A)                         % 3 aretes de 2 sommets

  Voir aussi TRIANGULATION, FREEBOUNDARY.
```

## `matlibre_tri_centres`

```
MATLIBRE_TRI_CENTRES Centre circonscrit ou inscrit de chaque triangle.
  Le centre circonscrit est équidistant des trois sommets : il se
  trouve en résolvant les deux équations de médiatrice. Le centre
  inscrit est équidistant des trois côtés : c'est le barycentre des
  sommets pondérés par les longueurs des côtés opposés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     tr = triangulation([1 2 3], [0 0; 1 0; 0 1]);
     c = matlibre_tri_centres(tr, 1, 'circonscrit');
     max(abs(c - [0.5 0.5])) < 1e-12

  Voir aussi TRIANGULATION, CIRCUMCENTER, INCENTER.
```

## `matlibre_triangles_alpha`

```
MATLIBRE_TRIANGLES_ALPHA Triangles de Delaunay assez ramassés pour être gardés.
  Un triangle est gardé si le rayon de son cercle circonscrit ne dépasse
  pas le seuil. Un triangle étiré a un grand rayon : c'est exactement
  celui qui relie deux amas éloignés, et le retirer creuse la forme.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     T = matlibre_triangles_alpha([0 1 1 0]', [0 0 1 1]', inf);
     size(T, 1)                      % 2 : le carre fait deux triangles

  Voir aussi ALPHASHAPE, BOUNDARY, DELAUNAY.
```

## `matlibre_url_encoder`

```
MATLIBRE_URL_ENCODER Encodage d'une valeur pour une adresse.
  T = MATLIBRE_URL_ENCODER(TEXTE) remplace par %XX tout ce qui n'est ni
  lettre, ni chiffre, ni l'un des caractères sûrs « -_.~ ».

  Sans cela, un espace ou une esperluette dans une valeur couperait la
  requête en deux : l'encodage n'est pas une politesse, c'est ce qui
  sépare la donnée de la syntaxe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_url_encoder('un chat&')   % 'un%20chat%26'

  Voir aussi WEBSAVE, WEBREAD, WEBWRITE.
```

## `matlibre_utf8_points`

```
MATLIBRE_UTF8_POINTS Points de code d'une suite d'octets UTF-8.
  POINTS = MATLIBRE_UTF8_POINTS(OCTETS) rend les points de code que la
  suite représente. Un octet de tête dit combien d'octets suivent :
  moins de 128 pour un caractère seul, 110xxxxx pour deux, 1110xxxx
  pour trois, 11110xxx pour quatre.

  Une suite mal formée est refusée plutôt que devinée : un octet de
  continuation orphelin ne désigne aucun caractère, et lui en prêter un
  ferait passer une donnée corrompue pour du texte.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_utf8_points(uint8([195 169]))   % 233, la lettre e accentuee

  Voir aussi UNICODE2NATIVE, NATIVE2UNICODE, MATLIBRE_POINTS_UTF8.
```

## `matlibre_valider`

```
MATLIBRE_VALIDER Lève l'erreur d'un validateur quand la condition échoue.
  Les fonctions MUSTBE... ne rendent rien : elles se taisent quand tout
  va bien et lèvent une erreur sinon. C'est ce contrat que cette
  fonction tient, avec l'identifiant que MATLAB emploie.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_valider(true, 'MATLAB:essai', 'jamais vu');

  Voir aussi MUSTBENUMERIC, MUSTBEPOSITIVE, VALIDATEATTRIBUTES.
```

## `matlibre_web_contenu`

```
MATLIBRE_WEB_CONTENU Interprétation du corps d'une réponse web.
  C = MATLIBRE_WEB_CONTENU(TEXTE,URL) rend le contenu décodé : un
  document JSON devient structure ou cellule, un fichier délimité
  devient une matrice, le reste reste du texte.

  C = MATLIBRE_WEB_CONTENU(TEXTE,URL,TYPE) impose l'interprétation :
  'auto' devine, 'json' décode, 'text' et 'raw' rendent le texte tel
  quel.

  Sans en-tête à notre disposition, « deviner » se règle sur
  l'extension de l'adresse et sur la forme du texte lui-même : c'est
  moins sûr qu'un Content-Type, et c'est pourquoi 'ContentType' existe.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_web_contenu('{"a":1}', 'http://x/y.json').a   % 1

  Voir aussi WEBREAD, WEBWRITE, WEBSAVE, JSONDECODE.
```

## `matlibre_web_corps`

```
MATLIBRE_WEB_CORPS Corps d'une requête, et le type qui le déclare.
  [CORPS,TYPE] = MATLIBRE_WEB_CORPS(DONNEES,REGLAGES) rend le texte à
  envoyer et le type de média à déclarer. Des couples nom/valeur
  partent comme un formulaire ; un texte part tel quel ; une structure
  ou une cellule part en JSON.

  'MediaType' des réglages l'emporte : un type mentionnant JSON force
  l'encodage JSON même sur des couples, car déclarer un type et en
  envoyer un autre est la faute la plus coûteuse à diagnostiquer.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [c, t] = matlibre_web_corps({'a', 1, 'b', 'x y'}, weboptions());
     c                               % 'a=1&b=x%20y'

  Voir aussi WEBWRITE, WEBOPTIONS, JSONENCODE.
```

## `matlibre_web_curl`

```
MATLIBRE_WEB_CURL Une requête web, menée par curl.
  MATLIBRE_WEB_CURL(URL,FICHIER,REGLAGES) télécharge URL dans FICHIER.
  REGLAGES est ce que rend WEBOPTIONS ; vide, ce sont les réglages par
  défaut. MATLIBRE_WEB_CURL(URL,FICHIER,REGLAGES,METHODE,CORPS,TYPE)
  envoie en plus le contenu du fichier CORPS, avec le type déclaré
  TYPE et la méthode METHODE.

  Rassembler ici la construction de la commande sert à ce que WEBSAVE
  et WEBWRITE obéissent aux mêmes réglages : un délai, un agent, une
  authentification ou un en-tête posés une fois valent pour les deux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     o = weboptions('Timeout', 30, 'UserAgent', 'MatLibre');
     o.Timeout                       % 30 : le delai passe a curl

  Voir aussi WEBSAVE, WEBREAD, WEBWRITE, WEBOPTIONS.
```

## `matlibre_web_reglages`

```
MATLIBRE_WEB_REGLAGES Sépare un objet WEBOPTIONS du reste des arguments.
  [R,RESTE] = MATLIBRE_WEB_REGLAGES(ARGUMENTS) rend les réglages, ceux
  par défaut s'il n'y en avait pas, et les autres arguments.

  MATLAB reconnaît l'objet à sa classe ; ici les réglages sont une
  structure, et c'est la présence conjointe des champs que WEBOPTIONS
  pose qui les distingue d'une structure de données à envoyer.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [r, reste] = matlibre_web_reglages({'q', 'chat', weboptions('Timeout', 9)});
     r.Timeout                       % 9
     numel(reste)                    % 2 : le couple q/chat

  Voir aussi WEBOPTIONS, WEBSAVE, WEBREAD, WEBWRITE.
```

## `matlibre_web_requete`

```
MATLIBRE_WEB_REQUETE Ajoute des paramètres à la partie requête d'une adresse.
  U = MATLIBRE_WEB_REQUETE(URL,PAIRES) rend l'adresse suivie de
  « ?nom=valeur&... », les valeurs étant encodées. Si l'adresse a déjà
  une requête, les paramètres s'y ajoutent avec « & ».

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_web_requete('http://x', {'q', 'un chat'})

  Voir aussi WEBSAVE, WEBREAD, WEBWRITE.
```

## `matlibre_xml_analyser`

```
MATLIBRE_XML_ANALYSER Arbre d'un document XML.
  Le nœud rendu porte les champs Name, Attributes, Children et Text.
  L'analyse est descendante : on lit les balises dans l'ordre, on
  empile à l'ouverture et l'on dépile à la fermeture, en vérifiant que
  le nom concorde — un document mal fermé est refusé, non deviné.

  Ce qui n'est pas traité : les entités autres que les cinq
  prédéfinies, les espaces de noms, les définitions de type. Une balise
  de traitement — la déclaration en tête — et un commentaire sont
  sautés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     n = matlibre_xml_analyser('<a><b>1</b></a>');
     n.Name                          % 'a'
     numel(n.Children)               % 1

  Voir aussi READSTRUCT, XMLREAD.
```

## `matlibre_xml_balise`

```
MATLIBRE_XML_BALISE Nom et attributs d'une balise ouvrante.
  Les attributs sont rendus dans une structure : un champ par attribut,
  sa valeur étant le texte entre guillemets, déjà déséchappé.

  La valeur peut être entourée de guillemets ou d'apostrophes : le XML
  accepte les deux, et le délimiteur choisi permet d'écrire l'autre tel
  quel à l'intérieur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [n, a] = matlibre_xml_balise('point x="1" y="2"');
     n                               % 'point'
     a.x                             % '1'

  Voir aussi MATLIBRE_XML_ANALYSER, READSTRUCT.
```

## `matlibre_xml_desechapper`

```
MATLIBRE_XML_DESECHAPPER Rend leur forme aux caractères protégés du XML.
  L'inverse de MATLIBRE_XML_ECHAPPER. L'esperluette se traite en
  dernier, symétriquement : la traiter d'abord transformerait
  « &amp;lt; » en « &lt; », puis en « < », ce qui n'est pas le texte de
  départ.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_xml_desechapper('a&lt;b &amp; c')     % 'a<b & c'

  Voir aussi READSTRUCT, XMLREAD, MATLIBRE_XML_ECHAPPER.
```

## `matlibre_xml_echapper`

```
MATLIBRE_XML_ECHAPPER Protège les caractères réservés du XML.
  Cinq caractères ne peuvent pas s'écrire tels quels dans du XML :
  l'esperluette, les deux chevrons, l'apostrophe et le guillemet.
  L'esperluette se traite en premier, sans quoi on échapperait les
  esperluettes qu'on vient d'introduire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_xml_echapper('a<b & c')      % 'a&lt;b &amp; c'

  Voir aussi WRITESTRUCT, XMLWRITE, MATLIBRE_XML_DESECHAPPER.
```

## `matlibre_xml_ecrire`

```
MATLIBRE_XML_ECRIRE Écrit un arbre XML, récursivement.
  Un élément sans enfant ni texte s'écrit en balise seule ; un élément
  qui ne porte que du texte tient sur une ligne ; les autres ouvrent un
  bloc indenté. C'est la forme que produit un éditeur XML, et celle qui
  se relit le mieux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     t = matlibre_xml_ecrire(matlibre_xml_analyser('<a>1</a>'), 0);
     ~isempty(strfind(t, '<a>1</a>'))

  Voir aussi XMLWRITE, XMLREAD.
```

## `matlibre_xml_en_structure`

```
MATLIBRE_XML_EN_STRUCTURE Convertit un arbre XML en structure.
  Un élément sans enfant ni attribut devient son texte, converti en
  nombre s'il en est un. Sinon, il devient une structure : un champ par
  enfant, et un champ « nomAttribute » par attribut.

  Des frères de même nom deviennent un tableau de structures — ou une
  cellule quand leurs formes diffèrent —, ce qui est la façon dont le
  XML exprime une liste.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     s = matlibre_xml_en_structure(matlibre_xml_analyser('<a><b>1</b></a>'));
     s.b                             % 1

  Voir aussi READSTRUCT, MATLIBRE_XML_ANALYSER.
```

## `maxk`

```
MAXK Les K plus grands éléments.
  B = MAXK(A,K) rend les K plus grands éléments, en ordre décroissant.
  Pour une matrice, l'opération se fait colonne par colonne.
  B = MAXK(A,K,DIM) opère le long de la dimension DIM.
  [B,I] = MAXK(...) rend en outre leurs indices.

  Si K dépasse le nombre d'éléments, tous sont rendus.

  C'est SORT suivi d'une troncature, et c'est ainsi qu'on l'écrit ici ;
  l'intérêt du nom est de dire l'intention — on ne veut pas l'ordre
  complet, seulement le sommet.

  Exemple :
     maxk([3 1 4 1 5], 2)                % 5 4
     [b, i] = maxk([3 1 4 1 5], 2);
     i                                   % 5 3
     maxk([1 2; 3 4], 1)                 % 3 4 : par colonne

  Voir aussi MINK, SORT, TOPKROWS, MAX.
```

## `memoize`

```
MEMOIZE Garde les résultats d'une fonction.
  MF = MEMOIZE(F) rend un objet qui s'appelle comme F mais retient ce
  qu'il a déjà calculé : le même jeu d'arguments n'est calculé qu'une
  fois. C'est utile pour une fonction lente et pure — dont le résultat
  ne dépend que de ses arguments.

  Sur l'objet rendu :
     MF.Enabled     mettre à false pour recalculer chaque fois
     MF.CacheSize   nombre de jeux d'arguments retenus (10 par défaut)
     clearCache(MF) vide le cache
     stats(MF)      compte les appels, les trouvailles et les calculs

  Exemple :
     lent = @(n) sum(primes(n));
     rapide = memoize(lent);
     rapide(100000);      % calculé
     rapide(100000);      % retrouvé

  Voir aussi FUNCTION_HANDLE, CONTAINERS.MAP, TIC, TOC.
```

## `meshc`

```
MESHC Maillage d'une surface, avec ses lignes de niveau en dessous.
  MESHC(X,Y,Z) trace le maillage de la surface et, dans le plan du bas,
  ses lignes de niveau. MESHC(Z) prend une grille entière.

  H = MESHC(...) rend les poignées.

  Le rendu de MatLibre est plan : la surface est montrée en couleurs,
  et les lignes de niveau par-dessus, ce qui met exactement la même
  information sous les yeux.

  Exemples :
     meshc(peaks(30));
     [X, Y] = meshgrid(-2:0.2:2);
     meshc(X, Y, X .* exp(-X.^2 - Y.^2));

  Voir aussi MESH, SURFC, CONTOUR, MESHZ, PEAKS.
```

## `meshz`

```
MESHZ Maillage d'une surface, avec un rideau sur les bords.
  MESHZ(X,Y,Z) trace le maillage et y ajoute, sur tout le pourtour, un
  rideau vertical qui descend jusqu'au plan du bas. C'est ce qui fait
  qu'une surface ne paraît pas flotter.

  MESHZ(Z) prend une grille entière.

  H = MESHZ(...) rend la poignée.

  Le rendu de MatLibre est plan : le rideau ne se voit pas, et MESHZ
  donne la même image que MESH.

  Exemples :
     meshz(peaks(30));

  Voir aussi MESH, MESHC, SURF, WATERFALL.
```

## `mink`

```
MINK Les K plus petits éléments.
  B = MINK(A,K) rend les K plus petits éléments, en ordre croissant.
  Pour une matrice, l'opération se fait colonne par colonne.
  B = MINK(A,K,DIM) opère le long de la dimension DIM.
  [B,I] = MINK(...) rend en outre leurs indices.

  Exemple :
     mink([3 1 4 1 5], 2)                % 1 1
     [b, i] = mink([3 1 4 1 5], 2);
     i                                   % 2 4
     isequal(mink([3 1 4], 3), sort([3 1 4]))     % 1

  Voir aussi MAXK, SORT, TOPKROWS, MIN.
```

## `minres`

```
MINRES Résolution itérative par méthode de Krylov.
  X = MINRES(A,B) résout A*X = B. X = MINRES(A,B,TOL,MAXIT) impose la
  tolérance relative — 1e-6 par défaut — et le nombre maximal
  d'itérations. X = MINRES(A,B,TOL,MAXIT,M1,M2,X0) ajoute un
  préconditionneur et un point de départ. A peut être une poignée de
  fonction rendant A*x.

  [X,DRAPEAU,RES,K,RESIDUS] = MINRES(...) rend le drapeau de sortie, le
  résidu relatif, le nombre d'itérations et leur historique.

  Contrairement à PCG, la matrice n'a pas à être définie positive : ces
  méthodes valent pour un système quelconque. Le prix est la garantie —
  le gradient conjugué converge de façon monotone en norme A, celles-ci
  peuvent stagner ou osciller.

  Exemple :
     A = [4 1 0; 1 3 1; 0 1 2];
     b = [1; 2; 3];
     x = minres(A, b, 1e-10, 50);
     norm(A * x - b) / norm(b) < 1e-9

  Voir aussi PCG, GMRES, MINRES, BICG, MLDIVIDE.
```

## `months`

```
MONTHS Nombre de mois entre deux dates.
  N = MONTHS(D1,D2) rend le nombre de mois entiers écoulés de D1 à D2.
  Il est négatif quand D2 précède D1.

  N = MONTHS(D1,D2,0) ne compte un mois que si le jour du mois de D2
  atteint celui de D1 ; avec 1, valeur par défaut, deux dates en fin de
  mois comptent un mois plein.

  Exemple :
     months('31-mar-2024', '30-apr-2024')     % 1

  Voir aussi CALMONTHS, BETWEEN, DAYSACT, DATENUM.
```

## `movie`

```
MOVIE Rejoue une animation (acceptée, sans effet).
  MOVIE(F) rejoue, dans MATLAB, les vues capturées par GETFRAME.
  MOVIE(F,N) la rejoue N fois ; MOVIE(F,N,FPS) fixe la cadence.

  Les figures de MatLibre sont rendues une fois pour toutes, et non
  animées : l'appel est accepté pour qu'un programme tourne sans
  retouche, et ne joue rien. La dernière vue reste affichée, ce qui est
  ce qu'une animation laisse quand on l'imprime.

  Exemple :
     for k = 1:10
         plot(sin((1:100) / 10 + k));
         F(k) = getframe;
     end
     movie(F, 2);          % accepte, sans effet

  Voir aussi GETFRAME, COMET, DRAWNOW, ANIMATEDLINE.
```

## `movmad`

```
MOVMAD Écart absolu médian glissant.
  Y = MOVMAD(X,K) rend, pour chaque point, l'écart absolu médian sur une
  fenêtre de K points centrée sur lui. Aux bords, la fenêtre se réduit à
  ce qui existe.
  Y = MOVMAD(X,[AVANT APRES]) donne une fenêtre asymétrique : AVANT
  points en arrière et APRES en avant.
  Y = MOVMAD(...,'Endpoints','discard') n'écrit que les points dont la
  fenêtre est entière ; la série rendue est alors plus courte.

  L'écart absolu médian est à l'écart type ce que la médiane est à la
  moyenne : il ne bouge pas quand une valeur isolée s'éloigne. Son point
  de rupture est de cinquante pour cent — il faut fausser la moitié des
  données pour le fausser — là où une seule valeur suffit à emporter
  l'écart type.

  Il vaut 0,6745 fois l'écart type sur des données gaussiennes ; c'est
  l'inverse de ce facteur, 1,4826, qui sert à le convertir quand on veut
  comparer les deux.

  Exemple :
     movmad([1 1 1 10 1 1 1], 3)     % la valeur aberrante ne perturbe
                                     % que trois points
     movmad(1:10, 3)                 % 1 partout au centre

  Voir aussi MOVMEAN, MOVMEDIAN, MOVSTD, MAD, ISOUTLIER.
```

## `mustBeA`

```
MUSTBEA Exige une valeur d'une classe donnée.
  MUSTBEA(A,CLASSE) lève une erreur si A n'est pas de la classe nommée,
  ni d'une classe qui en dérive. CLASSE peut être une cellule de
  plusieurs, et il suffit alors d'en satisfaire une.

  Le contrôle passe par ISA, donc l'héritage compte : une sous-classe
  satisfait le validateur de sa classe mère. C'est ce qu'on veut d'un
  contrôle de type, et ce qui le sépare d'une comparaison de CLASS.

  Exemple :
     mustBeA(3, 'double');                    % passe
     mustBeA(int8(3), {'int8', 'int16'});     % passe

  Voir aussi ISA, CLASS, MUSTBENUMERIC, VALIDATEATTRIBUTES.
```

## `mustBeFinite`

```
MUSTBEFINITE Exige des valeurs finies.
  MUSTBEFINITE(A) lève une erreur si A contient un infini ou un NaN.

  Exemple :
     mustBeFinite([1 2 3]);         % passe
     mustBeFinite(0);               % passe

  Voir aussi MUSTBENONNAN, MUSTBEREAL, ISFINITE.
```

## `mustBeGreaterThan`

```
MUSTBEGREATERTHAN Exige une valeur strictement supérieure à une borne.
  MUSTBEGREATERTHAN(A,BORNE) lève une erreur si un élément de A ne l'est pas.
  La comparaison se fait terme à terme, et un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeGreaterThan(3, 1);       % passe
     mustBeGreaterThan([2 5], 1);   % passe

  Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
```

## `mustBeGreaterThanOrEqual`

```
MUSTBEGREATERTHANOREQUAL Exige une valeur supérieure ou égale à une borne.
  MUSTBEGREATERTHANOREQUAL(A,BORNE) lève une erreur si un élément de A ne l'est pas.
  La comparaison se fait terme à terme, et un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeGreaterThanOrEqual(1, 1);      % passe : l'egalite est admise
     mustBeGreaterThanOrEqual([1 2], 1);

  Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
```

## `mustBeInRange`

```
MUSTBEINRANGE Exige une valeur dans un intervalle.
  MUSTBEINRANGE(A,BAS,HAUT) refuse tout élément hors de [BAS,HAUT],
  bornes comprises.
  MUSTBEINRANGE(A,BAS,HAUT,'exclude-lower') ouvre la borne basse ;
  'exclude-upper' ouvre la haute ; 'exclusive' ouvre les deux.

  Le choix des bornes ouvertes ou fermées n'est pas un détail : une
  probabilité vit dans [0,1] fermé, un taux d'apprentissage dans ]0,1[
  ouvert — zéro n'apprend rien et un diverge.

  Exemple :
     mustBeInRange(0.5, 0, 1);                        % passe
     mustBeInRange(0, 0, 1);                          % passe : borne fermee
     mustBeInRange(0.5, 0, 1, 'exclusive');           % passe

  Voir aussi MUSTBEGREATERTHAN, MUSTBELESSTHAN, MUSTBEPOSITIVE.
```

## `mustBeInteger`

```
MUSTBEINTEGER Exige des valeurs entières.
  MUSTBEINTEGER(A) lève une erreur si un élément de A n'est pas un
  entier. Le contrôle porte sur la valeur, non sur la classe : 3 en
  double passe, 3,5 non.

  Un NaN ou un infini est refusé : ni l'un ni l'autre n'est un entier.

  Exemple :
     mustBeInteger(3);              % passe, bien que ce soit un double
     mustBeInteger([1 2 3]);        % passe
     mustBeInteger(int8(5));        % passe

  Voir aussi MUSTBEPOSITIVE, MUSTBEFINITE, ROUND, ISINTEGER.
```

## `mustBeLessThan`

```
MUSTBELESSTHAN Exige une valeur strictement inférieure à une borne.
  MUSTBELESSTHAN(A,BORNE) lève une erreur si un élément de A ne l'est pas.
  La comparaison se fait terme à terme, et un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeLessThan(0, 1);          % passe
     mustBeLessThan([-1 0], 1);     % passe

  Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
```

## `mustBeLessThanOrEqual`

```
MUSTBELESSTHANOREQUAL Exige une valeur inférieure ou égale à une borne.
  MUSTBELESSTHANOREQUAL(A,BORNE) lève une erreur si un élément de A ne l'est pas.
  La comparaison se fait terme à terme, et un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeLessThanOrEqual(1, 1);         % passe : l'egalite est admise
     mustBeLessThanOrEqual([0 1], 1);

  Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
```

## `mustBeMember`

```
MUSTBEMEMBER Exige une valeur prise dans un ensemble.
  MUSTBEMEMBER(A,ENSEMBLE) lève une erreur si un élément de A n'est pas
  dans ENSEMBLE. C'est le validateur des paramètres à choix fermé — un
  nom de méthode, un mode, une unité.

  Le message nomme les valeurs admises : c'est la moitié de son utilité,
  puisqu'il évite d'aller lire le code pour savoir quoi écrire.

  Exemple :
     mustBeMember('linear', {'linear', 'cubic'});     % passe
     mustBeMember([1 2], [1 2 3]);                    % passe

  Voir aussi ISMEMBER, VALIDATESTRING, MUSTBETEXT.
```

## `mustBeNegative`

```
MUSTBENEGATIVE Exige une valeur strictement négative.
  MUSTBENEGATIVE(A) lève une erreur si un seul élément de A ne l'est pas.
  Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeNegative(-3);            % passe
     mustBeNegative([-1 -2]);       % passe

  Voir aussi MUSTBENONPOSITIVE, MUSTBEPOSITIVE, VALIDATEATTRIBUTES.
```

## `mustBeNonNan`

```
MUSTBENONNAN Refuse les valeurs manquantes.
  MUSTBENONNAN(A) lève une erreur si A contient un NaN. Un infini passe,
  à la différence de MUSTBEFINITE : l'infini est une valeur, le NaN est
  l'absence de valeur.

  Exemple :
     mustBeNonNan([1 Inf 3]);       % passe : l'infini est une valeur
     mustBeNonNan(0);               % passe

  Voir aussi MUSTBEFINITE, ISNAN, ISMISSING.
```

## `mustBeNonempty`

```
MUSTBENONEMPTY Refuse une valeur vide.
  MUSTBENONEMPTY(A) lève une erreur si A est vide.

  Exemple :
     mustBeNonempty([1 2]);         % passe
     mustBeNonempty('a');           % passe

  Voir aussi MUSTBEVECTOR, ISEMPTY, MUSTBENUMERIC.
```

## `mustBeNonnegative`

```
MUSTBENONNEGATIVE Exige une valeur positive ou nulle.
  MUSTBENONNEGATIVE(A) lève une erreur si un seul élément de A ne l'est pas.
  Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeNonnegative(0);          % passe : zero est admis
     mustBeNonnegative([0 1 2]);    % passe

  Voir aussi MUSTBEPOSITIVE, MUSTBENONPOSITIVE, VALIDATEATTRIBUTES.
```

## `mustBeNonpositive`

```
MUSTBENONPOSITIVE Exige une valeur négative ou nulle.
  MUSTBENONPOSITIVE(A) lève une erreur si un seul élément de A ne l'est pas.
  Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeNonpositive(0);          % passe : zero est admis
     mustBeNonpositive([-1 0]);     % passe

  Voir aussi MUSTBENEGATIVE, MUSTBENONNEGATIVE, VALIDATEATTRIBUTES.
```

## `mustBeNonzero`

```
MUSTBENONZERO Exige une valeur non nulle.
  MUSTBENONZERO(A) lève une erreur si un seul élément de A ne l'est pas.
  Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBeNonzero(3);              % passe
     mustBeNonzero([-1 1]);         % passe

  Voir aussi MUSTBEPOSITIVE, MUSTBENONEMPTY, VALIDATEATTRIBUTES.
```

## `mustBeNonzeroLengthText`

```
MUSTBENONZEROLENGTHTEXT Exige du texte non vide.
  MUSTBENONZEROLENGTHTEXT(A) refuse la chaîne vide, qui passe pourtant
  MUSTBETEXT : une chaîne vide est du texte, elle n'est simplement pas
  utilisable comme nom, comme motif ou comme clé.

  Exemple :
     mustBeNonzeroLengthText('abc');    % passe
     mustBeNonzeroLengthText({'a'});    % passe

  Voir aussi MUSTBETEXT, MUSTBETEXTSCALAR, ISEMPTY.
```

## `mustBeNumeric`

```
MUSTBENUMERIC Exige une valeur numérique.
  MUSTBENUMERIC(A) ne fait rien si A est numérique, et lève une erreur
  sinon. Un logique n'est pas numérique ici : MUSTBENUMERICORLOGICAL
  existe pour l'accepter.

  Les validateurs ne rendent rien. C'est leur contrat : ils se taisent
  quand tout va bien, et l'appelant n'a donc rien à tester. Ils servent
  dans un bloc « arguments », où le nom du validateur suit le nom du
  paramètre.

  Exemple :
     mustBeNumeric(3);              % passe
     mustBeNumeric([1 2; 3 4]);     % passe aussi

  Voir aussi MUSTBEREAL, MUSTBEFINITE, MUSTBEINTEGER, VALIDATEATTRIBUTES.
```

## `mustBeNumericOrLogical`

```
MUSTBENUMERICORLOGICAL Exige une valeur numérique ou logique.
  MUSTBENUMERICORLOGICAL(A) accepte ce qu'accepte MUSTBENUMERIC, plus
  les tableaux logiques.

  La distinction compte : un logique se comporte comme un numérique dans
  presque tous les calculs, mais pas dans l'indexation, où il désigne des
  positions au lieu de valoir des rangs.

  Exemple :
     mustBeNumericOrLogical(true);      % passe
     mustBeNumericOrLogical(3);         % passe

  Voir aussi MUSTBENUMERIC, MUSTBEREAL, ISLOGICAL.
```

## `mustBePositive`

```
MUSTBEPOSITIVE Exige une valeur strictement positive.
  MUSTBEPOSITIVE(A) lève une erreur si un seul élément de A ne l'est pas.
  Le contrôle porte sur tous les éléments : un tableau ne passe que s'il
  passe entièrement.

  Exemple :
     mustBePositive(3);             % passe
     mustBePositive([1 2 3]);       % passe

  Voir aussi MUSTBENONNEGATIVE, MUSTBENEGATIVE, MUSTBENONZERO, VALIDATEATTRIBUTES.
```

## `mustBeReal`

```
MUSTBEREAL Exige une valeur réelle.
  MUSTBEREAL(A) lève une erreur si A a une partie imaginaire non nulle.

  Un complexe dont la partie imaginaire est exactement nulle passe :
  c'est ISREAL qui décide, et il regarde le stockage, non la valeur.

  Exemple :
     mustBeReal(3);                 % passe
     mustBeReal([1 2 3]);           % passe

  Voir aussi MUSTBENUMERIC, MUSTBEFINITE, ISREAL, COMPLEX.
```

## `mustBeScalarOrEmpty`

```
MUSTBESCALAROREMPTY Exige un scalaire ou un vide.
  MUSTBESCALAROREMPTY(A) accepte un seul élément ou aucun, et refuse
  deux ou davantage.

  C'est le validateur d'un paramètre facultatif : vide veut dire « non
  fourni », et une seule valeur veut dire « celle-ci ».

  Exemple :
     mustBeScalarOrEmpty(3);        % passe
     mustBeScalarOrEmpty([]);       % passe

  Voir aussi MUSTBEVECTOR, MUSTBENONEMPTY, ISSCALAR, ISEMPTY.
```

## `mustBeText`

```
MUSTBETEXT Exige du texte.
  MUSTBETEXT(A) accepte un tableau de caractères, un tableau string ou
  une cellule de textes, et refuse tout le reste.

  Les trois formes du texte en MATLAB se valent ici : c'est justement
  l'intérêt du validateur, qui laisse l'appelant écrire 'abc', "abc" ou
  {'abc'} sans que la fonction ait à s'en soucier.

  Exemple :
     mustBeText('abc');             % passe
     mustBeText({'a', 'b'});        % passe

  Voir aussi MUSTBETEXTSCALAR, MUSTBEMEMBER, ISCELLSTR, ISSTRING.
```

## `mustBeTextScalar`

```
MUSTBETEXTSCALAR Exige un seul texte.
  MUSTBETEXTSCALAR(A) accepte une ligne de caractères, une string
  scalaire ou une cellule d'un seul texte, et refuse un tableau de
  plusieurs.

  Exemple :
     mustBeTextScalar('abc');       % passe
     mustBeTextScalar({'abc'});     % passe

  Voir aussi MUSTBETEXT, MUSTBENONZEROLENGTHTEXT, ISSCALAR.
```

## `mustBeVector`

```
MUSTBEVECTOR Exige un vecteur.
  MUSTBEVECTOR(A) refuse une matrice et un tableau vide.
  MUSTBEVECTOR(A,'allow-all-empties') accepte un vide.

  Un scalaire est un vecteur : c'est la convention de MATLAB, et elle
  évite d'avoir à traiter à part le cas d'un seul élément.

  Exemple :
     mustBeVector([1 2 3]);         % passe
     mustBeVector(5);               % passe : un scalaire est un vecteur

  Voir aussi MUSTBESCALAROREMPTY, MUSTBENONEMPTY, ISVECTOR, ISSCALAR.
```

## `namelengthmax`

```
NAMELENGTHMAX Longueur maximale d'un nom.
  N = NAMELENGTHMAX rend le nombre de caractères qu'un nom de
  variable, de fonction ou de champ peut compter.

  Exemple :
     namelengthmax()             % 63 : la longueur maximale d'un nom

  Voir aussi ISVARNAME, GENVARNAME.
```

## `native2unicode`

```
NATIVE2UNICODE Convertit des octets en texte.
  T = NATIVE2UNICODE(B) interprète les octets B dans l'encodage par
  défaut, qui est ici UTF-8. T = NATIVE2UNICODE(B,ENCODAGE) choisit
  l'encodage : 'UTF-8', 'US-ASCII' ou 'ISO-8859-1'.

  C'est l'inverse d'UNICODE2NATIVE : lire un fichier avec FREAD donne
  des octets, et c'est ici qu'ils redeviennent du texte.

  Exemple :
     native2unicode(uint8([97 98 99]))                 % 'abc'
     double(native2unicode(uint8(233), 'ISO-8859-1'))  % [195 169] : e accentue

  Voir aussi UNICODE2NATIVE, CHAR, FREAD.
```

## `newplot`

```
NEWPLOT Prépare l'axe courant à recevoir un nouveau tracé.
  H = NEWPLOT rend l'axe courant après l'avoir effacé, sauf si HOLD est
  actif — auquel cas il le rend tel quel. C'est ce que fait toute
  fonction de tracé avant de dessiner ; on l'appelle quand on en écrit
  une soi-même, pour qu'elle respecte HOLD comme les autres.

  Exemple :
     function monTrace(x, y)
         newplot;
         line(x, y);
         line(x, -y);
     end

  Voir aussi HOLD, CLA, GCA, CLF, LINE.
```

## `nextpow2`

```
NEXTPOW2 Exposant de la puissance de deux immédiatement supérieure.
  P = NEXTPOW2(N) rend le plus petit entier P tel que 2^P >= abs(N).
  Pour un tableau, le calcul se fait élément par élément.

  Exemple :
     nextpow2(1000)   % 10

  Voir aussi POW2.
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

## `normest`

```
NORMEST Estime la norme spectrale par la méthode de la puissance.
  N = NORMEST(A) estime la plus grande valeur singulière de A à 1e-6
  près. N = NORMEST(A,TOL) impose la tolérance relative.
  [N,K] = NORMEST(...) rend en outre le nombre d'itérations.

  L'itération est celle de la puissance appliquée à A'*A : partant d'un
  vecteur quelconque, on alterne x <- A*x et x <- A'*x en normalisant, et
  la norme du résultat converge vers la plus grande valeur singulière.
  La convergence est géométrique, de raison le carré du rapport entre la
  deuxième et la première valeur singulière : rapide quand la première
  domine, lente quand deux sont proches.

  Elle ne demande que des produits matrice-vecteur, jamais la matrice
  entière : c'est ce qui la rend utilisable sur une grande matrice
  creuse, là où SVD demanderait de la remplir.

  Le résultat est une estimation par le bas — l'itération monte vers la
  vraie valeur sans jamais la dépasser.

  Exemple :
     A = magic(5);
     abs(normest(A) - norm(A)) / norm(A) < 1e-6
     normest(eye(4))                    % 1

  Voir aussi NORM, COND, CONDEST, SVD.
```

## `normest1`

```
NORMEST1 Estime la norme 1 par l'algorithme de Hager.
  N = NORMEST1(A) estime la plus grande somme des modules d'une colonne.
  [N,V,W] = NORMEST1(A) rend en outre un vecteur V tel que W = A*V et
  NORM(W,1) = N*NORM(V,1) : le témoin de l'estimation.
  [N,V,W,K] = NORMEST1(...) rend le nombre d'itérations.

  La norme 1 d'une matrice est le maximum de ||A*x||_1 sur les x de norme
  1. Ce maximum est atteint en un sommet du cube unité — un vecteur de
  plus ou moins un — et l'algorithme de Hager cherche ce sommet en
  suivant le gradient du signe : partant de x, on calcule A*x, on prend
  son signe, on calcule A'*signe, et l'on saute au sommet indiqué par sa
  plus grande composante.

  L'estimation est toujours une borne inférieure, et elle est presque
  toujours exacte. Elle ne demande que des produits par A et par A',
  ce qui la rend applicable là où l'on ne veut pas parcourir toutes les
  colonnes.

  Exemple :
     A = magic(5);
     normest1(A) == norm(A, 1)          % 1 : exacte ici
     [n, v, w] = normest1(magic(4));
     abs(norm(w, 1) - n * norm(v, 1)) < 1e-10

  Voir aussi NORM, NORMEST, CONDEST.
```

## `nthargout`

```
NTHARGOUT Ne garder qu'une sortie d'une fonction.
  V = NTHARGOUT(N,F,ARG1,...) appelle F avec les arguments donnés en
  demandant N sorties, et ne rend que la N-ième.

  V = NTHARGOUT([N1 N2 ...],F,...) rend, dans un tableau de cellules,
  les sorties demandées.

  Exemple :
     nthargout(2, @max, [3 9 4])   % 2, la position du maximum

  Voir aussi FEVAL, DEAL, NARGOUT.
```

## `numlock`

```
NUMLOCK État de la touche de verrouillage numérique.
  NUMLOCK('on') et NUMLOCK('off') demandent l'allumage ou l'extinction
  du verrouillage numérique ; E = NUMLOCK rend l'état courant, 'on' ou
  'off'.

  La touche appartient au serveur graphique. Là où MatLibre ne peut pas
  l'atteindre — une session sans écran, ou un système qui ne l'expose
  pas —, l'état rendu est 'off' et la demande reste sans effet, sans
  erreur.

  Exemple :
     etat = numlock();
     ischar(etat) || islogical(etat)

  Voir aussi INPUT, KEYBOARD.
```

## `ode89`

```
ODE89 Intégration à très haute précision par extrapolation.
  [T,Y] = ODE89(F,[T0 TF],Y0) intègre y' = F(t,y) de T0 à TF depuis Y0.
  [T,Y] = ODE89(F,TSPAN,Y0) avec TSPAN de plus de deux éléments intègre
  d'un instant au suivant et tombe exactement dessus : interpoler entre
  les pas d'une méthode d'ordre huit coûterait toute la précision
  qu'elle a gagnée.
  [T,Y] = ODE89(...,OPTIONS) accepte les réglages d'ODESET : 'RelTol',
  'AbsTol', 'MaxStep'.

  MATLAB emploie ici une paire de Runge-Kutta d'ordre huit et neuf de
  Verner. MatLibre emploie l'extrapolation de Gragg-Bulirsch-Stoer, qui
  atteint la même précision par un chemin plus court à expliquer : on
  avance sur un même pas avec un nombre croissant de sous-pas — deux,
  quatre, six, huit —, et l'on extrapole le résultat vers un sous-pas
  nul par le procédé d'Aitken-Neville.

  Ce qui rend l'extrapolation possible est que l'erreur de la règle du
  point milieu est une série en puissances paires du sous-pas : chaque
  niveau d'extrapolation supprime le terme suivant, et l'ordre monte
  deux par deux. Quatre niveaux suffisent à dépasser l'ordre huit.

  Elle convient aux problèmes lisses et non raides, où l'on veut une
  précision proche de celle de la machine. Sur un problème raide,
  ODE15S reste le bon choix.

  Exemple :
     [t, y] = ode89(@(t, y) -y, [0 1], 1);
     abs(y(end) - exp(-1)) < 1e-11
     [t, y] = ode89(@(t, y) [y(2); -y(1)], [0 2*pi], [1; 0]);
     abs(y(end, 1) - 1) < 1e-10           % le cercle se referme

  Voir aussi ODE45, ODE113, ODE15S, ODESET, DEVAL.
```

## `openfig`

```
OPENFIG Rouvre une figure enregistrée (indisponible).
  OPENFIG(NOM) rouvre, dans MATLAB, la figure enregistrée dans le
  fichier .fig nommé.

  Un fichier .fig est un fichier MAT portant le modèle d'objets
  graphiques de MathWorks, que MatLibre n'a pas : il ne peut pas le
  relire, et le dit plutôt que d'ouvrir une figure vide. SAVEFIG écrit
  du SVG, qu'un navigateur ou un éditeur d'images rouvre.

  Exemple :
     % OPENFIG demande un fichier .fig, que MatLibre n'ecrit pas.
     try
         openfig('inexistant.fig');
     catch e
         e.identifier
     end

  Voir aussi SAVEFIG, SAVEAS, OPEN, FIGURE.
```

## `pagectranspose`

```
PAGECTRANSPOSE Transposée conjuguée de chaque page d'un tableau.
  B = PAGECTRANSPOSE(A) échange les deux premières dimensions de A et
  conjugue les valeurs.

  Exemple :
     a = cat(3, [1 1i; 0 1], [1 0; 0 1]);
     b = pagectranspose(a);
     b(1, 2, 1)                  % 0 : la transposition conjugue aussi

  Voir aussi PAGETRANSPOSE, PAGEMTIMES.
```

## `pageinv`

```
PAGEINV Inverse chaque page d'un tableau.
  B = PAGEINV(A) inverse séparément chacune des pages A(:,:,k,...), qui
  doivent être carrées. La forme du tableau est conservée.

  Une page est une tranche à deux dimensions d'un tableau qui en a
  davantage. Les fonctions PAGE... traitent chacune comme une matrice
  indépendante : c'est la façon d'appliquer une opération matricielle à
  une pile de matrices sans écrire de boucle, et sans mélanger les pages
  entre elles comme le ferait une multiplication ordinaire.

  Comme INV, elle avertit et rend des infinis sur une page singulière.
  Inverser pour résoudre reste une mauvaise idée : PAGEMLDIVIDE est plus
  précis et plus rapide.

  Exemple :
     A = cat(3, [2 0; 0 4], [1 1; 0 1]);
     B = pageinv(A);
     B(:, :, 1)                          % [0.5 0; 0 0.25]
     max(max(abs(pagemtimes(A, B) - cat(3, eye(2), eye(2))))) < 1e-12

  Voir aussi PAGEMLDIVIDE, PAGEMTIMES, PAGETRANSPOSE, INV.
```

## `pagemldivide`

```
PAGEMLDIVIDE Résout un système par page.
  X = PAGEMLDIVIDE(A,B) résout A(:,:,k)*X(:,:,k) = B(:,:,k) pour chaque
  page. Si l'un des deux n'a qu'une page, elle sert pour toutes : c'est
  la même règle de diffusion que PAGEMTIMES.

  Résoudre page par page n'est pas la même chose que résoudre le grand
  système bloc-diagonal qu'elles forment ensemble : ici les pages ne
  communiquent pas, et c'est justement ce qu'on veut quand elles
  décrivent des instants, des essais ou des capteurs distincts.

  Exemple :
     A = cat(3, [2 0; 0 4], [1 1; 0 1]);
     B = cat(3, [2; 4], [3; 1]);
     X = pagemldivide(A, B);
     X(:, :, 1)                          % [1; 1]
     max(max(abs(pagemtimes(A, X) - B))) < 1e-12

  Voir aussi PAGEMTIMES, PAGEINV, MLDIVIDE, PAGETRANSPOSE.
```

## `pagemtimes`

```
PAGEMTIMES Produit matriciel page par page.
  C = PAGEMTIMES(A,B) multiplie chaque page A(:,:,k) par la page
  B(:,:,k) correspondante. Une entrée n'ayant qu'une page sert à
  toutes les pages de l'autre.

  C = PAGEMTIMES(A,TA,B,TB) transpose au passage : TA et TB valent
  'none', 'transpose' ou 'ctranspose'.

  Exemple :
     a = reshape(1:8, 2, 2, 2);
     c = pagemtimes(a, a);

  Voir aussi MTIMES, PAGETRANSPOSE, PAGEMLDIVIDE.
```

## `pagesvd`

```
PAGESVD Décomposition en valeurs singulières de chaque page.
  S = PAGESVD(A) rend, pour chaque page, ses valeurs singulières en
  colonne.
  [U,S,V] = PAGESVD(A) rend la décomposition complète : chaque page
  vérifie A(:,:,k) = U(:,:,k)*S(:,:,k)*V(:,:,k)'.
  [...] = PAGESVD(A,'econ') rend la forme économique.

  Comme toutes les fonctions PAGE..., elle traite les pages
  séparément : il n'y a pas de décomposition commune, et une page n'a
  aucune influence sur une autre.

  Exemple :
     A = cat(3, diag([3 1]), diag([2 5]));
     s = pagesvd(A);
     s(:, :, 1)'                         % 3 1
     [U, S, V] = pagesvd(A);
     max(max(max(abs(pagemtimes(pagemtimes(U, S), pagetranspose(V)) - A)))) < 1e-12

  Voir aussi SVD, PAGEMTIMES, PAGEINV, PAGETRANSPOSE, SVDS.
```

## `pagetranspose`

```
PAGETRANSPOSE Transposée de chaque page d'un tableau.
  B = PAGETRANSPOSE(A) échange les deux premières dimensions de A, les
  suivantes restant en place.

  Exemple :
     a = cat(3, [1 2; 3 4], [5 6; 7 8]);
     b = pagetranspose(a);
     b(:, :, 1)                  % [1 3; 2 4]

  Voir aussi PAGECTRANSPOSE, PAGEMTIMES, PERMUTE.
```

## `pan`

```
PAN Déplacement à la souris (accepté, sans effet).
  PAN ON permet, dans MATLAB, de faire glisser le contenu d'un axe à la
  souris ; PAN OFF l'interdit.

  Les figures de MatLibre ne sont pas manipulables à la souris :
  l'appel est accepté pour qu'un programme tourne sans retouche. Pour
  déplacer la vue, XLIM et YLIM font le travail.

  Exemple :
     plot(1:100); pan('on');

  Voir aussi ZOOM, XLIM, YLIM, ROTATE3D, BRUSH.
```

## `pareto`

```
PARETO Diagramme de Pareto : les causes rangées par importance.
  PARETO(Y) trace les valeurs de Y en barres, de la plus grande à la
  plus petite, et superpose la courbe de leur somme cumulée en pour
  cent. C'est le diagramme du contrôle qualité : il montre d'un coup
  d'œil combien de causes suffisent à expliquer l'essentiel des
  défauts.

  PARETO(Y,NOMS) étiquette les barres avec les chaînes de NOMS.

  PARETO(Y,NOMS,SEUIL) ne montre que les premières barres, jusqu'à ce
  que le cumul atteigne SEUIL — une fraction entre 0 et 1. Le défaut
  est 0.95 : on s'arrête quand 95 pour cent est expliqué.

  [H,I] = PARETO(...) rend les poignées et l'ordre de tri.

  Exemples :
     pareto([12 3 45 7 22], {'a','b','c','d','e'});
     % c d'abord, puis e, puis a : trois causes sur cinq

     defauts = [40 25 15 10 5 3 2];
     pareto(defauts, {}, 0.8);

  Voir aussi BAR, BARH, SORT, CUMSUM, HISTOGRAM.
```

## `parquetinfo`

```
PARQUETINFO Renseigne sur un fichier Parquet sans le lire.
  I = PARQUETINFO(FICHIER) rend une structure décrivant le fichier :
  son chemin, le nombre de lignes, le nombre de groupes de lignes, les
  noms des variables et leurs classes.

  Seul le pied du fichier est lu. C'est ce qui permet de savoir ce que
  contient un fichier de plusieurs gigaoctets sans en ouvrir une
  colonne.

  Exemple :
     f = fullfile(tempdir, 'info.parquet');
     parquetwrite(f, table([1; 2], ["x"; "y"], 'VariableNames', {'a', 'b'}));
     i = parquetinfo(f);
     i.NumRows                       % 2
     i.VariableNames{2}              % 'b'

  Voir aussi PARQUETREAD, PARQUETWRITE.
```

## `parquetread`

```
PARQUETREAD Lit un fichier Parquet dans une table.
  T = PARQUETREAD(FICHIER) rend la table que contient le fichier.
  T = PARQUETREAD(FICHIER,'SelectedVariableNames',NOMS) ne lit que les
  colonnes nommées — c'est l'intérêt d'un format en colonnes : le reste
  du fichier n'est pas touché.

  Les classes sont restituées d'après le schéma : un int8 écrit revient
  int8, une chaîne revient chaîne.

  Une colonne facultative est lue : ses niveaux de définition disent où
  sont les trous. Un trou devient NaN dans une colonne flottante ; dans
  une colonne entière, booléenne ou textuelle, il n'existe pas de
  valeur qui veuille dire « absent », et la lecture est refusée plutôt
  que de mettre un zéro à la place.

  Ce qui est lu : l'encodage PLAIN, sans compression. Un fichier
  compressé ou encodé en dictionnaire est refusé avec la raison : mieux
  vaut un refus net qu'une colonne muettement fausse.

  Exemple :
     f = fullfile(tempdir, 'lecture.parquet');
     parquetwrite(f, table([1; 2], ["x"; "y"], 'VariableNames', {'a', 'b'}));
     T = parquetread(f);
     height(T)                       % 2

  Voir aussi PARQUETWRITE, PARQUETINFO, READTABLE, TABLE.
```

## `parquetwrite`

```
PARQUETWRITE Écrit une table dans un fichier Parquet.
  PARQUETWRITE(FICHIER,T) écrit la table T au format Parquet : un
  groupe de lignes, encodage PLAIN, sans compression.

  Parquet range les données par colonne, chaque colonne portant son
  type. C'est ce qui permet de n'en lire qu'une, et de la lire sans
  deviner : un CSV oblige à relire tout le fichier et à interpréter
  chaque champ.

  Les colonnes portées sont les numériques, les booléennes et les
  textuelles. Un entier étroit garde sa largeur par le type converti,
  si bien que PARQUETREAD rend exactement les classes écrites. Une
  colonne d'un autre genre est refusée plutôt que rangée de travers.

  Une colonne catégorielle part comme du texte : Parquet ne porte pas
  la liste des catégories, et PARQUETREAD la rendra donc en chaînes.

  Ce qui n'est pas écrit : ni compression, ni dictionnaire, ni valeurs
  absentes — toutes les colonnes sont déclarées obligatoires. Les
  fichiers produits se lisent partout ; ils sont seulement plus gros
  qu'ils ne pourraient l'être.

  Exemple :
     f = fullfile(tempdir, 'exemple.parquet');
     T = table([1; 2; 3], ["a"; "b"; "c"], 'VariableNames', {'n', 'nom'});
     parquetwrite(f, T);
     R = parquetread(f);
     isequal(R.n, T.n) && isequal(R.nom, T.nom)   % 1 : rien n'a bouge

  Voir aussi PARQUETREAD, PARQUETINFO, WRITETABLE, TABLE.
```

## `pascal`

```
PASCAL Matrice de Pascal.
  P = PASCAL(N) rend la matrice symétrique définie positive dont les
  termes sont les coefficients binomiaux : P(i,j) = C(i+j-2, i-1).
  Sa première ligne et sa première colonne ne comptent que des uns, et
  chaque autre terme est la somme de celui du dessus et de celui de
  gauche.
  P = PASCAL(N,1) rend le facteur triangulaire inférieur, qui est sa
  propre inverse au signe près.
  P = PASCAL(N,2) rend une rotation de ce facteur, dont le cube vaut
  l'identité.

  Son déterminant vaut un, quelle que soit sa taille : c'est ce qui en
  fait un cas d'école du mauvais conditionnement, car ses valeurs
  propres s'écartent énormément tout en gardant un produit égal à un.
  Elle sert à éprouver un solveur linéaire.

  Exemple :
     pascal(4)
     det(pascal(6))                  % 1, malgre des termes jusqu'a 252
     cond(pascal(6))                 % enorme : mal conditionnee
     L = pascal(4, 1);
     L * L                           % l'identite : L est son inverse

  Voir aussi HADAMARD, MAGIC, HILB, TOEPLITZ.
```

## `patch`

```
PATCH Polygones remplis.
  PATCH(X,Y,C) trace le polygone dont les sommets sont (X,Y), rempli de
  la couleur C. C est une lettre, un nom, ou un triplet [r v b].

  Si X et Y sont des matrices, chaque colonne donne un polygone.

  PATCH(X,Y,Z,C) accepte des sommets à trois dimensions ; le rendu de
  MatLibre étant plan, Z ne change rien au dessin.

  PATCH('Faces',F,'Vertices',V) décrit les polygones par une liste de
  sommets V — un par ligne — et une liste de faces F, chaque ligne
  donnant les indices des sommets d'une face. C'est la forme compacte,
  celle qu'emploient les maillages : un sommet partagé n'est écrit
  qu'une fois.

  PATCH(...,'FaceColor',C) et PATCH(...,'EdgeColor',C) nomment les
  couleurs séparément ; 'none' laisse la face ou le bord vide.

  H = PATCH(...) rend les poignées des polygones.

  Exemples :
     patch([0 1 1 0], [0 0 1 1], 'r');            % un carre rouge

     % Deux triangles qui partagent une arete
     V = [0 0; 1 0; 1 1; 0 1];
     F = [1 2 3; 1 3 4];
     patch('Faces', F, 'Vertices', V, 'FaceColor', [0.6 0.8 1]);

  Voir aussi FILL, RECTANGLE, TRIMESH, TRISURF, LINE, AREA.
```

## `pcg`

```
PCG Gradient conjugué préconditionné.
  X = PCG(A,B) résout A*X = B pour une matrice symétrique définie
  positive. X = PCG(A,B,TOL,MAXIT) impose la tolérance relative — 1e-6
  par défaut — et le nombre maximal d'itérations.
  X = PCG(A,B,TOL,MAXIT,M1,M2,X0) donne un préconditionneur M1*M2 et un
  point de départ. A peut aussi être une poignée de fonction rendant
  A*x.

  [X,DRAPEAU,RES,K,RESIDUS] = PCG(...) rend le drapeau de sortie — 0 si
  la tolérance est atteinte, 1 si le nombre d'itérations est épuisé —,
  le résidu relatif final, le nombre d'itérations et l'historique.

  La méthode construit une suite de directions conjuguées : chaque
  direction est orthogonale aux précédentes au sens du produit scalaire
  défini par A. C'est cette orthogonalité qui garantit la convergence en
  au plus N itérations en arithmétique exacte, et qui fait qu'aucune
  direction n'est jamais reprise.

  Le nombre d'itérations utile est gouverné par le conditionnement :
  l'erreur décroît d'un facteur (sqrt(k)-1)/(sqrt(k)+1) par itération,
  où k est le conditionnement. C'est toute la raison d'être du
  préconditionneur, qui vise à rapprocher M de A pour rendre k petit.

  La symétrie n'est pas vérifiée : appliqué à une matrice qui ne l'est
  pas, l'algorithme ne converge simplement pas. BICG et GMRES existent
  pour ce cas.

  Exemple :
     % La matrice du laplacien discret : symetrique, definie positive.
     n = 20;
     A = full(spdiags([-ones(n,1), 2*ones(n,1), -ones(n,1)], -1:1, n, n));
     b = ones(n, 1);
     [x, drapeau, residu, k] = pcg(A, b, 1e-10, 100);
     drapeau                             % 0 : la tolerance est atteinte
     norm(A * x - b) / norm(b) < 1e-9

  Voir aussi BICG, CGS, MINRES, GMRES, MLDIVIDE.
```

## `pdepe`

```
PDEPE Équation aux dérivées partielles parabolique ou elliptique en 1-D.
  SOL = PDEPE(M,PDEFUN,ICFUN,BCFUN,XMESH,TSPAN) résout

     c(x,t,u,du/dx) du/dt = x^-m d/dx ( x^m f(x,t,u,du/dx) ) + s(...)

  où M vaut 0 en géométrie plane, 1 en cylindrique et 2 en sphérique.
  PDEFUN rend [C,F,S] ; ICFUN rend la condition initiale en un point ;
  BCFUN rend [PL,QL,PR,QR] pour les conditions P + Q*F = 0 aux deux
  bouts. SOL est un tableau TSPAN par XMESH par composante.

  La méthode est celle des lignes : on discrétise l'espace, ce qui
  change l'équation aux dérivées partielles en un système d'équations
  différentielles ordinaires en temps, puis on l'intègre par ODE15S. Le
  système est raide — la raideur croît comme le carré du nombre de
  points — et c'est pour cela qu'un solveur explicite n'y suffit pas.

  La discrétisation en espace est en volumes finis : le flux F est
  évalué aux milieux de mailles, et la divergence prise entre eux. Cette
  écriture conserve exactement la quantité intégrée, ce qu'une
  différence finie centrée ne fait pas — et c'est ce qui compte pour une
  équation de conservation.

  Le terme x^m traite la symétrie : en cylindrique et en sphérique,
  l'aire de la surface traversée croît avec le rayon, et c'est ce
  facteur qui l'exprime.

  Une condition de Dirichlet — Q nul — n'est pas une équation
  différentielle : la valeur au bord est déterminée à chaque instant en
  résolvant P = 0, non intégrée.

  Exemple :
     % Equation de la chaleur sur [0,1], bords a zero, creneau initial.
     f = @(x, t, u, dudx) deal(1, dudx, 0);
     ic = @(x) sin(pi * x);
     bc = @(xl, ul, xr, ur, t) deal(ul, 0, ur, 0);
     x = linspace(0, 1, 21);
     t = linspace(0, 0.1, 6);
     sol = pdepe(0, f, ic, bc, x, t);
     % La solution exacte est sin(pi x) exp(-pi^2 t).
     max(abs(sol(end, :)' - sin(pi * x)' * exp(-pi^2 * 0.1))) < 5e-3

  Voir aussi ODE15S, BVP4C, PDEVAL, INTERP1.
```

## `pdeval`

```
PDEVAL Évalue la solution de PDEPE entre les points du maillage.
  UOUT = PDEVAL(M,XMESH,UI,XOUT) interpole en XOUT la composante UI de
  la solution rendue par PDEPE sur le maillage XMESH.
  [UOUT,DUOUTDX] = PDEVAL(...) rend aussi la dérivée en espace.

  L'interpolation est cubique d'Hermite : sur chaque maille, le
  polynôme prend aux deux bouts la valeur du nœud et une pente déduite
  de la parabole passant par lui et ses deux voisins. Deux conséquences
  qui font tout l'intérêt du procédé : la dérivée rendue est celle de la
  fonction rendue — elles ne peuvent pas se contredire —, et l'ensemble
  est exact sur les paraboles, donc d'ordre deux en dérivée comme la
  discrétisation dont la solution vient.

  Une interpolation affine, elle, donnerait une dérivée constante par
  morceaux, discontinue aux nœuds et d'ordre un : elle perdrait la
  précision que PDEPE a mise à obtenir.

  M ne sert pas au calcul : il est accepté pour que l'appel ait la même
  forme que celui de PDEPE, dont la solution vient.

  Exemple :
     x = linspace(0, 1, 21);
     u = sin(pi * x);
     [v, dv] = pdeval(0, x, u, 0.25);
     abs(v - sin(pi * 0.25)) < 1e-3
     abs(dv - pi * cos(pi * 0.25)) < 1e-2

  Voir aussi PDEPE, INTERP1, DEVAL, PCHIP.
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

  Exemple :
     [X, Y, Z] = peaks(20);
     size(Z)                     % 20 20

  Voir aussi SURF, CONTOUR, MESHGRID.
```

## `perms`

```
PERMS Toutes les permutations des éléments d'un vecteur.
  P = PERMS(V) rend une matrice dont chaque ligne est une permutation
  de V. L'ordre suit celui de MATLAB : lexicographique inverse.

  Exemple :
     P = perms([1 2 3]);
     size(P, 1)                  % 6 : trois factorielle

  Voir aussi NCHOOSEK, RANDPERM, FACTORIAL.
```

## `pie`

```
PIE Diagramme circulaire.
  PIE(X) trace un disque découpé en secteurs proportionnels aux
  éléments de X. Si la somme de X vaut un ou moins, les valeurs sont
  prises pour des fractions et le disque reste incomplet ; sinon elles
  sont normalisées.

  PIE(X,DECOLLER) écarte du centre les secteurs dont l'élément de
  DECOLLER n'est pas nul : c'est ainsi qu'on met en avant une part.

  PIE(X,DECOLLER,ETIQUETTES) nomme les secteurs. Sans étiquettes, ce
  sont les pourcentages qui sont écrits.

  H = PIE(...) rend les poignées des secteurs et des textes.

  Le premier secteur commence en haut et les suivants tournent dans le
  sens des aiguilles d'une montre, comme dans MATLAB.

  Un diagramme circulaire se lit mal dès qu'il compte plus de cinq ou
  six parts : l'œil compare les angles beaucoup moins bien que les
  longueurs. Un BAR trié, ou un PARETO, dit souvent la même chose plus
  clairement.

  Exemples :
     pie([3 1 1]);
     pie([30 20 50], [0 0 1], {'nord', 'sud', 'est'});

  Voir aussi PIE3, BAR, PARETO, FILL, LEGEND.
```

## `pie3`

```
PIE3 Diagramme circulaire en perspective.
  PIE3(X) trace le même diagramme que PIE, vu de biais. Le rendu de
  MatLibre est plan : le disque est simplement aplati verticalement,
  ce qui donne l'ellipse que la perspective produirait, sans épaisseur.

  PIE3(X,DECOLLER) et PIE3(X,DECOLLER,ETIQUETTES) suivent la même
  règle que PIE.

  La perspective d'un diagramme circulaire fausse la lecture : les
  secteurs du devant paraissent plus grands que ceux du fond, à surface
  égale. PIE existe pour cette raison, et vaut mieux.

  Exemples :
     pie3([3 1 1]);
     pie3([30 20 50], [0 0 1], {'nord', 'sud', 'est'});

  Voir aussi PIE, BAR3, PARETO, FILL.
```

## `pink`

```
PINK Carte de couleurs pastel, pour les images en sépia.
  CARTE = PINK() rend une carte de 256 couleurs pastel, dans les tons
  sépia. CARTE = PINK(M) en rend M.

  Elle vaut sqrt((2*GRAY + HOT)/3). La racine est une correction de
  gamma : elle relève les valeurs basses, si bien que la clarté perçue
  croît à peu près linéairement le long de l'échelle, alors qu'elle
  croîtrait trop lentement dans l'ombre sans elle.

  D'où son usage sur les photographies en noir et blanc, qu'elle teinte
  sans détruire l'ordre des niveaux : la carte reste monotone en clarté.

  Exemple :
     carte = pink(8);
     carte(1, :)

  Voir aussi GRAY, HOT, BONE, COPPER, COLORMAP.
```

## `pivot`

```
PIVOT Tableau croisé d'une table.
  P = PIVOT(T,'Columns',C,'Rows',R) compte les lignes de T pour chaque
  couple de valeurs des variables R et C : une ligne de P par valeur
  de R, une colonne par valeur de C.

  P = PIVOT(T,'Columns',C,'Rows',R,'DataVariable',D) agrège la
  variable D au lieu de compter.
  PIVOT(...,'Method',M) choisit l'agrégation : 'count' par défaut,
  'sum', 'mean', 'median', 'max', 'min', ou une fonction.
  PIVOT(...,'IncludeTotals',true) ajoute une ligne et une colonne de
  totaux.

  Exemple :
     t = table({'a';'a';'b'}, [1;2;1], [10;20;30], ...
               'VariableNames', {'g', 'c', 'v'});
     pivot(t, 'Rows', 'g', 'Columns', 'c', ...
           'DataVariable', 'v', 'Method', 'sum')

  Voir aussi GROUPSUMMARY, FINDGROUPS, SPLITAPPLY, UNSTACK.
```

## `plotmatrix`

```
PLOTMATRIX Tableau de nuages de points, toutes les paires de colonnes.
  PLOTMATRIX(X) trace, pour chaque paire de colonnes de X, le nuage de
  l'une contre l'autre, dans une grille d'axes. La diagonale porte
  l'histogramme de chaque colonne. C'est la façon la plus rapide de
  voir d'un coup toutes les relations deux à deux d'un jeu de données.

  PLOTMATRIX(X,Y) trace chaque colonne de Y contre chaque colonne de X.
  La grille compte alors autant de lignes que Y a de colonnes et autant
  de colonnes que X en a, et il n'y a pas d'histogramme.

  PLOTMATRIX(...,STYLE) prend une chaîne de style, comme PLOT. Le
  défaut est le point.

  H = PLOTMATRIX(...) rend les poignées des nuages.

  Exemples :
     X = randn(200, 3);
     X(:, 3) = X(:, 1) + 0.3 * randn(200, 1);
     plotmatrix(X);                % la liaison 1-3 saute aux yeux

     plotmatrix(randn(100, 2), randn(100, 3));

  Voir aussi PLOT, SCATTER, SUBPLOT, CORR, PCA.
```

## `plotyy`

```
PLOTYY Deux courbes, deux échelles d'ordonnées.
  PLOTYY(X1,Y1,X2,Y2) trace la première courbe et la seconde sur le
  même axe, la seconde étant remise à l'échelle de la première de
  sorte que les deux occupent la même hauteur. Les graduations de
  droite, celles de la seconde échelle, sont écrites en légende.

  PLOTYY(X1,Y1,X2,Y2,F) emploie la fonction de tracé nommée F —
  'plot', 'semilogy', 'stem'… — pour les deux courbes.
  PLOTYY(X1,Y1,X2,Y2,F1,F2) en emploie une pour chacune.

  [AX,H1,H2] = PLOTYY(...) rend l'axe et les deux poignées.

  MATLAB donne à la seconde courbe un axe des ordonnées qui lui est
  propre, gradué à droite. MatLibre n'a pas de second axe : il
  normalise la seconde courbe pour qu'elle se superpose lisiblement à
  la première, et nomme le facteur dans la légende. La forme des deux
  courbes et leur comparaison restent justes ; ce sont les graduations
  de droite qui manquent.

  Depuis R2016a, MATLAB recommande YYAXIS plutôt que PLOTYY.

  Exemples :
     x = 0:0.1:10;
     plotyy(x, sin(x), x, 1000 * exp(-x));
     legend('sin (gauche)', 'exp (droite)');

  Voir aussi PLOT, YYAXIS, SUBPLOT, LEGEND, TILEDLAYOUT.
```

## `polar`

```
POLAR Courbe en coordonnées polaires (nom historique).
  POLAR(THETA,RHO) fait ce que fait POLARPLOT. C'est le nom que la
  fonction portait avant R2016a ; MATLAB le garde pour les programmes
  anciens, et MatLibre aussi.

  POLAR(THETA,RHO,STYLE) prend une chaîne de style.

  Exemples :
     theta = linspace(0, 2*pi, 200);
     polar(theta, sin(2 * theta));

  Voir aussi POLARPLOT, COMPASS, ROSE, PLOT.
```

## `polarplot`

```
POLARPLOT Courbe en coordonnées polaires.
  POLARPLOT(THETA,RHO) trace la courbe dont l'angle est THETA, en
  radians, et le rayon RHO.

  POLARPLOT(THETA,RHO,STYLE) prend une chaîne de style, comme PLOT.

  POLARPLOT(...,'Name',valeur) accepte les mêmes propriétés que PLOT.

  H = POLARPLOT(...) rend la poignée de la courbe.

  MatLibre n'a pas d'axes polaires : la courbe est convertie en
  coordonnées cartésiennes et tracée sur un axe ordinaire, sur lequel
  sont dessinés les cercles de rayon constant et les rayons qui
  servent de graduations. La lecture est la même ; ce qui manque est
  la graduation angulaire en degrés autour du cadre.

  Exemples :
     theta = linspace(0, 2*pi, 400);
     polarplot(theta, 1 + cos(theta));       % la cardioide
     polarplot(theta, abs(sin(3*theta)));    % la rosace a six petales

  Voir aussi POLAR, COMPASS, ROSE, PLOT, POL2CART.
```

## `polyarea`

```
POLYAREA Aire d'un polygone.
  A = POLYAREA(X,Y) rend l'aire du polygone dont les sommets sont
  (X,Y), pris dans l'ordre. Le contour se referme tout seul : il n'est
  pas nécessaire de répéter le premier sommet.
  A = POLYAREA(X,Y,DIM) travaille suivant la dimension DIM ; par défaut
  la première non singleton, ce qui traite une matrice comme un
  polygone par colonne.

  La formule est celle du lacet : l'aire vaut la moitié de la somme des
  produits croisés des sommets consécutifs. Elle se lit comme la somme
  des aires signées des triangles formés avec l'origine — ceux qui
  débordent comptent en négatif et se compensent exactement, quelle que
  soit l'origine choisie et que le polygone soit convexe ou non.

  L'aire rendue est positive : le sens de parcours ne change que le
  signe, et POLYAREA en prend la valeur absolue.

  Un polygone qui se recoupe n'a pas d'aire bien définie ; la formule en
  rend une, mais elle compte les régions selon leur enlacement.

  Exemple :
     polyarea([0 1 1 0], [0 0 1 1])           % 1 : le carre unite
     polyarea([0 4 4 0], [0 0 3 3])           % 12
     abs(polyarea(cos(0:0.01:2*pi), sin(0:0.01:2*pi)) - pi) < 1e-3

  Voir aussi INPOLYGON, CONVHULL, BOUNDARY, TRAPZ.
```

## `polyshape`

```
POLYSHAPE Région du plan délimitée par des polygones.
  PG = POLYSHAPE(X,Y) construit la région bordée par le polygone de
  sommets (X,Y). PG = POLYSHAPE(P) où P a deux colonnes fait de même.
  Plusieurs contours se donnent séparés par des NaN, ou en cellules :
  POLYSHAPE({X1,X2},{Y1,Y2}).

  Un contour parcouru dans le sens direct est plein ; un contour
  parcouru dans l'autre sens et contenu dans un plein est un trou.
  C'est la convention de MATLAB, et elle suffit à décrire une région
  percée sans rien ajouter à la structure.

  Ce qu'on lui demande : AREA, PERIMETER, CENTROID, BOUNDINGBOX,
  ISINTERIOR, BOUNDARY, NUMSIDES, NUMBOUNDARIES, NUMREGIONS, HOLES,
  ISHOLE, REGIONS, TRANSLATE, SCALE, ROTATE, ADDBOUNDARY, RMBOUNDARY,
  OVERLAPS, CONVHULL, PLOT, et les opérations booléennes UNION,
  INTERSECT, SUBTRACT et XOR.

  Ce qui n'est pas fait : la simplification automatique d'un contour
  qui se recoupe lui-même. MATLAB la fait à la construction ; ici le
  contour est pris tel quel, et une aire calculée sur un contour croisé
  compte les régions selon leur enlacement.

  Quand deux régions se touchent exactement — une arête commune, un
  sommet posé sur une arête —, l'algorithme de découpage n'a ni entrée
  ni sortie franche à suivre. Le cas est résolu en déplaçant l'une des
  deux d'un cheveu : cent milliardièmes de son étendue. Le résultat est
  alors juste à ce déplacement près, soit une dizaine de chiffres
  significatifs, et non à la précision machine comme dans les autres
  cas.

  Exemple :
     carre = polyshape([0 2 2 0], [0 0 2 2]);
     area(carre)                     % 4
     autre = polyshape([1 3 3 1], [1 1 3 3]);
     area(intersect(carre, autre))   % 1 : le carre commun
     area(union(carre, autre))       % 7 : 4 + 4 - 1

  Voir aussi POLYAREA, INPOLYGON, CONVHULL, BOUNDARY, ALPHASHAPE.
```

## `pow2`

```
POW2 Puissance de deux, ou mantisse mise à l'échelle.
  Y = POW2(X) rend 2.^X.
  Y = POW2(F,E) rend F .* 2.^E.

  Exemple :
     pow2(3)                     % 8
     pow2(0.5, 4)                % 8 : mantisse et exposant

  Voir aussi NEXTPOW2.
```

## `prism`

```
PRISM Carte de couleurs répétant les six couleurs du prisme.
  CARTE = PRISM() rend une carte de 256 couleurs répétant en boucle les
  six couleurs du prisme : rouge, orange, jaune, vert, bleu, violet.
  CARTE = PRISM(M) en rend M.

  Elle est délibérément discontinue : deux niveaux voisins reçoivent des
  couleurs sans rapport, et le motif recommence tous les six niveaux.
  Elle ne représente donc aucun ordre, et employée sur un champ continu
  elle fabrique des bandes qui n'existent pas dans les données.

  Son usage est ailleurs : distinguer des régions étiquetées, des lignes
  de niveau successives, des composantes connexes — tout ce qui est
  nominal et non ordonné, où le contraste maximal entre voisins est
  justement ce qu'on cherche.

  Exemple :
     carte = prism(12);
     isequal(carte(1:6, :), carte(7:12, :))

  Voir aussi COLORMAP, LINES, PARULA, HSV.
```

## `quiver`

```
QUIVER Champ de vecteurs.
  QUIVER(X,Y,U,V) trace une flèche partant de chaque point (X,Y) et
  portant le vecteur (U,V). X, Y, U et V ont la même taille.

  QUIVER(U,V) place les flèches aux nœuds d'une grille entière.

  QUIVER(...,ECHELLE) multiplie la longueur des flèches par ECHELLE.
  Par défaut, elles sont mises à l'échelle de façon à ne pas se
  chevaucher. QUIVER(...,0) les trace à leur longueur vraie, sans
  aucune mise à l'échelle : c'est ce qu'il faut quand la longueur a un
  sens physique.

  QUIVER(...,STYLE) prend une chaîne de style, comme PLOT.

  H = QUIVER(...) rend les poignées.

  Exemples :
     [X, Y] = meshgrid(-2:0.4:2);
     quiver(X, Y, -Y, X);                  % un champ tournant

     Z = X .* exp(-X.^2 - Y.^2);
     [DX, DY] = gradient(Z, 0.4);
     contour(X, Y, Z); hold on; quiver(X, Y, DX, DY); hold off

  Voir aussi QUIVER3, COMPASS, FEATHER, CONTOUR, GRADIENT, STREAMLINE.
```

## `quiver3`

```
QUIVER3 Champ de vecteurs en trois dimensions.
  QUIVER3(X,Y,Z,U,V,W) trace une flèche partant de chaque point
  (X,Y,Z) et portant le vecteur (U,V,W).

  QUIVER3(Z,U,V,W) place les flèches sur la surface Z.

  QUIVER3(...,ECHELLE) et QUIVER3(...,STYLE) suivent la même règle que
  QUIVER.

  H = QUIVER3(...) rend les poignées.

  Le rendu de MatLibre est plan : les flèches sont projetées en
  laissant tomber la troisième coordonnée, comme le fait PLOT3.

  Exemples :
     [X, Y] = meshgrid(-2:0.5:2);
     Z = X .* exp(-X.^2 - Y.^2);
     [U, V, W] = surfnorm(X, Y, Z);
     quiver3(X, Y, Z, U, V, W);

  Voir aussi QUIVER, PLOT3, SURFNORM, CONTOUR3.
```

## `rampeCarte`

```
RAMPECARTE Rampe de 0 à 1 sur M points, colonne.
  Pour M = 1 la rampe vaut zéro, comme dans MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     g = rampeCarte(5);
     g'                          % 0 0.25 0.5 0.75 1

  Voir aussi AUTUMN.
```

## `rat`

```
RAT Approximation rationnelle par fractions continues.
  [N,D] = RAT(X) rend deux entiers tels que N/D vaut X à la tolérance
  par défaut près (1e-6 fois la valeur).
  S = RAT(X) rend la chaîne « n/d ».

  Exemple :
     [n, d] = rat(0.75);
     [n d]                       % 3 4
     abs(n / d - 0.75) < 1e-12

  Voir aussi GCD, FORMAT.
```

## `readcell`

```
READCELL Lit un fichier délimité dans un tableau de cellules.
  C = READCELL(FICHIER) lit un fichier texte délimité — .csv, .txt —
  et rend un tableau de cellules : une case numérique donne un nombre,
  les autres donnent du texte. Rien n'est sauté : la ligne d'en-tête
  est la première ligne de C.

  C = READCELL(FICHIER,'Delimiter',D) impose le séparateur, par son
  caractère ou par l'un des noms 'comma', 'semi', 'tab', 'space'.

  Exemple :
     f = fullfile(tempdir, 'essai.csv');
     writecell({'nom', 'valeur'; 'a', 1}, f);
     readcell(f)

  Voir aussi WRITECELL, READMATRIX, READTABLE, READVARS.
```

## `readlines`

```
READLINES Lit un fichier texte, une ligne par élément.
  L = READLINES(FICHIER) rend un tableau de chaînes, une par ligne du
  fichier, les fins de ligne retirées.
  L = READLINES(FICHIER,'EmptyLineRule','skip') saute les lignes vides.
  L = READLINES(FICHIER,'LineEnding',SEP) découpe sur SEP plutôt que sur
  les fins de ligne usuelles.

  Les trois conventions de fin de ligne sont reconnues : celle d'Unix,
  celle de Windows et celle des anciens Mac. Un fichier écrit sur l'une
  se relit donc sur l'autre, ce qui est le seul comportement utile.

  Une dernière ligne vide — celle qu'un fichier bien formé laisse après
  son dernier retour — n'est pas rendue : sans quoi tout aller-retour
  par WRITELINES ajouterait un élément à chaque passage.

  Exemple :
     f = [tempname '.txt'];
     writelines(["premiere"; "deuxieme"], f);
     l = readlines(f);
     numel(l)                        % 2
     delete(f);

  Voir aussi WRITELINES, FILEREAD, READTABLE, STRSPLIT, SPLITLINES.
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

## `readstruct`

```
READSTRUCT Lit un fichier XML ou JSON dans une structure.
  S = READSTRUCT(FICHIER) reconnaît le format à l'extension : .xml ou
  .json. S = READSTRUCT(...,'FileType',TYPE) l'impose.

  Un élément XML devient un champ ; ses attributs deviennent des champs
  dont le nom porte le suffixe « Attribute », comme dans MATLAB. Des
  éléments frères de même nom deviennent un tableau de structures.

  Le texte d'un élément est converti en nombre quand il en est un :
  c'est ce que fait MATLAB, et c'est ce qui permet de relire un fichier
  écrit par WRITESTRUCT sans rien reconvertir.

  Exemple :
     f = [tempname '.xml'];
     writestruct(struct('a', 1, 'b', "deux"), f);
     s = readstruct(f);
     s.a                             % 1, en nombre
     delete(f);

  Voir aussi WRITESTRUCT, XMLREAD, JSONDECODE, READTABLE.
```

## `readvars`

```
READVARS Lit les colonnes d'un fichier, une par sortie.
  [A,B,C] = READVARS(FICHIER) lit le fichier comme READTABLE et rend
  chaque variable dans sa propre sortie, dans l'ordre des colonnes.

  Exemple :
     f = fullfile(tempdir, 'essai.csv');
     writecell({'x','y'; 1, 2; 3, 4}, f);
     [x, y] = readvars(f);

  Voir aussi READTABLE, READMATRIX, READCELL.
```

## `rectangle`

```
RECTANGLE Rectangle, éventuellement arrondi ou elliptique.
  RECTANGLE('Position',[X Y L H]) trace un rectangle dont le coin
  inférieur gauche est en (X,Y), de largeur L et de hauteur H.

  RECTANGLE(...,'Curvature',C) arrondit les coins. C va de 0 — des
  coins droits — à 1 — l'ellipse inscrite. C peut être un couple
  [horizontal, vertical] pour arrondir différemment les deux
  directions.

  RECTANGLE(...,'FaceColor',C) remplit ; sans elle, seul le contour est
  tracé. 'EdgeColor' et 'LineWidth' règlent le contour.

  RECTANGLE sans argument trace le carré unité.

  H = RECTANGLE(...) rend la poignée.

  C'est ainsi qu'on dessine un cercle dans MATLAB : un rectangle carré
  de courbure un.

  Exemples :
     rectangle('Position', [0 0 2 1]);
     rectangle('Position', [0 0 2 2], 'Curvature', 1);    % un cercle
     rectangle('Position', [1 1 3 2], 'Curvature', 0.3, ...
               'FaceColor', [0.9 0.9 0.5]);
     axis('equal');

  Voir aussi PATCH, FILL, LINE, PLOT, AXIS.
```

## `rectint`

```
RECTINT Aire d'intersection de rectangles.
  A = RECTINT(A,B) rend une matrice dont l'élément (I,J) est l'aire
  commune au rectangle I de A et au rectangle J de B. Chaque rectangle
  est une ligne [X Y LARGEUR HAUTEUR], le coin étant le plus bas à
  gauche.

  L'intersection de deux rectangles alignés sur les axes est un
  rectangle, et son côté suivant chaque axe est le recouvrement des deux
  intervalles : c'est ce qui rend le calcul immédiat, et nul dès que
  l'un des deux recouvrements l'est.

  Exemple :
     rectint([0 0 2 2], [1 1 2 2])            % 1 : ils se recouvrent d'un carre
     rectint([0 0 1 1], [3 3 1 1])            % 0 : disjoints

  Voir aussi POLYAREA, INPOLYGON, RECTANGLE.
```

## `refresh`

```
REFRESH Redessine une figure.
  REFRESH redessine la figure courante ; REFRESH(N) la figure N.

  Les figures de MatLibre sont rendues à la demande : l'appel est
  accepté pour qu'un programme tourne sans retouche, et n'a rien à
  faire. DRAWNOW joue le même rôle.

  Exemple :
     plot(1:10); refresh;

  Voir aussi DRAWNOW, FIGURE, CLF, SHG.
```

## `repelem`

```
REPELEM Répétition élément par élément.
  B = REPELEM(V,N) répète chaque élément du vecteur V. N est un
  scalaire, ou un vecteur donnant le nombre de copies de chaque
  élément.

  B = REPELEM(A,M,N) répète chaque élément de la matrice A en un bloc
  de M lignes et N colonnes ; M et N peuvent être des vecteurs donnant
  la hauteur de chaque ligne et la largeur de chaque colonne.

  Exemples :
     repelem([1 2 3], 2)        % [1 1 2 2 3 3]
     repelem([1 2 3], [1 2 3])  % [1 2 2 3 3 3]
     repelem([1 2; 3 4], 2, 3)

  Voir aussi REPMAT, KRON, RESHAPE.
```

## `rescale`

```
RESCALE Remise à l'échelle linéaire d'un tableau.
  Y = RESCALE(X) ramène les valeurs dans [0,1].
  Y = RESCALE(X,A,B) les ramène dans [A,B].

  Exemple :
     rescale([2 4 6])            % 0 0.5 1
     rescale([2 4 6], 10, 20)    % 10 15 20

  Voir aussi NORMALIZE, MIN, MAX.
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

  Voir aussi RESIDUEZ.
```

## `ribbon`

```
RIBBON Colonnes dessinées en rubans côte à côte.
  RIBBON(Y) trace une bande par colonne de Y, les bandes étant rangées
  côte à côte dans la profondeur. RIBBON(X,Y) place les points en X.
  RIBBON(X,Y,LARGEUR) donne aux bandes la largeur voulue.

  H = RIBBON(...) rend les poignées.

  Le rendu de MatLibre est plan : chaque colonne est tracée comme une
  aire décalée, ce qui donne la même lecture que la perspective de
  MATLAB.

  Exemples :
     ribbon(peaks(20));

     t = linspace(0, 2*pi, 100)';
     ribbon([sin(t), sin(2*t), sin(3*t)]);

  Voir aussi WATERFALL, AREA, MESH, SURF, PLOT3.
```

## `rmmissing`

```
RMMISSING Retire les valeurs manquantes.
  B = RMMISSING(A) retire d'un vecteur les valeurs manquantes, et
  d'une matrice ou d'une table les lignes qui en contiennent une.

  B = RMMISSING(A,DIM) travaille suivant la dimension DIM : 2 retire
  les colonnes.

  RMMISSING(...,'MinNumMissing',N) ne retire une ligne que si elle
  compte au moins N valeurs manquantes.
  RMMISSING(...,'DataVariables',V) ne regarde, dans une table, que les
  variables nommées.

  [B,MARQUE] = RMMISSING(A) rend en outre les positions retirées.

  Exemple :
     rmmissing([1 NaN 3])          % [1 3]

  Voir aussi ISMISSING, STANDARDIZEMISSING, FILLMISSING, RMOUTLIERS.
```

## `rmoutliers`

```
RMOUTLIERS Retire les valeurs aberrantes.
  B = RMOUTLIERS(A) retire d'un vecteur les valeurs aberrantes, et
  d'une matrice les lignes qui en contiennent une.
  B = RMOUTLIERS(A,METHODE,...) choisit le critère, comme ISOUTLIER.

  [B,MARQUE] = RMOUTLIERS(A) rend aussi ce qui a été retiré.

  Retirer change la longueur : sur une série mesurée, cela décale tout
  ce qui suit et rompt l'alignement avec le temps. FILLOUTLIERS, qui
  remplace, est souvent préférable.

  Exemple :
     rmoutliers([1 2 3 100 5])       % [1 2 3 5]

  Voir aussi ISOUTLIER, FILLOUTLIERS, RMMISSING.
```

## `rose`

```
ROSE Histogramme angulaire.
  ROSE(THETA) répartit les angles THETA — en radians — en vingt
  secteurs et trace, pour chacun, un secteur dont le rayon est
  l'effectif. C'est l'histogramme des directions : il montre si les
  angles se concentrent quelque part.

  ROSE(THETA,N) emploie N secteurs.
  ROSE(THETA,BORDS) emploie les bords donnés.

  [H,N,C] = ROSE(THETA,...) rend les poignées, les effectifs et les
  centres des secteurs.

  Exemples :
     rose(randn(500, 1));                   % concentre autour de zero
     rose(2 * pi * rand(500, 1), 12);       % a peu pres uniforme
     [~, n, c] = rose([0 0 0 pi pi], 4);

  Voir aussi POLARPLOT, COMPASS, HISTOGRAM, HISTCOUNTS.
```

## `rotate`

```
ROTATE Fait tourner des objets graphiques.
  ROTATE(H,DIRECTION,ANGLE) fait tourner les objets désignés par H de
  ANGLE degrés autour de l'axe DIRECTION, qui est donné soit par
  [AZIMUT ELEVATION], soit par un vecteur [X Y Z].

  ROTATE(H,DIRECTION,ANGLE,ORIGINE) fait passer l'axe par ORIGINE
  plutôt que par le centre du tracé.

  MatLibre applique la rotation dans le plan des X et des Y, la seule
  que son rendu montre : une rotation autour de l'axe des Z tourne
  comme dans MATLAB, les autres ne changent rien.

  Exemples :
     h = plot([0 1], [0 0], 'LineWidth', 2);
     rotate(h, [0 0 1], 90);        % la ligne se dresse

  Voir aussi ROTATE3D, VIEW, SET, GET.
```

## `rotate3d`

```
ROTATE3D Rotation à la souris (acceptée, sans effet).
  ROTATE3D ON permet, dans MATLAB, de faire tourner une figure
  tridimensionnelle à la souris ; ROTATE3D OFF l'interdit.

  Les figures de MatLibre ne sont pas manipulables à la souris et son
  rendu est plan : l'appel est accepté pour qu'un programme tourne sans
  retouche.

  Exemple :
     surf(peaks(30)); rotate3d('on');

  Voir aussi ZOOM, PAN, VIEW, DATACURSORMODE, BRUSH.
```

## `savefig`

```
SAVEFIG Enregistre une figure dans un fichier.
  SAVEFIG(NOM) enregistre la figure courante sous le nom donné.
  SAVEFIG(H,NOM) enregistre la figure désignée par H.

  MATLAB écrit un fichier .fig, qui est un fichier MAT portant son
  modèle d'objets graphiques. MatLibre n'a pas ce modèle : il
  enregistre le dessin en SVG, seul format qu'il sache écrire. Un nom
  en .fig ou sans extension devient donc un .svg ; un nom portant une
  autre extension est refusé par SAVEAS. Le dessin est conservé ; ce
  qui ne l'est pas est la possibilité de rouvrir la figure pour la
  modifier.

  Exemples :
     plot(1:10);
     savefig('courbe.svg');
     savefig('courbe');            % ecrit courbe.svg

  Voir aussi SAVEAS, PRINT, OPENFIG, EXPORTGRAPHICS, FIGURE.
```

## `scatter3`

```
SCATTER3 Nuage de points dans l'espace.
  SCATTER3(X,Y,Z) place un point à chaque triplet.
  SCATTER3(X,Y,Z,S) donne aux points la taille S.
  SCATTER3(X,Y,Z,S,C) leur donne la couleur C.
  SCATTER3(...,STYLE) prend une chaîne de style, comme PLOT.

  H = SCATTER3(...) rend la poignée du nuage.

  Le rendu de MatLibre est plan : les points sont projetés en laissant
  tomber la troisième coordonnée, comme le fait PLOT3.

  Exemples :
     scatter3(randn(100,1), randn(100,1), randn(100,1));
     t = linspace(0, 6*pi, 200);
     scatter3(cos(t), sin(t), t, 20, 'r');

  Voir aussi SCATTER, PLOT3, STEM3, QUIVER3.
```

## `scatteredInterpolant`

```
SCATTEREDINTERPOLANT Interpolation de données dispersées.
  F = SCATTEREDINTERPOLANT(X,Y,V) construit un interpolant des valeurs V
  aux points (X,Y), qui n'ont pas à former une grille. F(XQ,YQ) évalue
  ensuite où l'on veut.
  F = SCATTEREDINTERPOLANT(P,V) où P a deux colonnes fait la même chose.
  F = SCATTEREDINTERPOLANT(...,METHODE) choisit 'linear' (par défaut) ou
  'nearest'. F = SCATTEREDINTERPOLANT(...,METHODE,PROLONGEMENT) choisit
  ce qui se passe hors de l'enveloppe convexe : 'none' (NaN, par défaut)
  ou 'nearest'.

  L'interpolation linéaire s'appuie sur la triangulation de Delaunay :
  le point interrogé tombe dans un triangle, et sa valeur est la moyenne
  des trois sommets pondérée par les coordonnées barycentriques. Deux
  conséquences qui font tout l'intérêt du procédé : l'interpolant repasse
  exactement par les données, et il est exact sur toute fonction affine —
  trois points définissent un plan, et le barycentre y reste.

  Hors de l'enveloppe convexe il n'y a pas de triangle, donc pas
  d'interpolation : c'est de l'extrapolation, et elle est refusée par
  défaut plutôt que devinée.

  Exemple :
     x = [0; 1; 0; 1; 0.5];  y = [0; 0; 1; 1; 0.5];
     v = 2 * x + 3 * y + 1;             % un plan
     F = scatteredInterpolant(x, y, v);
     abs(F(0.25, 0.75) - (2*0.25 + 3*0.75 + 1)) < 1e-12
     isnan(F(5, 5))                     % dehors : pas d'extrapolation

  Voir aussi GRIDDEDINTERPOLANT, GRIDDATA, DELAUNAYTRIANGULATION, INTERP2.
```

## `setxor`

```
SETXOR Différence symétrique de deux ensembles.
  C = SETXOR(A,B) rend, triées et sans répétition, les valeurs qui
  figurent dans A ou dans B mais pas dans les deux.

  [C,IA,IB] = SETXOR(A,B) rend en outre les positions telles que la
  part de C venue de A soit A(IA) et celle venue de B soit B(IB).

  SETXOR(A,B,'stable') garde l'ordre de première apparition : d'abord
  ce qui vient de A, puis ce qui vient de B.

  Exemple :
     setxor([1 2 3 4], [3 4 5])   % [1 2 5]

  Voir aussi UNION, INTERSECT, SETDIFF, ISMEMBER.
```

## `sgtitle`

```
SGTITLE Titre commun à tous les sous-graphes d'une figure.
  SGTITLE(TXT) pose TXT au-dessus de l'ensemble des sous-graphes.
  H = SGTITLE(...) rend la poignée du texte.

  La différence avec TITLE tient à la portée : TITLE nomme un axe,
  SGTITLE nomme la figure entière. C'est ce qu'il faut quand plusieurs
  sous-graphes racontent une même chose sous des angles différents.

  Le rendu étant plan et sans zone réservée au-dessus des axes, le titre
  est posé sur le premier sous-graphe : il est lisible et se retrouve à
  l'impression, mais il n'est pas centré sur la figure comme dans
  MATLAB. C'est la seule différence, et elle est dite ici plutôt que
  laissée à découvrir.

  Exemple :
     figure;
     subplot(1, 2, 1); plot(1:10);
     subplot(1, 2, 2); plot(10:-1:1);
     sgtitle('Deux vues du meme signal');
     close all;

  Voir aussi TITLE, SUBPLOT, SUBTITLE, XLABEL.
```

## `shiftdim`

```
SHIFTDIM Décalage des dimensions d'un tableau.
  B = SHIFTDIM(X,N) décale les dimensions de X de N crans : pour N
  positif, les N premières dimensions passent à la fin ; pour N
  négatif, N dimensions de taille 1 sont ajoutées devant.

  [B,NSHIFTS] = SHIFTDIM(X) supprime les dimensions de tête de taille 1
  et rend leur nombre.

  Exemple :
     a = ones(1,1,3,2);
     [b,n] = shiftdim(a);   % size(b) = [3 2], n = 2

  Voir aussi PERMUTE, RESHAPE, SQUEEZE.
```

## `shortestpath`

```
SHORTESTPATH Plus court chemin entre deux nœuds d'un graphe.
  CHEMIN = SHORTESTPATH(G,S,T) rend la suite des nœuds du plus court
  chemin de S vers T, ou un tableau vide s'il n'y en a aucun.
  [CHEMIN,LONGUEUR] = SHORTESTPATH(...) rend en outre sa longueur, somme
  des poids traversés.
  [...] = SHORTESTPATH(...,'Method','unweighted') ignore les poids et
  compte les arêtes.

  Sur un DIGRAPH, le chemin suit le sens des arcs : il peut exister de S
  vers T et non de T vers S. Sur un GRAPH, les deux sens se valent.

  L'algorithme est celui de Dijkstra, qui suppose des poids positifs.
  Avec un poids négatif il rendrait un résultat faux sans le dire :
  son raisonnement est qu'un nœud une fois atteint au moindre coût ne
  peut plus être amélioré, ce qu'un arc négatif dément.

  Exemple :
     g = graph([1 2 1], [2 3 3], [1 1 5]);
     [c, l] = shortestpath(g, 1, 3);
     c                               % 1 2 3 : le detour est moins cher
     l                               % 2
     d = digraph([1 2 3], [2 3 4]);
     isempty(shortestpath(d, 4, 1))  % 1 : on ne remonte pas un arc

  Voir aussi GRAPH, DIGRAPH, DISTANCES, CONNCOMP, MINSPANTREE.
```

## `slice`

```
SLICE Coupes d'un volume.
  SLICE(V,SX,SY,SZ) montre, dans MATLAB, le volume V coupé par les
  plans d'abscisses SX, d'ordonnées SY et de cotes SZ.

  SLICE(X,Y,Z,V,SX,SY,SZ) place le volume sur la grille donnée.

  H = SLICE(...) rend les poignées.

  Le rendu de MatLibre est plan : il ne montre pas un volume en
  perspective. SLICE dessine donc les coupes les unes à côté des
  autres, chacune comme une image — ce qui donne la même information,
  sans le relief.

  Exemples :
     [X, Y, Z] = meshgrid(-2:0.2:2);
     V = X .* exp(-X.^2 - Y.^2 - Z.^2);
     slice(V, [], [], [5 11 17]);      % trois coupes en z

  Voir aussi IMAGESC, CONTOURSLICE, ISOSURFACE, SURF, MESHGRID.
```

## `sphere`

```
SPHERE Coordonnées d'une sphère.
  SPHERE trace une sphère unité de vingt mailles.
  SPHERE(N) en emploie N.

  [X,Y,Z] = SPHERE(N) rend les trois grilles de coordonnées, sans rien
  tracer. Chacune est de taille (N+1) x (N+1). C'est la forme utile :
  on met ensuite la sphère à l'échelle et on la déplace,

     [X, Y, Z] = sphere(30);
     surf(2*X + 5, 2*Y, 2*Z);        % une sphere de rayon 2 en x = 5

  Le rendu de MatLibre est plan : SPHERE sans sortie montre la
  troisième coordonnée en couleurs, ce qui donne le disque ombré qu'on
  verrait de face.

  Exemples :
     sphere;
     [X, Y, Z] = sphere(10);
     size(X)                          % 11 par 11
     max(max(X.^2 + Y.^2 + Z.^2))     % 1 : les points sont sur la sphere

  Voir aussi CYLINDER, ELLIPSOID, SURF, MESH, PEAKS.
```

## `split`

```
SPLIT Découpe du texte en morceaux.
  C = SPLIT(S) découpe S aux espaces.
  C = SPLIT(S,SEP) découpe au séparateur donné ; SEP peut être un
  tableau de séparateurs, tous reconnus.
  C = SPLIT(S,SEP,DIM) range les morceaux suivant la dimension DIM.

  [C,SEP] = SPLIT(...) rend en outre les séparateurs rencontrés.

  La sortie est un tableau de chaînes quand l'entrée en est un, et un
  tableau de cellules sinon. Toutes les entrées doivent donner le même
  nombre de morceaux, comme dans MATLAB.

  Exemples :
     split('a,b,c', ',')
     split(string({'a-b'; 'c-d'}), '-')

  Voir aussi STRSPLIT, JOIN, SPLITLINES, STRTRIM, EXTRACTBEFORE.
```

## `splitapply`

```
SPLITAPPLY Applique une fonction groupe par groupe.
  Y = SPLITAPPLY(F,X,G) découpe X suivant les numéros de groupe G —
  ceux que rend FINDGROUPS — et applique F à chaque morceau. Les
  résultats sont empilés dans Y, un par groupe.

  Y = SPLITAPPLY(F,X1,X2,...,G) passe un morceau de chaque tableau.
  [Y1,Y2,...] = SPLITAPPLY(...) récupère plusieurs sorties.

  Exemple :
     x = [1 2 3 4];  g = [1 1 2 2];
     splitapply(@sum, x, g)     % [3; 7]

  Voir aussi FINDGROUPS, ACCUMARRAY, ARRAYFUN, GROUPSUMMARY.
```

## `splitlines`

```
SPLITLINES Découpe du texte à chaque saut de ligne.
  C = SPLITLINES(S) rend une ligne par ligne de S. Les trois fins de
  ligne — LF, CR, CRLF — sont reconnues.

  Exemple :
     splitlines(sprintf('un\ndeux'))

  Voir aussi SPLIT, STRSPLIT, JOIN.
```

## `spring`

```
SPRING Carte de couleurs magenta - jaune.
  CARTE = SPRING() rend une carte de 256 couleurs allant du magenta au
  jaune. CARTE = SPRING(M) en rend M.

  Le rouge reste à un, le vert monte de zéro à un et le bleu descend de
  un à zéro : la carte parcourt le bord du cube des couleurs à rouge
  maximal. Comme COOL, elle varie surtout en teinte, la luminance
  augmentant peu ; elle sert quand on veut du contraste coloré sans
  éclaircir le fond.

  Exemple :
     carte = spring(8);
     carte(end, :)

  Voir aussi AUTUMN, SUMMER, WINTER, COLORMAP.
```

## `sprintfc`

```
SPRINTFC Formate chaque valeur dans sa propre cellule.
  C = SPRINTFC(FORMAT,VALEURS) applique le format à chaque élément de
  VALEURS et rend un tableau de cellules de même taille, une chaîne par
  élément.

  SPRINTF, lui, recycle le format sur toutes les valeurs et rend une
  seule chaîne : SPRINTF('%d ', 1:3) donne '1 2 3 ', là où SPRINTFC rend
  trois cellules. C'est la différence entre concaténer et étiqueter.

  La fonction n'est pas documentée par MathWorks, mais elle existe
  depuis longtemps et sert à fabriquer des étiquettes d'axes ou de
  légende, où l'on veut une chaîne par élément.

  Exemple :
     sprintfc('%d', [1 2 3])             % {'1'  '2'  '3'}
     sprintfc('point %d', 1:2)           % {'point 1'  'point 2'}
     numel(sprintfc('%.2f', rand(2, 3))) % 6 : la forme est gardee

  Voir aussi SPRINTF, COMPOSE, NUM2STR, CELLSTR.
```

## `stackedplot`

```
STACKEDPLOT Plusieurs signaux empilés, une échelle chacun.
  STACKEDPLOT(Y) trace chaque colonne de Y dans son propre cadre, les
  uns au-dessus des autres, avec un axe des abscisses commun. Chaque
  signal garde son échelle : c'est ce qui distingue STACKEDPLOT d'un
  PLOT de toutes les colonnes, où le plus grand écrase les autres.

  STACKEDPLOT(X,Y) place les points aux abscisses X.

  STACKEDPLOT(...,'DisplayLabels',L) nomme les cadres avec les chaînes
  de L.

  H = STACKEDPLOT(...) rend les poignées des courbes.

  Exemples :
     t = linspace(0, 10, 200)';
     Y = [sin(t), 1000 * exp(-t), t.^2];
     stackedplot(t, Y, 'DisplayLabels', {'sin', 'exp', 'carre'});

  Voir aussi PLOT, SUBPLOT, TILEDLAYOUT, PLOTYY, YYAXIS.
```

## `standardizeMissing`

```
STANDARDIZEMISSING Remplace des valeurs par la marque de manquant.
  B = STANDARDIZEMISSING(A,IND) remplace par la valeur manquante
  propre au type — NaN, '', <undefined>, NaT — toutes les valeurs
  énumérées dans IND. C'est le pas à faire avant RMMISSING quand un
  fichier code l'absence par -99 ou par 'N/A'.

  STANDARDIZEMISSING(T,IND,'DataVariables',V) ne touche, dans une
  table, que les variables nommées.

  Exemple :
     standardizeMissing([1 2 -99], -99)    % [1 2 NaN]

  Voir aussi ISMISSING, RMMISSING, FILLMISSING.
```

## `stem3`

```
STEM3 Tiges dans l'espace.
  STEM3(X,Y,Z) trace, pour chaque triplet, une tige verticale surmontée
  d'un cercle.
  STEM3(Z) place les tiges aux nœuds d'une grille entière.
  STEM3(...,STYLE) prend une chaîne de style.

  H = STEM3(...) rend la poignée.

  Le rendu de MatLibre est plan : la tige va de zéro à Z, dessinée dans
  le plan des X et des Z.

  Exemples :
     t = linspace(0, 2*pi, 20);
     stem3(cos(t), sin(t), t);
     stem3(rand(4, 4));

  Voir aussi STEM, PLOT3, SCATTER3, BAR3.
```

## `strings`

```
STRINGS Tableau de chaînes vides.
  S = STRINGS(N) rend un tableau N sur N de chaînes vides.
  S = STRINGS(M,N) rend un tableau M sur N.
  S = STRINGS(SIZE) accepte aussi un vecteur de dimensions.
  S = STRINGS() rend une seule chaîne vide.

  Une chaîne vide n'est pas une chaîne manquante : "" a une longueur
  nulle, alors que MISSING n'a pas de valeur. C'est pourquoi STRINGS
  sert à préallouer — les cases sont utilisables telles quelles — là où
  un tableau de manquantes signalerait qu'il reste du travail.

  Préallouer avant une boucle évite de réallouer à chaque tour, ce qui
  coûte cher dès que le tableau devient grand.

  Exemple :
     s = strings(1, 3);
     strlength(s)                    % [0 0 0]
     s(2) = "milieu";

  Voir aussi STRING, BLANKS, CELL, ZEROS, ISMISSING.
```

## `subtitle`

```
SUBTITLE Sous-titre d'un axe, sous son titre.
  SUBTITLE(TXT) pose TXT sous le titre de l'axe courant.
  H = SUBTITLE(...) rend la poignée du texte.

  Le rendu n'ayant qu'une ligne de titre par axe, le sous-titre est
  joint au titre, séparé par un retour à la ligne. Le texte est donc
  bien là, mais sur la même poignée que le titre : le modifier ensuite
  modifie les deux. C'est dit ici plutôt que laissé à découvrir.

  Exemple :
     figure; plot(1:10);
     title('Signal');
     subtitle('mesure du 3 mars');
     close all;

  Voir aussi TITLE, SGTITLE, XLABEL.
```

## `summer`

```
SUMMER Carte de couleurs vert - jaune.
  CARTE = SUMMER() rend une carte de 256 couleurs allant du vert au
  jaune. CARTE = SUMMER(M) en rend M.

  Le rouge monte de zéro à un, le vert de 0,5 à un, le bleu reste à 0,4.
  Le bleu constant, non nul, désature l'ensemble : aucune couleur n'est
  pure, ce qui adoucit la carte et évite les teintes criardes des cartes
  à canaux saturés.

  La clarté croît de façon monotone, donc l'ordre des valeurs reste
  lisible en niveaux de gris.

  Exemple :
     carte = summer(8);
     carte(:, 3)'

  Voir aussi AUTUMN, SPRING, WINTER, COLORMAP.
```

## `surfc`

```
SURFC Surface, avec ses lignes de niveau en dessous.
  SURFC(X,Y,Z) trace la surface et, dans le plan du bas, ses lignes de
  niveau. SURFC(Z) prend une grille entière.

  H = SURFC(...) rend les poignées.

  Le rendu de MatLibre est plan : la surface est montrée en couleurs,
  et les lignes de niveau par-dessus.

  Exemples :
     surfc(peaks(30));
     [X, Y] = meshgrid(-2:0.2:2);
     surfc(X, Y, X.^2 - Y.^2);

  Voir aussi SURF, MESHC, CONTOUR, SURFL, PEAKS.
```

## `surfl`

```
SURFL Surface éclairée.
  SURFL(X,Y,Z) trace la surface en la colorant d'après l'angle que fait
  sa normale avec une source de lumière, ce qui en fait ressortir le
  relief. SURFL(Z) prend une grille entière.

  SURFL(...,S) place la source dans la direction S = [AZIMUT ELEVATION]
  ou S = [SX SY SZ].

  H = SURFL(...) rend la poignée.

  MatLibre ne fait pas d'éclairage : la surface est montrée en
  couleurs, comme SURF, et la direction de la source est acceptée sans
  effet. Ce qui manque est l'ombrage ; ce que la surface vaut se lit
  toujours.

  Exemples :
     surfl(peaks(40));
     surfl(peaks(40), [45 30]);

  Voir aussi SURF, SURFNORM, LIGHT, LIGHTING, MATERIAL, SHADING.
```

## `surfnorm`

```
SURFNORM Normales d'une surface.
  [NX,NY,NZ] = SURFNORM(X,Y,Z) rend les trois composantes de la normale
  unitaire en chaque point de la surface. La normale est le produit
  vectoriel des deux dérivées partielles, normalisé.

  [NX,NY,NZ] = SURFNORM(Z) prend une grille entière pour X et Y.

  SURFNORM(...) sans sortie trace la surface et ses normales.

  Les dérivées sont obtenues par GRADIENT, donc par différences
  centrées à l'intérieur et décentrées aux bords.

  Exemples :
     [X, Y] = meshgrid(-2:0.5:2);
     Z = X .* exp(-X.^2 - Y.^2);
     [nx, ny, nz] = surfnorm(X, Y, Z);
     max(max(abs(nx.^2 + ny.^2 + nz.^2 - 1)))     % 1 : elles sont unitaires

     surfnorm(X, Y, Z);

  Voir aussi GRADIENT, SURF, QUIVER3, MESH.
```

## `svds`

```
SVDS Quelques valeurs singulières seulement.
  S = SVDS(A) rend les six plus grandes valeurs singulières.
  S = SVDS(A,K) en rend K. S = SVDS(A,K,'smallest') rend les K plus
  petites.
  [U,S,V] = SVDS(...) rend la décomposition tronquée : A est approchée
  par U*S*V', et c'est la meilleure approximation de rang K au sens de
  la norme de Frobenius comme de la norme spectrale — c'est le théorème
  d'Eckart-Young.

  Comme EIGS, MATLAB emploie une méthode de Krylov et MatLibre la
  décomposition complète tronquée : même résultat, coût de SVD.

  La troncature est le fondement de l'analyse en composantes
  principales et de la compression : garder les K premières valeurs
  singulières, c'est garder la part d'énergie qu'elles portent, et
  l'erreur commise est exactement la valeur singulière suivante.

  Exemple :
     A = magic(4);
     svds(A, 2)'                         % les deux plus grandes
     [U, S, V] = svds(A, 1);
     s = svd(A);
     abs(norm(A - U * S * V') - s(2)) < 1e-10   % Eckart-Young

  Voir aussi SVD, EIGS, PCA, RANK, NORMEST.
```

## `swapbytes`

```
SWAPBYTES Inverse l'ordre des octets.
  Y = SWAPBYTES(X) rend X avec, pour chaque élément, les octets pris à
  l'envers : c'est le passage d'un boutisme à l'autre. X doit être d'un
  type entier ou flottant de taille connue ; la classe est conservée.

  Exemple :
     swapbytes(uint16(1))    % 256

  Voir aussi TYPECAST, CAST, CLASS.
```

## `swarmchart`

```
SWARMCHART Nuage de points dispersés par catégorie.
  SWARMCHART(X,Y) dessine les points (X,Y) en écartant latéralement ceux
  qui partagent la même abscisse, de sorte qu'aucun n'en cache un autre.
  SWARMCHART(X,Y,TAILLE) et SWARMCHART(X,Y,TAILLE,COULEUR) suivent la
  syntaxe de SCATTER.
  SWARMCHART(...,'XJitter',...) et les autres propriétés sont acceptées.
  H = SWARMCHART(...) rend la poignée.

  Un nuage ordinaire superpose les points de même abscisse : sur des
  données groupées, on ne voit plus qu'un trait vertical et l'effectif
  disparaît. L'écartement rend visible la densité — c'est la même
  information qu'un histogramme, mais sans choisir de largeur de classe.

  L'écart est déterministe, non tiré au hasard : les points d'un même
  groupe sont répartis symétriquement autour de leur abscisse, ce qui
  redonne le même dessin d'un appel à l'autre.

  Exemple :
     figure();
     x = [ones(1, 20), 2 * ones(1, 20)];
     swarmchart(x, [randn(1, 20), randn(1, 20) + 3]);
     close all;

  Voir aussi SCATTER, BOXCHART, HISTOGRAM, PLOT.
```

## `symamd`

```
SYMAMD Renumérotation par degré minimal, matrice symétrique.
  P = SYMAMD(A) rend une permutation qui réduit le remplissage de la
  factorisation de Cholesky de A(P,P).

  L'algorithme élimine à chaque pas le nœud de plus petit degré dans le
  graphe d'élimination, puis relie entre eux tous ses voisins — c'est ce
  que fait la factorisation, et simuler le graphe suffit à prévoir le
  remplissage sans calculer la moindre valeur.

  MATLAB emploie ici l'approximation d'Amestoy, Davis et Duff, qui
  majore le degré au lieu de le recalculer ; MatLibre calcule le degré
  exact. Le résultat est du même ordre et le coût plus élevé, ce qui
  compte sur une très grande matrice et pas sur une petite.

  Réduire le remplissage n'est pas la même chose que réduire la bande :
  SYMRCM range les coefficients près de la diagonale, SYMAMD ne s'occupe
  que de ce que la factorisation va créer. Sur une matrice issue d'un
  maillage, le degré minimal l'emporte largement.

  Exemple :
     A = [1 1 1 1; 1 1 0 0; 1 0 1 0; 1 0 0 1];
     p = symamd(A);
     isequal(sort(p), 1:4)                    % 1 : c'est une permutation
     find(p == 1) > 1                         % le noeud le plus lie attend

  Voir aussi SYMRCM, COLAMD, CHOL.
```

## `symrcm`

```
SYMRCM Renumérotation de Cuthill-McKee inverse.
  P = SYMRCM(A) rend une permutation qui, appliquée à A, en réduit la
  largeur de bande : A(P,P) a ses coefficients non nuls plus près de la
  diagonale.

  L'algorithme parcourt le graphe d'adjacence en largeur depuis un nœud
  périphérique, en visitant les voisins par degré croissant, puis
  renverse l'ordre obtenu. Le renversement n'est pas un ornement : il
  déplace les nœuds de fort degré vers la fin, ce qui réduit encore le
  remplissage de la factorisation.

  Une bande étroite fait deux choses : la factorisation de Cholesky ne
  remplit que dans la bande, donc coûte O(n*b^2) au lieu de O(n^3), et
  le stockage suit. C'est la raison d'être de la renumérotation.

  Le nœud de départ est choisi de plus petit degré : c'est
  l'heuristique usuelle pour approcher un nœud périphérique sans
  calculer l'excentricité de tous.

  Exemple :
     A = [1 0 1 0; 0 1 0 1; 1 0 1 0; 0 1 0 1];
     p = symrcm(A);
     isequal(sort(p), 1:4)                    % 1 : c'est une permutation
     matlibre_largeur_bande(A(p, p)) <= matlibre_largeur_bande(A)

  Voir aussi SYMAMD, COLAMD, CHOL, LU.
```

## `tabularTextDatastore`

```
TABULARTEXTDATASTORE Lecture par morceaux d'un ou plusieurs fichiers texte.
  DS = TABULARTEXTDATASTORE(CHEMIN) ouvre un fichier, une liste de
  fichiers, ou tous les fichiers d'un dossier. La lecture se fait
  ensuite par morceaux : READ rend le suivant, HASDATA dit s'il en
  reste, RESET revient au début, READALL lit tout d'un coup.

  L'intérêt d'un magasin de données est de ne pas tout charger : un jeu
  plus gros que la mémoire se traite morceau par morceau, et le
  programme qui le parcourt ne change pas quand le jeu grandit. C'est
  la seule raison d'en employer un ; pour un fichier qui tient en
  mémoire, READTABLE suffit et va plus vite.

  Réglages : 'ReadSize' (nombre de lignes par morceau, 20000 par
  défaut), 'Delimiter', 'ReadVariableNames', 'TreatAsMissing'.

  Le magasin se copie par référence : READ le fait avancer, sans qu'on
  ait à le réaffecter. C'est ce qui permet d'écrire la boucle usuelle —
  « while hasdata(ds), morceau = read(ds); end » — qui ne se terminerait
  jamais sur un objet qui se copierait par valeur.

  Exemple :
     f = [tempname '.csv'];
     writelines(["a,b"; "1,2"; "3,4"; "5,6"], f);
     ds = tabularTextDatastore(f, 'ReadSize', 2);
     premier = read(ds);
     height(premier)                 % 2 lignes : le morceau demande
     delete(f);

  Voir aussi DATASTORE, READTABLE, READ, READALL, PRESERVE.
```

## `tall`

```
TALL Tableau dont le calcul est différé.
  T = TALL(A) fait d'un tableau un tableau différé. T = TALL(MAGASIN)
  part d'un magasin de données. Les opérations ordinaires — arithmétique,
  comparaison, fonctions élémentaires, réductions, indexation — ne
  calculent rien : elles décrivent ce qu'il faudra faire. GATHER
  l'exécute et rend le résultat ordinaire.

  C'est ce report qui fait l'intérêt du procédé : on écrit la chaîne
  entière — filtrer, transformer, résumer — puis on la parcourt une
  seule fois. Décrire ne coûte rien, et une chaîne qui ne finit pas par
  GATHER ne coûte rien non plus.

  Dans MATLAB, un tableau différé permet en outre de travailler sur des
  données plus grandes que la mémoire. Ici le calcul est bien différé,
  mais il s'effectue en mémoire au moment du GATHER : la forme du
  programme est celle de MATLAB, l'économie de mémoire ne l'est pas.
  TALL(MAGASIN) lit donc tout le magasin lorsqu'on rassemble.

  SIZE, NUMEL, LENGTH et ISEMPTY répondent directement au lieu de
  rendre un tableau différé comme le fait MATLAB : la taille est ici
  connue sans détour, et imposer un GATHER pour l'obtenir n'apprendrait
  rien à personne.

  Exemple :
     t = tall([1 2 3 4 5]);
     grands = t(t > 2);
     gather(sum(grands))             % 12
     istall(grands)                  % 1 : rien n'a encore ete calcule

  Voir aussi GATHER, ISTALL, DATASTORE, ARRAYDATASTORE, HEAD, TAIL.
```

## `tensorprod`

```
TENSORPROD Produit tensoriel avec contraction de dimensions.
  C = TENSORPROD(A,B) rend le produit extérieur : C a pour dimensions
  celles de A suivies de celles de B, et C(i,...,j,...) = A(i,...)*B(j,...).
  C = TENSORPROD(A,B,DIMA,DIMB) contracte les dimensions DIMA de A avec
  les dimensions DIMB de B, qui doivent être de mêmes tailles : on
  somme sur ces indices, et ils disparaissent du résultat.
  C = TENSORPROD(A,B,'all') contracte toutes les dimensions et rend un
  scalaire, à condition que A et B aient la même taille.

  C'est la généralisation du produit matriciel : contracter la deuxième
  dimension de A avec la première de B redonne A*B. Le produit scalaire,
  la trace d'un produit, le produit extérieur en sont d'autres cas
  particuliers — ce qui les distingue n'est que le choix des indices
  sommés.

  Exemple :
     A = [1 2; 3 4];
     B = [5 6; 7 8];
     max(max(abs(tensorprod(A, B, 2, 1) - A * B))) < 1e-12
     tensorprod([1 2 3], [4 5 6], 2, 2)      % 32 : le produit scalaire
     size(tensorprod(ones(2, 3), ones(4, 5)))   % 2 3 4 5

  Voir aussi PAGEMTIMES, KRON, DOT, MTIMES, PERMUTE.
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

## `timeit`

```
TIMEIT Mesure le temps d'exécution d'une fonction.
  T = TIMEIT(F) appelle F plusieurs fois et rend la médiane des temps
  mesurés, en secondes. F ne prend aucun argument : pour mesurer un
  appel avec arguments, on l'enveloppe — TIMEIT(@() sort(x)).
  T = TIMEIT(F,NSORTIES) demande NSORTIES sorties à chaque appel.

  La médiane, non la moyenne : une mesure de temps est bornée par le
  bas — l'exécution ne peut pas être plus rapide que ce que la machine
  permet — et polluée par le haut, dès qu'un autre processus prend la
  main. La distribution est donc dissymétrique, et la moyenne suit les
  valeurs hautes qui ne disent rien de la fonction.

  Le nombre d'appels s'adapte : une fonction rapide est appelée en
  rafale jusqu'à ce que le total soit mesurable, et le temps rendu est
  celui d'un appel. Sans cela, la résolution de l'horloge dominerait le
  résultat.

  Un premier appel est fait et jeté : il paie le chargement du fichier,
  l'allocation initiale et le remplissage des caches, qu'on ne veut pas
  compter.

  Exemple :
     t = timeit(@() sum(1:1000));
     t > 0 && t < 1
     x = rand(1, 1000);
     timeit(@() sort(x)) > 0

  Voir aussi TIC, TOC, PROFILE, CPUTIME.
```

## `topkrows`

```
TOPKROWS Les K premières lignes dans l'ordre du tri.
  B = TOPKROWS(A,K) rend les K lignes de A qui viennent en tête d'un tri
  décroissant, colonne par colonne de gauche à droite : la première
  colonne décide, la deuxième départage, et ainsi de suite.
  B = TOPKROWS(A,K,COL) trie sur les colonnes données, dans cet ordre.
  Une colonne négative se trie en ordre croissant.
  B = TOPKROWS(A,K,COL,SENS) impose 'ascend' ou 'descend'.
  [B,I] = TOPKROWS(...) rend en outre les rangs des lignes retenues
  dans A.

  C'est SORTROWS suivi d'une troncature, mais l'intention est autre :
  on ne veut pas l'ordre complet, seulement le sommet. La différence
  compte dès que le tableau est grand — K lignes sur un million ne
  demandent pas de trier le million.

  Si K dépasse le nombre de lignes, toutes sont rendues.

  Exemple :
     topkrows([3 1; 1 2; 2 3], 2)          % [3 1; 2 3]
     topkrows([3 1; 1 2; 2 3], 2, 2)       % trie sur la deuxieme colonne
     [b, i] = topkrows([3 1; 1 2; 2 3], 1);
     i                                     % 1 : la premiere ligne

  Voir aussi SORTROWS, SORT, MAXK, MINK.
```

## `transform`

```
TRANSFORM Applique une fonction à chaque morceau lu d'un magasin.
  DS = TRANSFORM(MAGASIN,F) rend un magasin dont chaque lecture rend
  F appliquée au morceau qu'aurait rendu MAGASIN.

  La transformation est paresseuse : elle n'a lieu qu'au moment de la
  lecture, morceau par morceau. C'est ce qui permet de décrire un
  prétraitement — mettre à l'échelle, découper, recoder — sans jamais
  tenir le jeu entier.

  Exemple :
     a = arrayDatastore([1; 2; 3]);
     d = transform(a, @(x) x * 10);
     read(d)                         % 10

  Voir aussi COMBINE, DATASTORE, READ, CELLFUN.
```

## `triangulation`

```
TRIANGULATION Maillage de triangles ou de tétraèdres.
  TR = TRIANGULATION(T,P) réunit une liste de connectivité T — une
  ligne par élément, portant les indices de ses sommets — et les points
  P, une ligne par point. C'est la façon dont MATLAB range un maillage :
  les coordonnées d'un côté, la topologie de l'autre, ce qui permet de
  déplacer les points sans refaire la connectivité.

  TR = TRIANGULATION(T,X,Y) et TRIANGULATION(T,X,Y,Z) acceptent les
  coordonnées séparées.

  Ce qu'on lui demande : FREEBOUNDARY, EDGES, NEIGHBORS, CIRCUMCENTER,
  INCENTER, FACENORMAL, VERTEXATTACHMENTS, EDGEATTACHMENTS, SIZE,
  ISCONNECTED, BARYCENTRICTOCARTESIAN, CARTESIANTOBARYCENTRIC.

  Exemple :
     P = [0 0; 1 0; 1 1; 0 1];
     T = [1 2 3; 1 3 4];
     tr = triangulation(T, P);
     size(freeBoundary(tr), 1)       % 4 : le carre a quatre cotes
     size(edges(tr), 1)              % 5 : quatre cotes et la diagonale

  Voir aussi DELAUNAYTRIANGULATION, DELAUNAY, FREEBOUNDARY, CONVHULL.
```

## `trimesh`

```
TRIMESH Maillage d'une triangulation.
  TRIMESH(T,X,Y,Z) trace les arêtes des triangles de T, dont les
  sommets sont (X,Y,Z). C'est TRISURF sans le remplissage : on voit à
  travers.

  TRIMESH(T,X,Y) trace la triangulation à plat.

  TRIMESH(...,'Color',C) fixe la couleur des arêtes.

  H = TRIMESH(...) rend les poignées.

  Le rendu de MatLibre est plan, comme pour TRISURF.

  Exemples :
     x = rand(30, 1); y = rand(30, 1);
     T = delaunay(x, y);
     trimesh(T, x, y);

  Voir aussi TRISURF, DELAUNAY, VORONOI, PATCH, PLOT.
```

## `trisurf`

```
TRISURF Surface définie par une triangulation.
  TRISURF(T,X,Y,Z) trace la surface dont les sommets sont (X,Y,Z) et
  les faces les triangles de T : chaque ligne de T donne les trois
  indices des sommets d'une face.

  TRISURF(T,X,Y) trace la triangulation à plat.

  TRISURF(...,'FaceColor',C) fixe la couleur des faces.

  H = TRISURF(...) rend les poignées des faces.

  Le rendu de MatLibre est plan : les triangles sont dessinés dans le
  plan des X et des Y, remplis d'une couleur unie.

  Exemples :
     x = rand(30, 1); y = rand(30, 1);
     T = delaunay(x, y);
     trisurf(T, x, y, x.^2 + y.^2);

  Voir aussi TRIMESH, DELAUNAY, PATCH, FILL, VORONOI.
```

## `uicontrol`

```
UICONTROL Commande d'interface (indisponible).
  UICONTROL crée, dans MATLAB, un bouton, une case à cocher, un champ
  de saisie ou un curseur dans une figure.

  MatLibre n'a pas de construction d'interfaces dans ses figures : ni
  UICONTROL, ni UIFIGURE, ni App Designer. Le bureau natif de MatLibre
  est écrit en Qt, non en MATLAB, et ses figures ne portent que des
  tracés. UICONTROL le dit plutôt que de créer un objet muet dont un
  programme attendrait des clics.

  Ce manque est documenté dans documentation/manques.md, au chapitre
  du bureau.

  Exemple :
     % MatLibre ne trace que des courbes : UICONTROL le dit plutot que de
     % rendre une poignee vers un bouton qui n'existe pas.
     try
         uicontrol('Style', 'pushbutton', 'String', 'ok');
     catch e
         e.identifier
     end

  Voir aussi FIGURE, INPUT, MENU, DISP.
```

## `unicode2native`

```
UNICODE2NATIVE Convertit du texte en octets.
  B = UNICODE2NATIVE(T) rend les octets du texte T dans l'encodage par
  défaut, qui est ici UTF-8. B = UNICODE2NATIVE(T,ENCODAGE) choisit
  l'encodage : 'UTF-8', 'US-ASCII' ou 'ISO-8859-1'.

  Dans MatLibre, un tableau de caractères contient déjà les octets
  UTF-8 du texte : la conversion vers UTF-8 est donc un changement de
  type et rien d'autre. Vers un encodage plus étroit, un caractère qui
  n'y tient pas devient un point d'interrogation, comme dans MATLAB —
  perdre un accent vaut mieux qu'échouer sur un fichier entier.

  Exemple :
     double(unicode2native('abc'))                 % [97 98 99]
     numel(unicode2native('é'))                    % 2 : deux octets en UTF-8
     double(unicode2native('é', 'ISO-8859-1'))     % 233 : un seul octet

  Voir aussi NATIVE2UNICODE, CHAR, DOUBLE, FWRITE.
```

## `uniquetol`

```
UNIQUETOL Valeurs distinctes à une tolérance près.
  U = UNIQUETOL(X,TOL) regroupe les valeurs dont l'écart relatif est
  inférieur à TOL (1e-6 par défaut).

  Exemple :
     u = uniquetol([1 1 + 1e-9 2], 1e-6);
     numel(u)                    % 2 : les deux premiers se confondent

  Voir aussi ISMEMBERTOL.
```

## `unzip`

```
UNZIP Extrait une archive ZIP.
  UNZIP(ARCHIVE,DOSSIER) extrait dans le dossier donné, le dossier
  courant par défaut.

  Exemple :
     f = fopen('a.txt', 'w'); fprintf(f, 'bonjour'); fclose(f);
     zip('archive.zip', {'a.txt'});
     delete('a.txt');
     unzip('archive.zip');
     fileread('a.txt')           % 'bonjour'

  Voir aussi ZIP.
```

## `usejava`

```
USEJAVA Dit si une partie de Java est disponible.
  T = USEJAVA(COMPOSANT) rend vrai si le composant demandé est
  utilisable. Les composants sont 'jvm', 'awt', 'swing' et 'desktop'.

  MatLibre n'embarque pas de machine virtuelle Java : la réponse est
  donc toujours faux. C'est la réponse utile — le rôle de USEJAVA est
  précisément de permettre à un programme de choisir une autre voie,
  et un programme qui interroge obtient ici de quoi le faire au lieu
  d'une fonction introuvable.

  Exemple :
     usejava('jvm')                  % 0 : pas de machine virtuelle
     if ~usejava('swing'), disp('interface en mode texte'); end

  Voir aussi ISJAVA, JAVACLASSPATH, JAVAOBJECT, COMPUTER.
```

## `validatestring`

```
VALIDATESTRING Complète une option textuelle parmi une liste.
  S = VALIDATESTRING(CHAINE,OPTIONS) rend l'élément de OPTIONS dont
  CHAINE est un préfixe, sans distinction de casse. Une erreur est levée
  si aucun ou plusieurs éléments correspondent.

  Exemple :
     validatestring('lin', {'linear', 'cubic'})     % 'linear' : l'abrege suffit

  Voir aussi INPUTPARSER.
```

## `vecnorm`

```
VECNORM Norme de chaque vecteur d'un tableau.
  N = VECNORM(A) rend la norme 2 de chaque colonne.
  N = VECNORM(A,P) utilise la norme P.
  N = VECNORM(A,P,DIM) travaille le long de la dimension DIM.

  Exemple :
     vecnorm([3 4]')             % 5 : la norme de la colonne
     vecnorm([3 4; 0 0], 2, 2)'  % 5 0 : par ligne

  Voir aussi NORM, SUM, HYPOT.
```

## `vectorize`

```
VECTORIZE Rend une expression applicable terme à terme.
  S = VECTORIZE(EXPRESSION) insère un point devant les opérateurs de
  multiplication, de division et de puissance : l'expression s'applique
  alors à des tableaux entiers plutôt qu'à des scalaires.

  Un point déjà présent n'est pas redoublé.

  EXPRESSION peut être une chaîne, un tableau de cellules de chaînes ou
  une poignée de fonction anonyme ; le résultat est du même genre, sauf
  pour une poignée, rendue sous forme de chaîne comme dans MATLAB.

  Exemple :
     vectorize('a*x^2 + b/c')      % a.*x.^2 + b./c

  Voir aussi STR2FUNC, FUNC2STR, INLINE.
```

## `voronoi`

```
VORONOI Diagramme de Voronoï.
  VORONOI(X,Y) trace le diagramme de Voronoï des points (X,Y) : le plan
  découpé en régions, une par point, chaque région rassemblant ce qui
  est plus proche de ce point que de tout autre.

  VORONOI(X,Y,T) emploie la triangulation T plutôt que de la calculer.

  [VX,VY] = VORONOI(...) rend les arêtes sans rien tracer : chaque
  colonne porte les deux extrémités d'une arête.

  Le diagramme est le dual de la triangulation de Delaunay : à chaque
  arête de Delaunay entre deux points correspond une arête de Voronoï
  qui joint les centres des cercles circonscrits des deux triangles
  adjacents. Les arêtes du bord, qui n'ont qu'un triangle, partent vers
  l'infini ; MatLibre les tronque au cadre du dessin.

  Exemples :
     x = rand(20, 1); y = rand(20, 1);
     voronoi(x, y);

     voronoi([0 1 1 0 0.5], [0 0 1 1 0.5]);

  Voir aussi DELAUNAY, TRIMESH, CONVHULL, PDIST2, KNNSEARCH.
```

## `waterfall`

```
WATERFALL Surface dessinée en lignes, une par rangée.
  WATERFALL(X,Y,Z) trace une courbe par ligne de Z, décalée de sorte
  que les courbes se suivent comme les marches d'une cascade. C'est la
  façon de montrer une famille de signaux — un spectre au fil du temps,
  par exemple — sans les superposer.

  WATERFALL(Z) prend une grille entière.

  H = WATERFALL(...) rend les poignées.

  Le rendu de MatLibre est plan : les courbes sont décalées
  verticalement d'un pas constant, ce qui donne la même lecture que la
  perspective de MATLAB.

  Exemples :
     waterfall(peaks(20));

     t = linspace(0, 1, 200);
     S = zeros(8, 200);
     for k = 1:8, S(k, :) = sin(2*pi*k*t) / k; end
     waterfall(S);

  Voir aussi RIBBON, MESH, SURF, PLOT3, STACKEDPLOT.
```

## `weboptions`

```
WEBOPTIONS Réglages d'une requête web.
  O = WEBOPTIONS() rend les réglages par défaut. O = WEBOPTIONS(NOM,
  VALEUR,...) en fixe. L'objet se passe ensuite à WEBREAD, WEBWRITE ou
  WEBSAVE.

  Les réglages reconnus : 'Timeout' (secondes), 'ContentType'
  ('auto', 'text', 'json', 'raw'), 'MediaType' (le type envoyé),
  'RequestMethod' ('auto', 'get', 'post', 'put', 'delete'),
  'CharacterEncoding', 'UserAgent', 'Username', 'Password',
  'HeaderFields' (une matrice de cellules à deux colonnes) et
  'CertificateFilename'.

  Exemple :
     o = weboptions('Timeout', 30, 'ContentType', 'json');
     o.Timeout                       % 30
     o.ContentType                   % 'json'

  Voir aussi WEBREAD, WEBWRITE, WEBSAVE, URLREAD.
```

## `webread`

```
WEBREAD Lit le contenu d'une adresse.
  C = WEBREAD(URL) télécharge l'adresse et rend son contenu. Un
  document JSON est décodé en structure ou en tableau de cellules ; un
  fichier délimité est lu comme une matrice ; le reste est rendu tel
  quel, en texte.

  C = WEBREAD(URL,NOM1,VAL1,...) ajoute des paramètres à la requête.

  C = WEBREAD(...,OPTIONS) obéit aux réglages de WEBOPTIONS ;
  'ContentType' impose alors l'interprétation au lieu de la deviner.

  Le téléchargement passe par curl, qui doit être installé. Aucune
  donnée n'est envoyée que celles de l'appel.

  Exemple :
     s = webread('https://example.com');

  Voir aussi WEBSAVE, WEBWRITE, WEBOPTIONS, JSONDECODE, URLREAD.
```

## `websave`

```
WEBSAVE Enregistre le contenu d'une adresse dans un fichier.
  F = WEBSAVE(FICHIER,URL) télécharge l'adresse et l'écrit dans
  FICHIER ; F est le chemin complet du fichier écrit.

  F = WEBSAVE(FICHIER,URL,NOM1,VAL1,...) ajoute des paramètres à la
  requête, comme le fait MATLAB : websave(f, url, 'q', 'chat') demande
  URL?q=chat.

  F = WEBSAVE(...,OPTIONS) obéit en plus aux réglages de WEBOPTIONS :
  délai, agent, authentification, en-têtes, autorité de certification.

  Le téléchargement passe par curl, qui doit être installé. Aucune
  donnée n'est envoyée que celles de l'appel.

  Exemple :
     f = websave(fullfile(tempdir, 'page.html'), 'https://example.com');

  Voir aussi WEBREAD, WEBWRITE, WEBOPTIONS, URLREAD, FILEREAD.
```

## `webwrite`

```
WEBWRITE Envoie des données à une adresse et rend sa réponse.
  R = WEBWRITE(URL,NOM1,VAL1,...) envoie les couples en corps de
  requête, encodés comme un formulaire, et rend la réponse décodée.

  R = WEBWRITE(URL,DONNEES) envoie DONNEES : un texte part tel quel,
  une structure ou une cellule part en JSON.

  R = WEBWRITE(...,OPTIONS) obéit aux réglages de WEBOPTIONS.
  'RequestMethod' choisit la méthode — POST par défaut, mais aussi PUT
  ou DELETE ; 'MediaType' déclare le type envoyé ; 'ContentType' dit
  comment lire la réponse.

  L'envoi passe par curl, qui doit être installé. Rien n'est envoyé
  que ce que l'appel contient.

  Exemple :
     o = weboptions('MediaType', 'application/json', 'RequestMethod', 'put');
     strcmp(o.MediaType, 'application/json')   % 1 : le type declare
     % r = webwrite('https://exemple.test/api', struct('a', 1), o);

  Voir aussi WEBREAD, WEBSAVE, WEBOPTIONS, JSONENCODE.
```

## `weeknum`

```
WEEKNUM Numéro de la semaine dans l'année.
  N = WEEKNUM(D) rend le numéro de la semaine où tombe la date D : la
  semaine 1 est celle du 1er janvier, et les semaines commencent le
  dimanche.

  N = WEEKNUM(D,J) fait commencer la semaine au jour J (1 pour
  dimanche, 2 pour lundi, …).

  N = WEEKNUM(D,J,1) suit la règle européenne (ISO 8601) : la semaine
  1 est celle qui contient le premier jeudi de l'année.

  Exemple :
     weeknum(datenum(2024, 1, 8))     % 2

  Voir aussi WEEKDAY, CALENDAR, DATENUM, DAY.
```

## `what`

```
WHAT Inventaire des fichiers MATLAB d'un dossier.
  S = WHAT(D) rend une structure décrivant le contenu de D : les
  fichiers .m, .mat, .mlx, .mex, les classes (@) et les paquets (+).
  Sans sortie, l'inventaire s'affiche.

  Sans argument, WHAT décrit le dossier courant.

  Exemple :
     s = what(matlibre_racine());     % le dossier des toolbox
     numel(s.m) >= 0

  Voir aussi DIR, WHICH, EXIST, LS.
```

## `wilkinson`

```
WILKINSON Matrice d'essai de Wilkinson.
  W = WILKINSON(N) rend une matrice tridiagonale symétrique dont la
  diagonale décroît puis recroît symétriquement, et dont les deux
  sous-diagonales ne comptent que des uns.

  Son intérêt tient à ses valeurs propres : les plus grandes vont par
  paires presque égales, séparées de moins de 1e-14 pour N = 21. C'est
  le cas d'école qui éprouve un algorithme de valeurs propres, car
  distinguer deux valeurs si proches demande toute la précision de la
  machine.

  Exemple :
     wilkinson(7)
     v = sort(eig(wilkinson(21)), 'descend');
     v(1) - v(2)                     % moins de 1e-13

  Voir aussi EIG, PASCAL, HILB, HADAMARD.
```

## `winter`

```
WINTER Carte de couleurs bleu - vert.
  CARTE = WINTER() rend une carte de 256 couleurs allant du bleu au
  vert. CARTE = WINTER(M) en rend M.

  Le rouge est nul, le vert monte de zéro à un, le bleu descend de un à
  0,5 sans jamais s'annuler. La carte reste donc froide d'un bout à
  l'autre, et le bleu résiduel empêche le vert pur en fin d'échelle.

  L'absence de rouge la rend lisible pour la forme la plus répandue de
  déficience de la vision des couleurs, qui confond le rouge et le vert :
  c'est ce qui la distingue des cartes arc-en-ciel.

  Exemple :
     carte = winter(8);
     all(carte(:, 1) == 0)

  Voir aussi AUTUMN, SPRING, SUMMER, COLORMAP, PARULA.
```

## `wordcloud`

```
WORDCLOUD Nuage de mots, dont la taille suit la fréquence.
  WORDCLOUD(MOTS,TAILLES) place chaque mot, écrit d'autant plus grand
  que sa taille est élevée.
  WORDCLOUD(TEXTE) compte les mots d'un texte et les place.
  H = WORDCLOUD(...) rend les poignées des textes posés.

  Le placement est en spirale : le mot le plus fréquent au centre, les
  suivants tournant autour, chacun au premier endroit libre. C'est la
  disposition usuelle, et elle a l'avantage de mettre au centre ce qu'on
  veut voir d'abord.

  Un nuage de mots ne mesure rien : deux aires ne se comparent pas à
  l'œil, et l'ordre des mots y est celui du hasard du placement. Il
  montre ce qui domine, non de combien — pour cela, un diagramme en
  barres dit la vérité et se lit.

  Exemple :
     figure;
     wordcloud(["chat" "chien" "oiseau"], [10 6 3]);
     close all;

  Voir aussi BAR, TEXT, HISTOGRAM, CATEGORICAL.
```

## `writecell`

```
WRITECELL Écrit un tableau de cellules dans un fichier délimité.
  WRITECELL(C,FICHIER) écrit une ligne par rangée de C, les cases
  séparées par des virgules. Un nombre s'écrit en clair, une chaîne
  telle quelle.

  WRITECELL(C,FICHIER,'Delimiter',D) impose le séparateur.

  Exemple :
     f = fullfile(tempdir, 'essai.csv');
     writecell({'nom', 'valeur'; 'a', 1}, f);

  Voir aussi READCELL, WRITEMATRIX, WRITETABLE.
```

## `writelines`

```
WRITELINES Écrit un texte dans un fichier, une ligne par élément.
  WRITELINES(L,FICHIER) écrit chaque élément de L sur sa propre ligne.
  WRITELINES(...,'WriteMode','append') ajoute à la suite au lieu de
  remplacer. WRITELINES(...,'LineEnding',SEP) choisit la fin de ligne.

  Le fichier se termine par une fin de ligne, comme le veut l'usage :
  c'est ce qui fait qu'un outil de ligne de commande affiche la dernière
  ligne correctement, et READLINES ne la compte pas pour autant.

  Exemple :
     f = [tempname '.txt'];
     writelines(["une"; "deux"; "trois"], f);
     isequal(readlines(f), ["une"; "deux"; "trois"])   % l'aller-retour revient
     delete(f);

  Voir aussi READLINES, FPRINTF, WRITETABLE, FILEWRITE.
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

## `writestruct`

```
WRITESTRUCT Écrit une structure en XML ou en JSON.
  WRITESTRUCT(S,FICHIER) reconnaît le format à l'extension : .xml ou
  .json. WRITESTRUCT(...,'FileType',TYPE) l'impose.
  WRITESTRUCT(...,'StructNodeName',NOM) nomme la racine du XML ;
  « struct » par défaut, comme dans MATLAB.

  Un champ devient un élément ; un champ dont le nom finit par
  « Attribute » devient un attribut de l'élément parent. Un tableau de
  structures devient une suite d'éléments frères de même nom.

  Exemple :
     f = [tempname '.xml'];
     s = struct('nom', "essai", 'valeur', 42);
     writestruct(s, f);
     r = readstruct(f);
     r.valeur == 42                  % l'aller-retour revient
     delete(f);

  Voir aussi READSTRUCT, XMLWRITE, JSONENCODE, WRITETABLE.
```

## `xmlread`

```
XMLREAD Lit un document XML.
  N = XMLREAD(FICHIER) rend l'arbre du document : une structure portant
  Name, Attributes, Children et Text, chaque enfant étant du même
  genre.

  MATLAB rend ici un objet du modèle DOM de Java. Il n'y a pas de Java
  dans MatLibre : l'arbre est rendu tel quel, en structures, et se
  parcourt avec les moyens du langage. Ce qui s'écrit
  `n.getChildNodes.item(0)` sous MATLAB s'écrit `n.Children{1}` ici.

  Ce qui n'est pas traité : les espaces de noms, les définitions de
  type, les entités autres que les cinq prédéfinies.

  Exemple :
     f = [tempname '.xml'];
     writelines("<mesure unite=""m"">3.5</mesure>", f);
     n = xmlread(f);
     n.Name                          % 'mesure'
     n.Attributes.unite              % 'm'
     delete(f);

  Voir aussi XMLWRITE, READSTRUCT, WRITESTRUCT, JSONDECODE.
```

## `xmlwrite`

```
XMLWRITE Écrit un document XML.
  XMLWRITE(FICHIER,N) écrit l'arbre N — celui que rend XMLREAD — dans
  le fichier. T = XMLWRITE(N) rend le texte sans rien écrire.

  L'écriture est indentée : deux espaces par niveau. Les cinq
  caractères réservés du XML sont protégés, dans le texte comme dans
  les valeurs d'attribut, faute de quoi le document produit ne se
  relirait pas.

  Exemple :
     n = matlibre_xml_analyser('<a x="1"><b>2</b></a>');
     t = xmlwrite(n);
     ~isempty(strfind(t, '<b>2</b>'))

  Voir aussi XMLREAD, WRITESTRUCT, READSTRUCT.
```

## `yyyymmdd`

```
YYYYMMDD Date écrite comme un nombre AAAAMMJJ.
  N = YYYYMMDD(D) rend la date sous la forme du nombre entier
  AAAAMMJJ : le 3 février 2024 devient 20240203. D est une date, un
  numéro de série ou du texte.

  Exemple :
     yyyymmdd(datetime(2024, 2, 3))     % 20240203

  Voir aussi DATENUM, DATESTR, DATEVEC, YEAR, MONTH, DAY.
```

## `zip`

```
ZIP Fabrique une archive ZIP.
  ZIP(ARCHIVE,FICHIERS) empaquette les fichiers donnés. FICHIERS peut
  être un nom, une cellule de noms ou un motif.

  L'archive est produite par la commande « zip » du système ; sans
  elle, la fonction le dit clairement plutôt que d'écrire un fichier
  incomplet.

  Exemple :
     f = fopen('b.txt', 'w'); fprintf(f, 'x'); fclose(f);
     fichier = zip('archive.zip', {'b.txt'});
     isfile(fichier)             % 1

  Voir aussi UNZIP.
```

## `zoom`

```
ZOOM Loupe à la souris (acceptée, sans effet interactif).
  ZOOM ON permet, dans MATLAB, de grossir une figure à la souris ;
  ZOOM OFF l'interdit ; ZOOM OUT revient à la vue d'ensemble.

  ZOOM(FACTEUR) grossit d'un facteur donné autour du centre de l'axe.
  C'est la seule forme que MatLibre applique vraiment : les figures ne
  sont pas manipulables à la souris, mais un facteur donné en clair
  change bel et bien les bornes.

  Exemples :
     plot(1:100); zoom(2);         % on voit deux fois moins large
     zoom('out');                  % retour a la vue d'ensemble

  Voir aussi XLIM, YLIM, AXIS, PAN, ROTATE3D.
```

