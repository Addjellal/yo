# Toolbox `compilateur`

```
% MATLAB Compiler — distribution d'un programme.
%
%   mcc        - Fabrique un lanceur autonome (mcc -m programme.m)
%   deploytool - Décrit ce que contient le paquet produit
%   isdeployed - Vrai dans une application produite par mcc
%   ismcc      - Vrai pendant la compilation : toujours faux ici
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

## `isdeployed`

```
ISDEPLOYED Vrai dans une application produite par MCC.
  OUI = ISDEPLOYED() vaut vrai quand le programme tourne par le lanceur
  que MCC a fabriqué, faux dans l'interpréteur. C'est ce qu'un programme
  teste pour ne régler son chemin qu'en développement :
     if ~isdeployed, addpath('outils'); end

  Exemple :
     isdeployed()                    % false : on est dans l'interpréteur

  Voir aussi MCC, ISMCC.
```

## `ismcc`

```
ISMCC Vrai pendant la compilation par MCC.
  OUI = ISMCC() vaut toujours faux dans MatLibre : MCC n'exécute pas le
  programme pour l'analyser, comme le fait MATLAB Compiler, il fabrique
  un lanceur. Un programme qui teste ISMCC pour sauter du code pendant
  la compilation garde donc son comportement ordinaire.

  Exemple :
     ismcc()                         % false

  Voir aussi ISDEPLOYED, MCC.
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
MCC Fabrique un lanceur autonome pour un programme MATLAB.
  MCC -m PROGRAMME.m fabrique, comme MATLAB Compiler, une application
  autonome nommée d'après PROGRAMME, dans le dossier courant. Options de
  MATLAB reconnues :
     -m            application autonome (la seule cible)
     -o NOM        nom de l'application
     -d DOSSIER    dossier où l'écrire
     -a CHEMIN     fichier ou dossier joint : son dossier va au chemin
     -v            dit ce qui est produit
  Les autres options (-W, -T, -R, -e...) sont refusées en le disant.
  CHEMIN = MCC('programme.m','sortie'), forme historique de MatLibre,
  reste admise.

  L'application est un lanceur qui appelle l'interpréteur MatLibre sur
  le programme, chemin des toolboxes réglé : c'est l'équivalent libre du
  MATLAB Runtime, dont un programme compilé par mcc a besoin. Rien ici
  ne devient un binaire autonome, et le prétendre serait mentir. Comme
  dans MATLAB, les arguments de la ligne de commande arrivent en texte
  à la fonction principale : « ./prog 21 » appelle prog('21'), et
  ISDEPLOYED y vaut vrai.

  MCC n'écrit jamais sur un fichier .m : une sortie qui en porterait le
  nom est refusée, ce qui protège le programme lui-même.

  Sous Windows, le lanceur est un fichier de commandes .bat ; ailleurs,
  un script shell rendu exécutable.

  Exemple :
     dossier = tempname(); mkdir(dossier);
     f = fopen(fullfile(dossier, 'double.m'), 'w');
     fprintf(f, 'function double(n)\n  disp(2 * str2double(n));\nend\n');
     fclose(f);
     lanceur = mcc('-m', fullfile(dossier, 'double.m'), '-d', dossier);
     if isunix, [~, sortie] = system([lanceur ' 21']); end   % 42

  Voir aussi DEPLOYTOOL, MATLABROOT, ISDEPLOYED.
```

