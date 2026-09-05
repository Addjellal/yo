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

## `autumn`

```
AUTUMN Carte de couleurs rouge - jaune.
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
```

## `copper`

```
COPPER Carte de couleurs noir - cuivre.
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

  Voir aussi INPUT, DATACURSORMODE, GTEXT, WAITFORBUTTONPRESS.
```

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

## `gray`

```
GRAY Carte de couleurs en niveaux de gris.
  CARTE = GRAY(M) rend une matrice M x 3 allant du noir au blanc.
  M vaut 256 par défaut.

  Exemple :
     carte = gray(4)   % [0 0 0; 1/3 1/3 1/3; 2/3 2/3 2/3; 1 1 1]
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

## `ismissing`

```
ISMISSING Repère les valeurs manquantes.
  TF = ISMISSING(A) rend un tableau de booléens marquant les valeurs
  absentes : NaN pour un nombre, '' pour une cellule de texte, la
  chaîne manquante pour un tableau de chaînes, <undefined> pour une
  catégorie, NaT pour une date.

  TF = ISMISSING(A,IND) traite en outre comme manquantes les valeurs
  énumérées dans IND.

  Pour une table, TF a une colonne par variable.

  Exemple :
     ismissing([1 NaN 3])          % [false true false]
     ismissing([1 2 -99], -99)     % [false false true]

  Voir aussi RMMISSING, STANDARDIZEMISSING, ISNAN, ISNAT.
```

## `issorted`

```
ISSORTED Vrai si le tableau est trié.
  TF = ISSORTED(A) est vrai si A est trié par ordre croissant.
  ISSORTED(A,SENS) teste 'ascend', 'descend', 'monotonic',
  'strictascend', 'strictdescend' ou 'strictmonotonic'.
  ISSORTED(A,'rows') teste les lignes d'une matrice ; voir ISSORTEDROWS.

  Exemples :
     issorted([1 2 2 5])                  % true
     issorted([1 2 2 5], 'strictascend')  % false

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

## `jet`

```
JET Carte de couleurs bleu - cyan - jaune - rouge.
  Construite par interpolation linéaire entre les six teintes qui la
  définissent : bleu foncé, bleu, cyan, jaune, rouge, rouge foncé.

  Exemple :
     c = jet(64);   % c(1,:) vaut [0 0 0.5], c(end,:) vaut [0.5 0 0]
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

## `matlibre_arguments_barres`

```
MATLIBRE_ARGUMENTS_BARRES Décode les arguments de BARH et de PARETO.
  Fonction interne : elle n'existe pas dans MATLAB. Elle applique la
  règle de BAR — Y seul, ou X et Y, puis une largeur, puis un style —
  pour que les diagrammes en barres de MatLibre s'accordent tous.
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

## `matlibre_contient_variable`

```
MATLIBRE_CONTIENT_VARIABLE Vrai si le nom apparaît comme variable seule.
  Fonction interne : elle n'existe pas dans MATLAB. Elle sert à
  MATLIBRE_POIGNEE_DEPUIS_TEXTE, qui doit distinguer le « y » de
  « x + y » de celui de « ylabel ».
```

## `matlibre_couleur_secteur`

```
MATLIBRE_COULEUR_SECTEUR La k-ième couleur de la palette des secteurs.
  Fonction interne : elle n'existe pas dans MATLAB. PIE, PIE3 et ROSE
  s'en servent pour que deux secteurs voisins se distinguent, sans
  dépendre de la palette des courbes, qui n'a que sept tons.
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

## `matlibre_evaluer_grille`

```
MATLIBRE_EVALUER_GRILLE Évalue une fonction de deux variables sur une grille.
  Fonction interne : elle n'existe pas dans MATLAB. FSURF, FMESH et
  FCONTOUR s'en servent ; comme pour une variable, une poignée non
  vectorisée est appelée point par point plutôt que de faire échouer le
  tracé.
```

## `matlibre_evaluer_sur`

```
MATLIBRE_EVALUER_SUR Évalue une fonction sur un vecteur, vectorisée ou non.
  Fonction interne : elle n'existe pas dans MATLAB. FPLOT, FSURF,
  EZPLOT et FCONTOUR s'en servent : une poignée écrite avec « * » au
  lieu de « .* » ne se vectorise pas, et il faut alors l'appeler point
  par point plutôt que d'echouer.
```

## `matlibre_fleche`

```
MATLIBRE_FLECHE Le tracé d'une flèche, hampe et pointe d'un seul trait.
  Fonction interne : elle n'existe pas dans MATLAB. QUIVER, COMPASS et
  FEATHER s'en servent ; la flèche est rendue comme une seule polyligne,
  ce qui la fait tenir en une courbe et non en trois.
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

## `matlibre_pas_grille`

```
MATLIBRE_PAS_GRILLE La distance typique entre deux points voisins.
  Fonction interne : elle n'existe pas dans MATLAB. QUIVER s'en sert
  pour mettre les flèches à l'échelle, de sorte que la plus longue
  tienne dans une maille sans empiéter sur la voisine.
```

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

## `matlibre_racine_toolbox`

```
MATLIBRE_RACINE_TOOLBOX Dossier qui contient les toolboxes.
  C'est celui que l'interpréteur a trouvé au démarrage ; la variable
  d'environnement MATLIBRE_TOOLBOX le remplace quand elle est posée.
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

## `namelengthmax`

```
NAMELENGTHMAX Longueur maximale d'un nom.
  N = NAMELENGTHMAX rend le nombre de caractères qu'un nom de
  variable, de fonction ou de champ peut compter.

  Voir aussi ISVARNAME, GENVARNAME.
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

  Voir aussi INPUT, KEYBOARD.
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

  Voir aussi SAVEFIG, SAVEAS, OPEN, FIGURE.
```

## `pagectranspose`

```
PAGECTRANSPOSE Transposée conjuguée de chaque page d'un tableau.
  B = PAGECTRANSPOSE(A) échange les deux premières dimensions de A et
  conjugue les valeurs.

  Voir aussi PAGETRANSPOSE, PAGEMTIMES.
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

## `pagetranspose`

```
PAGETRANSPOSE Transposée de chaque page d'un tableau.
  B = PAGETRANSPOSE(A) échange les deux premières dimensions de A, les
  suivantes restant en place.

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
```

## `rat`

```
RAT Approximation rationnelle par fractions continues.
  [N,D] = RAT(X) rend deux entiers tels que N/D vaut X à la tolérance
  par défaut près (1e-6 fois la valeur).
  S = RAT(X) rend la chaîne « n/d ».
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
  enregistre la figure sous la forme que dit l'extension du nom —
  .svg, .png, .pdf —, et prend le SVG quand le nom n'en porte aucune.
  Le dessin est conservé ; ce qui ne l'est pas est la possibilité de
  rouvrir la figure pour la modifier.

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

## `summer`

```
SUMMER Carte de couleurs vert - jaune.
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

  Voir aussi FIGURE, INPUT, MENU, DISP.
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

## `webread`

```
WEBREAD Lit le contenu d'une adresse.
  C = WEBREAD(URL) télécharge l'adresse et rend son contenu. Un
  document JSON est décodé en structure ou en tableau de cellules ; un
  fichier délimité est lu comme une matrice ; le reste est rendu tel
  quel, en texte.

  C = WEBREAD(URL,NOM1,VAL1,...) ajoute des paramètres à la requête.

  Le téléchargement passe par curl, qui doit être installé. Aucune
  donnée n'est envoyée que celles de l'appel.

  Exemple :
     s = webread('https://example.com');

  Voir aussi WEBSAVE, JSONDECODE, URLREAD.
```

## `websave`

```
WEBSAVE Enregistre le contenu d'une adresse dans un fichier.
  F = WEBSAVE(FICHIER,URL) télécharge l'adresse et l'écrit dans
  FICHIER ; F est le chemin complet du fichier écrit.

  F = WEBSAVE(FICHIER,URL,NOM1,VAL1,...) ajoute des paramètres à la
  requête, comme le fait MATLAB : websave(f, url, 'q', 'chat') demande
  URL?q=chat.

  Le téléchargement passe par curl, qui doit être installé. Aucune
  donnée n'est envoyée que celles de l'appel.

  Exemple :
     f = websave(fullfile(tempdir, 'page.html'), 'https://example.com');

  Voir aussi WEBREAD, URLREAD, FILEREAD.
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
     s = what(fullfile(matlabroot, 'toolbox', 'matlab'));
     numel(s.m)

  Voir aussi DIR, WHICH, EXIST, LS.
```

## `winter`

```
WINTER Carte de couleurs bleu - vert.
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

