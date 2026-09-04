# Toolbox `gestion-risques`

```
% Risk Management Toolbox — mesures de risque de marché et de crédit.
%
% Mesures de marché
%   valueAtRisk       - Valeur en risque, historique ou paramétrique
%   expectedShortfall - Perte moyenne au-delà de la valeur en risque
%   drawdownSeries    - Série des pertes depuis le dernier sommet
%   riskContribution  - Décomposition du risque, par actif ou contrepartie
%
% Contrôle a posteriori
%   varbacktest       - Huit tests sur un modèle de valeur en risque
%   esbacktest        - Tests d'Acerbi et Székely sur la perte moyenne
%   runtests, summary - Passer tous les tests, compter les dépassements
%
% Capital et concentration
%   asrf                 - Capital du modèle à facteur unique de Bâle
%   concentrationIndices - Herfindahl, Gini, Hall-Tideman, Theil
%
% Notations et transitions
%   transprob             - Matrice de transition, par cohorte ou par durée
%   transprobbytotals     - La même, depuis des comptages agrégés
%   transprobtothresholds - Seuils de qualité de crédit
%   transprobfromthresholds - Le chemin inverse
%   creditTransition      - Estimation sur des trajectoires complètes
%
% Modèle structurel
%   mertonmodel        - Probabilité de défaut par l'option sur l'actif
%   mertonByTimeSeries - La même, estimée sur une série de capitalisations
%
% Portefeuilles de crédit
%   creditDefaultCopula   - Défauts corrélés par variables latentes
%   creditMigrationCopula - Migrations de notation corrélées
%   simulate, getScenarios - Scénarios de pertes
%   portfolioRisk         - Perte attendue, écart type, VaR, perte au-delà
%   confidenceBands       - Convergence de l'estimation
%
% Grilles de score
%   creditscorecard - Construction d'une grille
%   autobinning     - Découpage des caractéristiques en tranches
%   bininfo         - Poids de la preuve et valeur d'information
%   bindata         - Données transformées en tranches ou en poids
%   fitmodel        - Régression logistique sur les poids de la preuve
%   formatpoints    - Échelle des points
%   displaypoints   - Barème
%   score           - Note d'un dossier
%   probdefault     - Probabilité de défaut
%   validatemodel   - Aire sous la courbe, Gini, Kolmogorov-Smirnov
```

## `asrf`

```
ASRF Capital réglementaire du modèle à facteur unique asymptotique.
  C = ASRF(PD,LGD,R) rend le capital à immobiliser par unité
  d'exposition, selon le modèle qui fonde les accords de Bâle : un seul
  facteur commun explique la corrélation des défauts, et le
  portefeuille est supposé assez fin pour que le risque propre à chaque
  contrepartie ait disparu.

  Le capital couvre la perte inattendue, non la perte totale : la perte
  attendue est censée être déjà provisionnée, et se retranche donc.

  ASRF(...,'VaRLevel',A) règle le quantile (0,999), 'EAD',E l'exposition
  — le résultat est alors un montant —, 'CorrelationType','basel'
  remplace R par la formule de Bâle, qui décroît quand la probabilité de
  défaut monte.

  Exemple :
     asrf(0.01, 0.45, 0.2)                       % capital par euro prete
     asrf(0.01, 0.45, [], 'CorrelationType', 'basel')

  Voir aussi CONCENTRATIONINDICES, CREDITDEFAULTCOPULA, MERTONMODEL.
```

## `autobinning`

```
AUTOBINNING Découpe automatique des caractéristiques d'une grille de score.
  SC = AUTOBINNING(SC) découpe chaque caractéristique en tranches : les
  variables numériques par quantiles, les variables de texte par
  catégorie.

  Découper n'est pas une commodité : c'est ce qui laisse une
  caractéristique agir de façon non monotone. Un revenu très faible et
  un revenu très élevé peuvent tous deux annoncer un risque, ce qu'un
  coefficient unique ne saurait dire.

  AUTOBINNING(SC,VARIABLES) ne traite que les variables nommées.
  AUTOBINNING(...,'NumBins',N) fixe le nombre de tranches (cinq),
  'MinCount',M le nombre minimal d'observations par tranche.

  Exemple :
     sc = autobinning(sc, 'revenu', 'NumBins', 4);

  Voir aussi BININFO, BINDATA, FITMODEL, CREDITSCORECARD.
```

## `bindata`

```
BINDATA Remplace les caractéristiques par leur tranche ou son poids.
  D = BINDATA(SC) rend les données d'origine, chaque caractéristique
  étant remplacée par le numéro de sa tranche. BINDATA(SC,DONNEES)
  traite d'autres données que celles de la grille.

  BINDATA(...,'OutputType','WOEModelInput') remplace plutôt par le
  poids de la preuve : c'est ce que FITMODEL donne à la régression.

  Exemple :
     d = bindata(sc, [], 'OutputType', 'WOEModelInput');

  Voir aussi BININFO, AUTOBINNING, FITMODEL.
```

## `bininfo`

```
BININFO Contenu des tranches d'une caractéristique.
  [T,IV] = BININFO(SC,VARIABLE) rend, tranche par tranche, le nombre de
  bons et de mauvais dossiers, leur rapport, le poids de la preuve, et
  la valeur d'information de la caractéristique entière.

  Le poids de la preuve d'une tranche est le logarithme du rapport
  entre la part des bons qu'elle contient et la part des mauvais : il
  est positif là où les bons dossiers se concentrent. La valeur
  d'information somme ces écarts, pondérés : elle dit à quel point la
  caractéristique sépare.

  Exemple :
     [t, iv] = bininfo(sc, 'revenu')

  Voir aussi AUTOBINNING, BINDATA, FITMODEL, DISPLAYPOINTS.
```

## `concentrationIndices`

```
CONCENTRATIONINDICES Mesures de concentration d'un portefeuille.
  I = CONCENTRATIONINDICES(EXPOSITIONS) rend une structure portant
  plusieurs indices, tous calculés sur les parts relatives des
  expositions :
     CR   part des plus grosses expositions (une par défaut)
     Gini inégalité de la répartition, de zéro à presque un
     HH   indice de Herfindahl-Hirschman, somme des carrés des parts
     HK   indice de Hannah et Kay, d'ordre réglable
     HT   indice de Hall et Tideman
     TE   indice d'entropie de Theil, normalisé

  [I,D] = CONCENTRATIONINDICES(...) rend aussi la part cumulée détenue
  par chaque décile, du plus gros au plus petit.

  Tous valent leur minimum quand les expositions sont égales, et leur
  maximum quand une seule contrepartie porte tout le portefeuille :
  c'est ce qui permet de les comparer entre portefeuilles de tailles
  différentes.

  CONCENTRATIONINDICES(...,'CRIndex',K) compte les K plus grosses,
  'HKIndex',A règle l'ordre de l'indice de Hannah et Kay (2 par défaut),
  'ScaleIndices',false rend les indices bruts, non normalisés.

  Exemple :
     concentrationIndices([100 100 100 100])     % reparti egalement
     concentrationIndices([400 0 0 0])           % tout sur un seul

  Voir aussi ASRF, RISKCONTRIBUTION, CREDITDEFAULTCOPULA.
```

## `confidenceBands`

```
CONFIDENCEBANDS Convergence d'une mesure de risque avec le nombre de scénarios.
  [B,N] = CONFIDENCEBANDS(C) rend, pour un nombre croissant de
  scénarios, l'estimation d'une mesure de risque et son intervalle de
  confiance. B a trois colonnes : borne basse, estimation, borne haute.

  C'est la façon de savoir combien de scénarios suffisent : quand les
  bandes se resserrent au-delà de la précision voulue, on peut
  s'arrêter.

  CONFIDENCEBANDS(...,'RiskMeasure',M) choisit la mesure — 'EL',
  'Std', 'VaR' ou 'CVaR' —, 'ConfidenceIntervalLevel',A le niveau de
  l'intervalle (0,95), 'NumPoints',P le nombre de points (100).

  Exemple :
     [b, n] = confidenceBands(c, 'RiskMeasure', 'VaR');
     plot(n, b);

  Voir aussi PORTFOLIORISK, RISKCONTRIBUTION, CREDITDEFAULTCOPULA.
```

## `creditDefaultCopula`

```
CREDITDEFAULTCOPULA Modèle de portefeuille de crédit à copule de défaut.
  C = CREDITDEFAULTCOPULA(PD,LGD,EAD,POIDS) décrit un portefeuille par
  la probabilité de défaut, la perte en cas de défaut et l'exposition de
  chaque contrepartie, ainsi que sa sensibilité à des facteurs communs.

  POIDS a une colonne par facteur, plus une dernière pour la part
  propre à la contrepartie ; la somme des carrés de chaque ligne doit
  valoir un, faute de quoi la variable latente n'est plus réduite.

  Le modèle est celui qui fonde toutes les mesures de risque de crédit
  modernes : une variable latente normale par contrepartie, corrélée
  aux autres par des facteurs communs, et un défaut lorsqu'elle passe
  sous le quantile correspondant à sa probabilité de défaut. La
  corrélation entre défauts ne vient donc pas d'une hypothèse
  supplémentaire : elle est celle des variables latentes.

  SIMULATE engendre des scénarios, PORTFOLIORISK résume les pertes,
  RISKCONTRIBUTION dit d'où elles viennent, CONFIDENCEBANDS montre à
  quelle vitesse l'estimation se stabilise et GETSCENARIOS rend les
  pertes simulées.

  CREDITDEFAULTCOPULA(...,'VaRLevel',A) règle le quantile (0,95),
  'FactorCorrelation',R la corrélation entre facteurs.

  Exemple :
     c = creditDefaultCopula([0.02; 0.05], [0.4; 0.6], [100; 200], ...
                             [0.5 sqrt(0.75); 0.5 sqrt(0.75)]);
     c = simulate(c, 20000);
     portfolioRisk(c)

  Voir aussi CREDITMIGRATIONCOPULA, ASRF, CONCENTRATIONINDICES.
```

## `creditMigrationCopula`

```
CREDITMIGRATIONCOPULA Modèle de portefeuille de crédit à migrations.
  C = CREDITMIGRATIONCOPULA(VALEURS,NOTATIONS,TRANSITION,LGD,POIDS)
  décrit un portefeuille dont chaque position vaut quelque chose de
  différent selon la notation de son émetteur. VALEURS a une colonne par
  notation, la dernière étant le défaut.

  Là où CREDITDEFAULTCOPULA ne connaît que deux états — vivant ou en
  défaut —, celui-ci suit toute l'échelle : une dégradation de notation
  fait déjà perdre de la valeur, bien avant le défaut. C'est la
  différence entre un modèle de perte et un modèle de valeur de marché.

  La corrélation vient des mêmes variables latentes ; ce sont les seuils
  tirés de la matrice de transition qui découpent leur domaine en
  notations d'arrivée.

  Exemple :
     valeurs = [100 98 95 60; 100 98 95 60];
     c = creditMigrationCopula(valeurs, [1; 2], transition, [0.4; 0.4], poids);
     c = simulate(c, 20000);
     portfolioRisk(c)

  Voir aussi CREDITDEFAULTCOPULA, TRANSPROBTOTHRESHOLDS, TRANSPROB.
```

## `creditTransition`

```
CREDITTRANSITION Matrice de transition estimée sur des trajectoires.
  P = CREDITTRANSITION(N) où N est une matrice dont chaque ligne est la
  trajectoire de notation d'un émetteur.
```

## `creditscorecard`

```
CREDITSCORECARD Grille de score de crédit.
  SC = CREDITSCORECARD(DONNEES,'IDVar',I,'ResponseVar',R) construit une
  grille à partir d'un tableau d'observations : une ligne par
  emprunteur, une colonne par caractéristique, et une colonne qui dit
  s'il a fait défaut.

  Une grille de score est une régression logistique déguisée en
  barème. Chaque caractéristique est découpée en tranches ; chaque
  tranche reçoit un poids tiré du rapport entre bons et mauvais
  dossiers qu'elle contient — le « poids de la preuve » —, puis une
  régression pèse les caractéristiques entre elles. Les coefficients
  sont enfin traduits en points, de sorte qu'un opérateur puisse
  additionner sans calculer d'exponentielle.

  Le chemin habituel : AUTOBINNING découpe, BININFO montre le
  découpage, FITMODEL ajuste, FORMATPOINTS choisit l'échelle,
  DISPLAYPOINTS écrit le barème, SCORE note un dossier, PROBDEFAULT en
  donne la probabilité de défaut et VALIDATEMODEL mesure le pouvoir
  discriminant.

  Les options : 'PredictorVars' limite les caractéristiques retenues,
  'GoodLabel' dit quelle valeur de la réponse désigne un bon dossier
  (la plus fréquente par défaut), 'WeightsVar' pondère les
  observations, 'BinMissingData' traite les valeurs manquantes comme
  une tranche.

  Exemple :
     sc = creditscorecard(donnees, 'IDVar', 'id', 'ResponseVar', 'defaut');
     sc = autobinning(sc);
     sc = fitmodel(sc);
     sc = formatpoints(sc, 'PointsOddsAndPDO', [500 2 50]);
     displaypoints(sc)

  Voir aussi BININFO, BINDATA, FITMODEL, DISPLAYPOINTS, FORMATPOINTS,
  SCORE, PROBDEFAULT, VALIDATEMODEL.
```

## `displaypoints`

```
DISPLAYPOINTS Barème d'une grille de score.
  [B,MIN,MAX] = DISPLAYPOINTS(SC) rend les points attribués à chaque
  tranche de chaque caractéristique, ainsi que les scores minimal et
  maximal atteignables. Sans sortie, le bareme est écrit.

  Les points d'une tranche sont son poids de la preuve multiplié par le
  coefficient de sa caractéristique, plus une part de la constante,
  le tout mis à l'échelle par FORMATPOINTS. Additionner les points d'un
  dossier revient exactement à évaluer la régression logistique.

  Exemple :
     [b, bas, haut] = displaypoints(sc);

  Voir aussi FORMATPOINTS, SCORE, PROBDEFAULT, FITMODEL.
```

## `drawdownSeries`

```
DRAWDOWNSERIES Perte relative depuis le dernier sommet, à chaque date.
```

## `esbacktest`

```
ESBACKTEST Contrôle a posteriori d'une perte moyenne au-delà de la VaR.
  E = ESBACKTEST(RENDEMENTS,VAR,ES) confronte les pertes subies aux
  valeurs en risque et aux pertes moyennes au-delà annoncées.

  La valeur en risque ne dit rien de l'ampleur des dépassements ; la
  perte moyenne au-delà, si. La contrôler demande un test différent :
  il ne suffit plus de compter les dépassements, il faut mesurer
  combien ils ont coûté.

  Le test est celui d'Acerbi et Székely : la somme des pertes
  dépassantes, rapportée à ce que le modèle annonçait, vaut zéro en
  moyenne quand le modèle dit vrai. Sa loi n'a pas de forme fermée ;
  elle est simulée sous l'hypothèse nulle, à graine fixée, de sorte que
  deux appels identiques rendent le même verdict.

  Les méthodes : UNCONDITIONALNORMAL suppose des rendements gaussiens,
  UNCONDITIONALT une loi de Student, RUNTESTS les passe tous deux,
  SUMMARY compte les dépassements.

  Exemple :
     e = esbacktest(rendements, valeursEnRisque, pertesMoyennes);
     runtests(e)

  Voir aussi VARBACKTEST, EXPECTEDSHORTFALL, VALUEATRISK.
```

## `expectedShortfall`

```
EXPECTEDSHORTFALL Perte moyenne conditionnelle au-delà de la VaR.
```

## `fitmodel`

```
FITMODEL Ajuste la régression logistique d'une grille de score.
  [SC,M] = FITMODEL(SC) régresse la réponse sur les poids de la preuve
  des caractéristiques découpées, et range les coefficients dans la
  grille.

  La régression porte sur les poids de la preuve, non sur les valeurs
  brutes : chaque caractéristique entre donc dans le modèle par un seul
  coefficient, quel que soit le nombre de ses tranches, et ce
  coefficient devrait valoir un si le découpage a bien fait son
  travail. S'en écarter beaucoup signale un découpage à revoir.

  FITMODEL(...,'PredictorVars',V) limite les caractéristiques,
  'VariableSelection','stepwise' les choisit une à une par leur apport.

  Exemple :
     [sc, m] = fitmodel(sc);
     m.Coefficients

  Voir aussi AUTOBINNING, BININFO, DISPLAYPOINTS, SCORE, PROBDEFAULT.
```

## `formatpoints`

```
FORMATPOINTS Choisit l'échelle des points d'une grille de score.
  SC = FORMATPOINTS(SC,'PointsOddsAndPDO',[P O D]) fixe l'échelle par
  trois nombres : au score P le rapport bons sur mauvais vaut O, et il
  double tous les D points.

  L'échelle n'a aucun effet sur le classement des dossiers ni sur les
  probabilités de défaut : elle ne fait que rendre les points lisibles.
  C'est une convention d'affichage, non un choix de modèle.

  FORMATPOINTS(...,'ShiftAndSlope',[S P]) donne directement le décalage
  et la pente, 'WorstAndBestScores',[W B] les fixe par les scores
  extrêmes atteignables.

  Exemple :
     sc = formatpoints(sc, 'PointsOddsAndPDO', [500 2 50]);

  Voir aussi DISPLAYPOINTS, SCORE, FITMODEL, PROBDEFAULT.
```

## `getScenarios`

```
GETSCENARIOS Pertes simulées d'un portefeuille de crédit.
  P = GETSCENARIOS(C) rend la perte de chaque contrepartie dans chaque
  scénario : une ligne par scénario, une colonne par contrepartie.
  GETSCENARIOS(C,I) ne rend que les scénarios demandés.

  Exemple :
     p = getScenarios(c);
     sum(p, 2)                      % pertes de portefeuille

  Voir aussi CREDITDEFAULTCOPULA, PORTFOLIORISK, RISKCONTRIBUTION.
```

## `matlibre_binomiale_cumulee`

```
MATLIBRE_BINOMIALE_CUMULEE Répartition binomiale, calculée en logarithmes.
  Les coefficients binomiaux dépassent vite les nombres représentables ;
  passer par les logarithmes de factorielles les garde finis.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_case_risque`

```
MATLIBRE_CASE_RISQUE Case K d'un vecteur, ou son unique valeur.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_contribution_credit`

```
MATLIBRE_CONTRIBUTION_CREDIT Décomposition des pertes par contrepartie.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_copule_latentes`

```
MATLIBRE_COPULE_LATENTES Variables latentes corrélées d'un modèle de crédit.
  Chaque contrepartie reçoit une combinaison des facteurs communs et
  d'un choc propre, dont la somme des carrés des poids vaut un : la
  variable obtenue est donc réduite, et sa corrélation avec celle d'une
  autre contrepartie est le produit scalaire de leurs poids de
  facteurs.

  La copule de Student remplace la normale par une normale divisée par
  la racine d'un khi-deux : les défauts groupés y sont plus fréquents,
  à corrélation égale.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_copule_simuler`

```
MATLIBRE_COPULE_SIMULER Scénarios de pertes d'un modèle de crédit.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_diffuser_risque`

```
MATLIBRE_DIFFUSER_RISQUE Met deux vecteurs à la même longueur par diffusion.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_es_critique`

```
MATLIBRE_ES_CRITIQUE Quantile de la statistique d'Acerbi et Székely.
  La loi de la statistique sous l'hypothèse nulle n'a pas de forme
  fermée ; elle dépend du nombre d'observations, du niveau et de la loi
  supposée des rendements. Elle est donc simulée — cinq mille tirages,
  graine fixée, résultat mis en cache pour que les appels suivants aux
  mêmes paramètres soient immédiats et identiques.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_es_student`

```
MATLIBRE_ES_STUDENT Perte moyenne au-delà du quantile d'une loi de Student.
  La forme fermée existe : elle fait intervenir la densité au quantile
  et un facteur qui tend vers un quand le nombre de degrés de liberté
  grandit, ramenant la formule au cas gaussien.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_es_test`

```
MATLIBRE_ES_TEST Test d'Acerbi et Székely sur la perte moyenne au-delà.
  La statistique compare la somme des pertes dépassantes à ce que le
  modèle annonçait ; elle vaut zéro en moyenne sous l'hypothèse nulle,
  et devient négative quand les dépassements coûtent plus cher que
  prévu.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_est_copule`

```
MATLIBRE_EST_COPULE Le modèle est-il un portefeuille de crédit simulé ?
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_generateur_vers_transition`

```
MATLIBRE_GENERATEUR_VERS_TRANSITION Matrice de transition par le générateur.
  L'intensité de passage de i vers j est le nombre de passages observés
  divisé par le temps passé en i ; la diagonale est l'opposé de la
  somme de la ligne, de sorte que les lignes du générateur somment à
  zéro. La matrice de transition sur un intervalle est l'exponentielle
  du générateur multiplié par cet intervalle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_khi_deux`

```
MATLIBRE_KHI_DEUX Tirages d'une loi du khi-deux.
  Pour un nombre entier de degrés de liberté, la somme des carrés
  d'autant de normales réduites est exactement un khi-deux, et coûte
  moins qu'un appel à la loi gamma.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_lancer_tests`

```
MATLIBRE_LANCER_TESTS Passe tous les tests d'un contrôle a posteriori.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_majoration_bale`

```
MATLIBRE_MAJORATION_BALE Facteur de majoration du capital, zone jaune.
  Le comité de Bâle majore le multiplicateur de capital par paliers,
  selon le nombre de dépassements observés sur deux cent cinquante
  jours. La règle est ici transposée au nombre d'observations réel, par
  la répartition binomiale.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_merton_resoudre`

```
MATLIBRE_MERTON_RESOUDRE Actif et volatilité implicites du modèle de Merton.
  Le point fixe alterne les deux équations : à volatilité d'actif
  donnée, la formule de Black et Scholes s'inverse pour donner l'actif ;
  l'actif connu, la relation entre les deux volatilités donne la
  nouvelle volatilité d'actif. La suite converge parce que chaque
  équation est monotone.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_migration_pertes`

```
MATLIBRE_MIGRATION_PERTES Pertes d'un portefeuille par migration de notation.
  La notation d'arrivée est la dernière dont le seuil est encore
  dépassé par la variable latente ; la perte est l'écart de valeur entre
  la notation de départ et celle d'arrivée. En défaut, seule la part
  recouvrée subsiste.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_normaliser_lignes`

```
MATLIBRE_NORMALISER_LIGNES Matrice stochastique tirée de comptages.
  Une ligne sans observation devient la ligne d'un état absorbant :
  faute de transition observée, on ne suppose rien de plus qu'un
  maintien sur place.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_notation_a`

```
MATLIBRE_NOTATION_A Notation en vigueur à des instants donnés.
  La notation est celle de la dernière observation antérieure ou égale ;
  NaN avant la première.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_part`

```
MATLIBRE_PART Rapport, nul quand le dénominateur l'est.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rapport_attente`

```
MATLIBRE_RAPPORT_ATTENTE Rapport de vraisemblance d'un temps d'attente.
  La loi géométrique de paramètre p donne au premier dépassement à la
  date n la vraisemblance p(1-p)^(n-1) ; la valeur libre est celle du
  paramètre 1/n, qui rend cette date la plus probable.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rapport_independance`

```
MATLIBRE_RAPPORT_INDEPENDANCE Test d'indépendance de Christoffersen.
  Compte les quatre transitions de la suite des dépassements, et compare
  une chaîne de Markov à deux paramètres à une suite indépendante.
  Grouper les dépassements est le défaut qu'aucun décompte global ne
  voit.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rapport_intervalles`

```
MATLIBRE_RAPPORT_INTERVALLES Test de Haas sur les temps entre dépassements.
  Chaque intervalle entre deux dépassements donne un rapport de
  vraisemblance de temps d'attente ; leur somme mesure si les
  dépassements se suivent de trop près ou de trop loin.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rapport_proportion`

```
MATLIBRE_RAPPORT_PROPORTION Rapport de vraisemblance de Kupiec.
  Compare la vraisemblance sous la proportion annoncée à celle sous la
  proportion observée. Elle est nulle quand les deux coïncident, et
  croît de part et d'autre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_colonnes`

```
MATLIBRE_SCORE_COLONNES Ramène un tableau de données à une structure.
  Accepte une table, une structure de colonnes ou un tableau de
  cellules dont la première ligne porte les noms.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_etiquette`

```
MATLIBRE_SCORE_ETIQUETTE Valeur de la réponse qui désigne un bon dossier.
  C'est la plus fréquente : les défauts sont, par construction, la
  minorité.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_extremes`

```
MATLIBRE_SCORE_EXTREMES Points non mis à l'échelle, et scores extrêmes.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_fusionner`

```
MATLIBRE_SCORE_FUSIONNER Supprime les bornes qui font des tranches trop rares.
  Une tranche de trois dossiers ne dit rien : son poids de la preuve
  serait déterminé par le hasard. On la fond dans sa voisine.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_indices`

```
MATLIBRE_SCORE_INDICES Numéro et nom de tranche de chaque observation.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_matrice`

```
MATLIBRE_SCORE_MATRICE Matrice des poids de la preuve.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_poids`

```
MATLIBRE_SCORE_POIDS Poids de la preuve de chaque observation.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_poser_tranche`

```
MATLIBRE_SCORE_POSER_TRANCHE Range ou remplace le découpage d'une variable.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_rang`

```
MATLIBRE_SCORE_RANG Numéro de tranche de chaque observation.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_reponse`

```
MATLIBRE_SCORE_REPONSE Indicatrices de bon et de mauvais dossier.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_selection`

```
MATLIBRE_SCORE_SELECTION Choix pas à pas des caractéristiques.
  À chaque tour, on ajoute celle qui abaisse le plus la déviance, et
  l'on s'arrête quand plus aucune ne l'abaisse assez pour justifier ce
  qu'elle coûte.

  Ce coût n'est pas d'un seul paramètre. Le poids de la preuve d'une
  caractéristique a été calculé sur la réponse : une variable à K
  tranches a déjà consommé K-1 degrés de liberté avant d'entrer dans la
  régression. Ne compter qu'un paramètre laisserait passer n'importe
  quel bruit découpé assez finement.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_score_tranche`

```
MATLIBRE_SCORE_TRANCHE Découpage rangé pour une variable.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_var_echecs`

```
MATLIBRE_VAR_ECHECS Dépassements d'un modèle de valeur en risque.
  Un dépassement est une perte plus grande que la valeur en risque
  annoncée : le rendement tombe sous l'opposé de celle-ci.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_var_test`

```
MATLIBRE_VAR_TEST Un test de contrôle a posteriori de la valeur en risque.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_verdict`

```
MATLIBRE_VERDICT Écrit « accept » ou « reject ».
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `mertonByTimeSeries`

```
MERTONBYTIMESERIES Modèle de Merton estimé sur une série de capitalisations.
  [PD,DD,A,SA] = MERTONBYTIMESERIES(E,L,R,T) estime la valeur et la
  volatilité des actifs à partir d'une série de capitalisations
  boursières, sans qu'on ait à donner la volatilité des capitaux
  propres.

  L'itération est celle de Vasicek et Kealhofer : à volatilité d'actif
  donnée, chaque capitalisation s'inverse en une valeur d'actif ; la
  série d'actifs ainsi obtenue donne une nouvelle volatilité ; on
  recommence. Le point fixe est atteint en quelques tours.

  Le résultat porte sur la dernière date de la série.

  Exemple :
     [pd, dd] = mertonByTimeSeries(capitalisations, dettes, 0.03, 1)

  Voir aussi MERTONMODEL, ASRF.
```

## `mertonmodel`

```
MERTONMODEL Probabilité de défaut par le modèle structurel de Merton.
  [PD,DD,A,SA] = MERTONMODEL(E,SE,L,R,T) rend la probabilité de défaut,
  la distance au défaut, la valeur des actifs et leur volatilité.

  L'idée de Merton est que détenir une action revient à détenir une
  option d'achat sur l'actif de l'entreprise, de prix d'exercice égal à
  sa dette : si l'actif vaut moins que la dette à l'échéance, les
  actionnaires abandonnent l'entreprise à ses créanciers. Le défaut est
  donc l'exercice manqué de cette option.

  L'actif et sa volatilité ne s'observent pas. Deux équations les
  déterminent : la formule de Black et Scholes qui donne les capitaux
  propres à partir de l'actif, et sa dérivée qui lie les deux
  volatilités. Le système se résout par itération.

  La distance au défaut est le nombre d'écarts types qui séparent
  l'actif du seuil ; la probabilité de défaut en est la queue normale.

  MERTONMODEL(...,'Drift',M) remplace le taux sans risque par une
  dérive attendue.

  Exemple :
     [pd, dd] = mertonmodel(50, 0.4, 40, 0.03, 1)

  Voir aussi MERTONBYTIMESERIES, ASRF, CREDITDEFAULTCOPULA.
```

## `portfolioRisk`

```
PORTFOLIORISK Résumé des pertes d'un portefeuille de crédit simulé.
  R = PORTFOLIORISK(C) rend la perte attendue, son écart type, la valeur
  en risque et la perte moyenne au-delà, aux quantiles demandés.

  [R,I] = PORTFOLIORISK(...) rend aussi les intervalles de confiance à
  quatre-vingt-quinze pour cent dus au nombre fini de scénarios : ils
  disent combien on peut se fier au résultat.

  Exemple :
     c = simulate(creditDefaultCopula(pd, lgd, ead, poids), 20000);
     portfolioRisk(c)

  Voir aussi CREDITDEFAULTCOPULA, RISKCONTRIBUTION, CONFIDENCEBANDS.
```

## `probdefault`

```
PROBDEFAULT Probabilité de défaut selon une grille de score.
  P = PROBDEFAULT(SC) rend la probabilité de défaut de chaque dossier
  ayant servi à l'ajustement ; PROBDEFAULT(SC,DONNEES) en traite
  d'autres.

  Elle ne dépend pas de l'échelle des points : celle-ci ne fait que
  déplacer et étirer le score, et la transformation inverse la rend
  telle quelle.

  Exemple :
     p = probdefault(sc);

  Voir aussi SCORE, VALIDATEMODEL, FITMODEL.
```

## `riskContribution`

```
RISKCONTRIBUTION Contribution de chaque composant au risque total.
  C = RISKCONTRIBUTION(POIDS,COVARIANCE) rend la contribution marginale
  de chaque actif à l'écart type d'un portefeuille : le poids multiplié
  par la dérivée du risque par rapport à ce poids. Les contributions
  somment exactement au risque, ce qui est la propriété qu'on attend
  d'une décomposition.

  C = RISKCONTRIBUTION(MODELE) décompose au contraire les pertes d'un
  portefeuille de crédit simulé : la perte attendue, l'écart type, la
  valeur en risque et la perte moyenne au-delà sont réparties entre les
  contreparties. La part de valeur en risque d'une contrepartie est sa
  perte moyenne dans les scénarios où la perte totale avoisine le
  quantile — c'est ce qui rend la somme des parts égale au total.

  Exemple :
     riskContribution([0.5 0.5], [0.04 0.01; 0.01 0.09])
     riskContribution(simulate(copule, 20000))

  Voir aussi PORTFOLIORISK, CONFIDENCEBANDS, CREDITDEFAULTCOPULA.
```

## `score`

```
SCORE Note des dossiers par une grille de score.
  [S,P] = SCORE(SC) note les dossiers qui ont servi à l'ajustement ;
  SCORE(SC,DONNEES) en note d'autres. P donne les points par
  caractéristique, dont S est la somme.

  Un score élevé désigne un bon dossier : la régression modélise la
  probabilité de ne pas faire défaut.

  Exemple :
     [s, p] = score(sc, nouveauxDossiers);

  Voir aussi PROBDEFAULT, DISPLAYPOINTS, FORMATPOINTS, VALIDATEMODEL.
```

## `summary`

```
SUMMARY Résumé d'un contrôle a posteriori.
  S = SUMMARY(V) compte les observations, les dépassements observés et
  attendus, et le niveau effectivement atteint. Sans sortie, le résumé
  est écrit.

  Exemple :
     summary(varbacktest(rendements, valeursEnRisque))

  Voir aussi VARBACKTEST, ESBACKTEST, RUNTESTS.
```

## `transprob`

```
TRANSPROB Matrice de transition de notation estimée sur des migrations.
  [P,T] = TRANSPROB(D) rend la matrice des probabilités de passer d'une
  notation à une autre sur un an. D est une matrice à trois colonnes :
  identifiant, date, notation, une ligne par observation.

  TRANSPROB(...,'algorithm','cohort') compte les notations au début et
  à la fin de chaque période, sans regarder ce qui s'est passé entre
  les deux. C'est la méthode simple, et le défaut.

  TRANSPROB(...,'algorithm','duration') estime d'abord la matrice des
  intensités : combien de passages de i vers j, rapportés au temps
  passé en i. La matrice de transition en est l'exponentielle. Cette
  méthode voit les allers-retours qu'une photographie annuelle manque,
  et donne des probabilités non nulles là où aucune transition directe
  n'a été observée.

  'snapsPerYear' fixe le nombre de photographies par an (1),
  'transInterval' la durée visée en années (1), 'labels' les
  étiquettes des notations.

  Exemple :
     d = [1 datenum('01-Jan-2020') 1; 1 datenum('01-Jan-2021') 2; ...
          2 datenum('01-Jan-2020') 2; 2 datenum('01-Jan-2021') 2];
     transprob(d)

  Voir aussi TRANSPROBBYTOTALS, TRANSPROBTOTHRESHOLDS, CREDITTRANSITION.
```

## `transprobbytotals`

```
TRANSPROBBYTOTALS Matrice de transition tirée de comptages agrégés.
  [P,T] = TRANSPROBBYTOTALS(TOTAUX) rend la matrice de transition sans
  repasser par les données individuelles. TOTAUX est la structure que
  rend TRANSPROB, ou un tableau de telles structures : elles sont alors
  additionnées avant l'estimation.

  C'est ainsi qu'on combine des historiques venus de sources
  différentes, ou qu'on recalcule une matrice sur un autre intervalle
  sans relire les migrations.

  Exemple :
     [~, t] = transprob(donnees);
     transprobbytotals(t)

  Voir aussi TRANSPROB, TRANSPROBTOTHRESHOLDS.
```

## `transprobfromthresholds`

```
TRANSPROBFROMTHRESHOLDS Matrice de transition tirée de seuils.
  P = TRANSPROBFROMTHRESHOLDS(S) est l'inverse de
  TRANSPROBTOTHRESHOLDS : la probabilité d'aller vers une notation est
  celle que la variable tombe entre son seuil et le suivant.

  Exemple :
     p = [0.9 0.08 0.02; 0.05 0.9 0.05; 0 0 1];
     max(max(abs(transprobfromthresholds(transprobtothresholds(p)) - p)))

  Voir aussi TRANSPROBTOTHRESHOLDS, TRANSPROB.
```

## `transprobtothresholds`

```
TRANSPROBTOTHRESHOLDS Seuils de qualité de crédit d'une matrice de transition.
  S = TRANSPROBTOTHRESHOLDS(P) traduit chaque ligne de la matrice en
  une suite de seuils sur une variable normale centrée réduite : la
  notation d'arrivée est celle dont le seuil est le plus grand que la
  variable dépasse.

  C'est ce qui permet de simuler des migrations corrélées : on tire des
  variables normales corrélées, et les seuils font le reste. Le premier
  seuil vaut l'infini, puisque la variable ne peut pas le dépasser.

  Exemple :
     seuils = transprobtothresholds([0.9 0.08 0.02; 0.05 0.9 0.05; 0 0 1])

  Voir aussi TRANSPROBFROMTHRESHOLDS, TRANSPROB, CREDITMIGRATIONCOPULA.
```

## `validatemodel`

```
VALIDATEMODEL Pouvoir discriminant d'une grille de score.
  [S,T] = VALIDATEMODEL(SC) rend l'aire sous la courbe de sensibilité,
  le coefficient de Gini et la statistique de Kolmogorov-Smirnov, ainsi
  que le tableau qui a servi à les calculer.

  L'aire sous la courbe est la probabilité qu'un bon dossier tiré au
  hasard reçoive un score plus élevé qu'un mauvais : un demi pour un
  modèle qui ne sait rien, un pour un modèle parfait. Le coefficient de
  Gini en est la version centrée, et la statistique de
  Kolmogorov-Smirnov le plus grand écart entre les deux répartitions.

  Exemple :
     s = validatemodel(sc);
     s.AUROC

  Voir aussi SCORE, PROBDEFAULT, FITMODEL.
```

## `valueAtRisk`

```
VALUEATRISK Valeur en risque d'une série de rendements.
  V = VALUEATRISK(R,NIVEAU) rend la perte que l'on ne dépasse qu'avec la
  probabilité 1-NIVEAU (0.95 par défaut), par la méthode historique.
  'normal' utilise l'hypothèse gaussienne.
```

## `varbacktest`

```
VARBACKTEST Contrôle a posteriori d'un modèle de valeur en risque.
  V = VARBACKTEST(RENDEMENTS,VAR) confronte les pertes réellement
  subies aux valeurs en risque annoncées la veille. VARBACKTEST(...,
  'VaRLevel',A) donne le niveau du modèle (0,95 par défaut).

  Un modèle de valeur en risque est une prévision, et une prévision se
  vérifie. Deux questions se posent : le nombre de dépassements est-il
  celui qu'annonce le niveau, et ces dépassements sont-ils dispersés ou
  groupés ? Un modèle peut avoir le bon nombre de dépassements et
  rester mauvais s'ils arrivent tous la même semaine.

  Les méthodes : TL le feu tricolore de Bâle, BIN le test binomial,
  POF la proportion de dépassements de Kupiec, TUFF le temps jusqu'au
  premier, CCI l'indépendance de Christoffersen, CC la couverture
  conditionnelle, TBFI et TBF les temps entre dépassements de Haas.
  RUNTESTS les passe tous, SUMMARY compte.

  Exemple :
     v = varbacktest(rendements, valeursEnRisque, 'VaRLevel', 0.99);
     runtests(v)

  Voir aussi ESBACKTEST, VALUEATRISK, EXPECTEDSHORTFALL.
```

