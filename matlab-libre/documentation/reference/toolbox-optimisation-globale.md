# Toolbox `optimisation-globale`

```
% Global Optimization Toolbox — optimisation globale.
%
%   ga             - Algorithme génétique
%   particleswarm  - Essaim particulaire
%   simulannealbnd - Recuit simulé
%   multistart     - Départs multiples sur un solveur local
%   MultiStart     - Le même, sous forme d'objet à lancer par RUN
%   GlobalSearch   - Échantillonnage large, puis raffinement des
%                    meilleurs points
%   createOptimProblem - Description d'un problème pour ces deux-là
%
% Recherche directe et multiobjectif
%   patternsearch - Recherche par motif, sans dérivée
%   gamultiobj    - Front de Pareto par algorithme génétique (NSGA-II)
%   paretosearch  - Front de Pareto par recherche directe
%   surrogateopt  - Optimisation par modèle de substitution radial
%
% Réglages
%   gaoptimset    - Options de l'algorithme génétique
%   psoptimset    - Options de la recherche par motif
%   saoptimset    - Options du recuit simulé
%
% Fonction interne (absente de MATLAB)
%   champOptimisation - Lecture d'une option avec valeur par défaut
```

## `GlobalSearch`

```
GLOBALSEARCH Solveur global par bassins d'attraction.
  GS = GLOBALSEARCH crée un solveur qui échantillonne largement, garde
  les points les plus prometteurs, puis lance le solveur local depuis
  eux seulement.

  [X,F] = RUN(GS,PROBLEME) lance la recherche sur le problème que rend
  CREATEOPTIMPROBLEM.

  La différence avec MULTISTART tient au choix des points : au lieu de
  tirer et de lancer, on tire beaucoup, on évalue, et l'on ne lance le
  solveur local que là où la fonction est déjà basse. Le même budget
  d'appels couvre alors plus de bassins.

  Exemple :
     prob = createOptimProblem('fminunc', ...
         'objective', @(x) x ^ 4 - 3 * x ^ 2 + x, 'x0', 0);
     [x, f] = run(GlobalSearch, prob);

  Voir aussi MULTISTART, CREATEOPTIMPROBLEM, PARTICLESWARM, GA.
```

## `MultiStart`

```
MULTISTART Solveur global par départs multiples.
  MS = MULTISTART crée un solveur qui relance un solveur local depuis
  plusieurs points tirés au hasard, et garde le meilleur résultat.
  MS = MULTISTART('UseParallel',false,'Display','off') règle les
  options ; MatLibre les accepte et n'en emploie que 'Display'.

  [X,F] = RUN(MS,PROBLEME,N) lance N départs sur le problème que rend
  CREATEOPTIMPROBLEM.

  Les départs multiples ne garantissent rien : ils rendent seulement
  improbable de rester dans le premier creux venu. C'est la différence
  avec GLOBALSEARCH, qui choisit ses points au lieu de les tirer.

  Exemple :
     prob = createOptimProblem('fminunc', ...
         'objective', @(x) x ^ 4 - 3 * x ^ 2 + x, 'x0', 0);
     [x, f] = run(MultiStart, prob, 20);

  Voir aussi GLOBALSEARCH, CREATEOPTIMPROBLEM, MULTISTART, FMINCON.
```

## `champOptimisation`

```
CHAMPOPTIMISATION Lit une option, ou rend la valeur par défaut.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `createOptimProblem`

```
CREATEOPTIMPROBLEM Description d'un problème pour un solveur global.
  PROB = CREATEOPTIMPROBLEM(SOLVEUR,'objective',F,'x0',X0,...) rassemble
  dans une structure ce qu'un solveur local demande : la fonction, le
  point de départ, les bornes et les contraintes. GLOBALSEARCH et
  MULTISTART s'en servent pour relancer ce solveur depuis plusieurs
  points.

  SOLVEUR vaut 'fmincon', 'fminunc', 'lsqnonlin' ou 'lsqcurvefit'.
  Les couples reconnus sont 'objective', 'x0', 'lb', 'ub', 'Aineq',
  'bineq', 'Aeq', 'beq', 'nonlcon', 'options', 'xdata' et 'ydata'.

  Exemple :
     prob = createOptimProblem('fmincon', 'objective', @(x) x ^ 2 - 3, ...
                               'x0', 1, 'lb', -5, 'ub', 5);
     [x, f] = run(MultiStart, prob, 10);

  Voir aussi GLOBALSEARCH, MULTISTART, FMINCON, OPTIMOPTIONS.
```

## `ga`

```
GA Algorithme génétique à codage réel.
  [X,F] = GA(FONCTION,N,BAS,HAUT) minimise FONCTION sur l'hypercube.
```

## `gamultiobj`

```
GAMULTIOBJ Algorithme génétique multiobjectif.
  [X,F] = GAMULTIOBJ(FONCTION,N,[],[],[],[],BAS,HAUT) cherche le front
  de Pareto de FONCTION, qui doit rendre un vecteur d'objectifs. X a
  une ligne par solution non dominée, F la valeur des objectifs.

  La sélection est celle de NSGA-II : on classe la population par
  rangs de domination, puis, à rang égal, par distance d'encombrement
  — ce qui étale le front au lieu de le concentrer.

  Exemple :
     f = @(x) [x(1)^2, (x(1)-2)^2];
     [x, v] = gamultiobj(f, 1, [], [], [], [], -2, 4);
```

## `gaoptimset`

```
GAOPTIMSET Options d'un algorithme génétique.
  O = GAOPTIMSET rend les réglages par défaut de GA :
    PopulationSize     taille de la population, 50
    Generations        nombre de générations, 100
    EliteCount         individus reconduits tels quels, 2
    CrossoverFraction  part des enfants issus d'un croisement, 0,8
    MutationRate       taux de mutation, 0,1
    Display            'final', 'iter' ou 'off'
    TolFun             seuil d'arrêt sur l'amélioration, 1e-6
    StallGenLimit      générations sans progrès avant d'arrêter, 50

  O = GAOPTIMSET('PopulationSize',N,...) en change ; GAOPTIMSET(O,...)
  part d'une structure existante.

  C'est l'interface d'origine ; OPTIMOPTIONS est la moderne, et les
  deux mènent à la même structure.

  Exemple :
     o = gaoptimset('PopulationSize', 200, 'Generations', 300);
     x = ga(@(v) sum(v .^ 2), 3, -5, 5, o);

  Voir aussi GA, GAMULTIOBJ, PSOPTIMSET, SAOPTIMSET, OPTIMOPTIONS.
```

## `matlibre_departs_multiples`

```
MATLIBRE_DEPARTS_MULTIPLES Rouage commun de MULTISTART et GLOBALSEARCH.
  Les points de départ sont tirés dans les bornes du problème — ou
  autour de x0 quand il n'y en a pas. TRIER vrai fait d'abord évaluer
  NESSAIS points et ne garde que les NDEPARTS meilleurs : c'est ce qui
  distingue GlobalSearch de MultiStart.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_options_globales`

```
MATLIBRE_OPTIONS_GLOBALES Rouage commun des trois fonctions d'options.
  Le premier argument peut être une structure existante, qu'on complète
  au lieu de repartir des défauts. Un nom inconnu est refusé : c'est ce
  qui distingue une faute de frappe d'un réglage.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `multistart`

```
MULTISTART Minimisation locale répétée depuis des points tirés au hasard.
```

## `paretosearch`

```
PARETOSEARCH Front de Pareto par recherche directe.
  Même but que GAMULTIOBJ, mais sans hasard de croisement : chaque
  point non dominé est sondé dans les directions de coordonnée, et le
  front s'épaissit tant qu'on trouve mieux.

  Exemple :
     f = @(x) [x(1)^2, (x(1)-2)^2];
     [x, v] = paretosearch(f, 1, [], [], [], [], -2, 4);
```

## `particleswarm`

```
PARTICLESWARM Optimisation par essaim particulaire.
```

## `patternsearch`

```
PATTERNSEARCH Recherche directe par motif généralisé.
  X = PATTERNSEARCH(F,X0) minimise F sans jamais dériver : à chaque
  tour, on sonde les 2N points obtenus en avançant d'un pas dans
  chaque direction de coordonnée. Si l'un est meilleur, on s'y déplace
  et le pas double ; sinon le pas est divisé par deux.

  PATTERNSEARCH(F,X0,A,B,AEQ,BEQ,BAS,HAUT,NONLCON) tient compte des
  contraintes : un point qui les viole est simplement refusé.

  La méthode converge vers un point stationnaire sur une fonction
  régulière, et supporte les fonctions bruitées ou non dérivables, là
  où un gradient numérique se perdrait.

  Exemple :
     x = patternsearch(@(v) (v(1)-1)^2 + (v(2)+2)^2, [0 0]);
```

## `psoptimset`

```
PSOPTIMSET Options d'une recherche par motif.
  O = PSOPTIMSET rend les réglages par défaut de PATTERNSEARCH :
    MaxIter          nombre maximal d'itérations, 200
    MeshTolerance    finesse du motif en deçà de laquelle on s'arrête,
                     1e-6
    InitialMeshSize  taille initiale du motif, 1
    MeshExpansion    facteur d'agrandissement après un succès, 2
    MeshContraction  facteur de réduction après un échec, 0,5
    TolFun, TolX     seuils d'arrêt, 1e-6
    Display          'final', 'iter' ou 'off'

  Exemple :
     o = psoptimset('MaxIter', 500, 'MeshTolerance', 1e-9);
     x = patternsearch(@(v) sum(v .^ 2), [1 1], [], [], [], [], [], [], [], o);

  Voir aussi PATTERNSEARCH, PARETOSEARCH, GAOPTIMSET, OPTIMOPTIONS.
```

## `saoptimset`

```
SAOPTIMSET Options d'un recuit simulé.
  O = SAOPTIMSET rend les réglages par défaut de SIMULANNEALBND :
    MaxIter              nombre maximal d'itérations, 1000
    InitialTemperature   température de départ, 100
    TemperatureFcn       loi de refroidissement, 'temperatureexp'
    ReannealInterval     itérations entre deux réchauffements, 100
    TolFun               seuil d'arrêt, 1e-6
    Display              'final', 'iter' ou 'off'

  La température commande la probabilité d'accepter un pas qui dégrade
  le critère : haute, on explore ; basse, on descend. C'est ce qui
  permet de sortir d'un creux local au début et de s'y poser à la fin.

  Exemple :
     o = saoptimset('MaxIter', 5000, 'InitialTemperature', 50);
     x = simulannealbnd(@(v) sum(v .^ 2), [1 1], [-5 -5], [5 5], o);

  Voir aussi SIMULANNEALBND, GAOPTIMSET, PSOPTIMSET, OPTIMOPTIONS.
```

## `simulannealbnd`

```
SIMULANNEALBND Recuit simulé avec bornes.
```

## `surrogateopt`

```
SURROGATEOPT Optimisation par modèle de substitution.
  X = SURROGATEOPT(F,BAS,HAUT) minimise une fonction coûteuse en
  construisant, à partir des points déjà évalués, une surface de
  réponse à base radiale ; le point suivant est choisi là où le modèle
  est bas et où l'on n'a pas encore regardé.

  Utile quand chaque évaluation prend du temps : le nombre d'appels à
  F reste petit.

  Exemple :
     x = surrogateopt(@(v) (v(1)-0.3)^2 + (v(2)+0.7)^2, [-1 -1], [1 1]);
```

