# Toolbox `econometrie`

```
% Econometrics Toolbox — séries temporelles et économétrie.
%
% Les tests de racine unitaire vont par paires opposées : ADFTEST et
% PPTEST prennent la racine unitaire pour hypothèse nulle, KPSSTEST et
% LMCTEST prennent la stationnarité. Conclure demande souvent les deux.
%
% Description d'une série
%   autocorr, parcorr - Autocorrélations simple et partielle
%   crosscorr         - Corrélation croisée de deux séries
%   lagmatrix         - Matrice des versions retardées
%   hurst             - Exposant de Hurst par l'analyse R/S
%
% Racine unitaire et stationnarité
%   adftest           - Dickey-Fuller augmenté
%   pptest            - Phillips et Perron, correction non paramétrique
%   kpsstest          - Kwiatkowski, Phillips, Schmidt et Shin
%   lmctest           - Leybourne et McCabe, correction paramétrique
%   vratiotest        - Rapport des variances de Lo et MacKinlay
%
% Autocorrélation et hétéroscédasticité des résidus
%   lbqtest           - Ljung et Box, autocorrélation d'ensemble
%   archtest          - Engle, variance conditionnelle
%
% Cointégration
%   egcitest          - Engle et Granger, par les résidus d'une régression
%   jcitest           - Johansen, par une régression de rang réduit
%
% Hypothèses emboîtées
%   lratiotest        - Rapport de vraisemblance
%   waldtest          - Test de Wald sur des restrictions
%   gctest            - Causalité au sens de Granger
%
% Régression et diagnostics
%   ols               - Moindres carrés ordinaires avec diagnostics
%   collintest        - Diagnostics de colinéarité de Belsley
%   aicbic            - Critères d'information d'Akaike et de Schwarz
%
% Modèles
%   arima             - Modèle autorégressif intégré à moyenne mobile
%   garch             - Variance conditionnelle hétéroscédastique
%   arfit             - Estimation d'un AR(p) par Yule-Walker
%   arsim             - Simulation d'un AR(p)
%
% Ce qu'on fait d'un modèle
%   estimate          - Ajuste les paramètres laissés à NaN
%   simulate          - Tire des trajectoires
%   forecast          - Prolonge une série observée
%   infer             - Retrouve les innovations et la vraisemblance
%   summarize         - Résume l'ajustement
%   filter            - Passe des innovations données dans le modèle
%
% Prix et rendements
%   price2ret, ret2price - Passage entre niveaux et rendements
%   tick2ret, ret2tick   - Les mêmes, sous leur autre nom
```

## `adftest`

```
ADFTEST Test de racine unitaire de Dickey-Fuller augmenté.
  H = ADFTEST(Y) teste si Y a une racine unitaire. H vaut un quand
  l'hypothèse est rejetée : la série est stationnaire.

  ADFTEST(...,'Model',M) choisit le modèle — 'AR' sans terme
  déterministe, 'ARD' avec une constante (défaut), 'TS' avec constante
  et tendance —, 'Lags',L le nombre de différences retardées ajoutées à
  la régression (zéro par défaut), 'Test',T la forme de la statistique
  — 't1', le rapport de Student (défaut), ou 't2', le coefficient
  normalisé —, 'Alpha',A le seuil (0,05).
  [H,P,STAT,CRIT] = ADFTEST(...) rend la valeur p, la statistique et la
  valeur critique.

  ADFTEST(Y,L), avec L numérique, garde la forme abrégée : L retards.

  Le test régresse la différence de la série sur son niveau retardé.
  Si ce niveau n'apporte rien, la série ne revient vers rien : elle a
  une racine unitaire. Les différences retardées servent à blanchir les
  résidus, faute de quoi la statistique n'a pas la loi annoncée.

  Sous l'hypothèse nulle, la statistique ne suit pas une loi de
  Student : sa loi limite est celle d'une fonctionnelle du mouvement
  brownien, décalée vers la gauche. C'est pourquoi les valeurs
  critiques sont si négatives.

  Exemple :
     adftest(randn(1, 200))          % 1 : pas de racine unitaire
     adftest(cumsum(randn(1, 200)))  % 0 : il y en a une

  Voir aussi PPTEST, KPSSTEST, LMCTEST, VRATIOTEST, EGCITEST.
```

## `aicbic`

```
AICBIC Critères d'information d'Akaike et de Schwarz.
  [AIC,BIC] = AICBIC(LOGL,NUMPARAM,NUMOBS) rend

     AIC = -2 LOGL + 2 NUMPARAM,
     BIC = -2 LOGL + NUMPARAM log(NUMOBS).

  Les deux pèsent l'ajustement contre le nombre de paramètres : entre
  deux modèles, on garde celui dont le critère est le plus petit. Le
  critère de Schwarz punit plus durement, et choisit donc des modèles
  plus simples dès que les observations se comptent par centaines.

  LOGL et NUMPARAM peuvent être des vecteurs : on compare alors
  plusieurs modèles d'un coup.

  Exemple :
     [aic, bic] = aicbic([-100 -95], [2 5], 100);
     % le second ajuste mieux, mais coûte trois paramètres

  Voir aussi ARFIT, OLS, LRATIOTEST, FITLM.
```

## `archtest`

```
ARCHTEST Test d'hétéroscédasticité conditionnelle.
  H = ARCHTEST(R) teste si la variance de R dépend du passé. H vaut un
  quand l'hypothèse d'homoscédasticité est rejetée : la série connaît
  des périodes calmes et des périodes agitées, ce qu'un modèle GARCH
  sait décrire.

  ARCHTEST(...,'Lags',L) choisit le nombre de retards (un par défaut),
  'Alpha',A le seuil (0,05).
  [H,P,STAT,CRIT] = ARCHTEST(...) rend la valeur p, la statistique et
  la valeur critique.

  Le test est celui d'Engle : on régresse le carré des résidus sur ses
  propres retards, et la statistique vaut N fois le coefficient de
  détermination. Elle suit un khi-deux à L degrés de liberté sous
  l'hypothèse nulle.

  Exemple :
     archtest(randn(1, 300))        % 0 : variance constante
     bruit = randn(1, 300) .* [ones(1, 150), 5 * ones(1, 150)];
     archtest(bruit, 'Lags', 2)     % souvent 1 : la variance change

  Voir aussi LBQTEST, GARCH, AUTOCORR, OLS.
```

## `arfit`

```
ARFIT Estimation d'un modèle autorégressif par Yule-Walker.
  [PHI,SIGMA2,C] = ARFIT(Y,P) rend les coefficients, la variance du
  bruit et la constante.
```

## `arima`

```
ARIMA Modèle autorégressif intégré à moyenne mobile.
  MDL = ARIMA(P,D,Q) décrit un modèle dont la partie autorégressive a
  P retards, la partie moyenne mobile Q retards, et dont la série est
  différenciée D fois. Les coefficients valent NaN : ils restent à
  estimer.

  MDL = ARIMA('ARLags',L1,'MALags',L2,...) choisit les retards un à un,
  ce qui permet un modèle creux — un retard 1 et un retard 12 sans les
  dix intermédiaires. Les autres propriétés se donnent de même :
  'Constant', 'AR', 'MA', 'D', 'Variance', 'Seasonality', 'SARLags',
  'SAR', 'SMALags', 'SMA', 'Distribution', 'Description'.

  Le modèle s'écrit, sur la série différenciée,
     y(t) = c + phi(1) y(t-1) + ... + e(t) + theta(1) e(t-1) + ...
  où e est un bruit blanc de variance Variance.

  Un coefficient laissé à NaN est estimé ; un coefficient donné est
  tenu pour connu et n'est pas touché. C'est ainsi qu'on impose une
  contrainte : 'Constant',0 estime le reste sans constante.

  ESTIMATE ajuste le modèle à des données, SIMULATE en tire des
  trajectoires, FORECAST prolonge une série observée, INFER retrouve
  les innovations et SUMMARIZE résume l'ajustement.

  Exemple :
     modele = arima(1, 0, 1);
     vrai = arima('Constant', 0.5, 'AR', {0.7}, 'MA', {0.3}, 'Variance', 1);
     y = simulate(vrai, 500);
     ajuste = estimate(modele, y);

  Voir aussi GARCH, ESTIMATE, SIMULATE, FORECAST, INFER, SUMMARIZE,
  AICBIC, LBQTEST.
```

## `arsim`

```
ARSIM Simulation d'un processus autorégressif.
```

## `autocorr`

```
AUTOCORR Fonction d'autocorrélation empirique.
```

## `collintest`

```
COLLINTEST Diagnostics de colinéarité de Belsley.
  S = COLLINTEST(X) rend les valeurs singulières des colonnes de X
  ramenées à la norme un. [S,IDX,PROP] = COLLINTEST(X) rend en plus les
  indices de conditionnement et les proportions de variance.

  Deux colonnes presque proportionnelles rendent les coefficients d'une
  régression instables sans que rien, dans les résidus, ne le signale.
  Belsley propose de regarder les valeurs singulières : un indice de
  conditionnement élevé annonce une dépendance quasi linéaire, et la
  ligne correspondante des proportions de variance dit lesquelles des
  colonnes y participent.

  Les colonnes sont ramenées à la norme un mais ne sont pas centrées :
  centrer effacerait la colinéarité de la constante avec le reste, qui
  est justement ce qu'on veut voir.

  COLLINTEST(...,'tolIdx',T) règle le seuil d'alerte sur l'indice de
  conditionnement (30), 'tolProp',P celui sur les proportions (0,5),
  'varNames',N nomme les colonnes, 'display','off' se tait.

  Une dépendance est signalée quand un indice dépasse tolIdx et qu'au
  moins deux colonnes y contribuent pour plus de tolProp.

  Exemple :
     x1 = randn(100, 1);
     X = [ones(100, 1), x1, x1 + 0.001 * randn(100, 1)];
     collintest(X)

  Voir aussi OLS, REGRESS, SVD, COND.
```

## `crosscorr`

```
CROSSCORR Corrélation croisée de deux séries.
  [XCF,LAGS] = CROSSCORR(X,Y) rend la corrélation croisée pour des
  retards allant de -20 à 20, ou de -(N-1) à N-1 si la série est plus
  courte. XCF(k) mesure la liaison entre X(t) et Y(t+LAGS(k)) : un pic
  à un retard positif dit que X précède Y.

  CROSSCORR(X,Y,NUMLAGS) borne le retard, CROSSCORR(X,Y,NUMLAGS,NUMSTD)
  règle les bornes de confiance, rendues en troisième sortie et
  valant NUMSTD sur racine de N (deux par défaut).

  Sans sortie demandée, la corrélation est tracée avec ses bornes.

  Exemple :
     x = randn(1, 200);
     y = [0 0 0 x(1:end-3)];        % y suit x de trois pas
     [xcf, lags] = crosscorr(x, y);
     [~, k] = max(xcf);
     lags(k)                        % 3

  Voir aussi AUTOCORR, PARCORR, XCORR, LAGMATRIX.
```

## `egcitest`

```
EGCITEST Test de cointégration d'Engle et Granger.
  H = EGCITEST(Y) teste si les colonnes de Y sont cointégrées. H vaut
  un quand l'absence de cointégration est rejetée : une combinaison
  linéaire des séries est stationnaire, alors que chacune prise seule
  ne l'est pas.

  La méthode tient en deux temps. On régresse d'abord la première
  colonne sur les autres : si les séries sont cointégrées, les résidus
  de cette régression sont stationnaires. On leur applique ensuite un
  test de racine unitaire. Comme la relation a été estimée et non
  donnée, les valeurs critiques sont plus sévères que celles du test de
  racine unitaire ordinaire, et d'autant plus que les régresseurs sont
  nombreux.

  EGCITEST(...,'creg',C) choisit les termes déterministes de la
  régression de cointégration — 'nc' aucun, 'c' une constante
  (défaut), 'ct' constante et tendance. 'rreg',R choisit le test des
  résidus — 'adf' (défaut) ou 'pp'. 'lags',L le nombre de retards,
  'test',T la forme — 't1', le rapport de Student (défaut), ou 't2',
  le coefficient normalisé —, 'alpha',A le seuil (0,05).
  'cvec',B impose le vecteur de cointégration au lieu de l'estimer :
  les valeurs critiques deviennent alors celles d'un simple test de
  racine unitaire.

  [H,P,STAT,CRIT,REG1,REG2] = EGCITEST(...) rend en plus la régression
  de cointégration et la régression sur les résidus.

  Exemple :
     x = cumsum(randn(300, 1));
     y = 2 * x + randn(300, 1);      % cointegrees
     egcitest([y, x])                % 1
     egcitest([cumsum(randn(300, 1)), cumsum(randn(300, 1))])  % 0

  Voir aussi JCITEST, ADFTEST, PPTEST, LMCTEST.
```

## `estimate`

```
ESTIMATE Ajuste un modèle de série temporelle à des données.
  ESTMDL = ESTIMATE(MDL,Y) remplace par leurs estimations les
  paramètres laissés à NaN dans MDL, et rend le modèle complété. Les
  paramètres déjà fixés le restent : c'est ainsi qu'on impose une
  contrainte.

  [ESTMDL,COV,LOGL,INFO] = ESTIMATE(...) rend la covariance des
  estimations, la log-vraisemblance atteinte et une structure décrivant
  l'ajustement.

  ESTIMATE(...,'Display','off') n'écrit rien.

  L'ajustement maximise la vraisemblance conditionnelle : les valeurs
  antérieures au début de l'échantillon sont prises à la moyenne du
  modèle, et les innovations correspondantes à zéro. La variance du
  bruit est concentrée hors du critère.

  Exemple :
     vrai = arima('Constant', 0.5, 'AR', {0.7}, 'Variance', 1);
     y = simulate(vrai, 800);
     ajuste = estimate(arima(1, 0, 0), y);

  Voir aussi ARIMA, GARCH, SIMULATE, FORECAST, INFER, SUMMARIZE.
```

## `forecast`

```
FORECAST Prolonge une série observée par le modèle.
  [Y,YMSE] = FORECAST(MDL,H,'Y0',DONNEES) rend la prévision à H pas et
  la variance de l'erreur de prévision, pas par pas.

  La prévision optimale au sens de l'erreur quadratique est
  l'espérance conditionnelle : on prolonge la récurrence du modèle en
  posant les innovations à venir à zéro. La variance de l'erreur se lit
  sur les poids de la représentation en moyenne mobile infinie ; elle
  croît avec l'horizon et tend, pour un modèle stationnaire, vers la
  variance de la série.

  Exemple :
     m = arima('Constant', 0, 'AR', {0.8}, 'Variance', 1);
     y = simulate(m, 200);
     [p, e] = forecast(m, 10, 'Y0', y);

  Voir aussi ARIMA, GARCH, ESTIMATE, SIMULATE, INFER.
```

## `garch`

```
GARCH Modèle de variance conditionnelle hétéroscédastique.
  MDL = GARCH(P,Q) décrit une variance qui dépend de ses P valeurs
  passées et des Q derniers carrés d'innovation :
     e(t) = sigma(t) z(t),  z blanc réduit
     sigma(t)^2 = k + g(1) sigma(t-1)^2 + ... + a(1) e(t-1)^2 + ...
  Les coefficients valent NaN : ils restent à estimer.

  Les cours de bourse ne bougent pas au hasard de façon uniforme : les
  fortes variations se suivent, les périodes calmes aussi. Un GARCH
  décrit cela sans supposer que la variance soit prévisible en signe,
  seulement en amplitude.

  MDL = GARCH('GARCHLags',L1,'ARCHLags',L2,...) choisit les retards un à
  un. Les autres propriétés se donnent de même : 'Constant', 'GARCH',
  'ARCH', 'Offset', 'Distribution', 'Description'.

  La variance est stationnaire quand la somme des coefficients GARCH et
  ARCH reste inférieure à un ; la variance de long terme vaut alors
  k / (1 - cette somme).

  Exemple :
     vrai = garch('Constant', 0.1, 'GARCH', {0.8}, 'ARCH', {0.1});
     [y, e, v] = simulate(vrai, 2000);
     ajuste = estimate(garch(1, 1), y);

  Voir aussi ARIMA, ESTIMATE, SIMULATE, FORECAST, INFER, ARCHTEST.
```

## `gctest`

```
GCTEST Test de causalité au sens de Granger.
  H = GCTEST(Y1,Y2) teste si le passé de Y1 aide à prévoir Y2 une fois
  connu le passé de Y2. H vaut un quand l'hypothèse de non-causalité
  est rejetée : Y1 apporte quelque chose.

  Il ne s'agit pas de causalité au sens usuel. Granger ne dit rien du
  mécanisme : il constate seulement qu'une série contient de
  l'information sur l'avenir d'une autre. Deux séries mues par une
  troisième, non observée, se « causent » ainsi l'une l'autre.

  GCTEST(...,'NumLags',P) choisit le nombre de retards (un par défaut),
  'Constant',false enlève la constante, 'Trend',true ajoute une
  tendance, 'Test','f' emploie la loi de Fisher au lieu du khi-deux,
  'Alpha',A règle le seuil (0,05).
  [H,P,STAT,CRIT] = GCTEST(...) rend la valeur p, la statistique et la
  valeur critique.

  Le test compare deux régressions de Y2 : l'une sur son seul passé,
  l'autre sur le passé des deux séries. Si la seconde ne réduit pas
  sensiblement la somme des carrés des résidus, Y1 n'apprend rien.

  Exemple :
     x = randn(1, 500);
     y = [0; 0.8 * x(1:end-1)'] + 0.3 * randn(500, 1);
     gctest(x, y)      % 1 : x precede y
     gctest(y, x)      % 0 : y ne precede pas x

  Voir aussi WALDTEST, LRATIOTEST, OLS, CROSSCORR.
```

## `hurst`

```
HURST Exposant de Hurst estimé par l'analyse R/S.
```

## `infer`

```
INFER Retrouve les innovations d'une série sous un modèle donné.
  E = INFER(MDL,Y) rend les innovations, [E,V,LOGL] rend en plus les
  variances conditionnelles et la log-vraisemblance.

  C'est l'opération inverse de SIMULATE : là où celui-ci part d'un
  bruit et construit une série, celui-ci part d'une série et retrouve
  le bruit qui l'aurait produite. Les résidus obtenus servent aux
  diagnostics — LBQTEST sur les innovations, ARCHTEST sur leurs carrés.

  Exemple :
     m = arima('Constant', 0, 'AR', {0.8}, 'Variance', 1);
     y = simulate(m, 500);
     e = infer(m, y);
     lbqtest(e)                     % 0 : les innovations sont blanches

  Voir aussi ARIMA, GARCH, ESTIMATE, SIMULATE, FORECAST, LBQTEST.
```

## `jcitest`

```
JCITEST Test de cointégration de Johansen.
  H = JCITEST(Y) teste le rang de cointégration des colonnes de Y. Le
  test est mené pour chaque rang possible : H(1) correspond à
  l'hypothèse « aucune relation », H(2) à « au plus une », et ainsi de
  suite. H(k) vaut un quand l'hypothèse est rejetée.

  On lit le résultat de gauche à droite et l'on s'arrête au premier
  rang non rejeté : c'est le nombre de relations de cointégration
  retenu. Rejeter « aucune relation » sans rejeter « au plus une »
  conclut à une relation.

  Là où le test d'Engle et Granger passe par une régression et n'en
  trouve qu'une, celui de Johansen les cherche toutes à la fois, par
  une régression de rang réduit du modèle à correction d'erreur. Les
  valeurs propres de la corrélation canonique entre les différences et
  les niveaux retardés portent l'information : autant de valeurs
  propres non nulles, autant de relations.

  JCITEST(...,'model',M) choisit la place des termes déterministes :
     'H2'   ni constante ni tendance
     'H1*'  constante dans la relation de cointégration
     'H1'   constante libre (défaut)
     'H*'   tendance dans la relation de cointégration
     'H'    tendance libre
  'lags',L donne le nombre de différences retardées (zéro par défaut),
  'test',T la statistique — 'trace' (défaut) ou 'maxeig' —,
  'alpha',A le seuil (0,05), 'display','off' se tait.

  [H,P,STAT,CRIT,MLES] = JCITEST(...) rend les valeurs p, les
  statistiques, les valeurs critiques et, pour chaque rang, une
  structure portant les valeurs propres, la matrice B des relations de
  cointégration, la matrice A des vitesses d'ajustement et la
  log-vraisemblance.

  Exemple :
     x = cumsum(randn(300, 1));
     Y = [x + randn(300, 1), x, cumsum(randn(300, 1))];
     jcitest(Y)        % [1 0 0] : une relation

  Voir aussi EGCITEST, ADFTEST, LMCTEST.
```

## `kpsstest`

```
KPSSTEST Test de stationnarité de Kwiatkowski, Phillips, Schmidt et Shin.
  H = KPSSTEST(Y) teste si Y est stationnaire. H vaut un quand
  l'hypothèse de stationnarité est rejetée : la série a une racine
  unitaire.

  L'hypothèse nulle est ici la stationnarité, à l'inverse d'ADFTEST où
  c'est la racine unitaire. Les deux se complètent : conclure demande
  souvent de les faire tous les deux.

  KPSSTEST(...,'Lags',L) choisit la fenêtre de la variance de long
  terme, 'Trend',false enlève la tendance du modèle, 'Alpha',A règle le
  seuil (0,05).
  [H,P,STAT,CRIT] = KPSSTEST(...) rend la valeur p, la statistique et
  la valeur critique.

  La statistique est la somme des carrés des résidus cumulés, divisée
  par le carré du nombre d'observations et par la variance de long
  terme estimée à la Newey-West.

  Exemple :
     kpsstest(randn(1, 200))        % 0 : stationnaire
     kpsstest(cumsum(randn(1, 200)))  % 1 : ne l'est pas

  Voir aussi ADFTEST, PPTEST, LMCTEST, VRATIOTEST.
```

## `lagmatrix`

```
LAGMATRIX Matrice des versions retardées d'une série.
```

## `lbqtest`

```
LBQTEST Test de Ljung et Box sur l'autocorrélation.
  H = LBQTEST(R) teste si la série R est du bruit blanc. H vaut un
  quand l'hypothèse est rejetée : il reste de l'autocorrélation.

  LBQTEST(...,'Lags',L) choisit le nombre de retards examinés (le
  minimum de vingt et de N-1 par défaut), 'Alpha',A le seuil (0,05),
  'DOF',D les degrés de liberté — à réduire du nombre de paramètres
  qu'un ajustement a déjà consommés.

  [H,P,STAT,CRIT] = LBQTEST(...) rend la valeur p, la statistique et la
  valeur critique.

  La statistique est

     Q = N (N+2) somme_{k=1..L} rho(k)^2 / (N-k),

  qui suit une loi du khi-deux à DOF degrés de liberté sous
  l'hypothèse de bruit blanc. Le facteur (N+2)/(N-k) corrige le biais
  de l'autocorrélation empirique aux grands retards, ce que le test de
  Box et Pierce ne fait pas.

  Exemple :
     lbqtest(randn(1, 200))         % 0 : du bruit reste du bruit
     lbqtest(cumsum(randn(1, 200))) % 1 : une marche ne l'est pas

  Voir aussi ARCHTEST, AUTOCORR, ADFTEST, KPSSTEST.
```

## `lmctest`

```
LMCTEST Test de stationnarité de Leybourne et McCabe.
  H = LMCTEST(Y) teste si Y est stationnaire autour d'une tendance. H
  vaut un quand cette hypothèse est rejetée : la série a une racine
  unitaire.

  L'hypothèse nulle est la même que celle de KPSSTEST, et la
  statistique a la même loi limite ; ce qui change est la manière de
  corriger l'autocorrélation. KPSS l'estime sans modèle, par une
  moyenne pondérée des covariances ; Leybourne et McCabe ajustent un
  ARIMA(p,1,1) et lisent la variance de long terme dans les paramètres
  estimés. Quand le modèle est juste, la correction paramétrique est
  plus fine et le test plus puissant.

  LMCTEST(...,'Lags',P) donne l'ordre autorégressif du modèle ajusté
  (zéro par défaut), 'Trend',false enlève la tendance, 'Alpha',A règle
  le seuil (0,05).
  [H,P,STAT,CRIT] = LMCTEST(...) rend la valeur p, la statistique et la
  valeur critique.

  Exemple :
     lmctest(randn(1, 200))           % 0 : stationnaire
     lmctest(cumsum(randn(1, 200)))   % 1 : ne l'est pas

  Voir aussi KPSSTEST, ADFTEST, PPTEST, VRATIOTEST.
```

## `lratiotest`

```
LRATIOTEST Test du rapport de vraisemblance.
  H = LRATIOTEST(ULLF,RLLF,DOF) compare deux modèles emboîtés : le
  libre, dont la log-vraisemblance vaut ULLF, et le contraint, dont
  elle vaut RLLF. DOF est le nombre de contraintes, c'est-à-dire la
  différence des nombres de paramètres. H vaut un quand les contraintes
  sont rejetées : le modèle libre explique significativement mieux.

  Ajouter des paramètres ne peut qu'augmenter la vraisemblance ; la
  question est de savoir si elle augmente plus que le hasard ne le
  ferait. Sous l'hypothèse nulle, deux fois l'écart des
  log-vraisemblances suit un khi-deux à DOF degrés de liberté.

  H = LRATIOTEST(...,ALPHA) règle le seuil (0,05 par défaut).
  [H,P,STAT,CRIT] = LRATIOTEST(...) rend la valeur p, la statistique et
  la valeur critique.

  ULLF peut être un vecteur : le test est alors mené pour chacune de
  ses valeurs, RLLF et DOF étant diffusés.

  Exemple :
     % Un AR(2) contre un AR(1), une contrainte.
     lratiotest(-140.2, -145.7, 1)      % 1 : le retard supplémentaire compte

  Voir aussi WALDTEST, AICBIC, ARIMA, ESTIMATE.
```

## `matlibre_arima_afficher`

```
MATLIBRE_ARIMA_AFFICHER Écrit le modèle sous une forme lisible.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_critere`

```
MATLIBRE_ARIMA_CRITERE Somme des carrés des innovations, avec pénalité.
  Un modèle non stationnaire ou non inversible est refusé par une
  valeur immense : l'optimiseur, qui ne connaît pas les contraintes,
  apprend ainsi à les respecter.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_cumuler`

```
MATLIBRE_ARIMA_CUMULER Intègre une série simulée, en partant de zéro.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_depart`

```
MATLIBRE_ARIMA_DEPART Point de départ de l'optimisation.
  La partie autorégressive part d'un ajustement de Yule-Walker, la
  partie moyenne mobile de zéro, et la constante de ce qui reproduit la
  moyenne observée. Un mauvais départ ne fausse pas le résultat mais
  coûte des itérations, et peut faire tomber dans un minimum local.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_differencier`

```
MATLIBRE_ARIMA_DIFFERENCIER Applique les différences ordinaire et saisonnière.
  MEMOIRE garde les valeurs qu'il faut pour revenir aux niveaux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_estimer`

```
MATLIBRE_ARIMA_ESTIMER Ajuste un ARIMA par vraisemblance conditionnelle.
  La variance du bruit est concentrée hors du critère : pour un jeu de
  coefficients donné, elle vaut la moyenne des carrés des innovations,
  et maximiser la vraisemblance revient à minimiser cette moyenne. Il
  ne reste donc à optimiser que les coefficients.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_filtrer`

```
MATLIBRE_ARIMA_FILTRER Passe des innovations réduites dans le modèle.
  Z porte des innovations d'écart type un : elles sont multipliées par
  la racine de la variance du modèle avant d'entrer dans la récurrence.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_inferer`

```
MATLIBRE_ARIMA_INFERER Innovations et vraisemblance d'une série observée.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_integrer`

```
MATLIBRE_ARIMA_INTEGRER Ramène des prévisions différenciées aux niveaux.
  HISTORIQUE est la série observée, dans ses unités d'origine ;
  PREVISIONS sont celles de la série différenciée D fois, et une fois
  de plus à la période SAISON quand celle-ci est non nulle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_logl`

```
MATLIBRE_ARIMA_LOGL Log-vraisemblance conditionnelle, variance comprise.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_normaliser`

```
MATLIBRE_ARIMA_NORMALISER Met les retards et les coefficients d'accord.
  Des coefficients donnés sans retards prennent les retards 1, 2, ... ;
  des retards donnés sans coefficients prennent NaN. Les degrés P et Q
  sont ensuite recalculés, différenciation et saisonnalité comprises.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_parametres`

```
MATLIBRE_ARIMA_PARAMETRES Liste les paramètres restés à estimer.
  Un paramètre vaut NaN tant qu'il n'est pas fixé : ce sont ceux-là qui
  entrent dans l'optimisation. Les autres sont tenus pour connus.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_polynomes`

```
MATLIBRE_ARIMA_POLYNOMES Développe les polynômes du modèle.
  PHI et THETA sont les coefficients, retard par retard, des parties
  autorégressive et moyenne mobile de la série différenciée : le
  produit des parties ordinaire et saisonnière est développé.
  PHINIVEAUX ajoute les facteurs de différenciation, ce qui donne le
  polynôme qui agit sur la série de niveau.

  La convention est celle de MATLAB : y(t) = ... + phi(i) y(t-i) + ...,
  les coefficients apparaissent donc avec le signe plus.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_poser`

```
MATLIBRE_ARIMA_POSER Place un jeu de valeurs dans les paramètres libres.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_prevoir`

```
MATLIBRE_ARIMA_PREVOIR Prévision et variance de l'erreur de prévision.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_psi`

```
MATLIBRE_ARIMA_PSI Poids de la représentation en moyenne mobile infinie.
  PSI(k+1) est le poids de l'innovation de rang t-k dans y(t). Ils
  donnent d'un coup la variance des erreurs de prévision : celle de la
  prévision à H pas vaut sigma carré fois la somme des H premiers
  carrés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_residus`

```
MATLIBRE_ARIMA_RESIDUS Innovations d'un ARMA, par récurrence conditionnelle.
  Les valeurs antérieures au début de l'échantillon sont prises nulles,
  en écart à la moyenne du modèle. C'est la vraisemblance dite
  conditionnelle : elle ne demande ni lissage ni rétroprévision, et
  l'écart avec la vraisemblance exacte s'efface quand l'échantillon
  grandit.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_resumer`

```
MATLIBRE_ARIMA_RESUMER Tableau des estimations et de leur précision.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_simuler`

```
MATLIBRE_ARIMA_SIMULER Trajectoires tirées du modèle.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_titre`

```
MATLIBRE_ARIMA_TITRE Une ligne qui nomme le modèle ajusté.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_arima_verifier`

```
MATLIBRE_ARIMA_VERIFIER Refuse un modèle dont un coefficient manque.
  Simuler ou prévoir demande un modèle complet ; seul ESTIMATE accepte
  des NaN, puisque c'est son travail de les remplacer.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_carres_residuels`

```
MATLIBRE_CARRES_RESIDUELS Somme des carrés des résidus d'une régression.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_cellule`

```
MATLIBRE_CELLULE Range une liste de coefficients en tableau de cellules.
  Un vecteur numérique devient une cellule par élément ; un tableau de
  cellules passe tel quel.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_dickey_fuller`

```
MATLIBRE_DICKEY_FULLER Régression de Dickey-Fuller augmentée.
  Régresse la différence de SERIE sur son niveau retardé, sur RETARDS
  différences retardées et sur les termes déterministes du MODELE.
  FORME vaut 't1' pour le rapport de Student du coefficient du niveau,
  't2' pour le coefficient normalisé T*a/(1-somme des gamma).

  DETERMINISTE, facultatif, remplace les termes du modèle par des
  colonnes données : c'est ce dont EGCITEST a besoin, les résidus d'une
  régression de cointégration n'ayant plus de constante à estimer.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_dickey_table`

```
MATLIBRE_DICKEY_TABLE Quantiles de la loi de Dickey-Fuller.
  La statistique ne suit pas une loi de Student : sous racine
  unitaire, sa loi limite est celle d'une fonctionnelle du mouvement
  brownien, décalée vers la gauche. Les quantiles rangés ici ont été
  obtenus en simulant huit mille marches aléatoires de quatre cents
  pas et en passant chacune par la même régression que le test ; ils
  s'accordent aux quantiles publiés par Dickey et Fuller à quelques
  centièmes près.

  FORME vaut 't1', le rapport de Student, ou 't2', le coefficient
  normalisé. Le test est unilatéral à gauche.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_diffuser_paire`

```
MATLIBRE_DIFFUSER_PAIRE Met deux tableaux à la même taille par diffusion.
  Un scalaire prend la taille de l'autre ; deux tableaux de même taille
  sont rendus tels quels ; toute autre combinaison est une erreur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_egci_table`

```
MATLIBRE_EGCI_TABLE Quantiles du test de cointégration d'Engle-Granger.
  Les résidus testés viennent d'une régression estimée : les moindres
  carrés ayant déjà cherché la combinaison la plus stationnaire, la
  statistique est plus négative que celle d'un test de racine unitaire
  ordinaire, et d'autant plus que les régresseurs sont nombreux. Les
  quantiles rangés ici ont été obtenus en simulant huit mille jeux de
  marches aléatoires indépendantes de quatre cents pas et en leur
  appliquant la procédure complète ; ils s'accordent aux quantiles
  publiés par MacKinnon à quelques centièmes près.

  REGRESSEURS vaut zéro quand le vecteur de cointégration est donné :
  le test redevient alors celui d'une racine unitaire ordinaire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_etendre_cellules`

```
MATLIBRE_ETENDRE_CELLULES Répète une cellule unique jusqu'à NOMBRE.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_afficher`

```
MATLIBRE_GARCH_AFFICHER Écrit le modèle sous une forme lisible.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_estimer`

```
MATLIBRE_GARCH_ESTIMER Ajuste un GARCH par maximum de vraisemblance.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_inferer`

```
MATLIBRE_GARCH_INFERER Innovations et variances d'une série observée.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_logl`

```
MATLIBRE_GARCH_LOGL Log-vraisemblance gaussienne d'un GARCH.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_normaliser`

```
MATLIBRE_GARCH_NORMALISER Met les retards et les coefficients d'accord.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_parametres`

```
MATLIBRE_GARCH_PARAMETRES Liste les paramètres restés à estimer.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_poser`

```
MATLIBRE_GARCH_POSER Place un jeu de valeurs dans les paramètres libres.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_prevoir`

```
MATLIBRE_GARCH_PREVOIR Prévision de la variance conditionnelle.
  Le niveau d'un GARCH n'est pas prévisible — la prévision de la série
  est l'écart moyen, rien de plus. Ce qui se prévoit, c'est la
  variance : FORECAST rend donc les variances attendues, qui convergent
  vers la variance de long terme.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_simuler`

```
MATLIBRE_GARCH_SIMULER Trajectoires d'un processus à variance changeante.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_transformer`

```
MATLIBRE_GARCH_TRANSFORMER Envoie R^n dans le domaine admissible.
  Une variance conditionnelle n'a de sens que si la constante est
  positive, les coefficients aussi, et leur somme inférieure à un ;
  sinon la variance devient négative ou explose. Plutôt que d'imposer
  ces bornes à l'optimiseur, qui ne les connaît pas, on optimise sans
  contrainte et l'on transforme : l'exponentielle rend la constante
  positive, et une normalisation répartit le budget de persistance
  entre les coefficients sans jamais l'épuiser.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_variances`

```
MATLIBRE_GARCH_VARIANCES Récurrence de la variance conditionnelle.
  GARCHS et ARCHS sont les coefficients rangés retard par retard. Les
  valeurs antérieures au début de l'échantillon prennent DEPART, en
  général la variance empirique de la série.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_garch_verifier`

```
MATLIBRE_GARCH_VERIFIER Refuse un modèle dont un coefficient manque.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_hessienne`

```
MATLIBRE_HESSIENNE Hessienne par différences finies centrées.
  Le pas suit l'échelle de chaque coordonnée : la racine cubique de
  l'epsilon machine équilibre l'erreur de troncature et l'erreur
  d'arrondi.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_inverser_hessienne`

```
MATLIBRE_INVERSER_HESSIENNE Covariance tirée d'une hessienne numérique.
  Une hessienne calculée par différences finies peut n'être ni définie
  ni même inversible ; on rend alors une matrice de NaN plutôt qu'un
  résultat faux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_johansen`

```
MATLIBRE_JOHANSEN Régression de rang réduit du modèle à correction d'erreur.
  Rend les valeurs propres de la corrélation canonique entre les
  différences et les niveaux retardés, une fois retirées de l'un et de
  l'autre les différences retardées et les termes déterministes. Ce
  sont ces valeurs propres qui portent toute l'information sur le rang
  de cointégration.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_johansen_table`

```
MATLIBRE_JOHANSEN_TABLE Quantiles des statistiques de cointégration.
  La loi limite des statistiques de trace et de valeur propre
  maximale est une fonctionnelle du mouvement brownien : elle n'a pas
  de forme fermée. Les quantiles rangés ici ont été obtenus en
  simulant, pour chaque modèle, six mille réalisations du processus
  sous l'hypothèse nulle — des marches aléatoires indépendantes, avec
  la partie déterministe que le modèle suppose présente dans les
  données — sur quatre cents observations. Ils s'accordent aux
  quantiles publiés à quelques centièmes près.

  DIMENSION est n moins le rang testé ; FORME vaut 'trace' ou
  'maxeig'. La statistique est unilatérale à droite.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_kpss_table`

```
MATLIBRE_KPSS_TABLE Valeur critique et valeur p du test KPSS.
  La loi limite de la statistique est celle de l'intégrale du carré
  d'un pont brownien — d'un pont de second niveau avec tendance. Elle
  n'a pas de forme fermée commode ; les quantiles publiés par
  Kwiatkowski et ses coauteurs sont interpolés, et la valeur p lue de
  même.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_modele_parametres`

```
MATLIBRE_MODELE_PARAMETRES Noms et valeurs des paramètres estimés.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_newey_west`

```
MATLIBRE_NEWEY_WEST Variance de long terme, fenêtre de Bartlett.
  La variance d'une somme de termes corrélés n'est pas la somme de
  leurs variances : il faut y ajouter les covariances, pondérées par
  une fenêtre qui décroît avec le retard. C'est ce que fait Newey-West,
  et c'est ce qui rend l'estimation positive.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_phillips_perron`

```
MATLIBRE_PHILLIPS_PERRON Régression de racine unitaire, corrigée.
  Même régression que Dickey-Fuller mais sans différences retardées :
  l'autocorrélation des résidus est traitée après coup, en remplaçant
  la variance instantanée par une variance de long terme.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_quantiles_gauche`

```
MATLIBRE_QUANTILES_GAUCHE Valeur p et valeur critique d'un test à gauche.
  NIVEAUX et QUANTILES décrivent la loi tabulée ; la valeur critique est
  le quantile d'ordre ALPHA, et la valeur p la proportion de la loi
  située sous la statistique. En dehors de la table, la valeur p est
  ramenée au niveau extrême le plus proche : la table ne sait rien
  au-delà.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_racines_admissibles`

```
MATLIBRE_RACINES_ADMISSIBLES Stationnarité et inversibilité.
  Les racines du polynôme autorégressif écrites en z doivent rester
  dans le disque unité : sinon la série n'a pas de variance finie. De
  même pour la partie moyenne mobile, sans quoi les innovations ne se
  retrouvent pas à partir des observations.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_retards`

```
MATLIBRE_RETARDS Matrice des valeurs retardées d'une série.
  Colonne j : la série décalée de j pas, prise aux indices LIGNES.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_texte_loi`

```
MATLIBRE_TEXTE_LOI Nom de la loi des innovations.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_texte_nombre`

```
MATLIBRE_TEXTE_NOMBRE Écrit un nombre, « NaN » compris.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `ols`

```
OLS Moindres carrés ordinaires, avec diagnostics.
```

## `parcorr`

```
PARCORR Autocorrélation partielle, par les équations de Yule-Walker.
```

## `pptest`

```
PPTEST Test de racine unitaire de Phillips et Perron.
  H = PPTEST(Y) teste si Y a une racine unitaire. H vaut un quand
  l'hypothèse est rejetée : la série est stationnaire.

  PPTEST(...,'Lags',L) choisit la fenêtre de la correction,
  'Model',M le modèle — 'AR' sans constante, 'ARD' avec constante
  (défaut), 'TS' avec constante et tendance —, 'Alpha',A le seuil.
  [H,P,STAT,CRIT] = PPTEST(...) rend la valeur p, la statistique et la
  valeur critique.

  La différence avec ADFTEST tient à la façon de traiter
  l'autocorrélation des résidus : au lieu d'ajouter des retards à la
  régression, on corrige la statistique par une variance de long
  terme. Le modèle reste donc à un seul retard, ce qui économise des
  degrés de liberté.

  Exemple :
     pptest(randn(1, 200))          % 1 : pas de racine unitaire
     pptest(cumsum(randn(1, 200)))  % 0 : il y en a une

  Voir aussi ADFTEST, KPSSTEST, VRATIOTEST, LMCTEST.
```

## `price2ret`

```
PRICE2RET Rendements tirés d'une série de prix.
  R = PRICE2RET(P) rend les rendements continus, c'est-à-dire les
  différences des logarithmes : R(t) = log(P(t+1)) - log(P(t)). Il y a
  un rendement de moins que de prix.

  R = PRICE2RET(P,DATES) rend aussi les instants correspondants.
  R = PRICE2RET(P,DATES,'Periodic') calcule les rendements simples,
  P(t+1)/P(t) - 1, au lieu des rendements continus.

  Le rendement continu s'ajoute d'une période à l'autre, ce que le
  rendement simple ne fait pas : c'est ce qui le rend commode pour
  cumuler, et c'est pourquoi les modèles le préfèrent.

  Une matrice est traitée colonne par colonne.

  Exemple :
     p = [100; 110; 99];
     price2ret(p)                   % [0.0953; -0.1054]
     price2ret(p, [], 'Periodic')   % [0.1; -0.1]

  Voir aussi RET2PRICE, TICK2RET, RET2TICK.
```

## `ret2price`

```
RET2PRICE Prix reconstruits à partir de rendements.
  P = RET2PRICE(R) recompose la série de prix, en partant de un.
  P = RET2PRICE(R,P0) part du prix donné.
  P = RET2PRICE(R,P0,'Periodic') traite R comme des rendements simples
  au lieu de rendements continus.

  C'est l'inverse de PRICE2RET : les deux se défont exactement.

  Exemple :
     p = [100; 110; 99];
     max(abs(ret2price(price2ret(p), 100) - p))   % nul

  Voir aussi PRICE2RET, RET2TICK, TICK2RET.
```

## `simulate`

```
SIMULATE Tire des trajectoires d'un modèle de série temporelle.
  Y = SIMULATE(MDL,N) rend une trajectoire de N observations.
  SIMULATE(...,'NumPaths',K) en rend K, une par colonne.
  [Y,E,V] = SIMULATE(...) rend aussi les innovations et, pour un modèle
  GARCH, les variances conditionnelles.

  La trajectoire commence après une période de rodage, assez longue
  pour que l'effet du départ ait disparu : la série rendue suit la loi
  stationnaire du modèle.

  Exemple :
     m = arima('Constant', 0, 'AR', {0.8}, 'Variance', 1);
     y = simulate(m, 1000);
     abs(var(y) - 1 / (1 - 0.64)) < 0.5      % variance theorique

  Voir aussi ARIMA, GARCH, ESTIMATE, FORECAST, INFER.
```

## `summarize`

```
SUMMARIZE Résumé d'un modèle, ajusté ou non.
  SUMMARIZE(MDL) écrit le modèle. Si MDL vient d'ESTIMATE, le résumé
  donne les estimations, leurs écarts types, les rapports de Student,
  les valeurs p, la log-vraisemblance et les critères d'information.

  S = SUMMARIZE(MDL) rend la structure au lieu de l'écrire.

  Exemple :
     ajuste = estimate(arima(1, 0, 0), y, 'Display', 'off');
     summarize(ajuste)

  Voir aussi ARIMA, GARCH, ESTIMATE, AICBIC.
```

## `vratiotest`

```
VRATIOTEST Test du rapport des variances de Lo et MacKinlay.
  H = VRATIOTEST(Y) teste si Y est une marche aléatoire. Y est une
  série de niveaux — des logarithmes de prix, typiquement. H vaut un
  quand l'hypothèse de marche aléatoire est rejetée.

  Sous une marche aléatoire, la variance croît proportionnellement à
  l'horizon : celle des accroissements sur Q périodes vaut Q fois celle
  des accroissements d'une période. Le rapport des deux doit donc valoir
  un. S'il dépasse un, les mouvements se prolongent ; s'il reste en
  dessous, ils se corrigent.

  VRATIOTEST(...,'Period',Q) choisit l'horizon (deux par défaut),
  'IID',true suppose les accroissements de même loi — la statistique
  est alors plus puissante mais suppose la variance constante ; le
  défaut, false, corrige l'hétéroscédasticité. 'Alpha',A règle le seuil
  (0,05).
  [H,P,STAT,CRIT,RATIO] = VRATIOTEST(...) rend la valeur p, la
  statistique centrée réduite, la valeur critique et le rapport
  lui-même.

  Q peut être un vecteur : le test est mené pour chaque horizon.

  Exemple :
     vratiotest(cumsum(randn(1, 500)))          % 0 : marche aléatoire
     x = filter(1, [1 -0.6], randn(1, 500));
     vratiotest(cumsum(x))                      % 1 : mouvements liés

  Voir aussi ADFTEST, KPSSTEST, LBQTEST, AUTOCORR.
```

## `waldtest`

```
WALDTEST Test de Wald sur des restrictions paramétriques.
  H = WALDTEST(R,JAC,COV) teste les restrictions r(theta) = 0. R est le
  vecteur des restrictions évaluées à l'estimation libre, JAC leur
  jacobienne par rapport aux paramètres, COV la matrice de covariance
  des paramètres estimés. H vaut un quand les restrictions sont
  rejetées.

  Le test ne demande que le modèle libre : il mesure de combien
  d'écarts-types les restrictions sont violées. La forme quadratique
  R'*inv(JAC*COV*JAC')*R suit un khi-deux à autant de degrés de liberté
  qu'il y a de restrictions.

  Pour des restrictions linéaires A*theta = c, prendre
  R = A*theta - c et JAC = A.

  H = WALDTEST(...,ALPHA) règle le seuil (0,05 par défaut).
  [H,P,STAT,CRIT] = WALDTEST(...) rend la valeur p, la statistique et
  la valeur critique.

  R, JAC et COV peuvent être des tableaux de cellules : le test est
  alors mené pour chaque triplet.

  Exemple :
     % Le second coefficient d'une régression est-il nul ?
     m = ols(y, X);
     A = [0 1 0];
     waldtest(A * m.beta, A, m.sigma2 * inv(X' * X))

  Voir aussi LRATIOTEST, OLS, GCTEST.
```

