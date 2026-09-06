# Toolbox `renforcement`

```
% Reinforcement Learning Toolbox — apprentissage par renforcement.
%
%   qlearning     - Apprentissage Q sur un environnement tabulaire
%   sarsa         - Apprentissage SARSA
%   greedyPolicy  - Politique gloutonne déduite d'une table Q
%   gridworld     - Environnement de grille pour l'exemple
```

## `greedyPolicy`

```
GREEDYPOLICY Action de valeur maximale dans chaque état.
```

## `gridworld`

```
GRIDWORLD Environnement de grille : quatre actions, récompense -1 par pas.
  ENV = GRIDWORLD(LIGNES,COLONNES,ARRIVEE,OBSTACLES) décrit une grille.
  ARRIVEE est un couple [I J], et OBSTACLES une matrice de couples
  [I J], une case par ligne — non des numéros d'état.

  Les états, eux, sont numérotés : l'état de la case (I,J) vaut
  (I-1)*COLONNES + J. C'est cette numérotation que la table Q emploie.

  Chaque pas coûte un point, atteindre l'arrivée en rapporte dix. Ce
  coût par pas est ce qui pousse l'agent à trouver un chemin court :
  sans lui, tout chemin qui finit par arriver vaudrait autant.

  Les actions : 1 vers le haut, 2 vers le bas, 3 vers la gauche, 4 vers
  la droite. Un mur ou un obstacle laisse l'agent sur place.

  Exemple :
     env = gridworld(5, 5, [5 5], [2 3; 3 3]);
     env.nEtats                      % 25
     [suivant, r, fini] = pasGrille(env, 1, 4);

  Voir aussi PASGRILLE, QLEARNING, SARSA, GREEDYPOLICY.
```

## `pasGrille`

```
PASGRILLE Transition de l'environnement de grille.
  [SUIVANT,RECOMPENSE,FINI] = PASGRILLE(ENV,ETAT,ACTION) applique
  l'action et rend le nouvel état, la récompense et si l'épisode se
  termine.

  ETAT et SUIVANT sont des numéros d'état, ARRIVEE et OBSTACLES des
  couples [I J] : c'est la convention de GRIDWORLD.

  Un mur ou un obstacle laisse l'agent où il était. Rien ne le signale
  autrement que par le fait de ne pas bouger : c'est à l'agent de
  l'apprendre, comme le reste.

  Exemple :
     env = gridworld(3, 3, [3 3]);
     pasGrille(env, 1, 1)            % 1 : le mur du haut retient
     [~, r, fini] = pasGrille(env, 6, 2);   % arrivee : r = 10, fini

  Voir aussi GRIDWORLD, QLEARNING, SARSA.
```

## `qlearning`

```
QLEARNING Apprentissage Q tabulaire sur un environnement de grille.
```

## `sarsa`

```
SARSA Apprentissage SARSA sur un environnement de grille.
```

