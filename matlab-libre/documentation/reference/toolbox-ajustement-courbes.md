# Toolbox `ajustement-courbes`

```
% Curve Fitting Toolbox — ajustement de courbes et de surfaces.
%
% Ajuster
%   fit                 - Ajuste un modèle à des données
%   fittype             - Modèle, nommé ou écrit à la main
%   fitoptions          - Réglages de l'ajustement
%   setoptions          - Attache des réglages à un modèle
%   cfit                - Courbe ajustée, qu'on évalue comme une fonction
%   sfit                - Surface ajustée
%
% Ce qu'on demande à un ajustement
%   feval               - L'évaluer
%   coeffvalues         - La valeur des coefficients
%   confint             - Leur intervalle de confiance
%   predint             - L'intervalle de la courbe, ou d'une observation
%   differentiate       - Ses dérivées
%   integrate           - Sa primitive
%   plot                - Son tracé
%   formula, coeffnames, probnames, probvalues
%   indepnames, dependnames, argnames, numargs, numcoeffs
%   islinear, type
%
% Préparer les données
%   prepareCurveData    - Colonnes, sans point non fini
%   prepareSurfaceData  - De même, en dépliant une grille
%   excludedata         - Masque des points à écarter
%   smooth              - Lissage : moyenne mobile, régression locale,
%                         Savitzky et Golay, variantes robustes
%
% Splines
%   csaps               - Spline de lissage, compromis réglé
%   spaps               - Spline la plus lisse dans une tolérance
%   csape               - Interpolation à conditions de bord choisies
%   spap2               - Spline des moindres carrés, à nœuds donnés
%   augknt              - Répétition des nœuds extrêmes
%   fnval               - Évaluation
%   fnder, fnint        - Dérivée et primitive
%   fnbrk               - Extraction d'une partie
%   fnplt               - Tracé
%
% Anciennes commodités de MatLibre
%   fitCurve            - Ajustement par un modèle nommé
%   fitSurface          - Ajustement polynomial d'une surface
%   goodnessOfFit       - R2, RMSE, SSE
%   smoothSpline        - Lissage par spline pénalisée
```

## `augknt`

```
AUGKNT Répète les nœuds extrêmes d'une suite.
  N = AUGKNT(SUITE,ORDRE) rend la suite de nœuds dont les deux extrêmes
  sont répétés ORDRE fois. C'est ce qu'il faut pour qu'une spline
  d'ordre ORDRE soit définie jusqu'aux bords de l'intervalle et y prenne
  la valeur de son premier — et de son dernier — coefficient.

  Exemple :
     augknt([0 1 2], 3)      % 0 0 0 1 2 2 2

  Voir aussi SPAP2, MATLIBRE_BASE_BSPLINE.
```

## `cfit`

```
CFIT Courbe ajustée, qu'on évalue comme une fonction.
  FO = FIT(X,Y,MODELE) rend un objet CFIT. On l'évalue en l'appelant :
  FO(XNOUVEAU). Il porte les coefficients trouvés, les résidus et de
  quoi calculer les intervalles de confiance.

  Ce qu'on lui demande :
     COEFFVALUES   - la valeur des coefficients
     CONFINT       - leur intervalle de confiance
     PREDINT       - l'intervalle de confiance de la courbe, ou d'une
                     observation à venir
     DIFFERENTIATE - les dérivées première et seconde
     INTEGRATE     - la primitive
     PLOT          - le tracé, avec les points s'ils sont donnés
     FORMULA, COEFFNAMES, PROBVALUES, TYPE, ISLINEAR, NUMCOEFFS

  Exemple :
     fo = fit((1:10)', (1:10)'.^2, 'poly2');
     fo(3)              % 9
     coeffvalues(fo)    % 1, 0, 0 a l'arrondi pres
     confint(fo)

  Voir aussi FIT, FITTYPE, SFIT, CONFINT, PREDINT.
```

## `csape`

```
CSAPE Spline cubique d'interpolation, à conditions de bord choisies.
  PP = CSAPE(X,Y) interpole par une spline cubique dont les bords
  suivent la condition « not-a-knot » : la dérivée troisième est
  continue au deuxième et à l'avant-dernier nœud.

  PP = CSAPE(X,Y,CONDITIONS) où CONDITIONS vaut :
    'complete' ou 'clamped'  dérivée première imposée aux deux bouts
    'second'                 dérivée seconde imposée aux deux bouts
    'variational', 'natural' dérivée seconde nulle aux deux bouts
    'periodic'               la fonction et ses deux dérivées se
                             raccordent d'un bout à l'autre
    'not-a-knot'             le défaut

  PP = CSAPE(X,Y,CONDITIONS,VALEURS) donne les valeurs imposées aux
  bords, quand la condition en demande.

  Le choix des conditions ne change rien au milieu de l'intervalle mais
  beaucoup près des bords : une spline naturelle y perd la précision
  qu'une spline « not-a-knot » conserve, tandis qu'une spline serrée est
  exacte si l'on connaît vraiment les pentes.

  Exemple :
     pp = csape(0:4, sin(0:4), 'complete', [cos(0) cos(4)]);
     abs(ppval(pp, 2.5) - sin(2.5)) < 0.01

  Voir aussi SPLINE, CSAPS, SPAPS, FNVAL.
```

## `csaps`

```
CSAPS Spline cubique de lissage.
  PP = CSAPS(X,Y) rend la spline qui réalise le meilleur compromis entre
  passer près des points et rester peu courbée. Elle minimise

     p * somme(w_i * (y_i - f(x_i))^2) + (1-p) * integrale de f''^2

  PP = CSAPS(X,Y,P) impose le paramètre de lissage, entre zéro et un.
  À un, la spline interpole exactement ; à zéro, elle se réduit à la
  droite des moindres carrés. Entre les deux, elle suit les données
  d'autant plus fidèlement que P est proche de un.

  VALEURS = CSAPS(X,Y,P,XX) évalue directement la spline en XX.
  CSAPS(X,Y,P,XX,W) pondère les points.

  [PP,P] = CSAPS(...) rend aussi le paramètre employé, ce qui est utile
  quand on l'a laissé choisir.

  Sans P, il est pris tel que le terme de fidélité et le terme de
  courbure pèsent également au vu de l'espacement des données.

  Exemple :
     x = linspace(0, 2*pi, 40)';
     y = sin(x) + 0.1 * randn(size(x));
     pp = csaps(x, y, 0.99);
     max(abs(ppval(pp, x) - sin(x))) < 0.2

  Voir aussi SPAPS, SPLINE, CSAPE, FIT, PPVAL.
```

## `excludedata`

```
EXCLUDEDATA Masque des points à écarter d'un ajustement.
  E = EXCLUDEDATA(X,Y,METHODE,VALEUR) rend un masque logique, vrai pour
  les points à écarter. Ce masque se passe ensuite à FIT par l'option
  'Exclude'.

  Méthodes :
    'box'       VALEUR vaut [xmin xmax ymin ymax] ; écarte ce qui est
                hors de la boîte
    'domain'    VALEUR vaut [xmin xmax] ; écarte ce qui est hors de
                l'intervalle des abscisses
    'range'     VALEUR vaut [ymin ymax] ; de même sur les ordonnées
    'indices'   VALEUR donne les indices à écarter
    'outliers'  VALEUR donne les résidus d'un premier ajustement ;
                écarte les points dont le résidu sort de plus d'une fois
                et demie l'écart interquartile hors des quartiles —
                la règle de Tukey, qui ne suppose rien de la loi du
                bruit

  Exemple :
     e = excludedata((1:10)', (1:10)', 'domain', [3 8]);
     sum(e)      % 4 points ecartes

  Voir aussi FIT, FITOPTIONS.
```

## `fit`

```
FIT Ajuste un modèle à des données.
  FO = FIT(X,Y,MODELE) ajuste le modèle aux couples donnés et rend un
  objet qu'on évalue comme une fonction : FO(XNOUVEAU).

  MODELE est un FITTYPE, ou directement le nom d'un modèle de la
  bibliothèque ('poly2', 'exp1', 'gauss3', 'smoothingspline'…), ou une
  expression écrite à la main.

  [FO,QUALITE] = FIT(...) rend aussi la qualité de l'ajustement : somme
  des carrés des écarts, R carré, R carré ajusté, écart quadratique
  moyen et degrés de liberté.

  [FO,QUALITE,SORTIE] = FIT(...) rend les résidus, la matrice
  jacobienne, le nombre d'itérations et le drapeau de sortie.

  FIT(...,OPTIONS) ou FIT(...,'Nom',VALEUR,...) règle l'ajustement ;
  voir FITOPTIONS. FIT(...,'problem',{...}) donne la valeur des
  paramètres que le modèle a déclarés imposés.

  Un modèle linéaire en ses coefficients est résolu directement, sans
  itération ni point de départ : le résultat est le minimum global. Un
  modèle non linéaire est ajusté par moindres carrés itératifs, depuis
  un point de départ déduit des données.

  Exemple :
     x = (0:0.1:5)';
     y = 3 * exp(-0.7 * x) + 0.01 * randn(size(x));
     [fo, gof] = fit(x, y, 'exp1');
     coeffvalues(fo)      % environ 3 et -0.7
     gof.rsquare

  Voir aussi FITTYPE, FITOPTIONS, CFIT, CONFINT, PREDINT, DIFFERENTIATE.
```

## `fitCurve`

```
FITCURVE Ajustement par un modèle nommé.
  TYPE vaut 'poly', 'exp' (a e^{bx}), 'power' (a x^b), 'log' (a + b ln x)
  ou 'gauss' (a exp(-((x-b)/c)^2)).
```

## `fitSurface`

```
FITSURFACE Ajustement polynomial d'une surface z = f(x,y).
  [COEFFICIENTS,MODELE] = FITSURFACE(X,Y,Z,DEGRE) ajuste un polynôme à
  deux variables du degré total demandé, au sens des moindres carrés.
  DEGRE vaut un par défaut, soit un plan.

  Le nombre de coefficients croît vite : (D+1)(D+2)/2, soit trois pour
  un plan, six au degré deux, dix au degré trois. Il faut au moins
  autant de points que de coefficients, et de préférence bien plus,
  sans quoi l'ajustement interpole le bruit.

  Les points doivent aussi être répartis : tous alignés, ils ne
  déterminent pas une surface, et le système devient singulier.

  Exemple :
     [x, y] = meshgrid(linspace(0, 1, 10));
     z = 2 * x + 3 * y + 1;
     c = fitSurface(x(:), y(:), z(:), 1);        % [1 2 3] a l'ordre pres

  Voir aussi FIT, SFIT, GOODNESSOFFIT, POLYFIT.
```

## `fitoptions`

```
FITOPTIONS Réglages d'un ajustement.
  OPT = FITOPTIONS() rend les réglages par défaut.
  OPT = FITOPTIONS('Method',M,...) impose la méthode et les réglages.
  OPT = FITOPTIONS(FT) rend les réglages qui conviennent au modèle FT :
  la méthode s'en déduit, et les bornes que le modèle impose à ses
  coefficients y figurent déjà.
  OPT = FITOPTIONS(OPT,'Nom',VALEUR,...) modifie des réglages existants.

  Champs et valeurs par défaut :
    Method            déduite du modèle
    Robust            'off' ; 'Bisquare' ou 'LAR' pondèrent à la baisse
                      les points les plus éloignés, à chaque tour, ce
                      qui empêche quelques valeurs aberrantes d'emporter
                      l'ajustement
    StartPoint        [] ; déduit des données quand il manque
    Lower, Upper      [] ; bornes des coefficients
    Weights           [] ; poids des observations
    Exclude           [] ; masque des points à écarter
    Normalize         'off' ; centre et réduit l'abscisse avant
                      d'ajuster, ce qui conditionne les polynômes de
                      degré élevé
    MaxIter           400
    TolFun, TolX      1e-8
    SmoothingParam    [] ; entre 0 — une droite — et 1 — l'interpolation
    Span              0.25 ; la part des points que voit un lissage local

  Exemple :
     opt = fitoptions('Method', 'NonlinearLeastSquares', 'StartPoint', [1 1]);

  Voir aussi FIT, FITTYPE, SETOPTIONS.
```

## `fittype`

```
FITTYPE Modèle d'ajustement, nommé ou écrit à la main.
  FT = FITTYPE('poly2') désigne un modèle de la bibliothèque. Les noms
  sont ceux de MATLAB : 'poly1' à 'poly9', 'exp1', 'exp2', 'power1',
  'power2', 'gauss1' à 'gauss8', 'sin1' à 'sin8', 'fourier1' à
  'fourier8', 'rat' suivi de deux chiffres, 'weibull', et les
  interpolants 'linearinterp', 'nearestinterp', 'pchipinterp',
  'cubicinterp', 'splineinterp', 'smoothingspline'.

  FT = FITTYPE('a*exp(b*x) + c') lit une expression : tout identifiant
  qui n'est ni la variable indépendante, ni un paramètre imposé, ni le
  nom d'une fonction connue, est un coefficient à ajuster. Les
  coefficients sont rangés par ordre alphabétique, comme dans MATLAB.

  FITTYPE(...,'independent',V) nomme la variable indépendante ('x' par
  défaut), 'dependent' la variable expliquée, 'coefficients' impose la
  liste des coefficients et leur ordre, 'problem' déclare des paramètres
  qui seront donnés au moment de l'ajustement plutôt qu'ajustés.

  Ce qu'on demande à un modèle : FORMULA, COEFFNAMES, NUMCOEFFS,
  INDEPNAMES, DEPENDNAMES, PROBNAMES, ARGNAMES, NUMARGS, ISLINEAR, TYPE.
  FEVAL l'évalue.

  Exemple :
     ft = fittype('a*x^2 + b');
     coeffnames(ft)      % a, b
     feval(ft, [2 1], 3)   % 19

  Voir aussi FIT, FITOPTIONS, CFIT, SETOPTIONS.
```

## `fnbrk`

```
FNBRK Extrait une partie d'une spline.
  V = FNBRK(F,PARTIE) où PARTIE vaut 'breaks' — ou 'knots' pour une
  B-spline —, 'coefs', 'pieces', 'order', 'dim' ou 'interval'.
  FNBRK(F,I) où I est un entier rend le morceau numéro I, comme spline
  à part entière.
  [B,C,L,K] = FNBRK(F) rend d'un coup les nœuds, les coefficients, le
  nombre de morceaux et l'ordre.

  Exemple :
     fnbrk(spline(1:5, (1:5).^2), 'order')      % 4

  Voir aussi FNVAL, FNDER, FNINT, SPLINE.
```

## `fnder`

```
FNDER Dérivée d'une fonction par morceaux.
  D = FNDER(F) rend la dérivée de la spline F, sous la même forme.
  D = FNDER(F,N) dérive N fois ; N négatif intègre.

  Dériver une spline cubique donne une spline quadratique : l'ordre
  baisse d'un, les morceaux restent les mêmes.

  Exemple :
     pp = spline(1:5, (1:5).^2);
     fnval(fnder(pp), 3)      % 6, la derivee de x^2

  Voir aussi FNINT, FNVAL, PPVAL, SPLINE.
```

## `fnint`

```
FNINT Primitive d'une fonction par morceaux.
  P = FNINT(F) rend la primitive de la spline F qui s'annule en son
  premier nœud. FNINT(F,V) lui donne la valeur V en ce point.

  Les constantes d'intégration des morceaux ne sont pas libres : elles
  sont fixées par la continuité de la primitive d'un morceau au suivant.

  Exemple :
     pp = spline(0:4, (0:4).^2);
     fnval(fnint(pp), 3)      % 9, l'integrale de x^2 de 0 a 3

  Voir aussi FNDER, FNVAL, PPVAL.
```

## `fnplt`

```
FNPLT Trace une fonction par morceaux.
  FNPLT(F) trace la spline sur son intervalle de définition.
  FNPLT(F,STYLE) impose le style du trait.
  FNPLT(F,[A B]) restreint l'intervalle.
  H = FNPLT(...) rend la poignée du tracé.

  Exemple :
     fnplt(spline(1:5, [1 3 2 5 4]));

  Voir aussi FNVAL, PLOT, FNBRK.
```

## `fnval`

```
FNVAL Évalue une fonction par morceaux.
  V = FNVAL(F,X) évalue la spline F aux abscisses X, que F soit donnée
  sous forme de morceaux polynomiaux — celle que rendent SPLINE et
  CSAPS — ou sous forme de B-splines, celle que rend SPAP2.

  FNVAL(X,F) est accepté aussi : l'ordre des arguments n'importe pas,
  comme dans MATLAB.

  Exemple :
     fnval(spline(1:5, (1:5).^2), 2.5)      % 6.25

  Voir aussi PPVAL, FNDER, FNINT, FNBRK, FNPLT.
```

## `goodnessOfFit`

```
GOODNESSOFFIT Indicateurs de qualité d'un ajustement.
  STATS = GOODNESSOFFIT(Y,YHAT) rend une structure : la somme des carrés
  des résidus, l'erreur quadratique moyenne, le coefficient de
  détermination et sa version ajustée.

  Le R2 dit quelle part de la variance est expliquée, mais il ne peut
  que croître quand on ajoute des paramètres — même inutiles. C'est
  pourquoi le R2 ajusté existe : il pénalise le nombre de paramètres, et
  peut donc décroître quand on en ajoute un qui n'apporte rien.

  Un R2 élevé ne dit pas que le modèle est juste : il peut être élevé
  sur un modèle faux et bas sur un modèle correct mais bruité. Regarder
  les résidus vaut mieux que regarder le R2.

  Exemple :
     stats = goodnessOfFit(y, modele(x));
     stats.rsquare
     stats.rmse

  Voir aussi FIT, FITSURFACE, CONFINT.
```

## `matlibre_ajuster_lineaire`

```
MATLIBRE_AJUSTER_LINEAIRE Moindres carrés, éventuellement robustes.
  [C,J] = MATLIBRE_AJUSTER_LINEAIRE(A,Y,POIDS,OPTIONS) résout le système
  pondéré au sens des moindres carrés. Le modèle étant linéaire, la
  solution est directe et c'est le minimum global : ni point de départ,
  ni itération.

  Avec l'option Robust, les poids sont recalculés à chaque tour d'après
  les résidus : un point très éloigné voit son poids tomber, et cesse
  d'emporter l'ajustement. C'est la moindre carrée itérativement
  repondérée.

  Exemple :
     c = matlibre_ajuster_lineaire([1 1; 2 1], [3; 5], [1; 1], fitoptions());
     c      % 2 et 1

  Voir aussi FIT, ROBUSTFIT.
```

## `matlibre_ajuster_nonlineaire`

_Pas de bloc d'aide._

## `matlibre_ajuster_surface`

```
MATLIBRE_AJUSTER_SURFACE Ajuste un modèle à deux variables.
  [SO,QUALITE,SORTIE] = MATLIBRE_AJUSTER_SURFACE(XY,Z,MODELE,ARGUMENTS)
  ajuste la surface aux triplets donnés. XY a deux colonnes.

  Les modèles polynomiaux sont linéaires en leurs coefficients : la
  résolution est directe. Les interpolants passent par une
  triangulation, ou par une régression locale pour 'lowess' et 'loess'.

  Exemple :
     [x, y] = meshgrid(0:0.2:1, 0:0.2:1);
     z = 1 + 2*x - 3*y + x.*y;
     so = fit([x(:) y(:)], z(:), 'poly22');

  Voir aussi FIT, SFIT, PREPARESURFACEDATA.
```

## `matlibre_appeler_expression`

```
MATLIBRE_APPELER_EXPRESSION Appelle une expression avec ses arguments à plat.
  Y = MATLIBRE_APPELER_EXPRESSION(F,COEFFICIENTS,PROBLEME,X) déplie les
  coefficients et les paramètres imposés en arguments séparés, ce que
  demande la fonction anonyme construite depuis l'expression.

  Exemple :
     f = str2func('@(a,b,x) a*x + b');
     matlibre_appeler_expression(f, [2 1], {}, 3)      % 7

  Voir aussi MATLIBRE_FONCTION_EXPRESSION.
```

## `matlibre_base_bspline`

```
MATLIBRE_BASE_BSPLINE Matrice des B-splines évaluées.
  N = MATLIBRE_BASE_BSPLINE(NOEUDS,ORDRE,X) rend la matrice dont la
  colonne j est la j-ième B-spline d'ordre ORDRE évaluée en X.

  Les B-splines sont construites par la récurrence de Cox et de Boor :
  celles d'ordre un sont les indicatrices des intervalles, et chaque
  ordre suivant combine deux voisines d'ordre inférieur. Elles sont
  positives, à support borné, et somment à un : une combinaison de
  B-splines reste donc dans l'enveloppe de ses coefficients, ce qui rend
  l'ajustement stable là où une base de monômes ne le serait pas.

  Exemple :
     N = matlibre_base_bspline([0 0 0 1 2 2 2], 3, [0.5; 1.5]);
     sum(N, 2)      % des uns

  Voir aussi SPAP2, FNVAL.
```

## `matlibre_base_expression`

```
MATLIBRE_BASE_EXPRESSION Matrice de conception d'un modèle linéaire.
  B = MATLIBRE_BASE_EXPRESSION(EXPRESSION,COEFFICIENTS,PROBLEME,
  INDEPENDANTE) rend la fonction qui, pour des abscisses données,
  construit la matrice dont la colonne k est le modèle évalué avec le
  seul coefficient k à un. Le modèle étant linéaire, cette matrice le
  décrit entièrement.

  Exemple :
     b = matlibre_base_expression('a*x + b', {'a', 'b'}, {}, 'x');
     b([1; 2])      % [1 1; 2 1]

  Voir aussi MATLIBRE_EXPRESSION_LINEAIRE, FIT.
```

## `matlibre_base_polynome`

```
MATLIBRE_BASE_POLYNOME Matrice des puissances de x.
  A = MATLIBRE_BASE_POLYNOME(X,ORDRE) rend la matrice dont la colonne k
  porte x à la puissance ORDRE+1-k. Le modèle polynomial étant linéaire
  en ses coefficients, l'ajustement se ramène à résoudre A*c = y au sens
  des moindres carrés.

  Exemple :
     matlibre_base_polynome([1; 2], 1)      % [1 1; 2 1]

  Voir aussi FIT, POLYFIT.
```

## `matlibre_base_surface`

```
MATLIBRE_BASE_SURFACE Matrice de conception d'un polynôme de surface.
  A = MATLIBRE_BASE_SURFACE(XY,PUISSANCES) où XY a deux colonnes rend la
  matrice dont la colonne k porte x^a * y^b pour le k-ième couple
  d'exposants.

  Exemple :
     matlibre_base_surface([2 3], [0 0; 1 0; 0 1])      % 1 2 3

  Voir aussi MATLIBRE_MODELE_SURFACE, FIT.
```

## `matlibre_bornes_completes`

```
MATLIBRE_BORNES_COMPLETES Bornes d'un vecteur de coefficients.
  B = MATLIBRE_BORNES_COMPLETES(DONNEES,NOMBRE,DEFAUT) complète des
  bornes partielles avec la valeur par défaut, et rend un vecteur de la
  bonne longueur.

  Exemple :
     matlibre_bornes_completes([0], 3, -inf)      % 0 -inf -inf

  Voir aussi FIT, FITOPTIONS.
```

## `matlibre_bspline_deriver`

```
MATLIBRE_BSPLINE_DERIVER Dérivée d'une spline en B-forme.
  [N,O,C] = MATLIBRE_BSPLINE_DERIVER(NOEUDS,ORDRE,COEFS) rend la
  B-forme de la dérivée : l'ordre baisse d'un, les nœuds extrêmes
  tombent, et les coefficients sont les différences divisées des
  anciens.

  Exemple :
     [n, o, c] = matlibre_bspline_deriver([0 0 0 1 2 2 2], 3, [0 1 2 3]);

  Voir aussi MATLIBRE_BSPLINE_VERS_PP, FNDER.
```

## `matlibre_bspline_valeurs`

```
MATLIBRE_BSPLINE_VALEURS Évalue une spline donnée en B-forme.
  Y = MATLIBRE_BSPLINE_VALEURS(NOEUDS,ORDRE,COEFS,X) combine les
  B-splines de la base par les coefficients donnés.

  Exemple :
     matlibre_bspline_valeurs([0 0 0 1 2 2 2], 3, [1 1 1 1], 0.5)      % 1

  Voir aussi FNVAL, SPAP2, MATLIBRE_BASE_BSPLINE.
```

## `matlibre_bspline_vers_pp`

```
MATLIBRE_BSPLINE_VERS_PP Convertit une B-forme en morceaux polynomiaux.
  PP = MATLIBRE_BSPLINE_VERS_PP(SP) rend la même spline sous la forme
  qu'attendent PPVAL, FNDER et FNINT.

  La conversion se fait par développement de Taylor au début de chaque
  morceau : les dérivées successives de la spline s'obtiennent
  exactement par la récurrence des B-splines, et non par différence
  finie.

  Exemple :
     sp = spap2(2, 3, (0:0.1:1)', (0:0.1:1)'.^2);
     max(abs(ppval(matlibre_bspline_vers_pp(sp), 0.5) - fnval(sp, 0.5)))

  Voir aussi SPAP2, FNVAL, MATLIBRE_PP_FORME.
```

## `matlibre_coefficients_expression`

```
MATLIBRE_COEFFICIENTS_EXPRESSION Coefficients d'une expression écrite à la main.
  N = MATLIBRE_COEFFICIENTS_EXPRESSION(EXPRESSION,INDEPENDANTE,PROBLEME)
  relève les identifiants de l'expression et écarte la variable
  indépendante, les paramètres imposés et les noms de fonctions connues.
  Ce qui reste est ajusté. Les noms sont rangés par ordre alphabétique,
  comme dans MATLAB, ce qui fixe l'ordre des coefficients.

  Un identifiant suivi d'une parenthèse est un appel de fonction et non
  un coefficient : c'est ce qui distingue « a*exp(b*x) » de « a*e(b) ».

  Exemple :
     matlibre_coefficients_expression('a*exp(b*x)', 'x', {})     % a, b

  Voir aussi FITTYPE.
```

## `matlibre_colonnes_base`

```
MATLIBRE_COLONNES_BASE Colonnes de la matrice de conception.
  A = MATLIBRE_COLONNES_BASE(FONCTION,NOMBRE,X) évalue le modèle avec un
  seul coefficient à un et les autres à zéro, une fois par coefficient.

  Exemple :
     % appelée par MATLIBRE_BASE_EXPRESSION

  Voir aussi MATLIBRE_BASE_EXPRESSION.
```

## `matlibre_covariance_ajustement`

```
MATLIBRE_COVARIANCE_AJUSTEMENT Covariance des coefficients ajustés.
  [C,S] = MATLIBRE_COVARIANCE_AJUSTEMENT(FO) rend la matrice de
  covariance des coefficients et l'écart type résiduel.

  La covariance est l'inverse de la matrice normale, multipliée par la
  variance résiduelle : c'est l'approximation linéaire de l'incertitude
  au point trouvé, valable tant que le modèle est peu courbé à
  l'échelle de cette incertitude.

  Exemple :
     fo = fit((1:10)', (1:10)', 'poly1');
     matlibre_covariance_ajustement(fo)

  Voir aussi CONFINT, PREDINT.
```

## `matlibre_depart_exponentielle`

```
MATLIBRE_DEPART_EXPONENTIELLE Point de départ d'un ajustement exponentiel.
  D = MATLIBRE_DEPART_EXPONENTIELLE(X,Y,ORDRE) ajuste une droite au
  logarithme des ordonnées positives : le modèle exponentiel y devient
  linéaire, et sa solution est un départ déjà proche.

  Exemple :
     x = (0:0.1:2)';
     matlibre_depart_exponentielle(x, 3*exp(-0.5*x), 1)      % 3, -0.5

  Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
```

## `matlibre_depart_fourier`

```
MATLIBRE_DEPART_FOURIER Point de départ d'un ajustement de Fourier.
  D = MATLIBRE_DEPART_FOURIER(X,Y,ORDRE) part de la moyenne pour la
  constante, de zéro pour les harmoniques, et de la raie spectrale la
  plus forte pour la pulsation fondamentale — le seul paramètre que la
  descente ne retrouve pas de loin.

  Exemple :
     t = (0:0.01:1)';
     matlibre_depart_fourier(t, cos(2*pi*t), 1)

  Voir aussi FIT, MATLIBRE_DEPART_SINUS.
```

## `matlibre_depart_gauss`

```
MATLIBRE_DEPART_GAUSS Point de départ d'un ajustement de gaussiennes.
  D = MATLIBRE_DEPART_GAUSS(X,Y,ORDRE) place une cloche par tranche de
  l'intervalle : son amplitude est le maximum local, son centre
  l'abscisse de ce maximum, sa largeur le quart de la tranche.

  Un ajustement non linéaire ne converge que depuis un départ
  raisonnable ; celui-ci est déduit des données plutôt que tiré au sort,
  ce qui rend l'ajustement reproductible.

  Exemple :
     matlibre_depart_gauss((-3:0.1:3)', exp(-(-3:0.1:3)'.^2), 1)

  Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
```

## `matlibre_depart_puissance`

```
MATLIBRE_DEPART_PUISSANCE Point de départ d'un ajustement en puissance.
  D = MATLIBRE_DEPART_PUISSANCE(X,Y,ORDRE) ajuste une droite aux
  logarithmes des abscisses et des ordonnées positives : le modèle en
  puissance y devient linéaire.

  Exemple :
     x = (1:10)';
     matlibre_depart_puissance(x, 2*x.^1.5, 1)      % 2, 1.5

  Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
```

## `matlibre_depart_rationnelle`

```
MATLIBRE_DEPART_RATIONNELLE Point de départ d'une fraction rationnelle.
  D = MATLIBRE_DEPART_RATIONNELLE(X,Y,HAUT,BAS) résout d'abord le
  problème linéarisé : multiplier par le dénominateur donne une
  équation linéaire en tous les coefficients, dont la solution sert de
  départ à l'ajustement véritable.

  Exemple :
     x = (1:10)'; y = (2*x + 1) ./ (x + 3);
     matlibre_depart_rationnelle(x, y, 1, 1)

  Voir aussi FIT, MATLIBRE_EVALUER_RATIONNELLE.
```

## `matlibre_depart_sinus`

```
MATLIBRE_DEPART_SINUS Point de départ d'un ajustement de sinusoïdes.
  D = MATLIBRE_DEPART_SINUS(X,Y,ORDRE) tire la pulsation du contenu
  fréquentiel des données — la raie la plus forte du spectre —, et
  l'amplitude de leur écart type.

  La pulsation est le paramètre dont l'ajustement dépend le plus : partie
  de trop loin, la descente tombe dans un minimum local à une fréquence
  voisine. La lire dans le spectre évite ce piège.

  Exemple :
     t = (0:0.01:1)';
     matlibre_depart_sinus(t, sin(2*pi*3*t), 1)

  Voir aussi FIT, MATLIBRE_DEPART_FOURIER.
```

## `matlibre_deriver_ajustement`

```
MATLIBRE_DERIVER_AJUSTEMENT Dérivées d'une courbe ajustée.
  [D1,D2] = MATLIBRE_DERIVER_AJUSTEMENT(FO,X) rend la dérivée première
  et la dérivée seconde. Une spline est dérivée exactement, morceau par
  morceau ; un modèle écrit en formule l'est par différences centrées,
  dont le pas est pris proportionnel à l'étendue des abscisses.

  Exemple :
     fo = fit((1:10)', (1:10)'.^2, 'poly2');
     matlibre_deriver_ajustement(fo, 3)      % environ 6

  Voir aussi DIFFERENTIATE, INTEGRATE.
```

## `matlibre_evaluer_fourier`

```
MATLIBRE_EVALUER_FOURIER Série de Fourier tronquée.
  Y = MATLIBRE_EVALUER_FOURIER(C,X,ORDRE) évalue la constante suivie
  des ORDRE harmoniques ; le dernier coefficient est la pulsation
  fondamentale.

  Exemple :
     matlibre_evaluer_fourier([0 1 0 1], 0, 1)      % 1

  Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
```

## `matlibre_evaluer_gauss`

```
MATLIBRE_EVALUER_GAUSS Somme de gaussiennes.
  Y = MATLIBRE_EVALUER_GAUSS(C,X,ORDRE) évalue la somme des ORDRE
  cloches dont C donne, par groupes de trois, l'amplitude, le centre et
  la largeur.

  Exemple :
     matlibre_evaluer_gauss([1 0 1], 0, 1)      % 1

  Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
```

## `matlibre_evaluer_interpolant`

```
MATLIBRE_EVALUER_INTERPOLANT Évalue une courbe interpolée ou lissée.
  Y = MATLIBRE_EVALUER_INTERPOLANT(I,X) applique l'interpolant construit
  par l'ajustement. Hors de l'intervalle des données, la valeur est
  prolongée plutôt que rendue non définie, comme le fait MATLAB pour les
  splines.

  Exemple :
     % appelée par CFIT

  Voir aussi FIT, CFIT, PPVAL.
```

## `matlibre_evaluer_modele`

```
MATLIBRE_EVALUER_MODELE Évalue un modèle sur des coefficients donnés.
  Y = MATLIBRE_EVALUER_MODELE(MODELE,ARGUMENTS) accepte les deux
  écritures : le vecteur des coefficients puis l'abscisse, ou bien les
  coefficients donnés un à un.

  Exemple :
     ft = fittype('a*x + b');
     matlibre_evaluer_modele(ft, {[2 1], 3})      % 7

  Voir aussi FITTYPE, FEVAL.
```

## `matlibre_evaluer_rationnelle`

```
MATLIBRE_EVALUER_RATIONNELLE Quotient de deux polynômes.
  Y = MATLIBRE_EVALUER_RATIONNELLE(C,X,HAUT,BAS) évalue la fraction dont
  C donne d'abord les HAUT+1 coefficients du numérateur, puis les BAS
  coefficients du dénominateur — dont le terme dominant vaut un.

  Exemple :
     matlibre_evaluer_rationnelle([1 0 0], 2, 1, 1)      % 1

  Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
```

## `matlibre_evaluer_sinus`

```
MATLIBRE_EVALUER_SINUS Somme de sinusoïdes.
  Y = MATLIBRE_EVALUER_SINUS(C,X,ORDRE) évalue la somme des ORDRE
  sinusoïdes dont C donne, par groupes de trois, l'amplitude, la
  pulsation et la phase.

  Exemple :
     matlibre_evaluer_sinus([1 1 0], pi/2, 1)      % 1

  Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
```

## `matlibre_evaluer_surface`

```
MATLIBRE_EVALUER_SURFACE Évalue une surface interpolée ou lissée.
  Z = MATLIBRE_EVALUER_SURFACE(I,XY) applique l'interpolant de surface.
  Les méthodes 'linearinterp', 'nearestinterp' et 'cubicinterp' passent
  par une triangulation des points ; 'lowess' et 'loess' ajustent un
  plan ou une quadrique aux voisins les plus proches.

  Exemple :
     % appelée par SFIT

  Voir aussi FIT, SFIT, GRIDDATA.
```

## `matlibre_expression_lineaire`

```
MATLIBRE_EXPRESSION_LINEAIRE L'expression est-elle linéaire en ses coefficients ?
  L = MATLIBRE_EXPRESSION_LINEAIRE(EXPRESSION,COEFFICIENTS,INDEPENDANTE)
  répond en évaluant : un modèle linéaire vérifie que la valeur en la
  somme de deux jeux de coefficients est la somme des valeurs, et qu'elle
  s'annule en zéro. Le contrôle porte sur plusieurs abscisses tirées au
  hasard, ce qui écarte les coïncidences.

  Savoir qu'un modèle est linéaire change tout : ses coefficients
  s'obtiennent alors par une résolution directe, sans point de départ ni
  itération, et le résultat est le minimum global.

  Exemple :
     matlibre_expression_lineaire('a*x + b*x^2', {'a', 'b'}, 'x')     % vrai

  Voir aussi FITTYPE, FIT.
```

## `matlibre_fit_base`

```
MATLIBRE_FIT_BASE Matrice de conception d'un modèle linéaire.
  A = MATLIBRE_FIT_BASE(MODELE,X,IMPOSEES) rend la matrice dont la
  colonne k est le modèle évalué avec le seul coefficient k à un.

  Exemple :
     matlibre_fit_base(fittype('poly1'), [1; 2], {})      % [1 1; 2 1]

  Voir aussi FIT, MATLIBRE_AJUSTER_LINEAIRE.
```

## `matlibre_fit_famille`

```
MATLIBRE_FIT_FAMILLE Voie de résolution d'un ajustement.
  F = MATLIBRE_FIT_FAMILLE(MODELE,OPTIONS) rend 'interpolant',
  'lineaire' ou 'nonlineaire'. Un modèle linéaire dont on borne les
  coefficients passe par la voie non linéaire, seule capable de tenir
  compte des bornes.

  Exemple :
     matlibre_fit_famille(fittype('poly1'), fitoptions())     % lineaire

  Voir aussi FIT.
```

## `matlibre_fit_interpolant`

```
MATLIBRE_FIT_INTERPOLANT Construit un interpolant ou une spline de lissage.
  [I,C] = MATLIBRE_FIT_INTERPOLANT(MODELE,X,Y,POIDS,OPTIONS) rend la
  description de la courbe et le vecteur de coefficients, vide pour un
  interpolant : une courbe qui passe par tous les points n'a pas de
  paramètre à ajuster.

  Exemple :
     i = matlibre_fit_interpolant(fittype('cubicinterp'), (1:5)', (1:5)'.^2, ones(5,1), fitoptions());

  Voir aussi FIT, CSAPS.
```

## `matlibre_fit_normalisation`

```
MATLIBRE_FIT_NORMALISATION Centre et échelle appliqués à l'abscisse.
  N = MATLIBRE_FIT_NORMALISATION(X,OPTIONS) rend [centre, echelle]. Sans
  normalisation, ce sont zéro et un.

  Normaliser change les coefficients mais pas la courbe ajustée ; c'est
  ce qui rend possible un polynôme de degré élevé, dont la matrice de
  conception serait sinon trop mal conditionnée pour être résolue.

  Exemple :
     matlibre_fit_normalisation([1;2;3], fitoptions('Normalize', 'on'))

  Voir aussi FIT, CFIT.
```

## `matlibre_fit_options`

```
MATLIBRE_FIT_OPTIONS Réglages et paramètres imposés d'un appel à FIT.
  [OPT,IMP] = MATLIBRE_FIT_OPTIONS(MODELE,ARGUMENTS) lit les arguments
  qui suivent le modèle : une structure de réglages, des couples nom et
  valeur, ou 'problem' suivi de la valeur des paramètres imposés.

  Exemple :
     [o, p] = matlibre_fit_options(fittype('poly1'), {'Robust', 'Bisquare'});

  Voir aussi FIT, FITOPTIONS.
```

## `matlibre_fit_selection`

```
MATLIBRE_FIT_SELECTION Points retenus pour l'ajustement, et leurs poids.
  [X,Y,P] = MATLIBRE_FIT_SELECTION(X,Y,OPTIONS) écarte les points exclus
  et ceux qui ne sont pas finis, et rend les poids — un par point,
  valant un par défaut.

  Un point non fini ne s'écarte pas tout seul : il contaminerait la
  somme des carrés et rendrait tout l'ajustement indéterminé.

  Exemple :
     [x, y] = matlibre_fit_selection([1;2;NaN], [1;2;3], fitoptions());

  Voir aussi FIT, EXCLUDEDATA.
```

## `matlibre_fit_trier`

```
MATLIBRE_FIT_TRIER Range les points par abscisse croissante.
  [X,Y,ORDRE] = MATLIBRE_FIT_TRIER(X,Y) trie les couples. Les splines et
  les interpolants l'exigent ; pour les autres modèles, cela ne change
  rien au résultat.

  Exemple :
     [x, y] = matlibre_fit_trier([2; 1], [4; 1]);

  Voir aussi FIT.
```

## `matlibre_fittype_surface`

```
MATLIBRE_FITTYPE_SURFACE Objet de modèle à partir d'une description de surface.
  FT = MATLIBRE_FITTYPE_SURFACE(SURFACE) enveloppe la description rendue
  par MATLIBRE_MODELE_SURFACE dans un objet FITTYPE à deux variables
  indépendantes.

  Exemple :
     ft = matlibre_fittype_surface(matlibre_modele_surface('poly11'));
     indepnames(ft)      % x, y

  Voir aussi FITTYPE, MATLIBRE_AJUSTER_SURFACE.
```

## `matlibre_fonction_expression`

```
MATLIBRE_FONCTION_EXPRESSION Rend évaluable une expression écrite à la main.
  F = MATLIBRE_FONCTION_EXPRESSION(EXPRESSION,COEFFICIENTS,PROBLEME,
  INDEPENDANTE) construit la fonction anonyme qui prend le vecteur des
  coefficients, les paramètres imposés et la variable indépendante, et
  rend la valeur de l'expression.

  Exemple :
     f = matlibre_fonction_expression('a*x + b', {'a', 'b'}, {}, 'x');
     f([2 1], {}, 3)      % 7

  Voir aussi FITTYPE, FEVAL.
```

## `matlibre_formule_fourier`

```
MATLIBRE_FORMULE_FOURIER Écriture d'une série de Fourier tronquée.
  T = MATLIBRE_FORMULE_FOURIER(ORDRE) rend la formule du modèle à ORDRE
  harmoniques : une constante, puis un cosinus et un sinus par
  harmonique, tous multiples d'une même pulsation.

  Exemple :
     matlibre_formule_fourier(1)      % a0 + a1*cos(x*w) + b1*sin(x*w)

  Voir aussi FITTYPE, FIT.
```

## `matlibre_formule_gauss`

```
MATLIBRE_FORMULE_GAUSS Écriture d'une somme de gaussiennes.
  T = MATLIBRE_FORMULE_GAUSS(ORDRE) rend la formule du modèle à ORDRE
  cloches : chacune a son amplitude, son centre et sa largeur.

  Exemple :
     matlibre_formule_gauss(1)      % a1*exp(-((x-b1)/c1)^2)

  Voir aussi FITTYPE, FIT.
```

## `matlibre_formule_polynome`

```
MATLIBRE_FORMULE_POLYNOME Écriture d'un polynôme, en toutes lettres.
  T = MATLIBRE_FORMULE_POLYNOME(ORDRE) rend la formule du modèle
  polynomial de cet ordre, telle que l'affiche un objet d'ajustement.

  Exemple :
     matlibre_formule_polynome(2)      % p1*x^2 + p2*x + p3

  Voir aussi FITTYPE, FORMULA.
```

## `matlibre_formule_rationnelle`

```
MATLIBRE_FORMULE_RATIONNELLE Écriture d'une fraction de polynômes.
  T = MATLIBRE_FORMULE_RATIONNELLE(HAUT,BAS) rend la formule du quotient
  d'un polynôme de degré HAUT par un polynôme de degré BAS dont le
  coefficient dominant vaut un — sans quoi numérateur et dénominateur
  pourraient être multipliés par une même constante, et les
  coefficients ne seraient pas déterminés.

  Exemple :
     matlibre_formule_rationnelle(1, 1)      % (p1*x + p2) / (x + q1)

  Voir aussi FITTYPE, FIT.
```

## `matlibre_formule_sinus`

```
MATLIBRE_FORMULE_SINUS Écriture d'une somme de sinusoïdes.
  T = MATLIBRE_FORMULE_SINUS(ORDRE) rend la formule du modèle à ORDRE
  sinusoïdes, chacune avec son amplitude, sa pulsation et sa phase.

  Exemple :
     matlibre_formule_sinus(1)      % a1*sin(b1*x + c1)

  Voir aussi FITTYPE, FIT.
```

## `matlibre_formule_surface`

```
MATLIBRE_FORMULE_SURFACE Écriture d'un polynôme à deux variables.
  T = MATLIBRE_FORMULE_SURFACE(PUISSANCES,NOMS) rend la formule telle
  que l'affiche un objet d'ajustement de surface.

  Exemple :
     [p, n] = matlibre_termes_surface(1, 1);
     matlibre_formule_surface(p, n)      % p00 + p10*x + p01*y

  Voir aussi MATLIBRE_MODELE_SURFACE.
```

## `matlibre_integrer_ajustement`

```
MATLIBRE_INTEGRER_AJUSTEMENT Primitive d'une courbe ajustée.
  V = MATLIBRE_INTEGRER_AJUSTEMENT(FO,X,X0) rend l'intégrale de la
  courbe entre X0 et chaque X. Une spline est intégrée exactement ; un
  modèle écrit en formule l'est par la méthode de Simpson sur une grille
  fine, exacte pour tout polynôme de degré trois.

  Exemple :
     fo = fit((0:0.1:2)', (0:0.1:2)'.^2, 'poly2');
     matlibre_integrer_ajustement(fo, 3, 0)      % environ 9

  Voir aussi INTEGRATE, DIFFERENTIATE.
```

## `matlibre_intervalle_coefficients`

```
MATLIBRE_INTERVALLE_COEFFICIENTS Intervalle de confiance des coefficients.
  B = MATLIBRE_INTERVALLE_COEFFICIENTS(FO,NIVEAU) rend deux lignes : la
  borne basse et la borne haute de chaque coefficient.

  La demi-largeur est le quantile de Student aux degrés de liberté du
  résidu, multiplié par l'écart type du coefficient. C'est la loi de
  Student et non la normale parce que la variance du bruit est estimée
  sur les mêmes données.

  Exemple :
     matlibre_intervalle_coefficients(fit((1:10)', (1:10)', 'poly1'), 0.95)

  Voir aussi CONFINT, PREDINT.
```

## `matlibre_intervalle_prediction`

```
MATLIBRE_INTERVALLE_PREDICTION Bornes de confiance de la courbe ajustée.
  B = MATLIBRE_INTERVALLE_PREDICTION(FO,X,NIVEAU,GENRE,SIMULTANE) rend
  deux colonnes : la borne basse et la borne haute en chaque X.

  L'incertitude sur la courbe vient de celle des coefficients,
  propagée par la jacobienne. L'intervalle d'observation y ajoute la
  variance du bruit de mesure : il dit où tombera un point à venir, non
  où passe la courbe.

  L'intervalle simultané est plus large : il vaut d'un coup pour toutes
  les abscisses, alors que l'intervalle ponctuel ne garantit son niveau
  qu'en une abscisse fixée d'avance.

  Exemple :
     fo = fit((1:10)', (1:10)' + 0.1, 'poly1');
     matlibre_intervalle_prediction(fo, 5, 0.95, 'functional', 'off')

  Voir aussi PREDINT, CONFINT.
```

## `matlibre_jacobienne_modele`

```
MATLIBRE_JACOBIENNE_MODELE Dérivées du modèle par rapport aux coefficients.
  J = MATLIBRE_JACOBIENNE_MODELE(MODELE,COEFFICIENTS,IMPOSEES,X) rend la
  matrice dont la colonne k est la dérivée du modèle par rapport au
  coefficient k, par différence centrée. C'est elle qui donne la
  covariance des coefficients, donc leurs intervalles de confiance.

  Le pas est proportionnel à l'ordre de grandeur du coefficient, avec un
  plancher : un pas fixe serait trop grand pour un coefficient minuscule
  et perdu dans l'arrondi pour un grand.

  Exemple :
     J = matlibre_jacobienne_modele(fittype('poly1'), [2 1], {}, [1; 2]);
     J      % [1 1; 2 1]

  Voir aussi FIT, CONFINT, PREDINT.
```

## `matlibre_lissage_local`

```
MATLIBRE_LISSAGE_LOCAL Régression locale pondérée, éventuellement robuste.
  L = MATLIBRE_LISSAGE_LOCAL(X,Y,FRACTION,ORDRE,ROBUSTE) ajuste, autour
  de chaque point, un polynôme aux voisins pondérés par la tricube de
  leur distance.

  La variante robuste recommence en pondérant à la baisse les points que
  le premier passage a laissés loin : cinq tours suffisent à écarter les
  valeurs aberrantes sans déformer le reste.

  Exemple :
     x = (1:20)';
     matlibre_lissage_local(x, x, 0.5, 1, false);      % la droite elle-meme

  Voir aussi SMOOTH, MATLIBRE_REGRESSION_LOCALE.
```

## `matlibre_modele_bibliotheque`

```
MATLIBRE_MODELE_BIBLIOTHEQUE Description d'un modèle nommé.
  M = MATLIBRE_MODELE_BIBLIOTHEQUE(NOM) rend la description du modèle
  que NOM désigne : sa formule, le nom de ses coefficients, la fonction
  qui l'évalue, s'il est linéaire en ses coefficients, et de quoi partir
  quand il ne l'est pas.

  Les noms suivent ceux de MATLAB : 'poly1' à 'poly9', 'exp1' et
  'exp2', 'power1' et 'power2', 'gauss1' à 'gauss8', 'sin1' à 'sin8',
  'fourier1' à 'fourier8', 'rat' suivi de deux chiffres, 'weibull', et
  les interpolants 'linearinterp', 'nearestinterp', 'pchipinterp',
  'cubicinterp', 'splineinterp', 'smoothingspline'.

  Un modèle vide est rendu si le nom n'est pas connu : c'est alors que
  FITTYPE le lit comme une expression.

  Exemple :
     m = matlibre_modele_bibliotheque('poly2');
     m.Coefficients     % p1 p2 p3

  Voir aussi FITTYPE, FIT.
```

## `matlibre_modele_surface`

```
MATLIBRE_MODELE_SURFACE Description d'un modèle de surface nommé.
  M = MATLIBRE_MODELE_SURFACE(NOM) rend la description des modèles à
  deux variables : 'poly' suivi de deux chiffres — le degré en x puis en
  y —, et les interpolants 'linearinterp', 'nearestinterp',
  'cubicinterp', 'lowess' et 'loess'.

  Un modèle « polyIJ » retient les termes x^a*y^b pour a jusqu'à I, b
  jusqu'à J, et a+b au plus le plus grand des deux : c'est la convention
  de MATLAB, qui évite les termes de degré total trop élevé.

  Exemple :
     m = matlibre_modele_surface('poly22');
     m.Coefficients     % p00 p10 p01 p20 p11 p02

  Voir aussi FITTYPE, FIT, SFIT.
```

## `matlibre_moyenne_mobile`

```
MATLIBRE_MOYENNE_MOBILE Moyenne mobile à fenêtre rétrécie aux bords.
  L = MATLIBRE_MOYENNE_MOBILE(Y,PORTEE) moyenne sur une fenêtre
  centrée. Près des extrémités, la fenêtre rétrécit symétriquement au
  lieu de déborder : le premier point est rendu tel quel. Un
  remplissage, ou une fenêtre décentrée, biaiserait les bords.

  Exemple :
     matlibre_moyenne_mobile([1 2 3 4 5]', 3)'      % 1 2 3 4 5

  Voir aussi SMOOTH.
```

## `matlibre_noms_modele`

```
MATLIBRE_NOMS_MODELE Liste de noms, quelle qu'en soit l'écriture.
  N = MATLIBRE_NOMS_MODELE(S) accepte une chaîne, un tableau de cellules
  de chaînes ou un tableau de chaînes, et rend un tableau de cellules.

  Exemple :
     matlibre_noms_modele('a')        % {'a'}

  Voir aussi FITTYPE.
```

## `matlibre_operateurs_spline`

```
MATLIBRE_OPERATEURS_SPLINE Opérateurs de la spline de lissage.
  [Q,R] = MATLIBRE_OPERATEURS_SPLINE(H) rend les deux matrices creuses
  qui lient les valeurs d'une spline naturelle à ses courbures : Q est
  la différence seconde divisée par les pas, R la matrice de la forme
  quadratique qui donne l'intégrale du carré de la dérivée seconde.

  Ce sont ces deux matrices qui ramènent le problème de lissage, posé
  sur un espace de fonctions, à un système linéaire de taille le nombre
  de points intérieurs.

  Exemple :
     [Q, R] = matlibre_operateurs_spline([1; 1; 1]);
     size(Q)     % 4 2

  Voir aussi CSAPS, SPAPS.
```

## `matlibre_option_canonique`

```
MATLIBRE_OPTION_CANONIQUE Nom exact d'une option d'ajustement.
  N = MATLIBRE_OPTION_CANONIQUE(DONNE) rend le nom du champ, quelle que
  soit la casse employée. MATLAB accepte 'startpoint' comme
  'StartPoint' ; il faut donc rapprocher les deux.

  Exemple :
     matlibre_option_canonique('startpoint')      % StartPoint

  Voir aussi FITOPTIONS.
```

## `matlibre_options_defaut`

```
MATLIBRE_OPTIONS_DEFAUT Réglages d'ajustement par défaut.
  OPT = MATLIBRE_OPTIONS_DEFAUT() rend la structure complète, tous
  champs présents : c'est ce qui permet à FIT de les lire sans avoir à
  vérifier chaque fois qu'ils existent.

  Exemple :
     matlibre_options_defaut().MaxIter      % 400

  Voir aussi FITOPTIONS, FIT.
```

## `matlibre_options_modele`

```
MATLIBRE_OPTIONS_MODELE Réglages qui conviennent à un modèle.
  OPT = MATLIBRE_OPTIONS_MODELE(FT) rend les réglages par défaut, avec
  la méthode que le modèle appelle et les bornes qu'il impose à ses
  coefficients — la largeur d'une gaussienne, par exemple, ne peut pas
  être négative.

  Exemple :
     matlibre_options_modele(fittype('gauss1')).Lower

  Voir aussi FITOPTIONS, FIT, FITTYPE.
```

## `matlibre_poids_robustes`

```
MATLIBRE_POIDS_ROBUSTES Poids déduits des résidus.
  P = MATLIBRE_POIDS_ROBUSTES(RESIDUS,NOMBREPARAMETRES,REGLAGE) rend le
  poids de chaque observation. L'échelle est estimée par l'écart absolu
  médian, divisé par 0,6745 pour qu'il coïncide avec l'écart type sur
  des données gaussiennes — une estimation que quelques valeurs
  aberrantes ne déplacent pas.

  Exemple :
     matlibre_poids_robustes([0.1; 0.1; 10], 1, matlibre_reglage_robuste('bisquare'))

  Voir aussi MATLIBRE_AJUSTER_LINEAIRE, ROBUSTFIT.
```

## `matlibre_pp_depuis_valeurs`

```
MATLIBRE_PP_DEPUIS_VALEURS Spline par morceaux, depuis valeurs et courbures.
  PP = MATLIBRE_PP_DEPUIS_VALEURS(X,A,M) construit la forme par morceaux
  d'une spline cubique dont on connaît les valeurs A et les dérivées
  secondes M aux nœuds. Les coefficients de chaque morceau s'en
  déduisent sans résoudre quoi que ce soit.

  Exemple :
     pp = matlibre_pp_depuis_valeurs([0;1;2], [0;1;0], [0;-2;0]);
     ppval(pp, 1)      % 1

  Voir aussi CSAPS, SPLINE, PPVAL.
```

## `matlibre_pp_forme`

```
MATLIBRE_PP_FORME Spline ramenée à la forme par morceaux.
  PP = MATLIBRE_PP_FORME(F) rend F telle quelle si elle est déjà en
  morceaux polynomiaux, et la convertit si elle est en B-splines.

  Exemple :
     pp = matlibre_pp_forme(spline(1:4, [1 2 3 4]));

  Voir aussi FNDER, FNINT, SPAP2.
```

## `matlibre_pulsations_dominantes`

```
MATLIBRE_PULSATIONS_DOMINANTES Pulsations les plus fortes du signal.
  P = MATLIBRE_PULSATIONS_DOMINANTES(X,Y,NOMBRE) rend les NOMBRE
  pulsations dont l'amplitude spectrale est la plus grande, l'ordonnée
  étant d'abord rééchantillonnée sur une grille régulière — la
  transformée de Fourier n'a de sens que là.

  Exemple :
     t = (0:0.01:1)';
     matlibre_pulsations_dominantes(t, sin(2*pi*3*t), 1) / (2*pi)   % 3

  Voir aussi MATLIBRE_DEPART_SINUS, MATLIBRE_DEPART_FOURIER.
```

## `matlibre_qualite_ajustement`

```
MATLIBRE_QUALITE_AJUSTEMENT Mesures de la qualité d'un ajustement.
  Q = MATLIBRE_QUALITE_AJUSTEMENT(Y,RESIDUS,POIDS,NOMBREPARAMETRES) rend
  la somme des carrés des écarts, le R carré, le R carré ajusté, l'écart
  quadratique moyen et les degrés de liberté.

  Le R carré ajusté pénalise le nombre de paramètres : sans lui, ajouter
  un terme améliore toujours l'ajustement, et l'on choisirait toujours le
  modèle le plus riche.

  Exemple :
     matlibre_qualite_ajustement([1;2;3], [0;0;0], [1;1;1], 2).rsquare   % 1

  Voir aussi FIT, GOODNESSOFFIT.
```

## `matlibre_reglage_robuste`

```
MATLIBRE_REGLAGE_ROBUSTE Fonction de poids d'un ajustement robuste.
  R = MATLIBRE_REGLAGE_ROBUSTE(NOM) rend le genre et la constante de
  réglage. 'Bisquare' annule le poids des résidus au-delà de quatre
  écarts robustes ; 'LAR' minimise la somme des écarts absolus, ce qui
  revient à pondérer par l'inverse de l'écart.

  Exemple :
     matlibre_reglage_robuste('bisquare')

  Voir aussi MATLIBRE_POIDS_ROBUSTES, FITOPTIONS.
```

## `matlibre_regression_locale`

```
MATLIBRE_REGRESSION_LOCALE Lissage par régression locale pondérée.
  Y = MATLIBRE_REGRESSION_LOCALE(XD,YD,X,PORTEE,DEGRE) ajuste, autour de
  chaque point où l'on veut la courbe, un polynôme de degré DEGRE aux
  points voisins, pondérés par la fonction tricube de leur distance.

  PORTEE est la part des points que voit chaque ajustement local : plus
  elle est grande, plus la courbe est lisse. La pondération tricube
  s'annule au bord du voisinage, ce qui évite les sauts quand un point
  entre ou sort.

  Exemple :
     x = (1:20)';
     matlibre_regression_locale(x, x.^2, [5; 10], 0.5, 1);

  Voir aussi SMOOTH, FIT.
```

## `matlibre_regression_locale_ponderee`

```
MATLIBRE_REGRESSION_LOCALE_PONDEREE Régression locale à poids imposés.
  Y = MATLIBRE_REGRESSION_LOCALE_PONDEREE(XD,YD,X,PORTEE,DEGRE,POIDS)
  fait comme MATLIBRE_REGRESSION_LOCALE, mais multiplie la pondération
  de distance par un poids propre à chaque point : c'est ainsi qu'un
  lissage robuste écarte les valeurs aberrantes.

  Exemple :
     x = (1:10)';
     matlibre_regression_locale_ponderee(x, x, x, 0.5, 1, ones(10, 1));

  Voir aussi MATLIBRE_LISSAGE_LOCAL, SMOOTH.
```

## `matlibre_regression_locale_surface`

```
MATLIBRE_REGRESSION_LOCALE_SURFACE Lissage local d'une surface.
  Z = MATLIBRE_REGRESSION_LOCALE_SURFACE(XYD,ZD,XY,PORTEE,DEGRE) ajuste,
  autour de chaque point demandé, un plan ou une quadrique aux voisins
  les plus proches, pondérés par la tricube de leur distance.

  Exemple :
     [x, y] = meshgrid(0:0.25:1, 0:0.25:1);
     matlibre_regression_locale_surface([x(:) y(:)], x(:), [0.5 0.5], 0.5, 1);

  Voir aussi MATLIBRE_EVALUER_SURFACE, FIT.
```

## `matlibre_savitzky_golay`

```
MATLIBRE_SAVITZKY_GOLAY Lissage par polynôme local de degré donné.
  L = MATLIBRE_SAVITZKY_GOLAY(Y,PORTEE,DEGRE) ajuste un polynôme aux
  points de chaque fenêtre et en garde la valeur au centre. Contrairement
  à la moyenne mobile, il conserve les extremums et la largeur des pics :
  un polynôme de degré deux suit une courbure, là où une moyenne
  l'aplatit.

  Aux extrémités, c'est le polynôme ajusté à la première — ou dernière —
  fenêtre complète qui est évalué, ce qui évite de rétrécir la fenêtre
  et de perdre le degré.

  Exemple :
     y = (1:9)'.^2;
     max(abs(matlibre_savitzky_golay(y, 5, 2) - y)) < 1e-10      % vrai

  Voir aussi SMOOTH.
```

## `matlibre_simpson`

```
MATLIBRE_SIMPSON Intégrale par la méthode de Simpson composée.
  V = MATLIBRE_SIMPSON(FONCTION,A,B,MORCEAUX) approche l'intégrale par
  des paraboles sur un nombre pair de morceaux. La formule est exacte
  pour tout polynôme de degré trois, ce qui la rend bien plus précise
  que les trapèzes à coût égal.

  Exemple :
     matlibre_simpson(@(t) t.^2, 0, 3, 100)      % 9

  Voir aussi INTEGRATE, QUAD, TRAPZ.
```

## `matlibre_smooth_arguments`

```
MATLIBRE_SMOOTH_ARGUMENTS Démêle les arguments de SMOOTH.
  [X,Y,PORTEE,METHODE,DEGRE] = MATLIBRE_SMOOTH_ARGUMENTS(ARGUMENTS) lit
  les formes acceptées : avec ou sans abscisses, avec ou sans portée,
  avec ou sans nom de méthode.

  Exemple :
     [x, y, p, m] = matlibre_smooth_arguments({[1 2 3], 'lowess'});

  Voir aussi SMOOTH.
```

## `matlibre_termes_surface`

```
MATLIBRE_TERMES_SURFACE Termes d'un polynôme à deux variables.
  [P,N] = MATLIBRE_TERMES_SURFACE(DEGREX,DEGREY) rend les couples
  d'exposants et les noms des coefficients, dans l'ordre de MATLAB :
  par degré total croissant, et à degré total égal, par puissance de x
  décroissante.

  Exemple :
     [p, n] = matlibre_termes_surface(2, 2);
     n      % p00 p10 p01 p20 p11 p02

  Voir aussi MATLIBRE_MODELE_SURFACE.
```

## `matlibre_tracer_ajustement`

```
MATLIBRE_TRACER_AJUSTEMENT Trace une courbe ajustée et ses données.
  H = MATLIBRE_TRACER_AJUSTEMENT(FO,ARGUMENTS) trace la courbe sur
  l'intervalle des données quand celles-ci sont fournies, sinon sur
  l'intervalle unité, et superpose les points.

  Exemple :
     fo = fit((1:10)', (1:10)'.^2, 'poly2');
     plot(fo, (1:10)', (1:10)'.^2);

  Voir aussi FIT, CFIT.
```

## `matlibre_tracer_surface`

```
MATLIBRE_TRACER_SURFACE Trace une surface ajustée et ses données.
  H = MATLIBRE_TRACER_SURFACE(SO,ARGUMENTS) trace la surface sur
  l'étendue des points quand ils sont donnés, et les superpose.

  Exemple :
     plot(so, [x y], z);

  Voir aussi SFIT, FIT.
```

## `prepareCurveData`

```
PREPARECURVEDATA Met des données en état d'être ajustées.
  [X,Y] = PREPARECURVEDATA(X,Y) rend deux vecteurs colonnes de nombres
  en double précision, débarrassés des points non finis. Les données
  arrivent souvent en lignes, en matrices ou avec des trous ; FIT les
  veut en colonnes et sans trou.

  [X,Y] = PREPARECURVEDATA([],Y) numérote les abscisses de un à N.
  [X,Y,W] = PREPARECURVEDATA(X,Y,W) prépare aussi les poids.

  Exemple :
     [x, y] = prepareCurveData([], [1 NaN 3]);
     x'      % 1 3

  Voir aussi PREPARESURFACEDATA, FIT, EXCLUDEDATA.
```

## `prepareSurfaceData`

```
PREPARESURFACEDATA Met des données de surface en état d'être ajustées.
  [X,Y,Z] = PREPARESURFACEDATA(X,Y,Z) rend trois vecteurs colonnes.
  Quand Z est une matrice et que X et Y sont les vecteurs des colonnes
  et des lignes, la grille est dépliée : à chaque valeur de Z
  correspondent son abscisse et son ordonnée.

  Les points non finis sont écartés.

  Exemple :
     [x, y, z] = prepareSurfaceData(1:3, 1:2, magic(3)(1:2, :));
     numel(z)      % 6

  Voir aussi PREPARECURVEDATA, FIT, SFIT.
```

## `sfit`

```
SFIT Surface ajustée, qu'on évalue comme une fonction de deux variables.
  SO = FIT([X Y],Z,MODELE) rend un objet SFIT. On l'évalue en
  l'appelant : SO(XNOUVEAU,YNOUVEAU).

  Les modèles sont les polynômes à deux variables — 'poly11', 'poly22',
  jusqu'à 'poly55' — et les interpolants 'linearinterp',
  'nearestinterp', 'cubicinterp', 'lowess' et 'loess'.

  Ce qu'on lui demande : COEFFVALUES, CONFINT, FORMULA, COEFFNAMES,
  TYPE, ISLINEAR, NUMCOEFFS, PLOT.

  Exemple :
     [x, y] = meshgrid(0:0.25:1, 0:0.25:1);
     z = 1 + 2*x - 3*y;
     so = fit([x(:) y(:)], z(:), 'poly11');
     so(0.5, 0.5)      % 0.5

  Voir aussi FIT, CFIT, FITTYPE, PREPARESURFACEDATA.
```

## `smooth`

```
SMOOTH Lissage d'une suite de données.
  YY = SMOOTH(Y) lisse par moyenne mobile sur cinq points.
  YY = SMOOTH(Y,PORTEE) impose la largeur de la fenêtre.
  YY = SMOOTH(Y,METHODE) ou SMOOTH(Y,PORTEE,METHODE) choisit la
  méthode : 'moving' (moyenne mobile), 'lowess' (régression locale
  linéaire), 'loess' (quadratique), 'rlowess' et 'rloess' (les mêmes,
  rendues robustes aux valeurs aberrantes), 'sgolay' (filtre de
  Savitzky et Golay).
  YY = SMOOTH(X,Y,...) tient compte d'abscisses non régulières.
  YY = SMOOTH(X,Y,PORTEE,'sgolay',DEGRE) impose le degré.

  Pour les méthodes locales, une portée inférieure à un se lit comme
  une fraction du nombre de points.

  Aux extrémités, la moyenne mobile rétrécit sa fenêtre de façon
  symétrique plutôt que de déborder : le premier point est rendu tel
  quel, le deuxième est la moyenne de trois, et ainsi de suite. C'est ce
  qui évite le biais qu'un remplissage introduirait.

  Exemple :
     y = [1 2 3 4 5];
     smooth(y)'      % 1  2  3  4  5, une droite reste une droite

  Voir aussi CSAPS, SPAPS, FIT, MEDFILT1.
```

## `smoothSpline`

```
SMOOTHSPLINE Lissage par pénalisation de la dérivée seconde.
  YLISSE = SMOOTHSPLINE(X,Y,LAMBDA) minimise
     sum (y - f)^2 + lambda * sum (f'')^2
```

## `spap2`

```
SPAP2 Spline des moindres carrés, à nœuds donnés.
  SP = SPAP2(NOEUDS,ORDRE,X,Y) ajuste, au sens des moindres carrés, la
  spline d'ordre ORDRE dont les nœuds sont donnés. À la différence d'une
  spline d'interpolation, elle ne passe pas par les points : elle a
  moins de coefficients qu'il n'y a de données, et lisse donc le bruit.

  SP = SPAP2(N,ORDRE,X,Y) où N est un entier place N morceaux de
  longueur égale sur l'intervalle des données.

  SPAP2(...,W) pondère les points.

  La spline rendue est en B-forme, comme dans MATLAB : elle s'évalue par
  FNVAL, se dérive par FNDER et se trace par FNPLT.

  Exemple :
     x = (0:0.05:1)';
     sp = spap2(4, 4, x, x .^ 3);
     max(abs(fnval(sp, x) - x .^ 3)) < 1e-10      % un cubique est exact

  Voir aussi CSAPS, SPAPS, FNVAL, FNBRK.
```

## `spaps`

```
SPAPS Spline la plus lisse qui reste dans une tolérance.
  PP = SPAPS(X,Y,TOL) rend la spline dont l'intégrale du carré de la
  dérivée seconde est la plus petite parmi celles dont la somme
  pondérée des carrés des écarts ne dépasse pas TOL.

  C'est le problème inverse de CSAPS : au lieu de fixer le compromis
  entre fidélité et douceur, on fixe la fidélité qu'on exige et l'on
  prend la courbe la plus lisse qui la respecte. TOL se lit donc dans
  l'unité des données au carré — c'est le bruit qu'on accepte de ne pas
  suivre.

  PP = SPAPS(X,Y,TOL,W) pondère les points.
  [PP,VALEURS,RHO] = SPAPS(...) rend aussi les valeurs lissées aux
  points et le paramètre de lissage employé.

  MatLibre rend la spline sous forme de morceaux polynomiaux, forme que
  FNVAL, FNDER et PPVAL acceptent ; MATLAB la rend en B-forme.

  Exemple :
     rng(1);
     x = linspace(0, 2*pi, 60)';
     y = sin(x) + 0.05 * randn(size(x));
     pp = spaps(x, y, 60 * 0.05^2);
     max(abs(ppval(pp, x) - sin(x))) < 0.1

  Voir aussi CSAPS, SPAP2, SPLINE, FNVAL.
```

