# Toolbox `mpc`

```
% Model Predictive Control Toolbox — commande prédictive.
%
% La méthode tient dans l'horizon fuyant : on optimise sur P pas, on
% n'applique que le premier, et l'on recommence avec la mesure fraîche.
%
%   mpcSetup   - Prépare un contrôleur, à partir du modèle et des poids
%   mpcmove    - La commande à appliquer maintenant
%   mpcsim     - Simulation complète en boucle fermée
```

## `mpcSetup`

```
MPCSETUP Prépare un contrôleur prédictif à horizon fuyant.
  Le problème résolu à chaque pas est
     min sum ||y(k) - r||^2 Q + ||du(k)||^2 R
  sur l'horizon de prédiction, la commande étant maintenue constante
  au-delà de l'horizon de commande.

  CONTROLEUR = MPCSETUP(A,B,C,P,M,Q,R) où (A,B,C) est le modèle discret,
  P l'horizon de prédiction, M l'horizon de commande, Q le poids de
  l'écart à la consigne et R celui de l'effort.

  L'horizon fuyant est ce qui fait la méthode : on résout sur P pas,
  on n'applique que le premier, et l'on recommence au pas suivant avec
  la mesure fraîche. C'est ce qui la rend robuste malgré un modèle
  imparfait.

  Le rapport Q/R est le seul vrai réglage : Q grand suit vite la
  consigne et sollicite les actionneurs, R grand ménage la commande et
  suit mollement. Il n'y a pas de choix universel, seulement un
  compromis à assumer.

  Les matrices de prédiction sont calculées une fois pour toutes ici :
  MPCMOVE n'a plus qu'à résoudre un système linéaire à chaque pas.

  Exemple :
     A = [1 0.1; 0 1]; B = [0.005; 0.1]; C = [1 0];
     ctrl = mpcSetup(A, B, C, 20, 5, 1, 0.1);
     [y, u] = mpcsim(ctrl, 1, 100);

  Voir aussi MPCMOVE, MPCSIM.
```

## `mpcmove`

```
MPCMOVE Commande optimale à appliquer à l'instant courant.
  [U,SEQUENCE] = MPCMOVE(CONTROLEUR,X,CONSIGNE) rend la commande à
  appliquer maintenant, et la séquence entière qu'elle inaugure.

  Seul U sert : la séquence est recalculée au pas suivant, avec l'état
  mesuré et non prédit. C'est ce rejet permanent qui distingue la
  commande prédictive d'une commande en boucle ouverte optimisée une
  fois pour toutes.

  Regarder SEQUENCE reste instructif : elle montre ce que le contrôleur
  compte faire, et l'écart entre ce plan et ce qu'il fait vraiment
  mesure ce que la rétroaction corrige.

  Exemple :
     x = [0; 0];
     for k = 1:100
         u = mpcmove(ctrl, x, 1);
         x = A * x + B * u;
     end

  Voir aussi MPCSETUP, MPCSIM.
```

## `mpcsim`

```
MPCSIM Simulation en boucle fermée du contrôleur prédictif.
  [Y,U,T] = MPCSIM(CONTROLEUR,CONSIGNE,NPAS) simule NPAS pas en boucle
  fermée depuis l'état nul, et rend la sortie, la commande et le temps.

  C'est la vérification qui compte : un contrôleur prédictif bien réglé
  rejoint la consigne sans erreur permanente, et la commande se
  stabilise. Une commande qui oscille indique un R trop petit devant Q.

  Exemple :
     [y, u, t] = mpcsim(ctrl, 1, 100);
     y(end)                          % 1 : la consigne est atteinte
     max(abs(diff(u)))               % l'a-coup de commande le plus fort

  Voir aussi MPCSETUP, MPCMOVE.
```

