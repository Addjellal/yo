# Toolbox `optimisation-globale`

```
% Global Optimization Toolbox — optimisation globale.
%
%   ga             - Algorithme génétique
%   particleswarm  - Essaim particulaire
%   simulannealbnd - Recuit simulé
%   multistart     - Départs multiples sur un solveur local
%
% Recherche directe et multiobjectif
%   patternsearch - Recherche par motif, sans dérivée
%   gamultiobj    - Front de Pareto par algorithme génétique (NSGA-II)
%   paretosearch  - Front de Pareto par recherche directe
%   surrogateopt  - Optimisation par modèle de substitution radial
%
% Fonction interne (absente de MATLAB)
%   champOptimisation - Lecture d'une option avec valeur par défaut
```

## `champOptimisation`

```
CHAMPOPTIMISATION Lit une option, ou rend la valeur par défaut.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
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

