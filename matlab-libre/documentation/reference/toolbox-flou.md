# Toolbox `flou`

```
% Fuzzy Logic Toolbox — logique floue.
%
% Fonctions d'appartenance
%   trimf, trapmf     - Triangle et trapèze
%   gaussmf, gauss2mf - Gaussienne, et gaussienne à plateau
%   gbellmf           - Cloche généralisée
%   sigmf, dsigmf, psigmf - Sigmoïde, différence et produit
%   zmf, smf, pimf    - Courbes en Z, en S et en Pi
%   evalmf            - Évaluation par le nom du type
%   plotmf            - Tracé des modalités d'une variable
%
% Construction d'un système
%   newfis            - Système vide, Mamdani ou Sugeno
%   mamfis, sugfis    - Les deux mêmes, forme moderne
%   addvar, addmf, addrule - Variables, modalités, règles
%   rmvar, rmmf       - Retraits, avec mise à jour des règles
%   getfis, setfis    - Lecture et écriture des champs
%   readfis, writefis - Fichiers .fis
%   showrule, plotfis - Règles en clair, structure du système
%
% Inférence
%   evalfis           - Mamdani et Sugeno, plusieurs sorties, cinq opérateurs
%   defuzz            - Défuzzification : centroid, bisector, mom, som, lom
%   probor            - Ou probabiliste
%   gensurf           - Surface de réponse
%   fuzarith          - Arithmétique sur les nombres flous
%
% Classification et apprentissage
%   fcm               - C-moyennes floues
%   subclust          - Classification soustractive de Chiu
%   genfis1           - Système par partition régulière
%   genfis2           - Système par classification soustractive
%   genfis3           - Système par c-moyennes floues
%   genfis            - Interface commune aux trois
%   anfis             - Apprentissage hybride de Jang
```

## `addmf`

```
ADDMF Ajoute une fonction d'appartenance à une variable.
```

## `addrule`

```
ADDRULE Ajoute des règles.
  Chaque ligne vaut [mfEntree1 ... mfEntreeN mfSortie poids operateur],
  où l'opérateur vaut 1 pour « et », 2 pour « ou », comme dans la
  documentation MathWorks.
```

## `addvar`

```
ADDVAR Ajoute une variable d'entrée ou de sortie.
  FIS = ADDVAR(FIS,'input'|'output',NOM,[MIN MAX])
```

## `anfis`

```
ANFIS Apprentissage d'un système de Sugeno par méthode hybride.
  FIS = ANFIS(DONNEES) apprend un système à partir d'une matrice dont
  les premières colonnes sont les entrées et la dernière la sortie.
  FIS = ANFIS(DONNEES,FIS0) part d'un système donné, construit par
  GENFIS1 ou GENFIS2.
  FIS = ANFIS(DONNEES,FIS0,N) fixe le nombre d'époques, dix par défaut.
  [FIS,ERREURS] = ANFIS(...) rend l'erreur quadratique moyenne à chaque
  époque.

  L'apprentissage est celui de Jang : à chaque époque, les paramètres
  de conclusion sont trouvés exactement par moindres carrés — la sortie
  en dépend linéairement —, puis les paramètres de prémisse sont
  corrigés par descente de gradient. Le pas s'adapte : il croît de dix
  pour cent quand l'erreur baisse, et se réduit de moitié sinon.

  C'est cette séparation qui fait la force de la méthode : la moitié
  linéaire du problème est résolue d'un coup au lieu d'être approchée.

  Exemple :
     x = (0:0.05:10)';
     donnees = [x, sin(x)];
     [fis, e] = anfis(donnees, genfis1(donnees, 7), 20);
     e(end) < e(1)   % vrai

  Voir aussi GENFIS1, GENFIS2, EVALFIS, FCM.
```

## `defuzz`

```
DEFUZZ Défuzzification d'un ensemble flou.
  Y = DEFUZZ(X,MF,'centroid'|'bisector'|'mom'|'som'|'lom')
```

## `dsigmf`

```
DSIGMF Différence de deux sigmoïdes.
  Y = DSIGMF(X,[A1 C1 A2 C2]) = sigmf(X,[A1 C1]) - sigmf(X,[A2 C2]).
```

## `estEntree`

```
ESTENTREE Le mot-clé désigne-t-il une entrée ?
  Accepte 'input' et 'in' pour une entrée, 'output' et 'out' pour une
  sortie ; toute autre valeur est refusée.
```

## `evalfis`

```
EVALFIS Inférence floue, Mamdani ou Sugeno.
  Y = EVALFIS(X,FIS) évalue le système. X est un vecteur d'entrées, ou
  une matrice dont chaque ligne est un jeu d'entrées ; Y a alors une
  ligne par jeu et une colonne par sortie.

  Y = EVALFIS(X,FIS,N) fixe le nombre de points de la grille de
  défuzzification, 101 par défaut.

  [Y,FORCES,AGREGATS,SORTIESREGLES] = EVALFIS(...) rend en plus, pour la
  dernière ligne d'entrées, les forces d'activation des règles, les
  ensembles flous agrégés par sortie, et la contribution de chaque règle.

  L'inférence suit les cinq opérateurs du système : conjonction,
  disjonction, implication, agrégation et défuzzification. Un indice de
  fonction d'appartenance négatif dans une règle vaut négation, un
  indice nul vaut « peu importe ».

  Chez Sugeno, les conclusions sont des fonctions des entrées :
  'constant' de paramètre c, ou 'linear' de paramètres [a1 ... aN a0].
  La sortie est leur moyenne pondérée par les forces ('wtaver') ou leur
  somme pondérée ('wtsum').

  Exemple :
     fis = newfis('t');
     fis = addvar(fis, 'input', 'x', [0 10]);
     fis = addmf(fis, 'input', 1, 'bas', 'trimf', [0 0 5]);
     fis = addmf(fis, 'input', 1, 'haut', 'trimf', [5 10 10]);
     fis = addvar(fis, 'output', 'y', [0 1]);
     fis = addmf(fis, 'output', 1, 'petit', 'trimf', [0 0 0.5]);
     fis = addmf(fis, 'output', 1, 'grand', 'trimf', [0.5 1 1]);
     fis = addrule(fis, [1 1 1 1; 2 2 1 1]);
     evalfis(5, fis)

  Voir aussi NEWFIS, ADDRULE, DEFUZZ, GENSURF.
```

## `evalmf`

```
EVALMF Évalue une fonction d'appartenance par son nom.
  Y = EVALMF(X,TYPE,PARAMS) où TYPE vaut 'trimf', 'trapmf', 'gaussmf',
  'gauss2mf', 'gbellmf', 'sigmf', 'dsigmf', 'psigmf', 'zmf', 'smf',
  'pimf', ou, pour une sortie de Sugeno, 'constant' ou 'linear'.

  Exemple :
     evalmf(0:4, 'trimf', [0 2 4])   % [0 0.5 1 0.5 0]

  Voir aussi TRIMF, TRAPMF, GAUSSMF, EVALFIS.
```

## `fcm`

```
FCM Classification par c-moyennes floues.
  [C,U,J] = FCM(DONNEES,N) partage les lignes de DONNEES en N classes
  floues. C porte les centres, une ligne par classe ; U(i,j) est le
  degré d'appartenance du point j à la classe i, les colonnes sommant à
  un ; J retrace la valeur du critère à chaque itération.

  FCM(DONNEES,N,OPTIONS) où OPTIONS vaut
    [EXPOSANT MAXITER TOLERANCE AFFICHAGE]
  valant par défaut [2 100 1e-5 0]. L'exposant, souvent noté m, règle le
  flou : à m proche de un la partition devient nette, et plus m grandit
  plus les appartenances s'égalisent.

  Le critère minimisé est somme_i somme_j U(i,j)^m ||x_j - c_i||^2. À
  chaque tour, les centres sont les barycentres pondérés des points, et
  les appartenances l'inverse des distances élevées à la puissance
  2/(m-1), normalisé : c'est le point fixe des conditions d'optimalité.

  Exemple :
     donnees = [randn(50,2); randn(50,2) + 6];
     [c, u] = fcm(donnees, 2);

  Voir aussi SUBCLUST, GENFIS2, EVALFIS.
```

## `fuzarith`

```
FUZARITH Arithmétique sur les nombres flous.
  Y = FUZARITH(X,A,B,OPERATION) où A et B sont deux ensembles flous
  échantillonnés sur la grille X, et OPERATION vaut 'sum', 'sub',
  'prod' ou 'div'.

  Le calcul suit le principe d'extension, appliqué par coupes de
  niveau : à chaque niveau alpha, A et B se réduisent à deux
  intervalles, sur lesquels l'opération est celle de l'arithmétique
  d'intervalles. Le résultat est reconstitué en superposant les coupes.

  Exemple :
     x = linspace(-10, 30, 401);
     a = trimf(x, [1 2 3]);
     b = trimf(x, [4 6 8]);
     y = fuzarith(x, a, b, 'sum');
     x(find(y == max(y), 1))   % voisin de 8 : 2 + 6

  Voir aussi TRIMF, EVALMF, DEFUZZ.
```

## `gauss2mf`

```
GAUSS2MF Deux demi-gaussiennes raccordées par un plateau.
  Y = GAUSS2MF(X,[S1 C1 S2 C2]) : montée gaussienne jusqu'à C1, plateau
  à 1 entre C1 et C2, descente gaussienne après C2.
```

## `gaussmf`

```
GAUSSMF Fonction d'appartenance gaussienne de paramètres [sigma centre].
```

## `gbellmf`

```
GBELLMF Cloche généralisée de paramètres [a b c].
```

## `genfis`

```
GENFIS Construction d'un système flou à partir de données.
  FIS = GENFIS(X,Y) partitionne régulièrement l'espace d'entrée, comme
  GENFIS1, et rend un système de Sugeno prêt pour ANFIS.
  FIS = GENFIS(X,Y,OPTIONS) où OPTIONS est une structure aux champs
    Methode          'gridpartition', 'subtractiveclustering' ou 'fcm'
    NumMembershipFunctions   pour la partition régulière
    ClusterInfluenceRange    pour la classification soustractive
    NumClusters              pour les c-moyennes floues

  Exemple :
     x = (0:0.1:10)';
     fis = genfis(x, sin(x), struct('Methode', 'fcm', 'NumClusters', 6));

  Voir aussi GENFIS1, GENFIS2, GENFIS3, ANFIS.
```

## `genfis1`

```
GENFIS1 Système de Sugeno par partition régulière de l'espace d'entrée.
  FIS = GENFIS1(DONNEES) construit un système à partir d'une matrice
  dont les dernières colonnes sont la sortie et les précédentes les
  entrées. Chaque entrée reçoit deux fonctions d'appartenance
  gaussiennes réparties uniformément sur son étendue, et il y a une
  règle par combinaison.

  FIS = GENFIS1(DONNEES,N) donne N fonctions par entrée, ou un vecteur
  d'autant d'éléments qu'il y a d'entrées.
  FIS = GENFIS1(DONNEES,N,TYPEENTREE,TYPESORTIE) choisit les types :
  'gaussmf' par défaut à l'entrée, 'linear' à la sortie ('constant'
  étant l'autre possibilité).

  Le système obtenu ne sait rien encore : ses conclusions sont nulles.
  C'est le point de départ d'ANFIS, qui les ajustera.

  Le nombre de règles croît comme N puissance le nombre d'entrées :
  au-delà de trois ou quatre entrées, GENFIS2 est préférable.

  Exemple :
     donnees = [(0:0.1:10)', sin(0:0.1:10)'];
     fis = genfis1(donnees, 5);
     numel(fis.regles(:,1))   % 5

  Voir aussi GENFIS2, ANFIS, EVALFIS.
```

## `genfis2`

```
GENFIS2 Système de Sugeno par classification soustractive.
  FIS = GENFIS2(X,Y,RA) cherche les centres de classes dans l'espace
  commun des entrées et des sorties, puis fait de chaque centre une
  règle : les prémisses sont des gaussiennes centrées sur la projection
  du centre dans l'espace d'entrée, et la conclusion la projection dans
  l'espace de sortie.

  À la différence de GENFIS1, le nombre de règles ne croît pas
  exponentiellement avec le nombre d'entrées : il vaut le nombre de
  classes trouvées, que le rayon RA règle indirectement.

  FIS = GENFIS2(X,Y,RA,BORNES,OPTIONS) passe les mêmes arguments que
  SUBCLUST.

  Exemple :
     x = (0:0.1:10)';
     fis = genfis2(x, sin(x), 0.3);

  Voir aussi GENFIS1, SUBCLUST, ANFIS.
```

## `genfis3`

```
GENFIS3 Système flou par c-moyennes floues.
  FIS = GENFIS3(X,Y) partage l'espace en deux classes par FCM et en tire
  un système de Sugeno, une règle par classe.
  FIS = GENFIS3(X,Y,TYPE,N) choisit le type, 'sugeno' ou 'mamdani', et
  le nombre de classes. N vaut 'auto' pour laisser FCM choisir deux
  classes par défaut.
  FIS = GENFIS3(X,Y,TYPE,N,OPTIONS) passe les options de FCM.

  À la différence de GENFIS2, le nombre de règles est demandé plutôt que
  déduit d'un rayon.

  Exemple :
     x = (0:0.1:10)';
     fis = genfis3(x, sin(x), 'sugeno', 6);

  Voir aussi GENFIS1, GENFIS2, FCM.
```

## `gensurf`

```
GENSURF Surface de réponse d'un système flou.
  [X,Y,Z] = GENSURF(FIS) évalue la sortie sur une grille des deux
  premières entrées. Sans sortie demandée, la surface est tracée.

  Exemple :
     [x, y, z] = gensurf(fis);
```

## `getfis`

```
GETFIS Lecture d'un champ d'un système d'inférence floue.
  GETFIS(FIS) affiche le résumé du système.
  GETFIS(FIS,'name'|'type'|'numinputs'|'numoutputs'|'numrules') rend le
  champ demandé, ainsi que les cinq opérateurs par leurs noms MATLAB :
  'andmethod', 'ormethod', 'impmethod', 'aggmethod', 'defuzzmethod'.
  GETFIS(FIS,'input',I,CHAMP) lit un champ d'une variable : 'name',
  'range', 'nummfs'.
  GETFIS(FIS,'input',I,'mf',J,CHAMP) lit 'name', 'type' ou 'params'.

  Exemple :
     getfis(fis, 'numinputs')
     getfis(fis, 'input', 1, 'mf', 2, 'params')

  Voir aussi SETFIS, SHOWRULE, NEWFIS.
```

## `mamfis`

```
MAMFIS Système d'inférence floue de Mamdani.
  FIS = MAMFIS crée un système vide nommé « fis ».
  FIS = MAMFIS('Name',NOM) le nomme.

  C'est la forme moderne de NEWFIS(NOM,'mamdani') : la conclusion de
  chaque règle est un ensemble flou, que l'inférence agrège puis
  défuzzifie.

  Exemple :
     fis = mamfis('Name', 'pilote');

  Voir aussi SUGFIS, NEWFIS, EVALFIS.
```

## `newfis`

```
NEWFIS Crée un système d'inférence floue.
  FIS = NEWFIS(NOM) crée un système de Mamdani vide.
  FIS = NEWFIS(NOM,TYPE) où TYPE vaut 'mamdani' ou 'sugeno'.
  FIS = NEWFIS(NOM,TYPE,ET,OU,IMPLICATION,AGREGATION,DEFUZZ) fixe les
  cinq opérateurs. Leurs valeurs par défaut sont celles de MATLAB :
  'min', 'max', 'min', 'max' et 'centroid' pour Mamdani, 'prod', 'probor',
  'prod', 'sum' et 'wtaver' pour Sugeno.

  La structure porte les champs nom, type, entrees, sorties, regles et
  les cinq opérateurs. Les variables sont des tableaux de cellules ;
  GETFIS et SETFIS donnent les accès nommés.

  Exemple :
     fis = newfis('exemple', 'sugeno');
     fis.defuzzification   % 'wtaver'

  Voir aussi MAMFIS, SUGFIS, ADDVAR, ADDMF, ADDRULE, EVALFIS.
```

## `pimf`

```
PIMF Fonction d'appartenance en Pi : montée en S puis descente en Z.
  Y = PIMF(X,[A B C D]) monte de A à B, vaut 1 de B à C, descend de C
  à D.

  Exemple :  pimf(5, [1 4 6 9])   % 1
```

## `plotfis`

```
PLOTFIS Vue d'ensemble d'un système d'inférence floue.
  PLOTFIS(FIS) écrit la structure du système : ses entrées avec leurs
  modalités, ses sorties, et le nombre de règles qui les relient.
  T = PLOTFIS(FIS) rend ce texte au lieu de l'afficher.

  Exemple :
     plotfis(fis)

  Voir aussi PLOTMF, SHOWRULE, GETFIS.
```

## `plotmf`

```
PLOTMF Tracé des fonctions d'appartenance d'une variable.
  PLOTMF(FIS,'input',I) trace, sur l'étendue de la variable, toutes ses
  fonctions d'appartenance superposées. C'est le premier regard qu'on
  porte sur un système flou : il montre si les modalités se recouvrent
  assez pour que la sortie soit continue, et si elles couvrent bien
  toute l'étendue.

  [Y,X] = PLOTMF(...) rend les courbes au lieu de les tracer, une
  colonne par fonction.

  Exemple :
     [y, x] = plotmf(fis, 'input', 1);
     max(sum(y, 2))   % somme des appartenances au point le plus couvert

  Voir aussi EVALMF, PLOTFIS, GENSURF.
```

## `poserVariables`

```
POSERVARIABLES Remplace la liste des entrées ou celle des sorties.
```

## `probor`

```
PROBOR Ou probabiliste, ou somme algébrique.
  Y = PROBOR(A,B) vaut A + B - A.*B. C'est la t-conorme associée au
  produit : elle remplace le maximum quand on veut que deux
  activations partielles se renforcent au lieu de s'ignorer.

  Y = PROBOR(X) applique l'opération le long des colonnes de X, ou le
  long d'un vecteur.

  Exemple :
     probor(0.5, 0.5)      % 0.75
     probor([0.5 0.5])     % 0.75

  Voir aussi MAX, MIN, EVALFIS.
```

## `psigmf`

```
PSIGMF Produit de deux sigmoïdes.
  Y = PSIGMF(X,[A1 C1 A2 C2]) = sigmf(X,[A1 C1]) .* sigmf(X,[A2 C2]).
```

## `readfis`

```
READFIS Lit un système d'inférence floue depuis un fichier .fis.
  FIS = READFIS(NOMFICHIER) relit le format texte de MathWorks. Les
  sections inconnues sont ignorées, ce qui rend la lecture tolérante aux
  fichiers écrits par des versions plus récentes.

  Exemple :
     fis = readfis('pilote.fis');

  Voir aussi WRITEFIS, NEWFIS.
```

## `rmmf`

```
RMMF Retire une fonction d'appartenance d'une variable.
  FIS = RMMF(FIS,'input',I,'mf',J) retire la J-ième fonction
  d'appartenance de la I-ième entrée. 'output' fait de même sur une
  sortie.

  Les règles qui s'y référaient sont retirées, et les indices supérieurs
  sont décalés : une règle ne peut pas désigner une fonction disparue.

  Exemple :
     fis = rmmf(fis, 'input', 1, 'mf', 2);

  Voir aussi ADDMF, RMVAR, ADDRULE.
```

## `rmvar`

```
RMVAR Retire une variable d'entrée ou de sortie.
  FIS = RMVAR(FIS,'input',I) retire la I-ième entrée, et avec elle la
  colonne correspondante de la matrice des règles.

  Exemple :
     fis = rmvar(fis, 'input', 2);

  Voir aussi ADDVAR, RMMF.
```

## `setfis`

```
SETFIS Écriture d'un champ d'un système d'inférence floue.
  FIS = SETFIS(FIS,CHAMP,VALEUR) écrit un champ du système : 'name',
  'type', 'andmethod', 'ormethod', 'impmethod', 'aggmethod',
  'defuzzmethod'.
  FIS = SETFIS(FIS,'input',I,CHAMP,VALEUR) écrit 'name' ou 'range'.
  FIS = SETFIS(FIS,'input',I,'mf',J,CHAMP,VALEUR) écrit 'name', 'type'
  ou 'params'.

  Exemple :
     fis = setfis(fis, 'defuzzmethod', 'bisector');
     fis = setfis(fis, 'input', 1, 'mf', 2, 'params', [1 4 7]);

  Voir aussi GETFIS, NEWFIS.
```

## `showrule`

```
SHOWRULE Affiche les règles d'un système flou, en clair.
  SHOWRULE(FIS) écrit toutes les règles ; TEXTE = SHOWRULE(FIS) les
  rend en cellule de chaînes.

  Exemple :
     fis = newfis('essai');
     showrule(fis)
```

## `sigmf`

```
SIGMF Fonction d'appartenance sigmoïde de paramètres [pente centre].
```

## `smf`

```
SMF Fonction d'appartenance en S : croît de 0 à 1.
  C'est le complément de ZMF sur le même intervalle.

  Exemple :  smf(10, [2 8])   % 1
```

## `subclust`

```
SUBCLUST Classification par soustraction, méthode de Chiu.
  C = SUBCLUST(X,RA) cherche les centres de classes sans qu'on ait à
  dire combien. Chaque point reçoit un potentiel, somme des influences
  de tous les autres :

     P(i) = somme_j exp(-4 ||x_i - x_j||^2 / RA^2)

  Le point de potentiel maximal devient un centre ; on retranche alors
  son influence à tous les autres, et on recommence. Un point entouré
  de voisins gagne, un point isolé perd : le nombre de classes sort du
  calcul au lieu d'y entrer.

  [C,S] = SUBCLUST(...) rend aussi les écarts types à donner aux
  fonctions d'appartenance gaussiennes construites autour des centres.

  SUBCLUST(X,RA,BORNES,OPTIONS) où OPTIONS vaut
    [ECRASEMENT ACCEPTATION REJET AFFICHAGE]
  valant par défaut [1.25 0.5 0.15 0]. L'écrasement fixe le rayon de
  soustraction, plus large que le rayon d'influence pour que deux
  centres ne se collent pas.

  Exemple :
     c = subclust([randn(50,2); randn(50,2) + 8], 0.5);

  Voir aussi FCM, GENFIS2.
```

## `sugfis`

```
SUGFIS Système d'inférence floue de Sugeno.
  FIS = SUGFIS crée un système vide nommé « fis ».
  FIS = SUGFIS('Name',NOM) le nomme.

  Chez Sugeno, la conclusion d'une règle n'est pas un ensemble flou mais
  une fonction des entrées, constante ou affine. Il n'y a donc rien à
  défuzzifier : la sortie est la moyenne des conclusions, pondérée par
  les forces d'activation. C'est ce qui rend ces systèmes dérivables, et
  donc apprenables — c'est sur eux que travaille ANFIS.

  Exemple :
     fis = sugfis('Name', 'approximateur');

  Voir aussi MAMFIS, NEWFIS, ANFIS, GENFIS.
```

## `trapmf`

```
TRAPMF Fonction d'appartenance trapézoïdale.
  Y = TRAPMF(X,[A B C D]) monte de zéro en A jusqu'à un en B, reste à
  un jusqu'à C, puis redescend à zéro en D.

  Comme pour TRIMF, les côtés de largeur nulle valent un sur le plateau :
  TRAPMF(X,[0 0 3 5]) est un épaulement gauche, qui vaut un en zéro.

  Exemple :
     trapmf(0:6, [1 2 4 5])   % [0 0 1 1 1 0 0]
     trapmf(0:5, [0 0 2 4])   % [1 1 1 0.5 0 0]

  Voir aussi TRIMF, PIMF, EVALMF.
```

## `trimf`

```
TRIMF Fonction d'appartenance triangulaire.
  Y = TRIMF(X,[A B C]) monte de zéro en A jusqu'à un en B, puis
  redescend à zéro en C.

  Les cas dégénérés comptent : quand A vaut B, la fonction saute à un en
  A et l'appartenance y vaut un, pas zéro — c'est l'épaulement gauche
  dont on se sert pour la modalité extrême d'une variable. De même quand
  B vaut C, à droite.

  Exemple :
     trimf(0:10, [0 5 10])   % [0 .2 .4 .6 .8 1 .8 .6 .4 .2 0]
     trimf(0:5, [0 0 5])     % [1 .8 .6 .4 .2 0]

  Voir aussi TRAPMF, GAUSSMF, EVALMF.
```

## `variablesDe`

```
VARIABLESDE Liste des variables d'entrée ou de sortie d'un système flou.
```

## `writefis`

```
WRITEFIS Écrit un système d'inférence floue dans un fichier .fis.
  WRITEFIS(FIS,NOMFICHIER) écrit le format texte de MathWorks : une
  section [System], une section par variable, et une section [Rules].
  L'extension .fis est ajoutée si elle manque.

  Le format est lisible et se relit par READFIS, ce qui donne un moyen
  simple de conserver un système entre deux sessions.

  Exemple :
     writefis(fis, 'pilote.fis');
     memeFis = readfis('pilote.fis');

  Voir aussi READFIS, NEWFIS.
```

## `zmf`

```
ZMF Fonction d'appartenance en Z : décroît de 1 à 0.
  Y = ZMF(X,[A B]) vaut 1 avant A, 0 après B, avec deux arcs de
  parabole raccordés au milieu — la courbe est donc dérivable.

  Exemple :  zmf(0, [2 8])   % 1
```

