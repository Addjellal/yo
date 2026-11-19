## Ce qui manque au-delà des fonctions

Le tableau ci-dessus compte des noms. Ce qui suit compte davantage : ce
sont les manques de structure, ceux qu'aucune fonction ajoutée ne
comblerait. Ils sont classés par ce qu'ils coûtent à l'utilisateur.

### Formats de fichiers

- **MAT niveau 7.3**. C'est un fichier HDF5, non le format MAT. Il est
  reconnu et l'erreur dit quoi faire — réenregistrer en `-v7` —, mais il
  n'est pas lu. Le lire demanderait un lecteur HDF5 complet.
- **Objets MCOS dans un fichier MAT**. Un `ss`, un `tf`, une `table`
  sauvés par MATLAB sont rangés dans une forme opaque qui renvoie à un
  sous-système du fichier. MatLibre lit la forme, nomme la variable et
  dit ce qu'il n'a pas su reconstruire, mais ne rebâtit pas l'objet.
- **Figures `.fig`**. Ce sont des fichiers MAT portant le modèle d'objets
  graphiques de MathWorks, que MatLibre n'a pas.
- **Modèles Simulink `.slx`**. `sim` existe pour les modèles écrits en
  MatLibre ; le format de MathWorks, non.
- **Scripts vivants `.mlx`**. Le format est une archive OPC ; l'éditeur
  ne les ouvre pas.

### Graphique

- **La classe d'une poignée de tracé**. Un `patch` se déclare `Type =
  'line'` et de classe `Line` : `findobj(gca,'Type','patch')` ne rend donc
  rien. La classe est fixée à la création de la poignée, avant que le
  genre du tracé ne soit connu ; la corriger demande de la faire suivre,
  et de reprendre ce qui distingue une poignée de série des autres. Le
  défaut est réel et connu ; il n'est pas corrigé.

### Langage

- **Dossiers `private/`** : les fonctions privées d'un dossier ne sont pas
  reconnues comme telles.
- **Dossiers de paquet `+nom/`** : la notation `paquet.fonction` marche
  pour ce qui est enregistré sous ce nom, non par découverte de dossier.
- **Événements et écouteurs** (`events`, `addlistener`, `notify`) : les
  `events` sont analysés, les écouteurs manquent. Les **classes poignées**
  (`classdef X < handle`), elles, partagent bien leur état : une méthode
  qui écrit dans l'objet se voit depuis toutes ses copies.
- **Héritage** : `classdef X < Y` est analysé, mais seul `handle` a un
  effet ; les méthodes et propriétés du parent ne sont pas héritées.
- **`matlab.unittest`** : le cadre de tests à classes. Les tests de
  MatLibre sont des scripts à `assert`.
- **Mots-clés de `classdef`** : `properties`, `methods`, `events` et
  `enumeration` sont sensibles au contexte, comme dans MATLAB — ce sont
  des mots-clés dans un `classdef`, des identificateurs partout ailleurs,
  si bien que `properties(sys)` appelle bien la fonction. En revanche les
  attributs entre parenthèses (`properties (Access = private)`) sont
  analysés et ignorés : rien n'est privé.
- **Interfaces externes** : MEX, appel de Java, de Python, de C++.
- **`functions(f)`** ne rend pas le champ `workspace` d'une fonction
  anonyme. La capture elle-même suit MATLAB : seules les variables que le
  corps cite sont retenues, à leur valeur du moment, et lues sans copie
  à chaque appel.

### Bureau

- **App Designer et GUIDE** : la construction d'interfaces. `uicontrol`
  et `uifigure` n'existent pas.
- **Éditeur de variables** : le tableau des variables se lit, il ne
  s'édite pas au clavier comme celui de MATLAB.
- **Outils interactifs des figures** : zoom à la souris, curseur de
  données, brosse, rotation 3D.
- **Comparaison de fichiers** (`visdiff`), **analyse de code**
  (`checkcode`, l'analyseur qui souligne dans l'éditeur).

### Graphique

Les noms du tableau ci-dessus sont tous présents ; ce qui suit est ce
qu'ils ne font pas encore comme MATLAB.

- **Rendu tridimensionnel** : le rendu de MatLibre est plan. `surf`,
  `mesh`, `plot3`, `contour3`, `scatter3` et leurs voisins tracent, mais
  sans perspective ; `view`, `light`, `lighting`, `material` et `hidden`
  sont acceptés sans effet. Chaque fiche d'aide le dit.
- **Second axe des ordonnées** : `plotyy` et `yyaxis` remettent la
  seconde courbe à l'échelle de la première au lieu de lui donner ses
  propres graduations à droite.
- **Axes polaires** : `polarplot`, `compass` et `rose` convertissent en
  coordonnées cartésiennes et dessinent eux-mêmes cercles et rayons ; la
  graduation angulaire du cadre manque.
- **Transparence** (`alpha`) et **bandes de `contourf`** : le fond est
  posé en champ continu, non découpé par niveau.
- **`histogram2`** dessine le quadrillage en couleurs — le
  `'DisplayStyle','tile'` de MATLAB — et non les barres en perspective.
- **Interaction à la souris** : `zoom`, `pan`, `rotate3d`, `brush`,
  `datacursormode` sont acceptés sans effet, et `ginput` dit qu'il ne
  peut pas ; les figures ne sont pas cliquables.
- **Format `.fig`** : `savefig` écrit du SVG, `openfig` refuse le format
  de MathWorks.
- **Palette par défaut** : viridis, et non parula. Les valeurs de parula
  appartiennent à MathWorks ; comme GNU Octave, MatLibre prend viridis
  (domaine public), et `colormap(parula)` le dit au lieu d'imiter.
  `colormap`, `clim`/`caxis`, `image` (indices directs), `imagesc` et
  `imshow` (gris sur la plage du type, couleurs vraies, images indexées)
  suivent MATLAB.
- **Légende** : les entrées, leurs styles et marqueurs, `Location` (y
  compris hors de l'axe et `'best'`), `Orientation` et `Box` suivent
  MATLAB ; la mise à jour automatique (`AutoUpdate`) et `NumColumns` sont
  acceptées sans effet, et une légende de contour montre un trait, non
  l'icône de MATLAB.
- **Pas d'interpréteur TeX** dans les titres, étiquettes, légendes et
  textes : `Z_L` ou `10^{-3}` s'écrivent tels quels, là où MATLAB
  (`Interpreter` vaut `'tex'` par défaut) met en indice et en exposant et
  traduit `\alpha`, `\pi`... Seules les graduations des axes
  logarithmiques écrivent leurs puissances de dix en exposant.
- **Marqueurs** : les quatorze formes de MATLAB, `MarkerSize`,
  `MarkerFaceColor` et `MarkerEdgeColor` ; `scatter` dessine encore des
  disques pleins, que MATLAB laisse creux par défaut.

- **`bar`** lit les données, la largeur, `'grouped'` et `'stacked'`,
  `FaceColor`, `EdgeColor`, `BarWidth`, `FaceAlpha` et `DisplayName` ;
  les styles `'hist'` et `'histc'` et une ligne de base non nulle
  (`BaseValue`) sont refusés en le disant. La disposition des barres
  groupées suit celle de MATLAB — le groupe occupe min(0,8, n/(n+1,5)) de
  l'écart —, sans en garantir chaque pixel.

### Traitement du signal

- **`maxflat`** : le filtre à module maximalement plat d'ordres
  dissymétriques — N zéros en z = −1 et M pôles — n'est pas conçu. Le cas
  N = M est exactement `butter`, qui est là.
- **Objets `digitalFilter`** : `designfilt` et l'objet qu'il rend
  n'existent pas. `lowpass` et ses voisines rendent les coefficients B et
  A au lieu de l'objet.
- **`intfilt`** en bande limitée résout les équations normales d'une
  interpolation idéale, ce qui est la définition ; les coefficients
  peuvent différer de MATLAB au dernier chiffre.

### Images

- **Pas d'objets ni de classes d'image** : une image est une matrice.
  `imref2d`, les objets `roi` (`drawcircle`, `images.roi.*`) et les
  applications interactives — `imtool`, `Color Thresholder`, `Image
  Segmenter` — n'existent pas ; `impixel` et `roipoly` prennent leurs
  points en argument au lieu de les faire cliquer.
- **`edge` façon Canny** : le seuil haut automatique est lu sur
  l'histogramme du gradient — celui qui laisse sept dixièmes des points
  du côté « pas un contour » —, le seuil bas en vaut quatre dixièmes.
  C'est la règle publiée ; les contours peuvent différer d'un pixel de
  ceux de MATLAB sur une image bruitée.
- **`imfindcircles`** ne cherche que par accumulation à deux étapes :
  `'Method'` et `'FilterSize'` sont reçus sans effet, et le mode
  `'PhaseCode'` de MATLAB n'est pas là. Les pics sont retenus au-dessus
  de huit dixièmes du maximum de l'accumulateur, puis dédoublonnés au
  rayon près.
- **`activecontour`** mène l'évolution par différences finies sur une
  fonction de niveau, sans réinitialisation de la distance signée : sur
  un très grand nombre d'itérations le contour peut se figer là où
  MATLAB continue d'avancer.
- **`montage`** assemble et rend l'image assemblée ; la navigation entre
  vignettes n'existe pas.

### Systèmes asservis

- **Pas de retards internes** : `InputDelay`, `OutputDelay` et `IODelay`
  sont portés et honorés — la réponse fréquentielle en `e^(-jwD)`, la
  réponse temporelle par décalage, exactement —, mais un retard *dans*
  une boucle fermée devient un retard interne, que le modèle ne porte
  pas. `feedback`, `connect` et les synthèses par retour d'état
  refusent donc un modèle retardé en le nommant, plutôt que de l'oublier
  et de rendre une boucle stable là où elle ne l'est pas. `pade` en
  donne l'approximation rationnelle, qui passe alors partout ; `thiran`
  est exact au sens du retard de groupe plat en zéro.
- **Pas de matrice de transferts dans un `tf`** : `tf` n'a qu'un
  numérateur et un dénominateur. `tf({…},{…})` à plusieurs cases est
  refusé en disant comment faire — assembler les voies,
  `[G11 G12; G21 G22]`, ce qui rend le modèle d'état à plusieurs voies
  que `step`, `bode`, `impulse`, `lsim`, `freqresp` et `sigma` traitent.
- **Un modèle à une voie rend des colonnes** : `[m,p] = bode(sys)` et
  `y = step(sys)` rendent des vecteurs colonnes, là où MATLAB rend des
  tableaux 1 × 1 × N qu'on passe à `squeeze`. À plusieurs voies, les
  formes sont celles de MATLAB : NY × NU × NW pour `bode`, NT × NY × NU
  pour `step` et `impulse`.
- **`margin`, `allmargin` et `bandwidth` ne valent que pour une voie** :
  sur une matrice de transferts, ils refusent en le disant et en
  renvoyant à `sys(i,j)` ; `loopmargin` traite la boucle multivariable.
  MATLAB calcule en plus les marges « une boucle à la fois » dans
  `allmargin`.
- **`tzero` ne traite que les modèles carrés** à plusieurs voies : les
  zéros de transmission y sont les valeurs finies du faisceau de
  Rosenbrock. Un modèle qui n'a pas autant d'entrées que de sorties est
  refusé en le nommant.
- **`pidtool` et `sisotool`** ne sont pas interactifs : MatLibre règle le
  correcteur — comme `pidtune` — et trace les vues une fois, là où MATLAB
  ouvre une application à curseurs.
- **Pas de modèle `genss`** : `getBlockValue` lit le bloc dans une
  structure de blocs ou dans un modèle nommé, non dans un modèle à blocs
  réglables.
- **`bodeoptions` et `stepDataOptions`** sont des structures : les champs
  que MatLibre traite sont énumérés dans leur aide, les autres sont
  gardés sans effet pour que le code écrit pour MATLAB s'exécute.

### Optimisation

- **Écriture par problème** : `optimvar`, `optimexpr`, `optimconstr` et
  `optimproblem` couvrent le linéaire, le quadratique et les variables
  entières. Les expressions non linéaires — un produit de trois
  variables, un logarithme — ne sont pas représentées, et `solve` ne sait
  donc pas déléguer à `fmincon` un problème écrit ainsi.
- **`solve` ne rend pas d'objet de sortie** : la solution est une
  structure à un champ par variable, non un `OptimizationResult`.
- **`coneprog`** ramène les contraintes de cône à `fmincon` par
  pénalisation, au lieu d'employer un point intérieur conique : la
  solution est bonne à quelques millièmes, non à la précision machine.
- **`linprog` et `quadprog`** minimisent une barrière logarithmique par
  Nelder-Mead : pas de simplexe, pas de base optimale, donc ni variables
  duales ni analyse de sensibilité.
- **`lsqnonlin` et `lsqcurvefit`** n'ont que Levenberg-Marquardt, résolu
  par QR du système augmenté ; l'algorithme par défaut de MATLAB,
  trust-region-reflective, n'est pas fait, et l'option `Algorithm` est
  ignorée. Les résultats coïncident à la tolérance près, non au dernier
  chiffre. `FunctionTolerance` n'arrête le calcul que si on la donne ;
  le pas des différences finies est relatif à |x| (`TypicalX` le borne
  par en dessous quand on le donne), là où MATLAB prend max(|x|, 1).

### Optimisation globale

- **`GlobalSearch` et `MultiStart`** relancent le solveur local depuis
  des points tirés dans les bornes ; `GlobalSearch` évalue d'abord un
  large échantillon et ne raffine que les meilleurs. MATLAB emploie une
  analyse de bassins d'attraction et un filtre sur les points de départ,
  ce qui lui fait économiser des appels — le résultat est le même, le
  budget diffère.
- **`createOptimProblem`** rend une structure, non un objet ; les
  solveurs locaux acceptés sont `fmincon`, `fminunc`, `lsqnonlin` et
  `lsqcurvefit`.
- **Options** : `gaoptimset`, `psoptimset` et `saoptimset` rendent des
  structures dont les champs sont ceux que MatLibre lit réellement. Les
  fonctions personnalisables de MATLAB — `MutationFcn`, `CrossoverFcn`,
  `SearchFcn`, `AnnealingFcn` — sont acceptées et sans effet.

### Finance

- **Les fonctions rendent des valeurs, elles ne tracent pas.**
  `HIGHLOW` rend les extrémités des barres, `POINTFIG` les colonnes et
  leurs symboles ; le tracé se fait ensuite avec `PLOT`. `COLLINTEST` et
  `PORTRAND` écrivent ou rendent, sans figure.
- **`EMAXDRAWDOWN`** repose sur une table à six décimales, obtenue en
  simulant quarante mille trajectoires de quatre mille pas par point de
  grille, avec la correction de continuité. À dérive nulle la table
  reprend la valeur exacte, racine de pi sur deux. Ailleurs, l'écart avec
  la valeur vraie est de l'ordre du millième.
- **Conventions de comptage** : les quatorze bases de `YEARFRAC` sont
  implémentées, les variantes ISMA se ramenant aux conventions
  correspondantes. La base 13, jours ouvrés sur 252, emploie le
  calendrier américain de `HOLIDAYS`.
- **`HOLIDAYS`** calcule les jours fériés du marché de New York à partir
  des règles — jour de l'an, Martin Luther King, Washington, vendredi
  saint, Souvenir, Juneteenth depuis 2022, fête nationale, travail,
  Thanksgiving, Noël — et non d'une table. Les fermetures
  exceptionnelles, funérailles nationales ou événements, n'y sont pas.
- **`CFAMOUNTS`** rend des vecteurs et non une table ; les drapeaux
  valent 0 pour l'intérêt couru, 1 pour un coupon, 3 pour le dernier
  flux.
- **`PORTOPT` et `FRONTCON`** résolvent un programme quadratique par
  point de la frontière, par la méthode des contraintes actives : les
  contraintes sont satisfaites exactement. Il n'y a pas d'objet
  `Portfolio`.
- **`PORTALPHA`** implémente `'xs'`, `'sml'`, `'capm'`, `'ml'`, `'gh1'`
  et `'gh2'`.
- **Indicateurs techniques** : les moyennes exponentielles emploient le
  facteur usuel, deux divisé par la période plus un ; `RSINDEX` emploie
  le lissage de Wilder, un sur la période. Les premières valeurs, tant
  que la fenêtre n'est pas pleine, valent NaN dans `RSINDEX` et
  `BOLLING`, et sont calculées sur la fenêtre partielle ailleurs.
- **`LINPROG` et `QUADPROG`** ont gagné une résolution exacte : quand la
  forme quadratique est définie positive, `QUADPROG` passe par la méthode
  des contraintes actives, et `LINPROG` termine sa barrière par une
  régularisation quadratique décroissante qui l'amène sur le sommet. La
  pénalisation reste le recours quand la matrice est singulière.
- **`DATENUM`, `DATEVEC`, `DATESTR` et `WEEKDAY`** acceptent désormais
  des tableaux : une matrice de dates par ligne, des composantes
  diffusées, un tableau de cellules de textes. `DATESTR` rend une
  matrice de caractères, une ligne par date.

### Gestion des risques

- **Les objets sont des `classdef` MatLibre**, non les objets de MATLAB :
  `creditDefaultCopula`, `creditMigrationCopula`, `varbacktest`,
  `esbacktest` et `creditscorecard` exposent leurs propriétés en clair, et
  les méthodes s'appellent en fonctions — `portfolioRisk(c)`,
  `runtests(v)`, `score(sc)`. `RUNTESTS` reste une méthode et non une
  fonction de fichier : le nom appartient déjà au lanceur de tests de
  MatLibre, et une fonction de fichier le masquerait.
- **`varbacktest` rend les tables de MATLAB** — `tl`, `bin`, `pof`,
  `tuff`, `cci`, `cc`, `tbfi`, `tbf`, `summary` et `runtests`, avec leurs
  colonnes (`POF`, `LRatioPOF`, `PValuePOF`, `Observations`...) et des
  verdicts catégoriels ; les valeurs des exemples de MathWorks sont
  retrouvées au chiffre près. **`esbacktest` et `bininfo` rendent encore
  des structures**, non des tables.
- **`esbacktest`** obtient ses valeurs critiques en simulant cinq mille
  fois la statistique sous l'hypothèse nulle, à graine fixée, avec mise en
  cache : deux appels identiques rendent le même verdict, mais la valeur
  diffère de celle de MATLAB à la troisième décimale. `esbacktestbysim`
  et les tests conditionnels manquent.
- **`varbacktest`** implémente les huit tests. Le feu tricolore suit la
  documentation de MathWorks — `Increase` vaut 3*(z annoncé / z observé
  - 1) en zone jaune, non la table des majorations du Comité de Bâle. Le
  test de Kupiec sur-rejette en petit échantillon quand les dépassements
  sont rares — c'est une propriété connue du test, non un défaut de
  calcul.
- **`transprob`** prend une matrice à trois colonnes — identifiant, date,
  notation — et non une table ; les notations sont des entiers, la
  première étant la meilleure.
- **`creditscorecard`** découpe les variables numériques par quantiles et
  les variables de texte par catégorie ; les découpages supervisés de
  MATLAB — monotone, arbre, khi-deux — manquent, de même que
  `modifybins`. La sélection pas à pas pénalise chaque candidate par les
  degrés de liberté que son découpage a déjà consommés, sans quoi une
  variable de bruit découpée finement passerait.
- **`concentrationIndices`** rend une structure et non une table ; les
  indices sont normalisés par défaut, entre zéro pour des expositions
  égales et un pour une exposition unique.
- **`asrf`** accepte `'CorrelationType','basel'`, qui applique la formule
  de corrélation des expositions d'entreprise ; les formules propres aux
  autres classes d'actifs manquent.

### Instruments financiers

- **Pas d'arbres de taux courts** : les modèles de Hull et White, de
  Black, Derman et Toy, de Black et Karasinski, ainsi que le cadre de
  Heath, Jarrow et Morton, ne sont pas là. Les plafonds, planchers et
  options sur échange se valorisent par le modèle de Black, les options
  sur action par formule fermée ou par arbre binomial.
- **`CRRTREE`** ne traite qu'un actif à volatilité constante et à
  dividende continu ; `BINPRICE`, lui, accepte des dividendes en espèces
  par le modèle du dividende séquestré, qui garde l'arbre recombinant.
  Les arbres d'Equal Probabilities, implicites et trinomiaux manquent.
- **`CRRPRICE` et `CRRSENS`** ne valorisent que les instruments
  `'OptStock'` d'un jeu.
- **Le jeu d'instruments** est une structure MatLibre, non l'objet de
  MATLAB : les champs `Type`, `FieldName`, `FieldClass`, `FieldData` et
  `Index` sont lisibles directement. Les types reconnus par `INSTADD`
  sont `'Bond'`, `'CashFlow'`, `'Fixed'`, `'Float'`, `'Swap'`,
  `'OptStock'`, `'Barrier'`, `'Lookback'`, `'Asian'`, `'Cap'`,
  `'Floor'` et `'Swaption'` ; `INSTADDFIELD` en crée d'autres.
  `INTENVPRICE` valorise les cinq premiers.
- **`LOOKBACKBYBLS`** prend l'extremum déjà observé égal au cours du
  jour ; il n'y a pas de champ pour un extremum antérieur.
- **`ASIANBYLEVY`** est une approximation par les deux premiers moments,
  comme dans MATLAB : l'erreur croît avec la volatilité.
- **Le contrat de protection** suppose des taux de hasard constants par
  morceaux entre les échéances cotées, la prime courue à la date de
  défaut comptée pour une demi-période, et pas de paiement initial.

### Économétrie

- **`arima` et `garch` sont des `classdef`**, non des objets MATLAB
  complets : les propriétés se lisent et s'écrivent, mais il n'y a ni
  validation à l'affectation ni affichage tabulaire. `ESTIMATE`,
  `SIMULATE`, `FORECAST`, `INFER` et `SUMMARIZE` sont des fonctions
  ordinaires qui reconnaissent le type de leur premier argument.
- **La vraisemblance est conditionnelle**, non exacte : les valeurs
  antérieures à l'échantillon sont prises à la moyenne du modèle et les
  innovations correspondantes à zéro. MATLAB emploie un filtre de Kalman
  qui les traite comme des inconnues à lisser ; l'écart s'efface quand
  l'échantillon grandit, mais sur deux cents points il se voit.
- **Les innovations sont gaussiennes.** La propriété `Distribution` est
  conservée et affichée, mais `'t'` n'est pas encore estimée.
- **Modèles saisonniers** : `Seasonality` applique une différence
  saisonnière, et `SARLags`/`SMALags` posent des coefficients aux retards
  voulus. Il n'y a pas de raccourci qui développe automatiquement un
  modèle multiplicatif complet.
- **`FORECAST` d'un GARCH rend les variances**, non des niveaux : le
  niveau d'un GARCH pur n'est pas prévisible.
- **`JCITEST` rend des vecteurs et un tableau de cellules**, non des
  tables MATLAB ; `MLES{r+1}` porte les valeurs propres, la matrice `B`
  des relations, la matrice `A` des vitesses d'ajustement et la
  log-vraisemblance du rang `r`.
- **Les valeurs critiques** des tests de racine unitaire, de Johansen et
  d'Engle-Granger ont été obtenues par simulation — huit mille tirages
  pour les premiers, six mille pour Johansen — plutôt que recopiées.
  Elles s'accordent aux tables publiées à quelques centièmes près, mais
  ce sont des estimations : sur la troisième décimale, elles diffèrent de
  celles de MATLAB.
- **`COLLINTEST`** écrit son tableau mais ne trace rien ; l'option
  `'plot'` est acceptée et sans effet.
- **`EGCITEST`** accepte `'creg'` valant `'nc'`, `'c'`, `'ct'` ou
  `'ctt'` ; les valeurs critiques tabulées vont jusqu'à cinq régresseurs,
  et `'ctt'` emploie celles de `'ct'`.

### Calcul formel

- **Des nombres flottants, non exacts.** Un `sym` numérique est un
  double : `sym(1)/3` vaut 0,333..., écrit `1/3` parce que la fraction
  redonne exactement ce double, et `pi` reste un nombre, non le symbole
  de MATLAB. L'écriture est sans perte — fraction simple quand elle
  existe, sinon le plus court décimal qui relit le double —, si bien que
  `matlabFunction` compile des coefficients justes.
- **Tableaux de `sym`** : les opérations élément par élément, le produit
  matriciel, `diff`, `int`, `subs`, `simplify` et `expand` s'appliquent à
  un tableau, et `solve` rend une colonne. `A\b`, `inv` et `det` d'une
  matrice de `sym` ne sont pas faits (`symmatrix` raisonne sur une matrice
  entière) ; `jacobian` et `hessian` rendent des cellules.
- **`simplify` regroupe, il ne transforme pas.** Il réduit les cas
  triviaux et réécrit une expression polynomiale en une variable à partir
  de ses coefficients. Les identités trigonométriques —
  sin(x)^2 + cos(x)^2 reste tel quel — et la réduction des radicaux ne
  sont pas faites. `factor` met en facteur les racines rationnelles,
  exactement, par le théorème qui les borne.
- **`solve` ne résout que le polynomial** : les racines rationnelles
  exactement, les autres par `roots` sur le quotient. Une équation
  transcendante est refusée (`vpasolve` la résout numériquement), et les
  systèmes ne sont pas gérés.
- **`int` connaît quelques règles exactes** : sommes, constantes, sinus,
  cosinus, exponentielle, logarithme et puissance d'un argument affine,
  base constante, la gaussienne exp(-a x^2 + b x + c) par la fonction
  d'erreur, et l'inverse d'un polynôme de degré un ou deux (logarithme,
  arc tangente). Hors de ces règles, il le dit. Une intégrale définie
  entre bornes numériques est recoupée par `integral`, et refusée si la
  primitive est discontinue sur l'intervalle. L'intégration par parties
  et le changement de variable ne sont pas faits.
- **`limit` est numérique**, par extrapolation de Richardson sur des pas
  géométriquement décroissants : une dizaine de chiffres justes sur les
  limites usuelles, mais aucune preuve. Une forme indéterminée que
  l'échantillonnage ne voit pas passe inaperçue.
- **`vpa` n'a pas de précision variable** : MatLibre calcule en double
  précision puis arrondit au nombre de chiffres demandé. Au-delà de
  quinze, les chiffres rendus ne sont pas justes.
- **`symsum` ne somme qu'entre bornes finies**, terme à terme : la série
  de Bâle, somme de 1/k^2 jusqu'à l'infini, est refusée.
- **Pas de transformées** : `laplace`, `ilaplace`, `fourier`, `ztrans` et
  `dsolve` n'existent pas.

### Communications

- **`gf` est une classe, non un objet natif** : les opérateurs y sont
  surchargés — `+`, `.*`, `./`, `.^`, `*`, l'indexation, la
  concaténation — mais un tableau de corps ne passe pas dans les
  fonctions natives qui attendent des nombres. `double(x)` en donne les
  valeurs.
- **`gfprimdf`** cherche le premier polynôme primitif dans l'ordre des
  codes croissants. Il coïncide avec la table de MATLAB partout sauf au
  degré sept, où MathWorks retient 1+x^3+x^7 quand la recherche trouve
  d'abord 1+x+x^7 ; les deux sont primitifs. Donnez le polynôme
  explicitement pour que deux calculs se comparent.
- **`gfadd` et `gfsub`** traitent un scalaire comme le polynôme
  constant, non comme un terme à répandre : sans cela l'identité de la
  division euclidienne ne tiendrait pas. `gfmul` et `gfdiv`, qui
  travaillent terme à terme, répandent bien le scalaire.
- **Les fonctions `gf*` d'extension** (`gfadd(a,b,field)` où le troisième
  argument est une table de corps) ne sont pas gérées : elles n'acceptent
  qu'un ordre premier. Le corps d'extension passe par la classe `gf`, ou
  par `gftable` pour lire sa table.
- **`bchdec` et `rsdec`** décodent par syndrome, Berlekamp-Massey et
  recherche de Chien, avec Forney pour les valeurs d'erreur en
  Reed-Solomon. Le décodage par effacements (`erasures`) et le décodage
  raccourci ne sont pas gérés.
- **Modulations de norme** : `dvbsapskmod` et `dvbsapskdemod` demandent
  les tables de rayons de la norme ETSI EN 302 307, une par rendement de
  code. MatLibre ne les reproduit pas : une constellation APSK
  quelconque s'écrit avec `genqammod`.
- **`semianalytic`** ramène le signal reçu à une énergie moyenne d'un, le
  rapport signal sur bruit étant défini à la réception : une atténuation
  uniforme ne change donc rien au résultat, une distorsion le dégrade.
  Sur canal parfait elle redonne exactement `berawgn` ; en modulation
  d'amplitude en quadrature, le compte des frontières la place à un
  facteur un et demi de la formule exacte.
- **`bercoding`** rend des bornes de l'union : la vraie courbe passe en
  dessous, et d'autant plus près que le rapport signal sur bruit est
  grand.

### Ondelettes

- **Familles construites, non recopiées** : `dbaux`, `symaux` et
  `biorwavf` sortent d'une factorisation spectrale, non d'une table.
  L'accord avec MATLAB est celui de la construction elle-même : exact
  pour les splines biorthogonales, et à la précision machine pour dbN et
  symN jusqu'à l'ordre vingt environ.
- **`bior5.5` et `bior6.8`** ne sont pas des splines : MATLAB les tire
  d'un ajustement au plus près de l'orthonormalité, que MatLibre ne
  reproduit pas. Ces deux noms sont refusés plutôt qu'approchés ; les
  treize autres, `bior4.4` — le couple 9/7 de JPEG 2000 — compris, sont
  là. `coifwavf` et les coiflets manquent pour la même raison.
- **Zéros de complètement** : MATLAB centre les filtres biorthogonaux
  dans un tableau de longueur commune. MatLibre les place là où
  l'alignement des deux filtres l'exige — un décalage impair changerait
  la parité du demi-bande et le repliement ne s'annulerait plus. Les
  coefficients non nuls sont les mêmes, leur position dans le tableau
  peut différer d'un rang.
- **`meyer`** échantillonne par transformée de Fourier inverse sur une
  grille dont le nombre de points doit être une puissance de deux ;
  MATLAB accepte n'importe quelle longueur.
- **Un seul mode de prolongement.** `dwt`, `wavedec` et leurs voisines
  analysent en périodique. `dwtmode` lit et pose le mode, mais refuse
  tout ce qui n'est pas `'per'` au lieu d'analyser autrement que promis ;
  `wextend`, lui, connaît les neuf prolongements.
- **`icwt`** ne rend que ce que les échelles demandées couvrent : la
  composante continue et le hors-bande sont perdus, ce qui est fidèle à
  ce que la transformée a gardé. Là où MATLAB emploie un banc de filtres
  analytique, MatLibre mesure le filtre que forment analyse et somme,
  puis l'inverse dans sa bande — quelques centièmes d'erreur relative
  loin des bords.
- **`wfbmesti`** sous-estime H d'environ cinq centièmes en dessous de
  0,5 : la relation d'échelle ne s'établit qu'aux niveaux grossiers, et
  la régression ne garde que les octaves du milieu.
- **`wvarchg`** choisit le nombre de ruptures avec une pénalité de
  4 log(n), deux fois celle du critère bayésien : celle-ci laissait
  passer une découpe de temps en temps sur du bruit pur.
- **Arbres de paquets** : MATLAB rend un objet `wptree` à méthodes ;
  MatLibre rend une structure de champ `type` valant `'wptree'`, dont
  `donnees` porte un nœud par case et `noeuds` la liste de ceux qui
  existent. Les fonctions de MATLAB — `wpcoef`, `wpsplt`, `leaves` — la
  prennent telle quelle ; `read`, `write`, `plot` et `drawtree` n'ont pas
  d'équivalent.
- **Bancs de filtres objets** : `cwtfilterbank` et `dwtfilterbank`
  n'existent pas ; `cwt` et `wavedec` prennent le nom de l'ondelette.
  `wcoherence`, `wsst`, `dualtree` et `dtfilters` manquent aussi, et
  `wavemngr` — la gestion d'une base d'ondelettes personnelles — n'a pas
  de sens ici, les familles étant construites plutôt que déclarées.

### Logique floue

- **Un système est une structure**, non un objet : `entrees` et `sorties`
  sont des cellules de variables, `regles` la matrice d'indices. Les
  fonctions modernes — `addInput`, `addMF`, `getTunableSettings` — la
  prennent telle quelle, mais la notation à points de MATLAB
  (`fis.Inputs(1).MembershipFunctions(2).Parameters`) n'existe pas.
- **`evalfis`** accepte les deux ordres d'arguments, le système se
  reconnaissant à ce qu'il est une structure.
- **`tunefis`** ne connaît que le simplexe de Nelder-Mead sur le vecteur
  des paramètres. La recherche par motifs, le recuit et les algorithmes
  génétiques de MATLAB savent sortir d'un minimum local ; celui-ci non.
  Il ne rend jamais un système plus mauvais que celui de départ.
- **`convertToSugeno`** remplace chaque modalité de sortie par son
  centre défuzzifié : la traduction est fidèle règle par règle, non point
  par point, et la sortie diffère donc de celle du Mamdani.
- **Pas de logique floue de type 2** : `mamfistype2`, `sugfistype2` et
  `convertToType2` manquent, ainsi que les arbres `fistree`.
- **`findcluster`** calcule et trace au lieu d'ouvrir une application ;
  `fuzzyLogicDesigner`, `ruleedit` et `mfedit` n'ont pas d'équivalent.

### Statistiques et apprentissage

- **Objets de modèle** : `fitlm` rend un objet `LinearModel` comme
  MATLAB — `Coefficients` en table (`Estimate`, `SE`, `tStat`,
  `pValue`), `Rsquared.Ordinary`, `Formula.Terms`, diagnostics, méthodes
  `predict`, `feval`, `random`, `coefCI`, `coefTest`, `anova` —, mais
  sans ses méthodes graphiques (`plot`, `plotResiduals`...), sans
  `step`, `addTerms`, `removeTerms`, sans `RobustOpts` ni `HatMatrix`.
  Les autres modèles — `ClassificationSVM`, `GeneralizedLinearModel`,
  `LinearMixedModel`... — sont encore des structures portant les mêmes
  champs, avec une fonction `predict` commune qui reconnaît le modèle à
  son champ `type` ; leurs `Coefficients` sont un vecteur, non une table.
- **`fitlme`** n'ajuste que les intercepts aléatoires — la forme
  `(1|g)` —, avec un ou plusieurs facteurs croisés. Les pentes
  aléatoires, `(x|g)`, et les modèles emboîtés ne le sont pas.
- **Formules de Wilkinson** : `fitlm` les lit (`+`, `-`, `*`, `:`,
  `^` sur une variable, `- 1`), mais pas la puissance d'une somme,
  `(A + B)^2`. `fitlme` ne lit que des termes séparés par `+`, et
  `fitglm` prend une matrice.
- **`nlinfit`** suit l'algorithme et les réglages de MATLAB
  (`statset('nlinfit')`, avertissements compris), mais refuse en le
  disant l'ajustement robuste (`Robust`), les poids (`Weights`) et les
  modèles d'erreur autres que `'constant'`.
- **`pca`** refuse en le disant les poids d'observation (`Weights`), un
  vecteur de `VariableWeights`, `Rows','pairwise'` et l'algorithme `als`.
- **`anova` d'un `LinearModel`** calcule les sommes de carrés de types
  1, 3 et `'h'`, non le type 2 ; le résumé n'a pas les lignes d'erreur
  d'ajustement et d'erreur pure.
- **`polytool` et `stepwise`** ne sont pas interactifs : MatLibre mène la
  procédure et rend le résultat, là où MATLAB ouvre une fenêtre où l'on
  ajoute et retire les termes à la main.
- **`eig(A,B)`** passe par la réduction de Cholesky quand B est
  symétrique définie positive, et par `B\A` sinon : une matrice B
  singulière — que MATLAB traite par la décomposition QZ, avec des
  valeurs propres infinies — n'est pas admise.

### Robustesse

Les noms sont tous présents ; ce qui suit est ce que la représentation
de MatLibre ne fait pas comme celle de MathWorks.

- **Pas de forme LFT.** MATLAB range une incertitude en transformation
  fractionnaire linéaire, ce qui rend l'analyse mu exacte. MatLibre garde
  la dépendance elle-même — la fonction des paramètres —, ce qui accepte
  une division ou une racine que la forme LFT ne représenterait qu'au
  prix d'un développement. En contrepartie, `wcgain`, `robstab` et leurs
  voisines balaient le domaine — sommets, tirages, descente locale — et
  rendent donc un **minorant** du pire cas, exact quand la dépendance est
  monotone, là où MATLAB rend un majorant par mu. Chaque fiche le dit.
- **`mussv` borne, il ne calcule pas.** La borne haute vient de la mise à
  l'échelle d'Osborne, la borne basse d'une recherche de phase ; elles se
  rejoignent sur un bloc plein et sur une structure diagonale de trois
  blocs au plus, non en général.
- **`dksyn` à D constant.** L'itération D-K emploie une mise à l'échelle
  constante en fréquence, non un ajustement rationnel de D : le
  correcteur trouvé est un peu moins bon, et d'ordre plus bas.
- **`hinfstruct` par le simplexe.** Le réglage d'un correcteur structuré
  passe par Nelder-Mead sur les paramètres, non par la méthode non lisse
  de MATLAB : plus lent, sans garantie d'optimum, mais applicable à
  n'importe quelle structure.
- **`iconnect` n'existe pas.** Les schémas s'assemblent par `sysic` ou
  par `connect`.

### Cartographie

- **Géodésie** : `distance`, `azimuth` et `reckon` suivent la forme de
  MATLAB — arc en degrés sur la sphère unité, longueur dans l'unité du
  demi-grand axe sur un ellipsoïde — ; sur l'ellipsoïde, la méthode de
  Vincenty (1975), au dixième de millimètre, qui ne converge pas pour
  deux points presque antipodaux : `distance` le dit par une erreur, là
  où MATLAB rend le résultat. La loxodromie (`'rh'`) n'est calculée que
  sur la sphère.
- **`areaint` rend l'aire exacte** du polygone à côtés de grand cercle.
  MATLAB intègre par trapèzes : sa documentation rend 0.0792 pour un
  fuseau de 30 degrés décrit avec des sommets tous les 30 degrés, dont
  l'aire exacte, 1/12, est ce que rend MatLibre.
- **`referenceEllipsoid`** connaît WGS84, GRS80, Hayford (international),
  Bessel et Clarke 1866, ou un vecteur [a e] ; pas `referenceSphere`, ni
  la base des codes EPSG. Les projections (`projcrs`, `projfwd`,
  `mfwdtran`) manquent ; `deg2utm` et `distanceGC` sont propres à
  MatLibre.

### Bio-informatique

- **`nwalign` et `swalign`** font les alignements de MATLAB — matrices
  BLOSUM45, 50, 62, 80, 90, PAM250 et NUC44, trous affines, score en
  bits —, sans le tracé de `Showscore`. Les autres matrices (`blosum(30)`,
  `pam(120)`...) sont refusées. `multialign`, `seqpdist` et les arbres
  phylogénétiques manquent.

### Aérospatial

- **`atmosisa`** couvre l'atmosphère type de -5 km à la mésopause
  (84,852 km), viscosités comprises ; `atmoscoesa`, `atmosnonstd` et les
  modèles de vent manquent.

### Radar et réseaux d'antennes

- **L'équation du radar** suit les signatures de MATLAB : `radareqpow`,
  `radareqrng` et `radareqsnr` prennent `RCS`, `Ts`, `Gain` (un gain ou
  deux, émission et réception), `Loss`, `CustomFactor`,
  `AtmosphericLoss`, `PropagationFactor` et `unitstr`, monostatique ou
  bistatique ; les exemples de MathWorks sont retrouvés aux chiffres
  imprimés. Les objets système (`phased.ULA`, `phased.MUSICEstimator`,
  `phased.RangeDopplerResponse`...) n'existent pas.
- **Estimation de direction** : `steervec` (réseau quelconque, phases
  quantifiées), `sensorcov`, `musicdoa`, `rootmusicdoa` et `espritdoa`
  suivent MATLAB ; `espritdoa` refuse en le disant une pondération des
  lignes (`RowWeighting`) autre que un. Avec une covariance exacte,
  `rootmusicdoa` rend les angles à 1e-7 près seulement : ses racines sont
  doubles sur le cercle unité, ce qui coûte la moitié des chiffres.

### Radiofréquences et antennes

- **Conversions de paramètres** : `s2z`, `z2s`, `s2y`, `y2s`, `s2abcd`,
  `abcd2s`, `gammain` et `gammaout` prennent des tableaux N x N x K, comme
  MATLAB ; l'objet `sparameters`, la lecture des fichiers Touchstone et
  les objets de circuit (`rfckt`, `circuit`) manquent.
- **Pas d'objets d'antenne** : `dipole`, `patchMicrostrip` et le calcul
  par la méthode des moments (impédance, courants, couplage) de l'Antenna
  Toolbox n'existent pas. MatLibre calcule les diagrammes analytiques —
  dipôle de longueur quelconque, facteur de réseau — et en tire
  directivité et ouverture, conformes à Balanis.

### Traitement du signal en temps réel

- **`firls`** calcule les moindres carrés intégrés en forme fermée, types
  I à IV et transformateur de Hilbert, comme MATLAB ; l'option
  `'differentiator'`, qui pondère l'erreur en 1/f², est refusée en le
  disant (`firpm` la connaît).
- **Pas d'objets système** (`dsp.FIRFilter`, `dsp.AudioFileReader`,
  `dsp.SpectrumAnalyzer`...) : le traitement par blocs s'écrit avec les
  fonctions.

### Audio

- **Descripteurs** : `spectralCentroid` et `zerocrossrate` suivent MATLAB
  — trames de 30 ms recouvertes de 20 ms, fenêtre rectangulaire, spectre
  de puissance ; méthodes `'difference'` et `'comparison'`, niveau, seuil,
  état initial. Le spectre d'une trame est |FFT|² sur les raies de 0 à
  fs/2. `audioFeatureExtractor`, `mfcc`, `melSpectrogram`, `pitch` et les
  autres descripteurs spectraux manquent ; `mfccSimple` en tient lieu.

### Communications sans fil

- **`ofdmmod` et `ofdmdemod`** suivent MATLAB : sous-porteuses de la plus
  négative à la plus positive, porteuses nulles, pilotes, préfixe variable
  d'un symbole à l'autre, fenêtre avancée dans le préfixe avec la rotation
  de phase compensée. Le suréchantillonnage (`OversamplingFactor` autre
  que un) est refusé en le disant.
- **`qammod` et `qamdemod`** placent les symboles comme MATLAB — le
  symbole 0 en haut à gauche, en descendant chaque colonne —, en ordre
  binaire, de Gray ou personnalisé, avec `UnitAveragePower` et l'entrée
  ou la sortie en bits. Les constellations en croix (M = 8, 32, 128...) et
  les sorties souples (`'llr'`, `'approxllr'`) sont refusées en le disant.

### Vision par ordinateur

- **Les points sont des tableaux**, non des objets `cornerPoints` : les
  détecteurs rendent les positions [x y] et la métrique, que
  `selectStrongest` sait trier. `detectHarrisFeatures` et
  `detectMinEigenFeatures` lisent `MinQuality`, `FilterSize` et `ROI`,
  retiennent un seul pixel par plateau et affinent la position au
  sous-pixel par une parabole dans chaque direction — la méthode de
  MATLAB n'est pas documentée, et les positions peuvent différer au
  dixième de pixel près.
- **`estimateGeometricTransform2D`** est robuste par défaut, comme MATLAB
  (MSAC, `MaxDistance` 1,5 pixel, `MaxNumTrials`, `Confidence`), et
  connaît les quatre types ; elle rend la matrice 3 x 3, non l'objet
  `rigid2d`, `affine2d` ou `projective2d`.

### Robotique

- **Quaternions** : `quatmultiply`, `quatdivide`, `quatconj`,
  `quatnormalize`, `quatinv`, `quatrotate`, `quatnorm` et `quatmod`
  suivent l'Aerospace Toolbox, ligne par ligne sur des tableaux M x 4 :
  `quatdivide(q,r)` rend inv(r) x q, `quatrotate` fait une rotation
  passive et `quatnorm` rend la somme des carrés. L'objet `quaternion`
  n'existe pas.
- **Trajectoires** : `cubicpolytraj`, `quinticpolytraj` et `trapveltraj`
  rendent la forme `pp` de MATLAB, que `ppval` évalue. Sans paramètre,
  `trapveltraj` prend une durée d'un par segment et une rampe d'un tiers
  du temps — MATLAB ne documente pas sa règle par défaut, les profils
  peuvent donc différer quand on ne fixe rien.
- **Arbres de corps rigides** : `rigidBodyTree` lit les URDF
  (`importrobot`) et porte la cinématique et la dynamique (`massMatrix`,
  `inverseDynamics`, `gravityTorque`, `forwardDynamics`) ; la détection de
  collisions (`checkCollision`) manque. `ikine2R`, `fkine2R` et
  `jacobian2R` sont propres à MatLibre.

### Identification de systèmes

- **Critères** : `aic` rend par défaut le critère normalisé nAIC, comme
  MATLAB, et `Report.Fit` porte `FitPercent`, `LossFcn`, `MSE`, `FPE`,
  `AIC`, `AICc`, `nAIC` et `BIC` selon les formules de sa documentation.
- **Estimation** : ARX par moindres carrés sur les échantillons qui ont
  tout leur passé ; ARMAX, OE, BJ et PEM minimisent l'erreur de
  prédiction avec des conditions initiales nulles, par Levenberg-Marquardt.
  L'option `InitialCondition` de MATLAB (`'estimate'`, `'backcast'`) n'est
  pas faite : sur des données courtes, les estimations diffèrent des
  siennes du poids des premiers échantillons.

### Navigation, fusion de capteurs, commande prédictive

- **Fonctions propres à MatLibre** : `haversine`, `azimuthTo`, `astar`,
  `ekfPredict`, `ekfUpdate`, `kalmanFilter`, `madgwickUpdate`,
  `complementaryFilter` et `trackAssign` rendent des tableaux ; les objets
  de MATLAB (`trackingEKF`, `trackingKF`, `imufilter`, `ahrsfilter`,
  `plannerAStarGrid`, `occupancyMap` complet) n'existent pas.
  `assignmunkres` suit la signature de MATLAB.
- **`trackAssign`** affecte au plus proche voisin global, exactement, par
  l'algorithme de Munkres ; `madgwickUpdate` suit le filtre de Madgwick
  (2010) au dernier chiffre près du paquet Python `ahrs`.
- **Commande prédictive** : `mpcSetup`, `mpcmove` et `mpcsim` traitent une
  entrée et une sortie, sans l'objet `mpc` de MATLAB : pas de poids sur
  les variations de commande, ni de contraintes sur les sorties. Les
  bornes de commande sont respectées exactement, par `quadprog`.

### Lidar, véhicule, conduite automatisée

- **ICP point à point** (`icpRegister`, en deux dimensions) : la
  transformation est exacte quand les appariements initiaux sont justes ;
  plus loin, sur une courbe échantillonnée régulièrement, il s'arrête dans
  le minimum local où les points ont glissé d'un pas. `pcregistericp` de
  la boîte vision traite les nuages 3-D.
- **Fonctions d'école** : `bicycleModel` (cinématique, pas d'Euler),
  `tireForce` (formule magique de Pacejka à quatre coefficients),
  `longitudinal`, `purePursuit`, `smoothPath`, `laneOffset` et
  `timeToCollision` sont propres à MatLibre ; les blocs et objets du
  Vehicle Dynamics Blockset et de l'Automated Driving Toolbox
  (`drivingScenario`, `referencePathFrenet`, `lateralControllerStanley`)
  manquent.

### Calcul

- **Décomposition de Schur** (`schur`, `ordschur`, `qz`) : elle manque à
  l'algèbre linéaire, et les solveurs de Riccati doivent s'en passer.
- **Matrices creuses** : elles existent, mais les factorisations creuses
  (`chol`, `lu`, `qr` creux) travaillent en dense, et `A\b` creux, au-delà
  de deux cents inconnues, est itératif — BiCGSTAB sans préconditionneur,
  arrêté à un résidu relatif de 1e-12 — : la solution est juste à 1e-10
  environ, non à la précision machine du solveur direct de MATLAB.
- **`hess`, `schur` et `sylvester`** n'existent pas.
- **`format short` d'une matrice** n'écrit pas le facteur d'échelle commun
  de MATLAB (« 1.0e+03 * ») : chaque élément garde ses quatre décimales.
  Un scalaire, lui, passe en notation exponentielle hors de [0.001, 1000)
  comme dans MATLAB.
- **Précision variable** (`vpa`) et calcul symbolique complet : la boîte
  Symbolique couvre le dérivé, l'intégré simple et la résolution
  polynomiale, non l'algèbre générale.
