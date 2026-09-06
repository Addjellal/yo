# Toolbox `edp`

```
% Partial Differential Equation Toolbox — équations aux dérivées partielles.
%
% Problèmes stationnaires
%   laplace2D  - Laplacien nul, bords à valeurs constantes
%   poisson2D  - Laplacien avec terme source, bords nuls
%   fem1D      - Éléments finis P1 en une dimension
%
% Problèmes d'évolution
%   heat1D     - Chaleur, par Crank-Nicolson : diffusion, inconditionnel
%   wave1D     - Ondes, par différences centrées : transport, condition
%                de Courant à respecter
```

## `fem1D`

```
FEM1D Éléments finis P1 pour -u'' = f, u(0) = u(L) = 0.
  [U,X] = FEM1D(F,LONGUEUR,N) résout le problème sur N éléments, F étant
  une poignée @(x). U et X portent les N+1 nœuds, bords compris.

  Les éléments P1 sont des fonctions chapeau : la solution est affine
  par morceaux, continue, et nulle aux bords. La matrice de rigidité qui
  en résulte est tridiagonale, symétrique et définie positive — c'est ce
  qui rend la résolution stable et rapide.

  L'erreur décroît comme le carré du pas : diviser le pas par deux
  divise l'erreur par quatre. C'est la vérification à faire sur un cas
  dont on connaît la solution exacte.

  Exemple :
     % -u'' = 1 sur [0,1] a pour solution x(1-x)/2.
     [u, x] = fem1D(@(x) ones(size(x)), 1, 32);
     max(abs(u - x .* (1 - x) / 2))

  Voir aussi POISSON2D, LAPLACE2D, HEAT1D.
```

## `heat1D`

```
HEAT1D Équation de la chaleur, schéma de Crank-Nicolson.
  [U,X,T] = HEAT1D(U0,ALPHA,L,TFINAL,NX,NT) avec U0 une poignée @(x)
  et des bords maintenus à zéro. NX est le nombre de points intérieurs,
  NT le nombre de pas de temps.

  Crank-Nicolson est la moyenne du schéma explicite et de l'implicite :
  il est d'ordre deux en temps comme en espace, et inconditionnellement
  stable — aucune condition ne lie le pas de temps au pas d'espace, là
  où le schéma explicite exigerait dt < dx^2 / (2 alpha).

  La chaleur diffuse : la solution s'aplatit, son maximum décroît, et
  son intégrale décroît aussi puisque les bords évacuent. Un mode propre
  sin(n pi x / L) décroît exactement en exp(-alpha (n pi / L)^2 t), sans
  changer de forme : c'est la vérification la plus sûre.

  Exemple :
     [u, x, t] = heat1D(@(x) sin(pi * x), 0.1, 1, 0.5, 50, 200);
     u(:, end) ./ u(:, 1)            % exp(-0.1 pi^2 * 0.5), partout

  Voir aussi WAVE1D, POISSON2D, FEM1D.
```

## `laplace2D`

```
LAPLACE2D Équation de Laplace avec conditions de Dirichlet constantes.
  U = LAPLACE2D(HAUT,BAS,GAUCHE,DROITE,NX,NY) résout le laplacien nul
  sur un rectangle dont chaque bord est maintenu à une valeur constante.

  Une fonction harmonique n'a ni maximum ni minimum à l'intérieur : ses
  extrêmes sont sur le bord. C'est le principe du maximum, et c'est la
  vérification la plus simple d'une solution de Laplace.

  Chaque point intérieur vaut la moyenne de ses quatre voisins : c'est à
  la fois le schéma numérique et une propriété exacte de la solution.
  Quatre bords égaux donnent donc une solution constante.

  Exemple :
     u = laplace2D(100, 0, 0, 0, 40, 40);
     max(u(:)) <= 100 && min(u(:)) >= 0      % le principe du maximum
     u = laplace2D(50, 50, 50, 50, 20, 20);  % constante a 50

  Voir aussi POISSON2D, HEAT1D, FEM1D.
```

## `poisson2D`

```
POISSON2D Résout -laplacien(u) = f sur un rectangle, u nul au bord.
  [U,X,Y] = POISSON2D(F,NX,NY,LARGEUR,HAUTEUR) où F est une poignée
  @(x,y) et où le rectangle vaut un sur un par défaut. NX et NY comptent
  les points intérieurs.

  C'est Laplace avec un terme source : la même équation, un second
  membre non nul. Le potentiel électrostatique d'une densité de charge,
  la flèche d'une membrane chargée, la température d'une plaque
  chauffée s'y ramènent tous.

  Le système est symétrique défini positif, donc la solution existe et
  elle est unique. Une source positive partout donne une solution
  positive partout : c'est le principe du maximum, en présence de
  source.

  Un mode propre est solution exacte : pour f = 2 pi^2 sin(pi x)
  sin(pi y) sur le carré unité, la solution est sin(pi x) sin(pi y).

  Exemple :
     f = @(x, y) 2 * pi^2 * sin(pi * x) .* sin(pi * y);
     [u, x, y] = poisson2D(f, 40, 40);
     max(u(:))                       % proche de 1

  Voir aussi LAPLACE2D, FEM1D, HEAT1D.
```

## `wave1D`

```
WAVE1D Équation des ondes en 1-D, différences centrées.
  [U,X,T] = WAVE1D(U0,C,LONGUEUR,TFINAL,NX,NT) résout u_tt = c^2 u_xx
  avec U0 une poignée @(x), une vitesse initiale nulle et des bords
  fixés à zéro.

  Contrairement à la chaleur, l'onde ne diffuse pas : elle transporte.
  L'énergie se conserve, la forme revient, et le schéma doit respecter
  la condition de Courant — c dt / dx au plus un — sans quoi il diverge.
  Ce n'est pas une question de précision mais de stabilité : au-delà,
  l'information numérique se propage moins vite que l'onde physique.

  Une corde pincée sur son mode fondamental revient à sa forme initiale
  au bout d'une période 2L/c : c'est la vérification à faire.

  Exemple :
     [u, x, t] = wave1D(@(x) sin(pi * x), 1, 1, 2, 100, 400);
     max(abs(u(:, end) - u(:, 1)))   % petit : une periode ecoulee

  Voir aussi HEAT1D, POISSON2D.
```

