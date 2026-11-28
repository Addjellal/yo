# Audit de reprise — 21 et 22 novembre 2026

Fait selon les douze volets de la section 5 de `reprise.md`, à partir du
commit `8228e76` de la branche `claude/matlab-libre-reprise-lgnad9`, sur le
conteneur de développement : quatre cœurs, 15 Go de mémoire, gcc 13.3,
CMake 3.28, Qt 6. Chaque constat dit ce qui a été vu, la preuve, la
gravité, et ce qui a été fait : **corrigé** (avec le commit) ou
**proposé** (avec un coût). Les propositions sont rassemblées, classées,
à la fin (section 14).

Gravité : **haute** — résultat faux silencieux, plantage, perte de
données, faille ; **moyenne** — erreur ou comportement faux mais visible,
écart à MATLAB qui trompe ; **basse** — confort, cosmétique, dette.

## En bref

- **46 commits** : 35 corrigent un défaut du code (dont un piège de
  performance), 6 la construction ou les tests, 1 la documentation, 4
  ajoutent des outils (options ASan/TSan/gcov, deux fuzzeurs,
  `verifierValeurs.m`). Chaque correction porte son test, qui échoue sans
  elle. **La batterie complète passe : 52 tests sur 52** (25 min 29 s).
- **Les défauts graves trouvés** : des résultats faux silencieux
  (`f = @(x) x; f(1,2)` rendait 1 ; `zeros(1e10)` un tableau vide ;
  `-sparse(...)` ne niait rien ; `histcounts` perdait une valeur ;
  `webread` d'un `.txt` rendait `[]` ; `system('exit 3')` rendait 768 ;
  `addpath(genpath(d))` n'ajoutait rien ; un opérande évalué deux fois
  quand un objet est en jeu), une **injection de commande** par l'adresse
  de `webread`, un `tempname` prévisible, **18 courses** entre les fils de
  `parfor` (TSan), une **lecture hors bornes** sur un `.mat` abîmé, un
  lexeur qui **bouclait sans fin** sur un `%{`, **quatorze plantages** de
  fonctions natives, la session arrêtée net par un tableau trop grand, et
  le bureau qui **perdait un onglet modifié** sans demander.
- **Performance** : le chemin s'indexait en temps quadratique ; corrigé,
  la console démarre en 0,03 s au lieu de 0,3, et un `parfor` vide coûte
  0,012 s au lieu de 0,39. Pas d'autre régression au banc ; restent lents
  l'algèbre dense sans LAPACK, `jsondecode` écrit en langage, la boucle
  scalaire, et Simulink interprété bloc par bloc.
- **Rien de faux** sous valgrind (aucune fuite), clang-tidy, l'analyseur
  statique de clang ; 80,8 % des lignes du cœur exercées par les seuls
  tests rapides.
- **Quatre décisions** vous reviennent (D1 à D4 : le solveur par défaut
  des modèles Simulink par valeur, `format short` par défaut, la langue des
  messages, l'invite hors terminal), et **trente-cinq propositions**
  classées (section 14), en tête : vérifier dans la batterie les valeurs
  qu'annoncent les fiches d'aide, « Did you mean », l'intégration
  continue, un guide pour qui vient de MATLAB, l'édition de ligne dans la
  console, une batterie de douze minutes, LAPACK.
- **Ce qui n'a pas pu être fait** : exécuter du code MATLAB téléchargé (le
  garde-fou de la session l'a refusé ; il a été analysé sans être
  exécuté), lire de vrais fichiers de MATLAB (aucun dans le conteneur),
  construire pour Windows (pas de MinGW), passer `test_simulink` et
  `test_aide` sous ASan (deux heures), voir le bureau à la densité 2.

## 1. Construction

**Release.** `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release` puis
`cmake --build build -j4` : 1 min 04 s depuis zéro. Dix lignes
d'avertissement, neuf distinctes, toutes dans les quatre fichiers connus :
`Base.cpp:967` (rétrécissement), `Mat.cpp:187-208` (initialiseur manquant
de `VariableMat::avertissement`, quatre fois), `Math.cpp:1018,1079` et
`Statistiques.cpp:551,555` (quatre fonctions jamais appelées). **Aucun
avertissement nouveau**, ni avant ni après les corrections de l'audit ;
les quatre fonctions mortes retirées (`edd366c`), il ne reste que les
avertissements de `Base.cpp` et `Mat.cpp`.

**Dette mesurée** (arbre à part, rien corrigé) :

| options | avertissements distincts | où |
|---|---:|---|
| `-Wall -Wextra -Wshadow -Wconversion` | 63 | 17 dans le cœur et le rendu (les 9 connus, 5 `-Wshadow` — `Arbre.h:126-127`, `Objets.cpp:686`, `Dessin.cpp:568`, `Espace.cpp:456` —, 3 `-Wconversion` dans `Analyseur.cpp:401-402`), 29 dans `src/bureau`, 17 dans `tests/bureau/test_bureau.cpp` |
| `-Wsign-conversion` en plus, cœur seul | 203 | des `int`/`size_t` mêlés, surtout dans les indices |

La dette est faible : le code convertit déjà explicitement presque
partout. Le seul avertissement qui signale du code mort est
`-Wunused-function` (section 8).

**Défaut corrigé — des accélérateurs liés sans être employés** (moyenne,
`8ac78f1`). CMake cherchait LAPACK, FFTW, SuiteSparse et OpenCV, les liait
et définissait `MATLIBRE_LAPACK`, `MATLIBRE_FFTW`... ; or aucune ligne du
code ne lit ces macros (`grep -rn MATLIBRE_LAPACK src include` : rien).
Sur une machine qui les a, le binaire en dépendait pour rien, et le
paquet `.deb` qui en sortait, ne déclarant que `libc6` et `libstdc++6`,
donnait ailleurs un `matlibre` qui ne démarrait pas, faute de ces
bibliothèques. Six documents promettaient une
accélération qui n'existe pas. Les options sont retirées, les documents
disent vrai ; brancher LAPACK pour de bon est la proposition P5.

**Ajouté** (`fee1955`) : `-DMATLIBRE_ASSAINIR=ON` (ASan et UBSan),
`-DMATLIBRE_ASSAINIR=thread` (TSan), `-DMATLIBRE_COUVERTURE=ON` (gcov),
que la fiche de reprise demandait.

## 2. La batterie

**Référence, avant toute correction** : 49 tests sur 49 en 38 min 48 s
(`ctest -j2`, machine partagée avec deux constructions). Les plus longs :
`test_simulink` 1 562 s, `test_aide` 760 s, `test_exemples` 323 s,
`test_ondelettes` 104 s, `test_domaines` 92 s ; le bureau 34 s.

**Un test instable, corrigé** (`36c2a4e`, `691432a`). « un polygone
blanc garde le contour noir qu'on lui a donne », dans `test_bureau.cpp`,
échouait ou passait d'un binaire à l'autre. Deux causes : la capture
était prise dès que la fenêtre paraissait, avant que le contenu n'arrive
du fil de calcul ; et surtout le contour, un trait d'un pixel, tombe
selon l'alignement au sous-pixel du carré à cheval sur deux colonnes,
lissé en deux pixels gris à moitié (`qGray` ≈ 128) que le seuil de 100
ne comptait pas — la capture enregistrée au moment de l'échec montre le
contour bien peint, 4 pixels sous le seuil sur 200 attendus. Le SVG de la
même figure porte d'ailleurs son contour (`stroke="#000000"`). Le test
attend que le contour soit peint et compte les pixels sous 200 : un
contour absent ou pris sur le fond, le défaut qu'il garde, n'en laisse
toujours aucun.

**Un réglage de test corrigé** (`77270d7`). CTest donnait
`MATLIBRE_TOOLBOX` aux tests en langage, pas au bureau : construit hors
du dépôt, le bureau ne trouvait pas la toolbox et quatre-vingt-quatre
vérifications échouaient pour une raison sans rapport avec elles.

La batterie compte désormais 52 tests : les trois nouveaux vérifient la
ligne de commande (section 10).

## 3. Mémoire et fils

Construits avec les options ajoutées par l'audit (`-DMATLIBRE_ASSAINIR=ON`,
`=thread`), en `RelWithDebInfo`, dans des arbres à part.

**ASan et UBSan.** Une batterie complète sous ASan n'est pas tenable ici :
sans concurrence, ASan multiplie les durées par quatre environ
(`test_differe` : 0,29 s → 1,17 s), et `test_simulink`, 26 minutes en
Release, en demanderait près de deux heures ; machine chargée, le facteur
montait à cinquante. Ont tourné sous ASan et UBSan **30 des 52 tests**
(deux passes partielles puis une sélection : les vérifications C++ et la
ligne de commande, le langage, les classes, les défauts, les graphiques,
les images, les fichiers MAT, les matrices, le numérique, le parallèle,
le texte, les types, l'apprentissage, l'automatique, la finance,
`test_litterature` — qui porte cinq modèles Simulink de la littérature —
et le bureau), plus les 3 039 + 800 textes du fuzzeur, les 360 fichiers
abîmés et les 72 tracés absurdes. **Un seul rapport** : la lecture hors
bornes d'un `.mat` abîmé (section 4). Ni `test_simulink`, ni `test_aide`,
ni les tests de domaine (signal, statistiques, ondelettes...) n'y sont
passés : ce serait le travail d'une nuit d'intégration continue (P6).

Deux artefacts de l'outil, non des défauts : ASan ne sait pas changer une
allocation démesurée en `std::bad_alloc` (il s'arrête sur
« allocation-size-too-big »), d'où l'option `allocator_may_return_null=1`
et le contrôle de taille ajouté en amont (`009856d`) ; et le bureau,
quatre fois plus lent, dépasse sous ASan les délais de 60 s de quatre de
ses 406 vérifications (la simulation des quarante blocs de la
bibliothèque) — sans aucun rapport d'ASan ni d'UBSan.

**TSan.** `test_parallele.m` : passe, aucun avertissement. Un script
d'épreuve écrit pour l'audit — deux `parfor` dont chaque tour ouvre,
écrit, relit et ferme son fichier, appelle `tic`, `toc`, `rng`, `rand`,
`tempname`, `help` et `svd` — donnait **18 avertissements** de course :

| course | où | correction |
|---|---|---|
| la table des fichiers ouverts (`std::map`), sans verrou | `EntreeSortie.cpp:904` | verrou, flux tenus par `shared_ptr` (`2142450`) |
| trois `std::function` communes réécrites à chaque installation de la bibliothèque, pendant qu'un autre travailleur les appelait | `PoigneesGraphiques.cpp:1085-1098`, lues dans `Interpreteur.cpp:992, 2298, 2486` | posées une fois (`00803a4`) |
| l'instant de départ de `tic`, la graine rapportée par `rng`, le chargement des fiches d'aide | `Temps.cpp:28`, `Base.cpp:354`, `Systeme.cpp` | propres au fil, ou sous verrou (`95ee0e8`) |
| le compteur de `tempname` (lu à la relecture, non vu par TSan) | `Systeme.cpp` | nom tiré au hasard sous verrou (`3ab79da`) |

Après : **zéro** avertissement, et chaque travailleur relit bien son
fichier. Un `fclose('all')` dans un travailleur ferme toujours les
fichiers des autres, la table étant commune : MATLAB, dont les
travailleurs sont des processus, n'a pas ce partage (proposition P1, qui
en ferait des travailleurs persistants, est l'occasion de la rendre
propre à chacun).

**valgrind** (memcheck, fuites) sur le corpus de figures, deux modèles
Simulink bâtis et simulés, et `test_texte_es.m` : **aucune erreur, aucune
fuite** (« All heap blocks were freed », 2,3 à 11 millions
d'allocations). À noter pour la performance : deux petites simulations
Simulink font onze millions d'allocations et en brassent 1,7 Go.


## 4. Robustesse

### Un fuzzeur maison

`outils/fuzz/` (`f9f4ef4`) : `fuzzer.py` tire des fichiers `.m` du dépôt
des textes abîmés — tronqués, amputés, doublés, mêlés, parsemés de jetons
ou d'octets changés — et des textes extrêmes ; `analyseSeule.cpp` les
lexe et les analyse sans rien exécuter ; une partie est ensuite exécutée,
chacun dans son processus et un dossier jetable, sous ASan et UBSan.
`fichiersAbimes.py` fait de même avec des fichiers de données. Les
mutations ne fabriquent ni `!` ni appel au système, aux fichiers ou au
réseau.

| passe | textes | défauts |
|---|---:|---|
| analyse, graine 1 | 3 039 | 14 extrêmes : 12 débordements de pile, 1 boucle sans fin |
| analyse, graine 2 (après corrections) | 2 039 | 2 extrêmes sous ASan seulement (corrigés ensuite, `5fbf611`) |
| exécution, graine 2 | 800 | 0 sur les textes mutés ; 4 extrêmes (évaluation récursive, ci-dessous) |
| fichiers abîmés, 30 mutants × 12 formats | 360 | 4 lectures hors bornes (`.mat`), 1 fin brutale (`.parquet`) |

**Corrigé — le lexeur bouclait sans fin sur un `%{` jamais refermé**
(haute, `e0f4725`). Arrivé au bout du texte, il repassait sans fin par la
branche du commentaire de bloc. Un script, une fonction ou un `eval`
contenant un `%{` oublié bloquait la session — console et bureau —, et
Ctrl-C n'y pouvait rien. Preuve : `printf '%%{\nx = 1\n' > f.m;
timeout 10 matlibre f.m` → code 124 ; après, le reste du texte est un
commentaire, comme dans MATLAB.

**Corrigé — les emboîtements démesurés faisaient tomber le programme**
(moyenne, `a665e10`, `5fbf611`). Dix mille parenthèses, crochets,
accolades, `if` ou opérateurs unaires emboîtés débordaient la pile de
l'analyseur récursif (erreur de segmentation, code 139) ; une somme d'un
million de termes débordait le destructeur récursif de l'arbre. L'analyse
s'arrête maintenant sur une erreur de syntaxe au-delà de 256 niveaux —
marge gardée pour la pile d'un mégaoctet du fil principal de Windows et
pour ASan —, et le nœud se détruit par une pile de travail.

**Reste — l'évaluation d'une très longue chaîne est récursive** (basse,
proposition P12). `x = 1+1+…+1` avec cent mille termes, cent mille
transpositions ou `a.b.b.…` tombent dans `Interpreteur::evaluer`, qui
descend l'arbre récursivement (vérifié sous gdb). Dix mille termes
passent. Aucun programme écrit à la main n'y arrive ; du code engendré
(`matlabFunction` d'une grosse expression) le pourrait.

**Corrigé — un `.mat` abîmé faisait lire hors du tampon** (haute,
`b21407e`). Dans la forme courte d'un élément MAT, la longueur
lue (16 bits) n'était pas bornée à 4 octets ; une longueur de 4 096
faisait lire au-delà (rapport d'ASan, `heap-buffer-overflow` dans
`lireNombre`, `FichierMat.cpp:367`). Quatre `.mat` mutés sur trente. La
forme courte annonçant plus de 4 octets est refusée : « Unable to read
the MAT-file: a small data element is longer than 4 bytes ».

**Corrigé — un tableau trop grand arrêtait la session** (haute,
`d5388eb`, `422b8c0`, `009856d`). Une longueur Parquet abîmée demandait
une plage de 2⁶¹ éléments ; plus simplement, `x = 1:1e18` ou
`ones(1e6, 1e6)` levaient `std::bad_alloc`, qu'aucun `try/catch`
n'attrapait : « Erreur interne : std::bad_alloc », code 3, espace de
travail perdu. Une plage trop longue et un tableau plus grand que la
mémoire de la machine sont désormais refusés avant d'être alloués, comme
dans MATLAB (« Requested 50000x50000 (18.6GB) array exceeds maximum
array size preference (15.7GB) ») — sous Linux, une demande à peine plus
grande que la mémoire pouvait sinon être acceptée à crédit, puis la
session tuée en la remplissant ; ce qui échappe à ce contrôle lève
`MATLAB:nomem`, que l'on attrape et après laquelle la session continue.

**Corrigé — une taille non représentable rendait un tableau vide**
(haute, `1f5647c`). `zeros(1e10)` rendait 0×0, `ones(2^31, 1)` 0×1,
`zeros(NaN)` 0×0, sans rien dire : `(int)1e10` est un comportement
indéfini qui vaut `INT_MIN` sur x86, ramené à zéro. Refusé désormais
(`MATLAB:array:SizeLimitExceeded`, `MATLAB:NonIntegerInput`).

### Cas limites

Soixante-douze tracés aux données absurdes (vides, NaN, ±Inf, 1e±308,
échelles logarithmiques de zéro ou de négatifs, `axis([1 1 1 1])`,
`xticks(1:1e5)`, deux cents entrées de légende, `subplot(1e4,1e4,1)`,
épaisseurs infinies, TeX inachevé...) rendus en SVG sous ASan et UBSan :
**aucun rapport**, 63 rendus, 9 refusés par une erreur — la bonne réponse.
`\color[rgb]{2,0,0}` sortait toutefois en vert (`#1FE000`) : composantes
non bornées, écrites sur trois chiffres puis tronquées par `snprintf` ;
corrigé (basse, `9eeb443`).

### Chaque fonction native, des arguments absurdes

`outils/eprouverNatives.sh` : 657 fonctions natives, chacune appelée avec
trente-deux formes d'arguments absurdes (vide, cellule, structure,
poignée, NaN, entiers, tailles négatives...), chaque appel dans son
processus — quelque 21 000 appels, **6 min 29 s** (la fiche annonçait une
demi-heure : le démarrage est désormais dix fois plus rapide, section 5).
**Quatorze plantages**, dans trois fonctions, **corrigés** (haute,
`6ed7eb4`) : `nthroot` lisait les nombres d'une cellule, d'une structure
ou d'une poignée qui n'en ont pas (six formes), `logm` ne contrôlait pas
son argument (sept), `num2cell(@sin, 1)` découpait une poignée comme un
tableau (une).

### Le bureau mis à l'épreuve

Le test du bureau couvre déjà ce que la fiche demandait : un calcul
sans fin coupé par Ctrl-C (l'invite revient, la commande suivante
passe), l'affichage d'un vecteur de dix millions d'éléments, un tracé
d'un million de points, la fenêtre restant vivante pendant ; sous ASan,
aucun rapport. Ce qui manque : le bureau ne surveille pas les fichiers
ouverts. Un script modifié par un autre programme (un `git checkout`)
ou supprimé n'est pas signalé, et l'enregistrer écrase la version du
disque par celle de l'éditeur ; MATLAB propose de recharger (P36). Et
la perte de travail par la croix d'un onglet a été corrigée (section 10).

## 5. Performance

**Le banc** (`outils/banc.m`, vingt-deux mesures, chacune la meilleure
de trois). Ses références datent du 21 novembre, sur un conteneur qui
n'est plus celui-ci : un même binaire varie ici de 40 % d'un passage à
l'autre (`elementaire 1500x1500` : 0,17 à 0,25 s). Pour séparer la
machine du code, le commit de départ `8228e76` a été reconstruit à côté
et les deux binaires passés en alternance sur la même machine : ils sont
au coude à coude (boucle scalaire 0,61 et 0,53 s pour l'un, 0,52 et
0,60 s pour l'autre ; `s.a(k)` 0,010 s des deux côtés ; appels de
fonction un peu plus rapides aujourd'hui). **Aucune régression** ; cette
machine est 1,2 à 1,4 fois plus lente que celle des références, et
aucune mesure n'approche le facteur 3.

**Corrigé — le chemin s'indexait en temps quadratique** (`c16566f`,
`c2199d6`). `callgrind` sur un petit script : 54 % des instructions
passaient dans `reindexerChemin`, au démarrage. Chaque `ajouterChemin`
réindexait tout le chemin, et la toolbox en ajoutait une soixantaine un
à un — quelque mille huit cents parcours de dossier ; chaque travailleur
de `parfor`, `spmd`, `parfeval` et `batch` recevait de même le chemin du
client dossier par dossier, et `addpath(genpath(d))` aussi.

| mesure | avant | après |
|---|---:|---:|
| démarrage de la console | 260-330 ms | 25-28 ms |
| `parfor` de huit tours vides | 0,39 s | 0,012 s |

Le « coût fixe de 0,23 s par `parfor` » que la fiche de reprise
attribuait à la création des fils, et pour lequel elle proposait un pool
persistant, venait surtout de là : P1 perd l'essentiel de son intérêt.
La référence du banc suit (`9e59da4`).

**Où MatLibre reste lent, et pourquoi.**

| quoi | mesure | pourquoi | ce qui l'accélérerait |
|---|---|---|---|
| une instruction scalaire | 0,5 µs le tour de `s = s + k*0.5` | parcours d'arbre ; un quart du temps en `malloc`/`free` : chaque scalaire est une `Valeur` qui alloue ses dimensions et son tampon (`callgrind`) | un scalaire sans allocation (dimensions et valeur logées dans la `Valeur`) — P13 ; puis du bytecode — P37 |
| `eig`, `svd` 300×300 | 0,33 et 0,59 s | Jacobi et QR écrits à la main, sans blocs ni BLAS | LAPACK facultatif — P5 |
| `jsondecode` de 4 000 nombres | 0,54 s (le texte se bâtit en 14 ms, `jsonencode` en 66 ms) | écrit en langage MATLAB (`toolbox/matlab/jsondecode.m`, 245 lignes) : l'analyse caractère par caractère passe par l'interpréteur | un `jsondecode` natif, les tests actuels gardés — P11 |
| `sim` d'un modèle à 4 blocs | 0,22 s pour 10 s simulées, 275 pas d'ode45 | un quart à compiler le schéma, le reste dans `passe`, l'évaluation interprétée du schéma bloc par bloc (1 935 passes, 0,17 ms chacune) ; onze millions d'allocations pour deux petites simulations (`valgrind`) | exécuter le programme que `MATLIBRE_SL_PROGRAMME` sait déjà engendrer, au bit près, au lieu de répartir bloc par bloc — P38 |

**La durée de la batterie** : 25 min 29 s (`-j3`) à 38 min 48 s (`-j2`,
machine partagée), bornée par `test_simulink` (1 529 à 1 562 s), puis
`test_aide` (760 s) et `test_exemples` (323 s). ctest lance d'abord les
plus longs, si bien qu'au-delà de trois cœurs rien ne se gagne tant que
`test_simulink` reste d'un bloc. Le découper en quatre fichiers
(catalogue, solveurs, Simscape, éditeur et fichiers) et `test_aide` en
deux ramènerait la batterie à une douzaine de minutes sur quatre cœurs,
sans rien retirer — P9.

## 6. Conflits

**Avec `main`.** `git rev-list --left-right --count origin/main...HEAD` :
0 commit de retard, 32 d'avance au début de l'audit ; `git merge-tree
--write-tree origin/main HEAD` fusionne sans conflit. Rien à faire.

**Entre noms.** `outils/verifierDoublons.m` : aucun doublon sur 3 144
fichiers, aucun masquage d'une fonction native. Un reste a été trouvé à
la main : `toolbox/maToolbox/Contents.m` (« % Ma toolbox », une ligne),
entré dans le dépôt avec `c11bb29`, trace d'un essai de
`matlab.addons.toolbox.installToolbox` ; il apparaissait dans
`matlab.addons.installedAddons` et faussait le compte des modules.
Retiré (basse, `fc907fc`). Voisin : `test_ecosysteme.m` installe sa boîte
d'essai *dans* `toolbox/` et la retire ensuite ; interrompu au milieu, il
laisserait un reste semblable, et il échouerait sur une installation en
lecture seule (`/usr/share/matlibre`). Proposition P20.

**Entre comportements — le solveur d'un modèle Simulink selon la façon
de le créer (à trancher, D1).** Mesure : le même schéma, un sinus intégré
sur dix secondes, bâti des deux façons.

| création | solveur de départ | instants | écart à 1 − cos t |
|---|---|---:|---:|
| `m = new_system('m')` (par valeur, propre à MatLibre) | `ode1`, pas de 0,01 | 1 001 | 5,0·10⁻³ |
| `new_system('m')` (par nom, la forme de MATLAB) | `VariableStepAuto` | 56 | 5,2·10⁻¹⁰ |

L'aide de `new_system` le dit, mais un utilisateur qui écrit
`sim(m, 10)` obtient sans avertissement un résultat cinq millions de
fois moins précis selon la forme qu'il a prise. Trois issues :

1. **la forme par valeur part aussi en `VariableStepAuto`**, sa sortie
   restant un tableau (recommandé) : précis par défaut ; mais les tests et
   exemples qui supposaient implicitement `ode1` au pas de 0,01 changent
   de résultat, et il faudra les reprendre un à un (coût : une à deux
   sessions, le temps de repasser `test_simulink` jusqu'au vert) ;
2. elle passe entièrement aux réglages de Simulink, sortie en `Dataset`
   comprise : la fidélité complète, mais tout ce qui lit `r.yout` comme
   un tableau casse ;
3. on garde l'écart, et `sim` avertit une fois par session quand un modèle
   par valeur tourne sur le solveur par défaut.

C'est un comportement visible : il n'a pas été changé.

## 7. Fidélité à MATLAB

### Du vrai code

L'exécution de code téléchargé a été refusée par le garde-fou de la
session ; le code réel a donc été **analysé sans être exécuté** :
`TheAlgorithms/MATLAB-Octave` (licence MIT, 128 fichiers, rien n'en est
repris dans le dépôt) passé dans `analyseSeule`. Deux fichiers refusés :

- `algorithms/machine_learning/Nearest-Neighbor/brightness.m` emploie
  `endfunction`, qui est de l'Octave : MATLAB le refuse aussi ;
- `algorithms/sorting/heap_sort.m`, du MATLAB valide, ne s'analysait pas :
  **défaut corrigé** (moyenne, `9586db1`). Une fonction imbriquée écrite
  au milieu du corps de sa parente, le corps reprenant après elle, tombait
  sur « Unexpected token 'count' at file level ». Le corps reprend
  désormais après chaque fonction imbriquée, qui voit l'espace de travail
  au moment de l'appel (`imbriqueeAuMilieu.m` rend 22).

L'exécution, elle, a été confrontée sur des programmes écrits pour
l'audit d'après le comportement documenté de MATLAB.

### Résultats faux trouvés et corrigés

| entrée | MatLibre avant | MATLAB | gravité | commit |
|---|---|---|---|---|
| `f = @(x) x; f(1,2)` | `1` | erreur *Too many input arguments* | haute | `fdebfde` |
| `num2str(pi)` | `'3.142'` | `'3.1416'` (exemple de la documentation) | moyenne | `f11c80b` |
| `sprintf('%d', 3.5)` | `'3.5'` | `'3.500000e+00'` | basse | `97bff07` |
| `sprintf('%d', 1e20)` | `'-9223372036854775808'` | `'100000000000000000000'` | moyenne | `97bff07` |
| `f() + objet` | `f` appelée deux fois | une fois | haute | `3a3e428` |
| `-objet` sans `uminus`, `-{1}`, `-@sin`, `~struct()` | l'opérande, ou un logique | erreur | moyenne | `1c26355` |
| `-sparse([1 0 2])` | `[1 0 2]` | `[-1 0 -2]` | haute | `498353d` |
| `zeros(1e10)`, `ones(2^31,1)` | 0×0, 0×1 | erreur | haute | `1f5647c` |
| `system('exit 3')` | `768` | `3` | moyenne | `a8b2305` |
| `webread('…/lisezmoi.txt')` | `[]` | le texte | haute | `ae8c878` |
| `sin()` | *… to 'fnSin'* (nom C++) | *Not enough input arguments.* | basse | `c6e108a` |

`f = @(x) x; f(1,2)` rendait 1 : l'argument en trop passait sans rien
dire, ce qui transformait une faute de programme en résultat. Un test de
`test_defauts.m` appelait d'ailleurs des poignées à deux paramètres avec
trois arguments, et se rabattait sur un seul en cas d'erreur : il
encodait le comportement faux et a été corrigé avec.

### Écarts relevés, non corrigés

| entrée | MatLibre | MATLAB | proposition |
|---|---|---|---|
| `zeros(2)(1)` | `0` | refusé (indexation chaînée d'un appel) | P23 |
| `[-Inf 1 3 NaN]` en `format short` | `-Inf 1.0000 3.0000 NaN` | `-Inf 1 3 NaN` (entiers) | P22 |
| `[2.382 4.618]` en `format short` | trois blancs entre colonnes | quatre | P22 |
| `num2str([1 2.5])` | `'  1  2.5'` (blancs de tête) | `'1         2.5'` | P22 |
| `webread` d'un `.csv` | matrice | table | P21 |
| `zeros(2.7)` | 2×2 | erreur *Size inputs must be integers* | P23 |
| format par défaut | tous les chiffres (`pi` → `3.141592653589793`) | `format short` | D2 |
| `f = @(x,y) x; f(1)` | *Unrecognized … 'y'* à l'usage | *Not enough input arguments* | P23 |

### Les références indépendantes

Les cas de la littérature (`test_litterature.m`, 49 boîtes) ont déjà été
confrontés à NumPy, SciPy, statsmodels, scikit-learn et ngspice lors des
sessions précédentes ; l'audit ne les a pas refaits. Les `.mat` relus ici
sont ceux qu'écrit MatLibre (v4, v6, v7) : faute de fichiers produits par
MATLAB dans le conteneur, la lecture de vrais `.mat` v5/v7 et `.slx` de
MathWorks n'a pas été éprouvée dans cet audit (proposition P19).

## 8. Logiciel

**Relecture des ajouts récents.** `Tampon.h` (copie sur écriture) est
juste : toute écriture détache un tampon partagé, le drapeau `seul_` ne
peut que retarder un détachement, jamais en manquer un ; le seul point
fin est la lecture relâchée de `use_count()` entre deux fils, sans effet
ici puisque chaque travailleur détache avant d'écrire. `Aleatoire.cpp`
suit Mersenne Twister et le ziggurat de Marsaglia et Tsang. `Tex.cpp` :
une couleur `\color[rgb]` non bornée (corrigé, `9eeb443`) ; la descente
dans les accolades est récursive, mais un titre n'en emboîte pas mille.
`Dessin.cpp`, `Espace.cpp` : rien de faux trouvé ; leurs cas limites ont
été éprouvés sous ASan (section 4).

**En relisant l'interpréteur**, trois défauts de plus, corrigés : les
opérandes évalués deux fois quand un objet est en jeu (`3a3e428`), les
opérateurs unaires qui rendaient leur opérande sur une cellule, une
structure ou un objet sans méthode (`1c26355`), le moins unaire d'un
creux qui ne niait rien (`498353d`). Et dans le bureau, la coche
« Afficher le ruban » qui disait l'inverse de l'état du ruban
(`5509759`).

**clang-tidy** (familles `bugprone`, `performance`, analyseur statique
de clang) sur `Tex.cpp`, `Espace.cpp`, `Dessin.cpp`, `ToileSVG.cpp`,
`Graphique.cpp`, `Aleatoire.cpp`, puis l'analyseur statique sur tout
`src/coeur` (3 min 12 s) : **aucun défaut réel**. Neuf remarques sur le
rendu (quatre divisions entières qui centrent un titre au demi-pixel
près, trois arrondis `(int)(x + 0.5)` de valeurs positives, une
énumération qui tiendrait sur un octet, un `reserve(256 * 3)`), douze
sur le cœur, toutes des faux positifs (un pointeur nul que le chemin ne
peut pas atteindre, un `va_list` bien copié) ou anodines (une
affectation morte dans `Affichage.cpp:116`).

**Couverture** (gcov, arbre `-DMATLIBRE_COUVERTURE=ON`, sur les tests
rapides : vingt-trois scripts et les vérifications C++ — tout sauf
Simulink, l'aide, les exemples et la plupart des tests par domaine) :
**80,8 %** des 28 425 lignes de `src/coeur`, `src/bibliotheque` et
`src/graphique`. L'analyseur (88 %), l'interpréteur (87 %), l'indexation
(88 %), l'algèbre linéaire (93 %), le rendu plan et en perspective (82 et
92 %) sont bien exercés. Les moins couverts : `Tests.cpp` (13 %,
`runtests` et les `assert*` du cadre de tests), `Compression.cpp` (44 %,
le DEFLATE des `.mat` v7), `Creuses.cpp` (48 %) et `Creux.cpp` (64 %),
les matrices creuses — c'est là que l'audit a trouvé le moins unaire qui
ne niait rien —, `Cartes.cpp` (57 %, `containers.Map`). `Statistiques.cpp`
et `Math.cpp` (58 et 64 %) le sont davantage par les tests de domaine,
écartés de cette mesure. (`Communs.cpp`, modifié après l'instrumentation,
sort à 0 % : ses compteurs ne correspondent plus, ce n'est pas une
mesure.) Une mesure de la batterie entière, une heure et demie en `-O0`,
irait dans l'intégration continue de nuit : P35.

**Code mort.** Quatre fonctions jamais appelées, que gcc signale depuis
longtemps : `betaIncompleteRegularisee` et `gammaIncompleteRegularisee`
(`Math.cpp:1029, 1090`), `normcdfFn` et `erfinvLocal`
(`Statistiques.cpp:551, 555`) — retirées (`edd366c`) : la construction
Release ne garde que les avertissements de `Base.cpp` et `Mat.cpp`.

**Fichiers trop gros.** Côté C++ : `TracesGraphiques.cpp` (3 076 lignes),
`Interpreteur.cpp` (2 633), `GenerationC.cpp` (1 886). Côté langage :
`matlibre_sl_compiler.m` (7 187 lignes) et `matlibre_sl_executer.m`
(5 547), le cœur de Simulink ; et `tests/scripts/test_simulink.m`
(15 068 lignes, 26 minutes), qui borne à lui seul la durée de la
batterie. Les découper est la proposition P9 (le test) et P27 (le code) ;
c'est un remaniement de gros fichiers, à décider.

**Architecture.** Deux faiblesses de fond sont ressorties de l'audit,
toutes deux liées aux fils : l'état global du processus (table des
fichiers, crochets, chargements paresseux) que partagent des
interpréteurs censés être indépendants — corrigé là où TSan l'a vu,
mais le motif reste à surveiller —, et l'évaluation récursive, dont la
profondeur dépend de la pile du fil (8 Mo sous Linux, 1 Mo pour le fil
principal sous Windows, souvent 8 Mo pour les fils de `parfor` selon le
système). Faire tourner chaque interpréteur sur un fil à pile explicite
(64 Mo, par exemple) réglerait d'un coup la récursion profonde et
l'écart entre systèmes (proposition P12).

## 9. Design

### Les figures

Douze figures variées (courbes et légende, barres groupées, `imagesc`
avec barre de couleurs, `contourf`, quatre sous-figures, `surf` en
perspective, titres et étiquettes en TeX, `step`, `bode`, `semilogy`,
camembert, `yyaxis`) écrites par `matlibre_svg`, rendues en PNG par
`outils/capturer.js` à densité 2, et regardées une à une.

L'ensemble est sobre et proche de MATLAB depuis R2014b : police
Helvetica, couleurs des séries de MATLAB (bleu, orange…), grille gris
clair, légende encadrée, titres gras, graduations rondes, perspective
juste, TeX rendu (`\omega_0`, `e^{-\alpha t}`). Défauts trouvés :

- **corrigé — l'histogramme était illisible** (moyenne, `1b14422`) : une
  graduation par bord de classe, en pleine précision, qui se
  chevauchaient (« -2.73232-2138… »), héritée de la règle « une
  graduation par barre » de `bar` ;
- **corrigé — `pie(X, étiquettes)`**, forme documentée de MATLAB,
  échouait (`6bafcd1`) ;
- les marqueurs posés sur la limite d'un axe sont coupés à moitié (le
  dernier point d'un `stem` à `y = 10`, ceux d'un `scatter` à `y = 1`) ;
  MATLAB les dessine entiers (P28) ;
- les bords de classes d'un histogramme ne sont pas ceux de MATLAB, qui
  choisit une largeur « ronde » alignée sur ses multiples : les effectifs
  diffèrent pour les mêmes données (P29) ;
- en perspective, les deux « 0 » des axes x et y se chevauchent au coin
  de la boîte (basse) ;
- la palette par défaut est viridis, non parula — choix documenté
  (`hors-fonctions.md`) ; mais `colormap(parula)` ne « le dit » pas,
  comme l'annonce ce document : on lit l'erreur générique « Unrecognized
  function or variable 'parula' » (P30) ;
- les titres de `bode`, `step`... sont en français (« Diagramme de
  Bode », « Pulsation (rad/s) ») là où MATLAB écrit « Bode Diagram »,
  « Frequency (rad/s) » : un choix, qui relève de D3.

### L'application de bureau

Captures hors écran (`MATLIBRE_CAPTURE`) de la fenêtre principale, de
l'aide, de l'éditeur Simulink et du profileur. La fenêtre est claire et
fidèle à la disposition de MATLAB — ruban à onglets et groupes nommés,
dossier courant à gauche, éditeur et fenêtre de commandes au centre,
espace de travail, points d'arrêt et historique à droite ; l'aide met en
page syntaxes, exemples et renvois cliquables ; l'éditeur Simulink
route ses fils à angle droit, boucle de retour comprise. Frictions :

- l'espace de travail coupe `<40×60 double>` sur deux lignes, et sa
  colonne « Classe » déborde du panneau à sa largeur par défaut (P31) ;
- deux scripts neufs s'appellent tous deux « sans-titre.m » ; MATLAB
  numérote (`Untitled`, `Untitled2`) (P31) ;
- la bibliothèque de blocs de l'éditeur Simulink montre les
  identifiants internes (`repeatingsequenceinterpolated`,
  `complextomagnitudeangle`) au lieu des noms de Simulink
  (« Repeating Sequence Interpolated ») qu'un utilisateur de MATLAB
  cherche ; sa colonne de description est tronquée (P32) ;
- **pas de thème sombre** : la palette claire est imposée (pour que
  Windows ne panache pas la fenêtre), quel que soit le thème du système ;
  MATLAB en a un depuis R2025a (P33) ;
- **haute densité** : avec `QT_SCALE_FACTOR=2`, les 409 vérifications du
  bureau passent, celles qui exigent qu'aucun libellé du ruban ne soit
  rogné comprises, et les icônes sont dessinées à la volée, donc nettes à
  toute densité ; mais la capture du test peint dans une image de taille
  fixe à densité 1, si bien que le rendu réel à densité 2 n'a pas été vu
  (P31 : une capture à la densité de l'écran) ;
- **accessibilité** : les menus ont leurs accélérateurs (`&Fichier`...),
  les actions leurs raccourcis (F5, F10, F11, Ctrl+C, Ctrl+E) ; le texte
  (#222 sur blanc) est très contrasté ; mais la toile des figures et
  celle de Simulink sont dessinées à la main, sans nom accessible ni
  navigation au clavier entre les blocs : un lecteur d'écran n'en dit
  rien (P34).

## 10. Ergonomie

Parcouru à la place de trois personnes : l'utilisateur de MATLAB qui
change d'outil, l'étudiant qui découvre, l'ingénieur qui lance des scripts
en ligne de commande.

### La ligne de commande

**Corrigé — `-q` annoncé, jamais lu** (moyenne, `81ee733`). `matlibre
--help` annonçait `-q, --quiet` ; l'option était prise pour un nom de
script (« Unable to open file '-q' », code 1). `--help` et `--version`
n'étaient reconnus qu'en premier, `--path` seulement avant tout le reste,
et une option inconnue était ouverte comme un fichier. Les options se
lisent maintenant dans n'importe quel ordre jusqu'au script ; `--path=D`
et `--` sont acceptés ; une option inconnue ou `--path` sans dossier sont
refusés avec le code 2 ; `--help` et `--version` répondent sans charger
la bibliothèque (6 ms). Trois tests CTest.

**Corrigé — `system`** (moyenne, `a8b2305`). Voir section 12.

**Les codes de retour** : 0 en succès, 1 sur une erreur du script ou de
`-e`, 2 sur une option fautive, 130 sur Ctrl-C ; 3 (« Erreur interne »)
ne sort plus sur un manque de mémoire (section 4).

**Frictions, non corrigées :**

- **pas d'édition de ligne** dans la console : elle lit par
  `std::getline`, si bien que les flèches écrivent `^[[A`, qu'il n'y a ni
  historique rappelable ni complétion — ce que le bureau, lui, offre.
  C'est la friction la plus forte pour l'ingénieur en terminal (P3) ;
- l'invite `>>` est écrite même quand l'entrée n'est pas un terminal :
  `echo 'disp(1)' | matlibre -q` donne `>>      1` puis `>>` ; un journal
  s'en trouve sali (décision D4) ;
- pas de « Did you mean: plot? » sur une faute de frappe (`plt(1:3)` →
  « Unrecognized function or variable 'plt'. ») (P4 — **fait** : la
  console et le bureau proposent la commande corrigée, le bureau la pose
  dans la saisie, Entrée l'exécute) ;
- le premier cadre d'une pile d'erreur ne montre pas sa ligne de code (le
  second, si) ; MATLAB les montre toutes (P24).

### Les messages

Les messages repris de MATLAB sont en anglais, ceux propres à MatLibre en
français, et le mélange se voit dans un même domaine : `figure('Position',
[0 0 0 0])` répond « Position must have positive width and height. »,
`scatter(1,1,0)` « La taille des marqueurs doit être positive. ». La
règle du dépôt (identifiants de MATLAB, textes en français pour ce qui est
propre à MatLibre) est tenable, mais elle mérite d'être tranchée pour les
messages d'*erreur d'usage* d'une fonction de MATLAB : D3.

**Corrigé** : `sin()` répondait « Not enough input arguments to 'fnSin' »
(le nom C++, trente-trois fonctions, `c6e108a`).

### Le bureau

**Corrigé — trois façons de perdre son travail** (haute, `2f8629b`) : la
croix d'un onglet modifié le supprimait sans rien demander ; à la
fermeture, « Enregistrer » suivi d'une annulation de « Enregistrer sous »
fermait quand même ; un enregistrement qui échouait (disque plein)
laissait le document marqué enregistré. Vérifié dans `test_bureau.cpp`
(« Annuler » garde l'onglet, « Ne pas enregistrer » le ferme).

Et la coche « Afficher le ruban », qui disait l'inverse de l'état du
ruban (`5509759`). Les frictions de présentation sont à la section 9.

### La rapidité ressentie

| geste | durée |
|---|---:|
| `matlibre --version` | 6 ms |
| démarrage de la console (`matlibre -e "1;"`) | 0,17 s |
| premier tracé écrit en SVG | rien de mesurable au-delà du démarrage |
| `tf`, `step` et `print` | idem |
| deux modèles Simulink bâtis et simulés | 0,76 s |

Ctrl-C interrompt entre deux instructions ; une fonction native longue
(`svd` d'une grande matrice, un `sort` de dix millions) ne s'interrompt
pas avant d'avoir fini (P25).

## 11. Documentation

**Corrigé — le README disait faux** (moyenne, `3119404`) : « pas
d'éditeur de schéma Simulink » alors que le bureau pose, câble, règle et
simule ; un exemple montrant `A\b` en `format short` quand MatLibre
affiche tous les chiffres par défaut ; 53 toolboxes pour 54 modules, 57
vérifications C++ pour 78. **Corrigé** aussi : `installation.md`,
`developpeur.md`, `architecture.md` et l'en-tête d'`AlgebreLineaire.h`
promettaient LAPACK, FFTW, SuiteSparse et OpenCV (`8ac78f1`) ;
`installation.md` décrivait une intégration continue qui n'a jamais
tourné (section 12).

**Les fiches d'aide** sont bonnes : syntaxes, exemples parlants, valeurs
annoncées en commentaire, « Voir aussi ». Mais **rien ne vérifie les
valeurs qu'elles annoncent** : `test_aide.m` exécute les exemples sans
lire leurs commentaires. La fiche de `num2str` annonçait `'3.1416'`
quand la fonction rendait `'3.142'`. 2 102 lignes d'exemple annoncent
ainsi une valeur. `outils/verifierValeurs.m` (nouveau) les compare :
premier passage, 33 s, **1 417 valeurs comparées, 34 écarts** :

| verdict | fiches |
|---|---|
| **défaut du code, corrigé** | `histcounts` : avec des bords automatiques, le dernier bord manquait le maximum d'un ulp, et une valeur sur mille n'était pas comptée une fois sur deux (`6119492`) |
| écart à MATLAB, à vérifier (P2) | `biorwavf('bior2.2')` complète le filtre de reconstruction par des zéros à droite (`[0.25 0.5 0.25 0 0]`) là où MATLAB le centre ; `risetime([0 0 0.5 1 1],1)` rend 1,584, les niveaux estimés n'étant pas exactement 0 et 1 (1,6 attendu) ; `disparityBM` rend 2 au lieu de 3 |
| valeur annoncée fausse | `resample` (150 et non 149 : ⌈100·3/2⌉), `regionprops` (5 : `bwlabel` connecte en 8 par défaut, comme MATLAB), `deprdv` (3 600 = 10 000 − 1 000 − 5 400), `wpcoef` (18, la longueur de l'extension symétrique par défaut), `gfweight(hammgen(3))` (4 : une matrice de contrôle lue comme génératrice ; il fallait `'par'`), `addrule` (`numel` d'une matrice de règles 2×4), `imwrite` (`magic(8)*4` atteint 256, qui ne tient pas dans un `uint8`), `symsubs` et `poly2sym`, `hessian`, `symstr` (MatLibre écrit `2*y`, comme MATLAB), `envelope` (`>=` strict sur des égalités à 5·10⁻¹⁴) |
| valeur annoncée trop arrondie | les maxima des fenêtres (`blackmanharris`, `flattopwin`, `nuttallwin` : « 1 »), `allmargin`, `dbm2w`, `directivity`, `fvfix`, `pvfix`, `lin2rgb`, `mel2hz`, `mpcsim`, `sigma`, `wpfun`, `poisscdf` |
| commentaire mal lu par l'outil | `addVoltageSource` (« 0,01 A », virgule décimale), `surfnorm` |

**C'est fait (P2)** : les 34 fiches sont corrigées — trois écarts
venaient du code, corrigés avec leur test (`c2d` et `d2c` faux dès que
A est singulière, les marges d'`allmargin` interpolées sur une grille,
les zéros de `biorwavf` non centrés) —, l'outil compare désormais 1 424
valeurs, sans faux « exemple qui ne tourne pas », et tourne dans la
batterie (test `aide_valeurs`, 22 s), qui échoue au premier écart.

Étendu ensuite aux tableaux annoncés (`[1 0.5; 2 3]`, chaque élément à
sa précision ; une matrice doit avoir la forme annoncée, un vecteur se
compare dans l'ordre), l'outil compare 1 730 valeurs et en a trouvé six
de plus, dont deux défauts du code : **`normalize`** était une native
qui ignorait toutes ses options (`'range'`, `'norm'`, `'scale'`,
`'center'`, la dimension) et réduisait le tableau entier au lieu de
chaque colonne — réécrite en `.m`, avec les méthodes, les sorties `C` et
`S` et les NaN de MATLAB ; **`fillmissing`** prolongeait les bouts par
la valeur la plus proche quelle que soit la méthode, si bien que
`'previous'` comblait un NaN de tête et que `'linear'` n'extrapolait pas
— les bouts suivent désormais la méthode, comme le défaut `'extrap'` de
MATLAB, et la deuxième sortie ne marque plus les positions restées
vides. Les quatre autres étaient des fiches : `imhmax` (une hauteur
supérieure au sommet abaisse toute l'image, comme dans MATLAB),
`jcitest` (exemple sans `rng`), `rgb2lab` et `whitepoint` (le D65 est
ici la somme des lignes de la matrice sRGB, 0,95047, là où MATLAB
documente 0,9504 ; la fiche le dit).

**Ce qui manque** : un guide de démarrage pour qui vient de MATLAB (ce
qui diffère — l'affichage long par défaut, la forme par valeur des
modèles Simulink, les formats d'image —, ce qui manque, où chercher) ;
`couverture.md`, `manques.md` et `hors-fonctions.md` ont l'information,
dispersée et longue (P7). Le vocabulaire flotte entre « toolbox »,
« boîte à outils » et « module » pour la même chose (P26).

## 12. Distribution et maintenance

**Construire depuis zéro**, en suivant `installation.md` : avec Qt,
1 min 04 s (quatre cœurs) ; sans Qt (`-DMATLIBRE_BUREAU=OFF`), 1 min 35 s
sur deux cœurs, `matlibre` et `matlibre_tests` seulement, aucun message
trompeur à la configuration depuis `8ac78f1`. `cmake --install` dans un
préfixe jetable pose 3 368 fichiers (24 Mo) : `bin/matlibre`,
`share/matlibre/` (la toolbox et ses fiches), `share/doc/MatLibre/`.
L'installé, lancé d'un autre dossier sans `MATLIBRE_TOOLBOX`, trouve sa
toolbox dans `../share/matlibre`, répond à `help`, `tf`, `ode45`. Il n'y
a pas de désinstallation : `xargs rm < build/install_manifest.txt` retire
les fichiers et laisse les dossiers vides (P8). Et
`matlab.addons.toolbox.installToolbox` écrit dans cette racine
installée, qui sous `/usr/local` n'est pas accessible en écriture sans
droits d'administrateur (P20). La construction pour Windows (MinGW) n'a
pas pu être éprouvée : la chaîne n'est pas dans le conteneur.

**L'intégration continue n'a jamais tourné.** `installation.md` décrivait
`.github/workflows/construire.yml` (Ubuntu, macOS, Windows, archives) ;
le fichier existe, mais rangé dans `matlab-libre/.github/`, alors que
GitHub ne lit que le `.github/workflows` de la racine du dépôt. Le
document dit désormais vrai (`8ac78f1`). L'ensemble proposé (P6) :
à la racine, `matlab-libre-rapide.yml` à chaque poussée qui touche
`matlab-libre/**` — construction Release sous Ubuntu avec Qt, les tests
C++, la ligne de commande, le bureau hors écran et les scripts de moins
d'une minute (une dizaine de minutes) — et `matlab-libre-nuit.yml`
chaque nuit — la batterie complète, la construction sans Qt, macOS et
Windows (MinGW), ASan sur la sélection de la section 3, l'outil
`verifierValeurs.m`. Le fichier inerte est à retirer.

**Journal des versions et guide de contribution** : il n'y a ni
`CHANGELOG.md` ni `CONTRIBUTING.md`. `developpeur.md` et la section 1 de
`reprise.md` tiennent lieu du second, mais hors de la vue d'un
contributeur qui arrive par GitHub ; la version annoncée est 0.1.0
depuis le début (P8).

**Ce qui touche au système, au réseau et aux fichiers.**

| fonction | constat | gravité | suite |
|---|---|---|---|
| `system`, `unix`, `dos` | code de retour faux (×256), sortie perdue pour une suite de commandes, fichier temporaire au nom fixe partagé entre sessions et vulnérable à un lien symbolique | haute | corrigé, `a8b2305` (tube) |
| `webread`, `websave`, `webwrite` | arguments de `curl` entre guillemets doubles : `$(...)` exécuté, `$` d'un mot de passe amputé, méthode non citée | haute | corrigé, `3ca072e` (apostrophes) |
| idem | le mot de passe passe en clair sur la ligne de commande de `curl`, visible par `ps` de tout utilisateur de la machine | moyenne | P15 (un fichier de configuration `curl -K` aux droits 0600, ou l'entrée standard) |
| `tempname` | nom prévisible (`matlibre_<pid>_<n>`) dans `/tmp`, compteur sans verrou, dossier ignoré | haute | corrigé, `3ab79da` |
| `webread` d'un `.txt` | contenu perdu (`[]`) | haute | corrigé, `ae8c878` |
| `imwrite` | écrivait un PGM sous un nom `.png` | moyenne | corrigé, `c8154d0` |
| `test_ecosysteme.m` | installe sa boîte d'essai dans `toolbox/` même | basse | P20 |
| `save`, `delete`, `copyfile`... | font ce que fait MATLAB, sans confirmation : c'est le comportement attendu | — | — |

## 13. Les corrections faites

Quarante-six commits, chacun avec sa preuve et, sauf pour la
documentation et les outils, un test qui échoue sans lui ; la batterie
complète a été repassée avant chaque poussée (section 2). Par gravité :

| gravité | commit | défaut |
|---|---|---|
| haute | `a8b2305` | `system` : code ×256, sortie perdue, fichier temporaire au nom fixe |
| haute | `3ca072e` | `webread`/`websave`/`webwrite` : injection de commande par l'adresse, `$` des mots de passe |
| haute | `ae8c878` | `webread` d'un `.txt` rendait `[]` |
| haute | `3ab79da` | `tempname` prévisible, compteur sans verrou, dossier ignoré |
| haute | `fdebfde` | une fonction anonyme acceptait un argument de trop |
| haute | `99afb65` | (suite) Stateflow appelait ses actions avec un argument de trop |
| haute | `3a3e428` | opérandes évalués deux fois quand un objet est en jeu |
| haute | `498353d` | `-sparse(...)` ne niait rien |
| haute | `1f5647c` | `zeros(1e10)`, `ones(2^31,1)`, `zeros(NaN)` rendaient un tableau vide |
| haute | `d5388eb`, `422b8c0`, `009856d` | un tableau trop grand arrêtait la session ; refusé avant d'allouer, comme MATLAB |
| haute | `e0f4725` | le lexeur bouclait sans fin sur un `%{` non refermé |
| haute | `b21407e` | lecture hors du tampon sur un `.mat` abîmé |
| haute | `2142450`, `00803a4`, `95ee0e8` | courses entre les fils d'un `parfor` (TSan : 18 → 0) |
| haute | `2f8629b` | le bureau perdait un onglet modifié sans demander |
| moyenne | `a665e10`, `5fbf611` | dix mille parenthèses faisaient tomber le programme |
| moyenne | `9586db1` | une fonction imbriquée au milieu du corps ne s'analysait pas |
| moyenne | `1c26355` | opérateurs unaires sur cellule, structure, poignée, objet sans méthode |
| moyenne | `f11c80b` | `num2str(pi)` rendait `'3.142'` |
| moyenne | `97bff07` | `sprintf('%d', 1e20)` débordait ; `'%d'` d'un non-entier |
| moyenne | `81ee733` | `-q` annoncé, jamais lu ; options dans un ordre imposé |
| moyenne | `8ac78f1` | accélérateurs liés sans être employés ; six documents faux |
| moyenne | `1b14422` | graduations illisibles sous un histogramme |
| moyenne | `c8154d0` | `imwrite` écrivait du PGM sous un nom `.png` |
| moyenne | `6bafcd1` | `pie(X, étiquettes)` échouait |
| moyenne | `3119404` | le README disait faux (éditeur Simulink, affichage, comptes) |
| basse | `c6e108a` | nom C++ (`fnSin`) dans les messages d'erreur |
| basse | `9eeb443` | `\color[rgb]` non borné |
| basse | `5509759` | la coche « Afficher le ruban » disait l'inverse |
| basse | `fc907fc` | `toolbox/maToolbox`, reste d'un essai |
| test | `36c2a4e`, `691432a`, `77270d7` | un test du bureau instable ; le bureau privé de toolbox hors du dépôt |
| outil | `fee1955`, `f9f4ef4` | options ASan/TSan/gcov ; fuzzeurs |
| haute | `6ed7eb4` | `nthroot`, `logm`, `num2cell` : quatorze plantages sur des arguments absurdes |
| haute | `6119492` | `histcounts` perdait le maximum avec des bords automatiques |
| haute | `c2199d6` | `addpath(genpath(d))` n'ajoutait rien ; ordre inverse de MATLAB ; `-end` ignoré |
| performance | `c16566f` | indexation quadratique du chemin : démarrage 0,3 s → 0,03 s, `parfor` vide 0,39 s → 0,012 s |
| outil | `edd366c`, `9e59da4`, `ff6cb62` | code mort retiré ; référence du banc ; `verifierValeurs.m` |

## 14. Ce qui reste : propositions et décisions

### Les décisions à prendre

Elles changent un comportement que l'utilisateur voit : rien n'a été
fait sans accord. **Les quatre ont été prises, chacune selon sa
recommandation**, et mises en œuvre à la reprise suivante :

- **D1** — `new_system('m')`, par valeur comme par nom, part en
  `VariableStepAuto`. `sim(m, T, PAS)` et `simset('FixedStep', PAS)`, qui
  demandent un pas, passent un modèle resté en automatique à son pendant à
  pas fixe, `FixedStepAuto`. Le générateur de programme, comme Simulink
  Coder, demande un pas fixe : les modèles qu'on traduit posent `ode1`.
- **D2** — MatLibre démarre en `format short` ; `format` seul y revient.
  L'option ne tient plus compte de la casse ni des blancs (`format LONG`,
  `format long e`), comme dans MATLAB.
- **D3** — Les erreurs et avertissements des fonctions de MATLAB et des
  toolboxes sont en anglais : le cœur C++, toutes les toolboxes, Simulink
  et Stateflow, messages construits hors de `error` compris (diagnostics
  de simulation, code engendré, fragments insérés). Restent en français
  l'aide, l'interface (bureau, avancement de `parsim`), les identifiants
  `MatLibre:` et ceux qui ne sont pas de MathWorks (`risque:`). Les tracés
  de l'automatique portent les titres et les axes de MATLAB (« Step
  Response », « Bode Diagram », « Time (seconds) », « From: u1  To: y1 »).
- **D4** — Ni invite ni bannière quand l'entrée n'est pas un terminal.

| | question | recommandation |
|---|---|---|
| **D1** | Le modèle Simulink par valeur (`m = new_system('m')`) part en `ode1` au pas de 0,01 ; par nom, en `VariableStepAuto` — 5·10⁻³ d'écart contre 5·10⁻¹⁰ sur une intégrale de sinus (section 6). | La forme par valeur part aussi en `VariableStepAuto`, sa sortie restant un tableau ; reprendre les tests qui supposaient `ode1`. |
| **D2** | L'affichage par défaut montre tous les chiffres (`pi` → `3.141592653589793`), quand MATLAB démarre en `format short` (`3.1416`). C'est un choix assumé du README ; c'est aussi le premier écart qu'un utilisateur de MATLAB voit. | Démarrer en `format short`, comme MATLAB ; `format long` reste à un mot. |
| **D3** | La langue : les messages repris de MATLAB sont en anglais, ceux propres à MatLibre en français, et les deux se côtoient dans un même domaine (`figure` : « Position must have positive width and height » ; `scatter` : « La taille des marqueurs doit être positive ») ; les titres des tracés de l'automatique sont en français. | Garder l'anglais de MATLAB pour toute erreur d'usage d'une fonction de MATLAB (même identifiant, même texte), le français pour l'aide, les avertissements propres à MatLibre et l'interface ; les titres de `bode`, `step`... comme MATLAB. |
| **D4** | La console écrit son invite `>>` même quand l'entrée n'est pas un terminal (`echo 'disp(1)' \| matlibre`). | Pas d'invite ni de bannière quand l'entrée n'est pas un terminal (MATLAB `-batch` n'en écrit pas). |

### Les propositions, classées

Intérêt pour l'utilisateur : ●●● fort, ●● moyen, ● faible. Coût : S
quelques heures, M une demi-session, L une à deux sessions, XL davantage.
Risque : ce qui peut casser. La dernière colonne signale ce qui demande
votre accord (dépendance, comportement visible, gros fichier remanié).

| # | proposition | domaine | intérêt | coût | risque | accord |
|---|---|---|---|---|---|---|
| P2 | **Fait.** Corriger les ~30 fiches dont la valeur annoncée est fausse ou trop arrondie, regarder `biorwavf`, `risetime`, `disparityBM`, puis faire tourner `verifierValeurs.m` dans la batterie | fidélité, doc | ●●● | S | faible | |
| P4 | **Fait.** « Did you mean: plot? » sur une faute de frappe : distance d'édition sur les fonctions connues et les variables, comme MATLAB | ergonomie | ●●● | S | faible | message visible |
| P6 | **Fait.** Intégration continue à la racine du dépôt : rapide à chaque poussée (construction sans avertissement, `ctest -LE lent`), complète chaque nuit (batterie, sans Qt et installation, ASan et UBSan sur toute la batterie hors bureau, TSan, couverture, macOS, Windows) ; le fichier inerte retiré | distribution | ●●● | S | faible | minutes d'Actions (dépôt public : gratuites) |
| P7 | **Fait.** Un guide « Venir de MATLAB » (`venir-de-matlab.md`) : ce qui diffère (affichage, forme par valeur des modèles, formats d'image, palette), ce qui manque, où chercher | doc | ●●● | S | nul | |
| P3 | **Fait**, écrite à la main (termios, séquences VT de la console Windows), sans dépendance. Édition de ligne dans la console : flèches, historique rappelable et enregistré, complétion | ergonomie | ●●● | M | faible | dépendance si linenoise |
| P9 | **Fait.** `test_simulink.m` en quatre parts (la section 26 coupée elle-même) ; `test_aide.m` non coupé, deux exemples de `flou` en faisaient l'essentiel (18 → 4 min) | maintenance | ●●● | M | faible | gros fichier de test (accordé) |
| P5 | **Fait.** LAPACK et BLAS facultatifs (`MATLIBRE_LAPACK`, AUTO) pour `eig`, `svd`, `A\b`, `*`, les algorithmes écrits à la main restant le repli ; trois défauts trouvés en route (`zp2sos`, `lasso`, Daubechies) | performance | ●●● | L | moyen (Windows, résultats au dernier chiffre) | dépendance (accordée) |
| P10 | Écrire et lire le PNG sans dépendance : le DEFLATE existe déjà pour les `.mat`, un PNG en blocs non compressés suffit à écrire | fonction | ●● | M | faible | |
| P11 | `jsondecode` natif (C++), les tests actuels gardés : 0,54 s → quelques millisecondes pour 4 000 nombres | performance | ●● | M | faible | |
| P13 | Un scalaire sans allocation dans `Valeur` : un quart du temps d'une boucle scalaire est `malloc`/`free` | performance | ●● | L | moyen (cœur) | gros fichier |
| P38 | Simuler les schémas par le programme qu'engendre déjà `MATLIBRE_SL_PROGRAMME`, au bit près, plutôt que bloc par bloc | performance | ●● | L | moyen | |
| P12 | L'interpréteur sur un fil à pile explicite (64 Mo), partout : la profondeur de récursion ne dépendrait plus du système (1 Mo pour le fil principal sous Windows), et les chaînes de 10⁵ termes ne tomberaient plus | robustesse | ●● | M | moyen | |
| P15 | Le mot de passe de `webread` hors de la ligne de commande de `curl` (visible par `ps`) : fichier de configuration 0600 ou entrée standard | sûreté | ●● | S | faible | |
| P36 | Le bureau surveille les fichiers ouverts : modifiés ou supprimés ailleurs, il propose de recharger au lieu d'écraser | ergonomie | ●● | S | faible | |
| P31 | Bureau : colonnes de l'espace de travail à leur largeur utile, scripts neufs numérotés (`sans-titre2.m`), capture du test à la densité réelle | design | ●● | S | faible | |
| P32 | La bibliothèque de l'éditeur Simulink sous les noms de Simulink (« Repeating Sequence Interpolated »), sa description lisible en entier | ergonomie | ●● | S | faible | |
| P21 | `webread` d'un `.csv` rend une table, comme MATLAB | fidélité | ●● | S | faible | visible |
| P22 | Affichage : entiers mêlés de NaN/Inf sans décimales, quatre blancs entre colonnes en `format short`, `num2str` d'une matrice sans blancs de tête | fidélité | ●● | M | moyen (tests) | visible |
| P29 | Les bords automatiques d'histogramme de MATLAB (largeur « ronde » alignée) : mêmes effectifs que MATLAB pour les mêmes données | fidélité | ●● | M | faible | visible |
| P25 | Ctrl-C interrompt aussi une fonction native longue (`svd`, `sort`, `conv` sur de grands tableaux) | ergonomie | ●● | M | faible | |
| P39 | `mamfis` et ses voisins sous les noms de propriétés de MATLAB (`Rules`, `Inputs`, `Outputs`...) ; ils sont aujourd'hui en français (`regles`, `entrees`) | fidélité | ●● | M | moyen | visible |
| P8 | `CHANGELOG.md` et `CONTRIBUTING.md` ; une cible `make desinstaller` (le manifeste de CMake) ; un numéro de version qui avance | distribution | ●● | S | nul | |
| P33 | Un thème sombre, au choix ou suivant le système | design | ●● | M | faible | visible |
| P24 | La pile d'une erreur montre la ligne de code de chaque cadre, le premier compris | ergonomie | ● | S | faible | |
| P23 | `zeros(2)(1)` refusé comme dans MATLAB ; `zeros(2.7)` en erreur ; « Not enough input arguments » pour une anonyme appelée avec trop peu d'arguments | fidélité | ● | S | moyen (code qui s'en servait) | visible |
| P28 | Les marqueurs posés sur la limite d'un axe dessinés entiers | design | ● | S | faible | |
| P30 | `parula` absent : un message qui dit pourquoi (viridis), comme `hors-fonctions.md` l'annonce | ergonomie | ● | S | nul | |
| P20 | `test_ecosysteme` et `installToolbox` dans une racine accessible en écriture (une racine utilisateur, comme le dossier des add-ons de MATLAB) | maintenance | ● | S | faible | |
| P26 | Un seul mot pour la même chose : « boîte à outils », « toolbox » et « module » alternent | doc | ● | S | nul | |
| P19 | Des `.mat` v5/v7 et des `.slx` produits par MATLAB dans `tests/donnees`, sous une licence claire, pour éprouver la lecture de vrais fichiers | fidélité | ● | M | faible | |
| P34 | Accessibilité des toiles (figures, Simulink) : noms accessibles, navigation au clavier | ergonomie | ● | L | faible | |
| P35 | Mesure de couverture de la batterie entière, chaque nuit | maintenance | ● | S | nul | |
| P27 | Découper `TracesGraphiques.cpp` (3 076 lignes), `matlibre_sl_compiler.m` (7 187) et `matlibre_sl_executer.m` (5 547) | logiciel | ● | L | moyen | gros fichiers |
| P1 | Un pool de travailleurs persistant pour `parfor` (`parpool`, `gcp`) : le coût fixe est tombé à 0,012 s (section 5) ; reste l'intérêt d'une table des fichiers et d'un état propres à chaque travailleur | performance | ● | L | moyen | |
| P37 | Compiler l'interpréteur en bytecode | performance | ● | XL | élevé | |
| — | Les suites de `reprise.md` §6 non reprises ici : SQL (`sqlite`, dépendance), `get(h,'Color')` en triplet (visible), l'API d'acquisition de MATLAB, les limites du rendu (éclairage, `shading interp`, LaTeX), `uicontrol`/`uifigure` | divers | ●●–● | L–XL | variable | selon le cas |

### La reprise du 27 novembre 2026

P6, P7 et P3 sont faits (`reprise.md`, section 3, donne les commits) ;
viennent ensuite, dans l'ordre du tableau, P9 (découper `test_simulink.m`
et `test_aide.m`, un remaniement de gros fichiers de test) et P5 (LAPACK,
une dépendance), qui demandent tous deux votre accord. Les cinq
avertissements de compilation anciens sont levés, si bien que
l'intégration continue refuse désormais tout avertissement.

Vérifier chaque écart du guide P7 sur l'interpréteur, et le test de bout
en bout de P3, ont fait trouver ce qui suit. Ce qui n'est que
documentation a été corrigé ; le reste change un comportement visible et
attend votre accord.

| # | constat | preuve | gravité | suite |
|---|---|---|---|---|
| P40 | Une poignée de fonction sauvée dans un `.mat` est écrite comme un `double`, sans avertissement : `load` rend un nombre | `f = @(x) x+1; save('p.mat','f'); t = load('p.mat'); class(t.f)` → `double` ; `classeMx` range `Classe::Fonction` dans le cas par défaut, `mxDOUBLE` | haute (perte silencieuse) | proposé : laisser la variable de côté avec un avertissement (`MatLibre:save:...`), une variable qui porte une poignée dans une cellule ou une structure aussi ; coût S. Le guide le dit tel qu'il est |
| P41 | D3 n'est pas entièrement appliquée : des erreurs de fonctions de MATLAB restent en français | `imwrite(I,'a.png')` → « IMWRITE n'écrit que les formats PGM et PPM… », `print('-dpng',…)` → « MatLibre n'enregistre les figures qu'en SVG… » ; un balayage des appels à `error` et `erreur` en relève environ soixante-dix (gestion des risques 19, bio-informatique, radar et communications sans fil 7 chacun, 5 dans le C++), davantage en comptant les messages assemblés sur plusieurs lignes | basse | proposé : les passer en anglais, en reprenant les tests qui cherchent un fragment français ; coût M |
| P42 | `dbstop in f at 3`, la forme de la fiche, pose le point d'arrêt à la ligne 51 — le code du caractère « 3 » — et l'exécution ne s'y arrête pas | `dbstop in fdbg at 3; dbstatus` → « Breakpoint for fdbg is on line 51. » ; `dbstop('in','fdbg','at',3)` marche | moyenne (le débogueur de la console, sous la forme documentée) | proposé : lire le numéro de ligne en texte comme en nombre ; coût S |
| P43 | `int64` et `uint64` sont rangés en `double` : au-delà de 2^53 le dernier chiffre se perd, et l'affichage prend un facteur d'échelle | `intmax('int64')` → `1.0e+18 * 9.2234` (MATLAB : `9223372036854775807`) ; jusqu'ici dit seulement pour Coder | moyenne | dit dans le guide ; un vrai stockage entier sur 64 bits toucherait `Valeur` (gros fichier, coût L) |
| — | La fiche de `new_system` et `couverture.md` disaient que le modèle par valeur part en `ode1` au pas de 0,01, ce que D1 a changé ; `hors-fonctions.md` tenait pour absents l'héritage, les paquets `+dossier` et la lecture des `.slx`, qui marchent ; `architecture.md` donnait 8 µs par instruction scalaire | vérifié sur l'interpréteur | basse | corrigé (P7 et la mise à jour des documents) |

### La reprise du 28 novembre 2026

Accordés : P9, P5 et les constats P40 à P43. **Faits** : P9, P5, P40
(`8c08b70`), P41 (`66086a5`), P42 (`11fc163`). **P43** (`int64` exact)
n'est pas commencé : c'est un chantier de plusieurs sessions, dont le plan
est dans `reprise.md`, section 6.

La première intégration continue (commit `075f958`) et LAPACK ont fait
trouver ce qui suit, corrigé chaque fois avec son test :

| défaut | preuve | gravité | commit |
|---|---|---|---|
| Windows ne compilait plus : `GetModuleFileNameA` sans `<windows.h>` | construction croisée MinGW, `'DWORD' was not declared` | haute (distribution) | `075f958` |
| `tempdir` rendait `/tmp` sans séparateur : `[tempdir 'f']` désignait `/tmpf`, à la racine du disque | `test_types` rouge sur le runner, non administrateur | moyenne | `4d97f45` |
| `zp2sos` complétait une section du premier ordre par le début (un pôle seul en 0,5 : `[0 0 1 1 1 -0.5]`) et laissait seule une racine réelle suivie d'une paire | sous LAPACK, `tf2sos` de `butter(4,0.3)` rendait trois sections | haute (résultat faux) | `cf549b6` |
| le premier modèle du chemin de `lasso` portait un coefficient de 1e-16 | `test_statistiques` sous LAPACK | basse | `df83dd8` |
| Daubechies d'ordre élevé : racines d'un polynôme déséquilibré (db45 : 2,5e-4 d'écart à l'orthogonalité sous LAPACK) | `test_domaines` sous LAPACK | moyenne | `f4c1cca` |
| clang sur ARM64 fusionne `a*b+c` : `-70:0.1:90` finissait à 90,00000000000001 | `test_litterature`, `test_signal` sous macOS | moyenne | `c551dd2` |
| `fopen` ouvrait en mode texte sauf `'b'` (MATLAB : binaire sauf `'t'`) ; sous Windows, un Parquet écrit ne se relisait pas | `test_parquet` sous Windows | haute sous Windows | `abfefae` |
| deux exemples de la logique floue prenaient 370 et 58 s | mesure de `test_aide` par module | basse (temps) | `222a7ee` |

Le test du bureau « les blocs de la bibliothèque se simulent tous »,
rouge sur les runners Linux et macOS et vert dans le conteneur, laissait
le bureau dans un dossier temporaire effacé : la suite écrivait à la
racine du disque, possible au seul administrateur (`2aecde8`, trouvé par
la console qu'il écrit désormais en cas d'échec). Restent ouverts, à
relire au prochain passage de l'intégration continue : sous Windows, le bureau qui
dépasse son délai et cinq scripts (`test_defauts`, `test_es_texte`,
`test_mat`, `test_litterature`, `aide_valeurs`), dont le mode texte de
`fopen` explique sans doute une partie, et `test_graphique`, qui écrit
dans un chemin en dur (`/tmp/matlibre_test_figure.svg`).

