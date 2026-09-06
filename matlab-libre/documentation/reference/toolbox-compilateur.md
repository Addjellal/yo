# Toolbox `compilateur`

```
% MATLAB Compiler — distribution d'un programme.
%
%   mcc        - Fabrique un lanceur autonome autour d'un script
%   deploytool - Décrit ce que contient le paquet produit
```

## `deploytool`

```
DEPLOYTOOL Décrit le paquet de distribution d'un script.
  D = DEPLOYTOOL('script.m') rend une structure disant ce qu'il faut
  emporter pour que le programme tourne ailleurs :

     script        le script lui-même
     interpreteur  le chemin de l'interpréteur MatLibre
     toolboxes     le dossier des boîtes à outils
     remarque      ce que le paquet n'est pas

  MATLAB distribue un programme compilé avec son « runtime », un
  ensemble de bibliothèques à installer sur la machine cible. Ici la
  dépendance est l'interpréteur et le dossier des toolboxes : c'est la
  même chose, dite plus simplement.

  Exemple :
     d = deploytool('analyse.m');
     d.toolboxes

  Voir aussi MCC, MATLABROOT.
```

## `matlibre_cheminAbsolu`

```
MATLIBRE_CHEMINABSOLU Vrai si le chemin ne dépend pas du dossier courant.
  Une barre oblique en tête sous Unix, une lettre de lecteur suivie de
  deux-points sous Windows, ou un chemin réseau à deux barres.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `mcc`

```
MCC Fabrique un lanceur pour un script.
  CHEMIN = MCC('script.m','programme') écrit un lanceur qui appelle
  l'interpréteur MatLibre sur le script, avec le chemin des toolboxes
  déjà réglé. Sans nom de sortie, le lanceur prend celui du script.

  C'est l'équivalent libre du « MATLAB Runtime » : le programme produit
  a besoin de l'interpréteur, comme un programme compilé par mcc a
  besoin du runtime. Rien ici ne devient un binaire autonome, et le
  prétendre serait mentir.

  Le lanceur nomme l'interpréteur par son chemin complet, celui de
  l'interpréteur qui a produit le lanceur : écrire « exec matlibre »
  supposerait qu'il soit dans le PATH de la machine cible, ce qui n'est
  vrai qu'après installation.

  Sous Windows, le lanceur est un fichier de commandes .bat ; ailleurs,
  un script shell rendu exécutable.

  Exemple :
     mcc('analyse.m', 'analyse')
     system('./analyse')

  Voir aussi DEPLOYTOOL, MATLABROOT.
```

