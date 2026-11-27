# Venir de MATLAB

Pour qui connaît MATLAB et veut savoir, avant d'y passer une journée, ce
qui l'attend dans MatLibre : ce qui se fait de la même façon, ce qui
diffère et peut surprendre, ce qui manque, et où chercher le reste.
Chaque écart cité ici a été vérifié sur l'interpréteur ; la liste
exhaustive, domaine par domaine, est dans
[`reference-matlab/hors-fonctions.md`](reference-matlab/hors-fonctions.md).

## Les cinq premières minutes

```bash
make                                    # compile ; Qt6, s'il est là, ajoute le bureau
build/bin/matlibre-bureau               # le bureau : ruban, éditeur, commandes, figures
build/bin/matlibre                      # la fenêtre de commandes, dans le terminal
build/bin/matlibre script.m             # exécuter un script, comme « matlab -batch »
build/bin/matlibre -e "disp(pi)"        # une commande
```

Le chemin de recherche contient déjà les toolboxes ; `addpath`, `path`,
`which` et `exist` s'y emploient comme d'habitude, et `--path dossier`
ajoute un dossier dès le lancement. La console rend 0 en cas de succès,
1 sur une erreur du script, 2 sur une option fautive : elle s'emploie
dans un `Makefile` ou une intégration continue. Elle n'écrit ni invite
ni bannière quand son entrée n'est pas un terminal (`echo 'disp(1)' |
matlibre`). Au terminal, la ligne s'édite comme dans la fenêtre de
commandes de MATLAB : ↑ rappelle les commandes qui commencent par ce
qu'on a tapé, gardées d'une session à l'autre ; Tab complète variables,
fonctions, champs et fichiers ; Échap efface la ligne (les touches sont
dans [`langage.md`](langage.md)).

`help nom` répond dans la console, `doc nom` (ou F1 sur un mot de
l'éditeur) ouvre le navigateur d'aide du bureau. Les fiches sont en
français ; vos propres fonctions ont leur aide, le bloc de commentaires
sous la ligne `function`. Une faute de frappe fait proposer la commande
corrigée :

```
>> plott(1:3)
Error: Unrecognized function or variable 'plott'.

Did you mean:
    plot(1:3)
```

Le bureau pose la commande corrigée dans la saisie : Entrée l'exécute.

## Ce qui se fait comme dans MATLAB

- **Le langage** : matrices rangées par colonnes, priorités des
  opérateurs, expansion implicite, indexation (`end`, logique, linéaire,
  chaînes `s.a(2).b{3}`), cellules, structures, chaînes `"..."` et
  `'...'`, fonctions locales et imbriquées, anonymes qui capturent leur
  espace de travail, `try`/`catch` et `MException`, arguments
  `nom=valeur` (R2021a), blocs `arguments`, `classdef` — héritage simple
  et multiple, classes `handle`, méthodes statiques, énumérations,
  paquets `+dossier` —, `parfor`, `spmd` et `parfeval`.
- **L'affichage** : MatLibre démarre en `format short` (`pi` →
  `3.1416`) ; `format long`, `format compact` et `format` seul font ce
  qu'ils font dans MATLAB. Cellules, structures, tableaux d'entiers et
  logiques s'affichent sous leurs en-têtes (« 2×2 cell array »,
  « struct with fields: »).
- **Les erreurs** : les messages et les identifiants des fonctions de
  MATLAB et des toolboxes sont ceux de MATLAB, en anglais
  (`MATLAB:UndefinedFunction`, `Control:analysis:RequiresSISO`) ; un
  `catch` qui teste `e.identifier` se porte tel quel. La pile montre le
  fichier, la ligne et le code de chaque appel traversé.
- **Le hasard** : `rng(0); rand` rend 0.8147 et `randn` 0.5377, comme
  MATLAB (Mersenne Twister, ziggurat) : les exemples à graine se
  reproduisent.
- **Les fichiers** : `.mat` v4, v6 et v7 en lecture et en écriture
  (compressés ou non), CSV, JSON, XML, Parquet, tableurs en texte ;
  `load_system` lit les modèles `.slx` et `.mdl`, `save_system` écrit un
  `.slx`.
- **Simulink par son nom** : `new_system('m')`, `add_block`, `add_line`,
  `set_param`, `get_param`, `find_system`, `sim('m')` — la forme des
  scripts MATLAB — avec les réglages d'un modèle neuf de Simulink
  (solveur automatique à pas variable, sorties en `Dataset`), et `sim`
  qui rend un `Simulink.SimulationOutput`.

## Ce qui diffère, et peut surprendre

| vous écrivez | MATLAB | MatLibre | ce qu'il faut savoir |
|---|---|---|---|
| `m = new_system('m')` | une poignée (un nombre) | une **structure** : le modèle comme valeur | Forme propre à MatLibre : chaque `add_block(m, ...)` rend un nouveau modèle, qu'on reprend (`m = add_block(m, ...)`). Elle part des mêmes réglages que la forme par nom ; dans `sim(m, T)`, `yout` est un tableau. Pour du code qui doit tourner dans MATLAB, écrire `new_system('m')` sans reprendre la sortie. |
| `colormap(parula)` | la palette par défaut | erreur : `parula` n'existe pas | La palette par défaut est **viridis** : les valeurs de parula appartiennent à MathWorks. Les figures n'ont donc pas les couleurs de MATLAB ; les séries de tracés, elles, les ont (bleu `#0072BD`, orange…). |
| `get(h, 'Color')` | `[0 0.4470 0.7410]` | `'#0072BD'` | Les deux formes s'écrivent ; la lecture rend le code hexadécimal, qu'un code qui compare à un triplet doit convertir. |
| `intmax('int64')` | `9223372036854775807` | `9.2234e+18` | Les entiers sont rangés en `double` : `int64` et `uint64` perdent leur dernier chiffre au-delà de 2^53, et s'affichent avec un facteur d'échelle. |
| `[-Inf 1 3 NaN]` | `-Inf 1 3 NaN` | `-Inf 1.0000 3.0000 NaN` | Des entiers mêlés de `Inf` ou `NaN` gardent leurs décimales ; les colonnes sont séparées de trois blancs au lieu de quatre. |
| `num2str([1 2.5])` | `'1         2.5'` | `'  1  2.5'` | Les blancs ne sont pas ceux de MATLAB : comparer des nombres, non leur texte. |
| `zeros(2)(1)`, `zeros(2.7)` | refusés | `0`, puis une matrice 2×2 | MatLibre est plus tolérant ; un code qui marche ici peut être refusé par MATLAB. |
| `imwrite(I, 'a.png')`, `imread('a.jpg')` | PNG, JPEG, TIFF… | refusés | Images en PGM et PPM seulement : PNG et JPEG demanderaient une bibliothèque que MatLibre n'emporte pas. |
| `print('-dpng', ...)`, `savefig` | PNG, PDF, `.fig` | du **SVG** seulement | Une figure s'écrit en SVG (`print('f.svg')`, `saveas`, `savefig`), qu'un navigateur affiche ; `-dpng` et `-dpdf` sont refusés, et `openfig` refuse le format de MathWorks. |
| `webread('…/donnees.csv')` | une table | une matrice | Lire le texte, puis `readtable` sur un fichier, si l'on veut une table. |
| `histogram(x)` | ses bords « ronds » | d'autres bords | Les effectifs automatiques diffèrent pour les mêmes données ; donner `BinEdges` pour comparer. |
| `fclose('all')` dans un `parfor` | ses fichiers seuls | ceux de tous les travailleurs | Les travailleurs sont des fils d'un même processus, non des processus : la table des fichiers ouverts est commune. |
| `f = @sin; save('a.mat', 'f')` | la poignée est rangée | écrite comme un nombre, sans avertissement : `load` rend un `double` | Défaut relevé, non corrigé : ne pas confier de poignée de fonction à un `.mat`. Les chaînes `"..."` reviennent en cellules de caractères ; un objet qu'a écrit MATLAB (MCOS) revient en structure témoin, avec un avertissement ; un `.mat` v7.3 (HDF5) ne se lit pas. |
| Ctrl-C pendant un `svd` de grande taille | interrompt | attend la fin | Ctrl-C coupe entre deux instructions, pas au milieu d'une fonction native longue. |

Et deux différences de fond :

- **La vitesse.** MatLibre interprète l'arbre syntaxique, sans
  compilation à la volée : une instruction scalaire coûte environ une
  demi-microseconde, une boucle est donc plus lente que dans MATLAB. Le
  calcul vectoriel tourne à la vitesse du C++. Vectoriser, la règle de
  MATLAB, est ici plus impérieuse encore. L'algèbre linéaire est écrite
  sans LAPACK : `eig` ou `svd` d'une matrice 300×300 prennent une
  fraction de seconde, là où MATLAB met quelques millisecondes.
- **La langue.** L'aide, l'interface du bureau et les messages propres à
  MatLibre (identifiants `MatLibre:...`) sont en français ; les erreurs
  et avertissements des fonctions de MATLAB, en anglais, comme dans
  MATLAB.

## Ce qui manque

- **Construire une interface** : ni `uicontrol`, ni `uifigure`, ni App
  Designer ou GUIDE, et `uiwait` n'attend pas. Les figures portent des
  tracés ; `input` lit le clavier.
- **Interagir avec une figure** : pas de zoom, de rotation 3D ni de
  curseur de données à la souris (`zoom`, `rotate3d` sont acceptés sans
  effet, `ginput` le dit) ; pas d'éclairage en 3D, et `shading interp`
  donne la moyenne d'une maille au lieu d'un dégradé.
- **Les scripts vivants** (`.mlx`) et les figures `.fig`.
- **Les interfaces externes** : MEX, Java (`usejava('jvm')` rend faux),
  Python, C++.
- **Dans le langage** : les dossiers `private/` ne sont pas reconnus ; les
  attributs d'accès (`Access = private`) sont lus et ignorés ; il n'y a pas
  d'écouteurs (`addlistener`, `notify`) ; ni `schur`, ni `hess`, ni
  `sylvester` ; le cadre de tests à classes `matlab.unittest` n'existe
  pas — `assert`, `runtests` et les scripts de test, oui.
- **Dans Simulink** : les signaux de taille variable, les annotations,
  `Simulink.Mask`, la linéarisation autour d'un point de fonctionnement
  calculé (`operpoint`, `findop`) ; Simscape au-delà des réseaux linéaires
  électriques, mécaniques et thermiques.
- **Dans les toolboxes** : cinquante-quatre modules répondent aux
  toolboxes de MathWorks, mais vingt-neuf d'entre eux n'en sont que des
  esquisses — de deux à neuf fonctions, le rouage central du domaine
  (`toolboxes.md` dit lesquelles).

## Où chercher

| question | où |
|---|---|
| cette fonction existe-t-elle ? | `exist('nom')` ou `which nom` dans la console ; [`manques.md`](manques.md), l'inventaire fonction par fonction face à la liste de MathWorks |
| que fait-elle, avec quelles options ? | `help nom`, `doc nom` ; [`reference.md`](reference.md) et `reference/` |
| en quoi diffère-t-elle de MATLAB ? | sa fiche d'aide le dit ; [`reference-matlab/hors-fonctions.md`](reference-matlab/hors-fonctions.md), domaine par domaine |
| quelle toolbox, sous quel nom ? | [`toolboxes.md`](toolboxes.md) |
| ce que l'interpréteur comprend | [`langage.md`](langage.md) |
| ce qui manque, en grand | [`couverture.md`](couverture.md) |
| ce qui est vérifié, et comment | [`etat.md`](etat.md) |

Les exemples d'école, un par boîte à outils, sont dans
`exemples/toolboxes/` : chacun se lance par `matlibre fichier.m` et
vérifie ce que la théorie prédit.
