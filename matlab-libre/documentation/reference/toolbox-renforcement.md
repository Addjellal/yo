# Toolbox `renforcement`

```
% Reinforcement Learning Toolbox — apprentissage par renforcement.
%
% Environnement
%   gridworld     - Grille à quatre actions, un point par pas
%   pasGrille     - Transition : état suivant, récompense, fin d'épisode
%
% Apprentissage
%   qlearning     - Hors politique : apprend la valeur de la meilleure
%   sarsa         - Sur politique : apprend la valeur de celle qu'il suit
%
% Déploiement
%   greedyPolicy  - L'action de valeur maximale dans chaque état
```

## `greedyPolicy`

```
GREEDYPOLICY Action de valeur maximale dans chaque état.
  POLITIQUE = GREEDYPOLICY(Q) rend, pour chaque état, l'action de plus
  grande valeur : c'est la politique qu'on déploie une fois
  l'apprentissage fini, sans plus d'exploration.

  Une politique gloutonne n'a de sens que sur une table Q apprise :
  appliquée à une table nulle, elle rend partout la première action.

  Exemple :
     Q = qlearning(env, 500);
     politique = greedyPolicy(Q);
     politique(1)                    % l'action a prendre dans l'etat 1

  Voir aussi QLEARNING, SARSA, PASGRILLE.
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
  Q = QLEARNING(ENV,EPISODES,ALPHA,GAMMA,EPSILON) apprend la table des
  valeurs état-action par la règle

     Q(s,a) <- Q(s,a) + ALPHA (r + GAMMA max_a' Q(s',a') - Q(s,a))

  ALPHA est le pas d'apprentissage, GAMMA l'actualisation du futur, et
  EPSILON la part d'exploration au hasard.

  Le maximum sur les actions suivantes est ce qui fait de Q-learning une
  méthode *hors politique* : il apprend la valeur de la meilleure
  politique, quelle que soit celle qu'il suit pour explorer. SARSA, qui
  emploie l'action réellement choisie, apprend la valeur de la politique
  suivie — d'où des comportements différents près d'un danger.

  La table part de zéro, ce qui est optimiste puisque chaque pas coûte :
  toute action non essayée paraît meilleure que celles qu'on connaît, et
  l'agent explore de lui-même. C'est pourquoi EPSILON peut rester petit.

  Exemple :
     env = gridworld(5, 5, [5 5], [2 3; 3 3]);
     Q = qlearning(env, 500);
     politique = greedyPolicy(Q);

  Voir aussi SARSA, GREEDYPOLICY, GRIDWORLD, PASGRILLE.
```

## `sarsa`

```
SARSA Apprentissage SARSA sur un environnement de grille.
  Q = SARSA(ENV,EPISODES,ALPHA,GAMMA,EPSILON) apprend par la règle

     Q(s,a) <- Q(s,a) + ALPHA (r + GAMMA Q(s',a') - Q(s,a))

  où a' est l'action réellement choisie au pas suivant, exploration
  comprise. Le nom vient de ce quintuplet : état, action, récompense,
  état, action.

  C'est ce qui en fait une méthode *sur politique* : elle apprend la
  valeur de la politique qu'elle suit, exploration incluse. Près d'un
  précipice, un agent SARSA apprend donc à s'écarter du bord, parce
  qu'il tient compte du risque de tomber en explorant ; un agent
  Q-learning longe le bord, parce qu'il évalue la politique parfaite.

  Aucune des deux n'a raison dans l'absolu : cela dépend de si l'agent
  continuera d'explorer une fois déployé.

  Exemple :
     env = gridworld(5, 5, [5 5]);
     Q = sarsa(env, 500);
     politique = greedyPolicy(Q);

  Voir aussi QLEARNING, GREEDYPOLICY, GRIDWORLD.
```

