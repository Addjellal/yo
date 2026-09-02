# MatLibre

Un interpréteur libre du langage MATLAB, écrit de zéro en C++17, avec
53 toolboxes écrites dans le langage lui-même.

```bash
make            # compile — aucune dépendance obligatoire
make test       # 57 verifications C++ + 22 suites en langage MATLAB
./build/bin/matlibre
```

```matlab
>> s = tf('s');
>> G = 1 / (s^2 + 2*s + 1)
G =
 
        1
  -------------
  s^2 + 2 s + 1
 
Continuous-time transfer function.

>> A = [4 1; 1 3];
>> A \ [1; 2]
ans =

    0.0909
    0.6364

>> [V, D] = eig(A); diag(D)'
ans =

    2.3820    4.6180

>> G = tf(1, [1 2 1]); step(G); print('reponse.svg');
```

## Ce que c'est

Un interpréteur complet du langage : types, opérateurs avec leurs
priorités documentées, indexation sous toutes ses formes, fonctions et
sous-fonctions, fonctions anonymes avec capture, `classdef` avec
surcharge d'opérateurs, `try/catch` avec les identifiants d'erreur de
MATLAB, `global` et `persistent`, listes séparées par des virgules.

- **636 fonctions natives** en C++ : tableaux, mathématiques, algèbre
  linéaire (LU, QR, Cholesky, SVD, valeurs propres), Fourier (Cooley-Tukey
  et Bluestein, donc exacte pour toute longueur), chaînes, cellules et
  structures, entrées-sorties, graphique, temps, système.
- **1386 fonctions de toolbox** en langage MATLAB, réparties en
  **53 modules** : signal, image, vision, apprentissage profond,
  statistiques, optimisation, automatique, communications, ondelettes,
  logique floue, finance, économétrie, robotique, aérospatial, radar, RF,
  antennes, audio, symbolique, EDP, Simulink, Stateflow, Simscape…
- **Les types de données de MATLAB moderne** : `duration`,
  `calendarDuration`, `datetime`, `categorical`, `table`, `timetable`,
  `containers.Map` et les tableaux creux `sparse`, avec l'indexation par
  `subsref`/`subsasgn`, les jointures, les regroupements et le
  ré-échantillonnage temporel.
- **Du calcul parallèle réel** : `parfor`, `spmd`, `parfeval` et leurs
  compagnons répartissent le travail sur un pool de travailleurs, chacun
  portant son propre interpréteur.
- **Un bureau natif** (`matlibre-bureau`) : une fenêtre Qt, l'éditeur, la
  fenêtre de commandes, l'espace de travail, les figures, le débogueur pas
  à pas et le profileur dans un seul exécutable.
- **Une aide qui ne ment pas** : 621 fonctions ont leur fiche — syntaxe,
  exemples, fonctions voisines —, et chaque exemple qu'elle montre est
  exécuté à chaque passage des tests.
- **Un générateur de code C** : `codegen` traduit scalaires et matrices de
  taille fixe, tous les types entiers avec leur saturation, le produit
  matriciel et le contrôle de flux, en C qui n'alloue rien.
- **Les fichiers MAT** : `save` et `load` écrivent et relisent le format
  de MathWorks — niveaux 4 et 5, compressés ou non, quel que soit l'ordre
  des octets. Le décompresseur DEFLATE est écrit ici même : rien à
  installer, et les fichiers vont dans les deux sens avec MATLAB.
- **Un rendu graphique** en SVG, écrit à la main : courbes, barres,
  nuages, tiges, escaliers, images, sous-graphes, légendes.
- **Aucune dépendance obligatoire.** LAPACK, BLAS et FFTW sont utilisés
  s'ils sont là, uniquement pour aller plus vite.

## Ce que ce n'est pas

MATLAB, ce sont plusieurs milliers de fonctions et un environnement
graphique complet. Ce dépôt en couvre une part utile, pas la totalité :
pas d'éditeur de schéma Simulink (les modèles se décrivent en appelant
`add_block` et `add_line`, mais la simulation est réelle), pas d'App
Designer, génération de code C restreinte aux scalaires et aux matrices de
taille fixe, pas d'objets ni de poignées de fonction dans les fichiers
MAT. La liste complète des écarts est dans
[`documentation/couverture.md`](documentation/couverture.md) — elle vaut
d'être lue avant de s'appuyer sur ce projet.

## Démarrer

```bash
make
./build/bin/matlibre-bureau                         # le bureau : une fenêtre native
./build/bin/matlibre                                # session interactive
./build/bin/matlibre exemples/01-prise-en-main.m
./build/bin/matlibre exemples/03-asservissement.m   # écrit une figure SVG
```

Sous Windows :

```powershell
.\outils\construire.ps1        # Qt est cherche tout seul dans C:\Qt
.\build\bin\matlibre-bureau.exe
```

Si Qt est ailleurs, ou si plusieurs versions cohabitent, indiquez-la :
`.\outils\construire.ps1 -Qt C:\Qt\6.11.1\mingw_64`. Le dossier
attendu est celui du compilateur — `mingw_64` avec MinGW, `msvc2022_64`
avec Visual Studio ; les mélanger ne produit rien de bon. Les DLL de Qt
sont déposées à côté de l'exécutable pendant la compilation, il n'y a donc
rien à ajouter au `PATH`.

**Le bureau** (`matlibre-bureau`) est une application native : un seul
exécutable, une seule fenêtre, l'interpréteur dans le même processus. Rien
à ouvrir dans un navigateur. On y retrouve le bureau de MATLAB — un ruban
à onglets (Accueil, Tracés) dont les groupes portent leur nom, le dossier
courant à gauche — tout ce qu'il contient, avec la taille, le type et une
icône par famille —, l'éditeur à onglets au centre avec coloration, sections
`%%`, indentation automatique et Ctrl-R/Ctrl-T pour commenter, la fenêtre
de commandes en dessous où l'invite vit dans le texte, l'espace de travail
et l'historique à droite. Chaque figure s'ouvre dans sa propre fenêtre,
peinte directement à l'écran, et s'enregistre ou se copie depuis son menu.
Le calcul tourne dans un fil à part : la fenêtre ne se fige pas, même sur
un tracé d'un million de points. Le débogueur est là : un clic dans la
marge pose un point d'arrêt, l'exécution s'y arrête, l'invite passe à
`K>>` — on lit et on modifie les variables sans reprendre —, puis pas à
pas (F10), entrer (F11), sortir (Maj+F11), continuer (Maj+F5). Ctrl+C
interrompt un calcul qui n'en finit pas, comme sous MATLAB. « Exécuter
et chronométrer » (Ctrl+F5) ouvre le profileur : les fonctions classées
par temps, et le code de chacune ligne à ligne avec ses passages. Qt6 est
la seule dépendance, et elle reste facultative — sans Qt, tout le reste se
compile comme avant.

**Les nombres s'affichent entiers.** MatLibre montre par défaut tous les
chiffres que la valeur porte — `pi` s'écrit `3.141592653589793`, un
`single` s'arrête à `3.1415927`, qui est tout ce qu'il porte. C'est le
seul écart d'affichage avec MATLAB, qui démarre en `format short` ;
`format short` le rétablit, `format` seul revient au réglage de départ.

**Quand quelque chose casse**, le message dit où : la fonction qui a
échoué, le fichier et la ligne de chaque appel traversé, avec la ligne de
code elle-même — c'est le rapport de MATLAB, et `err.stack` porte les
mêmes cadres.

```
Error using double
Conversion to double from struct is not possible.

Error in isstable (line 35)
    a = double(a(:)).';

Error in monScript (line 12)
    assert(isstable(modele));
```

**La documentation** vit dans le bureau : `doc nom` — ou F1 sur un mot de
l'éditeur — ouvre le navigateur d'aide, avec la liste des fonctions, la
page mise en forme et des renvois cliquables. Elle marche aussi sur vos
propres fonctions : l'aide est le bloc de commentaires placé sous la ligne
`function`, comme sous MATLAB.

| Exemple | Ce qu'il montre |
|---|---|
| [`01-prise-en-main.m`](exemples/01-prise-en-main.m) | matrices, cellules, structures, chaînes, contrôle de flux |
| [`02-traitement-signal.m`](exemples/02-traitement-signal.m) | Butterworth, filtrage aller-retour, densité spectrale |
| [`03-asservissement.m`](exemples/03-asservissement.m) | fonction de transfert, marges, boucle fermée, schéma-blocs |
| [`04-apprentissage.m`](exemples/04-apprentissage.m) | k-moyennes, ACP, arbre de décision, réseau de neurones |
| [`05-image-et-circuit.m`](exemples/05-image-et-circuit.m) | filtre médian, seuil d'Otsu, contours, circuit RLC |

## Documentation

| Fichier | Contenu |
|---|---|
| [`langage.md`](documentation/langage.md) | ce que l'interpréteur comprend, type par type |
| [`installation.md`](documentation/installation.md) | compiler, installer, empaqueter, gérer les toolboxes |
| [`toolboxes.md`](documentation/toolboxes.md) | les 53 modules et leur correspondance MathWorks |
| [`reference.md`](documentation/reference.md) | les 966 fonctions, avec leur aide — généré |
| [`architecture.md`](documentation/architecture.md) | comment l'interpréteur est bâti |
| [`developpeur.md`](documentation/developpeur.md) | ajouter une fonction, une toolbox, un test |
| [`couverture.md`](documentation/couverture.md) | ce qui manque, dit franchement |
| [`manques.md`](documentation/manques.md) | l'inventaire compare a MATLAB, fonction par fonction — genere |

## Tests

```bash
make test
```

57 vérifications C++ sur le lexeur, l'analyseur, l'indexation, l'algèbre
et les messages d'erreur ; 22 suites en langage MATLAB dont une qui
contrôle **un résultat exact par toolbox** : `blsprice(100,100,0.05,1,0.2)`
doit rendre 10,4506 ; `butter(2,0.2)` les coefficients de la référence ;
`atmosisa(0)` 288,15 K et 101 325 Pa ; l'encodeur convolutif suivi du
décodeur de Viterbi doit restituer le message exact.

## Origine

Rien n'est repris de MathWorks. Les algorithmes viennent de la
littérature publique et les comportements de la documentation publique de
MATLAB, que les tests reproduisent valeur par valeur.

Code sous licence MIT — voir [`LICENSE`](LICENSE).
