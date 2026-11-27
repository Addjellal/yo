# Reprendre le travail sur MatLibre

Fiche de passation d'une session à la suivante. À lire en premier ; elle
renvoie aux documents de fond : `etat.md` (ce qui est fait et ce qui
reste, par boîte à outils), `architecture.md` (comment l'interpréteur et
le rendu sont bâtis), `developpeur.md` (compiler, ajouter une fonction,
conventions), `reference-matlab/hors-fonctions.md` (ce qui diffère de
MATLAB, domaine par domaine).

Dernière mise à jour : 22 novembre 2026, à la fin de l'audit de reprise
(`audit-reprise.md`). La batterie complète passe, 52 tests sur 52, au
dernier commit de code de l'audit.

## 1. Les règles du dépôt

- **Branche** : `claude/matlab-libre-reprise-lgnad9` sur `addjellal/yo`.
  On ne pousse que là. Pas de pull request sans demande explicite.
- **Tout commiter et pousser avant de rendre la main** : un hook d'arrêt
  le vérifie et relance la session tant qu'il reste des modifications.
- **Messages de commit** : en français **sans accents**, un titre
  « Domaine : résumé » (`Graphique : ...`, `Coeur : ...`,
  `Simulink : ...`), un corps qui dit le pourquoi et ce qui a été
  mesuré. Ils se terminent par les deux lignes d'attribution
  (`Co-Authored-By: ...` et `Claude-Session: ...`) que la session donne.
- **Langue** : code commenté, aide, documents et messages d'erreur
  propres à MatLibre en français. Les identifiants d'erreur suivent
  MATLAB (`MATLAB:hg:InvalidProperty`) quand MATLAB en a un, sinon
  `MatLibre:domaine:Cause`.
- **Lignes de 100 colonnes au plus**, en C++ comme en `.m`.
- **Chaque fiche d'aide** porte un bloc « Exemple : » ou « Exemples : »
  et une ligne « Voir aussi » : `tests/scripts/test_aide.m` exécute
  **tous** les exemples et exige le « Voir aussi ». Les fonctions natives
  ont leur fiche dans `toolbox/aide/*.txt`, sous `### nom`.
- **Fonctions internes** préfixées `matlibre_` (elles n'existent pas dans
  MATLAB et le disent dans leur aide). Deux fichiers dont les noms ne
  diffèrent que par la casse (`addMF`/`addmf`) : l'un va dans le
  sous-dossier `homonymes/` du module.
- **La fidélité à MATLAB fait foi.** Quand un test encode un
  comportement propre à MatLibre et faux au regard de MATLAB, c'est le
  test qu'on corrige, en le disant dans le commit (exemples récents :
  `bar3` rend une poignée par colonne, `patch` un seul objet, `'r'` vaut
  `[1 0 0]`, `xticks` rend les graduations montrées).
- **Après un ajout ou un retrait de fonction**, régénérer la
  documentation :

  ```
  build/bin/matlibre --path toolbox outils/manques.m
  build/bin/matlibre --path toolbox outils/genererReference.m
  build/bin/matlibre --path toolbox outils/majComptes.m
  ```

  Le texte des écarts à MATLAB s'écrit dans
  `documentation/reference-matlab/hors-fonctions.md` ; `manques.md` en
  est tiré.

## 2. Construire et tester

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release      # une fois
cmake --build build -j4                             # tout, bureau Qt compris
build/bin/matlibre --path toolbox script.m          # lancer un script
build/bin/matlibre --path toolbox --path tests/scripts tests/scripts/test_graphique.m
cd build && ctest -j2 --timeout 7000 > log          # la batterie complète
cd build && ctest -R bureau                          # l'application de bureau, hors écran
```

- La batterie compte 52 tests (les 47 scripts, les vérifications C++, le
  bureau, trois tests de la ligne de commande) et dure **25 minutes avec
  `-j3`** : `test_simulink` à lui seul 25 minutes, `test_aide` 13,
  `test_exemples` 5. ctest lance d'abord les plus longs ; au-delà de trois
  cœurs, rien ne se gagne tant que `test_simulink` reste d'un bloc (P9 de
  l'audit). Les autres tiennent en quelques secondes ou minutes ; on les
  lance un par un pendant le travail.
- **Ne rien modifier pendant que la batterie tourne** : les `.m` de
  `toolbox/` sont lus au fil de l'exécution, et une fonction réécrite en
  cours de route fait échouer des tests qui n'ont rien à voir (c'est
  arrivé). Ne pas reconstruire non plus : le binaire change sous les
  tests.
- Les tests de cas de la littérature, un par boîte à outils, sont dans
  `tests/scripts/test_litterature.m` (49 boîtes à outils). Les exemples
  d'école, un par boîte, dans `exemples/toolboxes/` (`test_exemples.m`).
- Les avertissements de compilation de `Base.cpp:970` et `Mat.cpp:187-208`
  sont anciens (ceux de `Math.cpp` et `Statistiques.cpp`, du code mort,
  sont partis avec lui) ; une modification ne doit pas en ajouter.

### Outils de vérification

- `outils/banc.m` est le banc de performance : vingt-deux mesures
  (interpréteur, copie sur écriture, calcul vectoriel, algèbre linéaire,
  texte, rendu, `parfor`, Simulink), chacune vérifiée et comparée à sa
  référence ; un rapport au-delà de 3 est signalé.
  `build/bin/matlibre --path toolbox outils/banc.m`, une minute.
- `outils/capturer.js` rend en PNG les SVG d'un dossier (Playwright et
  son Chromium sont installés dans le conteneur) :
  `node outils/capturer.js dossier_svg dossier_png`. Les figures
  s'écrivent avec `matlibre_svg()`. Les PNG se regardent avec l'outil de
  lecture d'images : c'est ainsi que chaque nouveauté graphique a été
  contrôlée, figure par figure.
- `outils/comparerImages.py avant_png apres_png` compare deux corpus au
  pixel (demande Pillow) : la façon de vérifier qu'un remaniement du rendu
  ne change pas l'image.
- `outils/vueFigure.sh script.m dossier_png` peint les figures d'un
  script dans la fenêtre du bureau (`VueFigure`), hors écran, pour les
  comparer au SVG.
- **Captures de l'application de bureau** :
  `MATLIBRE_CAPTURE=/chemin/fenetre.png build/bin/matlibre_tests_bureau`
  écrit, en fin de test, la fenêtre principale et celle de l'aide. Pour la voir vivre : `xvfb-run -a
  build/bin/matlibre-bureau &` puis `import -window root capture.png`
  (Xvfb et ImageMagick sont installés).
- **Contrôles de cohérence** : `outils/verifierDoublons.m` (deux `.m` de
  même nom, un `.m` qui masque une fonction native), `outils/audit.m`
  (aide, exemples, tests par boîte à outils), `outils/verifierExemples.m`
  (tous les exemples d'aide), `outils/verifierValeurs.m` (les valeurs
  qu'annoncent les exemples, « expr % valeur », comparées à ce que rend
  l'expression ; 33 s, 34 écarts à corriger, voir l'audit),
  `outils/eprouverNatives.sh` (chaque native appelée avec des arguments
  absurdes : une erreur MATLAB est juste, un plantage jamais ; 6 min 30 s
  depuis que le démarrage a été divisé par dix).
- **Fuzzeurs** (`outils/fuzz/`) : `fuzzer.py` abîme des `.m` du dépôt et
  les passe dans l'analyseur seul (`analyseSeule.cpp`, à compiler contre
  un arbre assaini, la commande est en tête du fichier) puis en exécute
  une partie ; `fichiersAbimes.py` fait relire des `.mat`, `.csv`,
  `.json`, `.slx`, images, sons, XML et Parquet abîmés.
- **Assainisseurs et couverture**, chacun dans un arbre à part :
  `-DMATLIBRE_ASSAINIR=ON` (ASan et UBSan), `-DMATLIBRE_ASSAINIR=thread`
  (TSan), `-DMATLIBRE_COUVERTURE=ON` (gcov). Sous ASan, passer
  `ASAN_OPTIONS=detect_leaks=0:allocator_may_return_null=1` ; compter un
  facteur 4 sur les durées (deux heures pour `test_simulink`). Un arbre
  construit hors du dépôt reçoit la toolbox par `MATLIBRE_TOOLBOX`, que
  CTest pose désormais pour tous les tests.
- **Vérifications croisées en Python** : les cas de la littérature ont
  été confrontés à des implémentations indépendantes. L'environnement se
  recrée ainsi (le scratchpad d'une session ne survit pas) :

  ```
  python3 -m venv /tmp/venv
  /tmp/venv/bin/pip install numpy scipy scikit-learn statsmodels pillow numfi fxpmath nltk
  /tmp/venv/bin/python -I script.py
  ```

  `libngspice.so.0` est installé (le hook de démarrage y veille) et se
  pilote par `ctypes` pour contrôler Simscape.

## 3. Ce qui a été fait dans les dernières sessions

| commit | contenu |
|---|---|
| `5c67b1a` → `7f78f6e` | Cas de la littérature, six lots, 49 boîtes à outils, chacun confronté à une référence publiée ou à une implémentation indépendante ; les résultats faux trouvés en route ont été corrigés (`ea52b93`, `933828e`). |
| `7335314` | Bureau : le ruban se replie quand la fenêtre rétrécit. |
| `4294110` | Collisions de casse (`homonymes/`), `dir` (`**`, plusieurs étoiles, `.` et `..`), et le générateur aléatoire de MATLAB : `rng(0); rand` rend 0.8147, `randn` 0.5377, comme la documentation (Mersenne Twister, ziggurat). |
| `c055708`, `bbe23bf` | Les tests et exemples qui ne tenaient qu'à la graine, rendus indépendants de la chance ; deux vrais défauts trouvés (`pcfitplane`, `mussv`). |
| `554052c` | Tableaux en copie sur écriture (`Tampon.h`) : passer un tableau de 16 Mo à une fonction ne le recopie plus (3,99 s → 0 s pour 200 appels). |
| `a9a20b9` | Une toile commune au SVG et à la fenêtre du bureau : le dessin n'est écrit qu'une fois. |
| `17ed9dd` | `scatter` propre (aires, couleurs par point, creux), la barre de couleurs dans ses huit positions avec étiquette et graduations, `xtickangle`/`ytickangle`, une graduation par barre, couleurs pures des lettres. |
| `9f0c666` | La perspective (`surf`, `mesh`, `plot3`, `scatter3`, `fill3`, `patch`, `bar3`, `stem3`, `quiver3`, `slice`, `meshc`...), l'interprète TeX des textes, `yyaxis` et `plotyy`. |
| `67fb95c` et suivant | Cette fiche, le banc de performance (`outils/banc.m`) et les outils de vérification du rendu (`outils/capturer.js`, `comparerImages.py`, `vueFigure.sh`). |
| `a8b2305` → `c0f5734` | **L'audit de reprise**, en douze volets (`audit-reprise.md`) : quarante-huit commits, dont trente-cinq corrections du code — résultats faux silencieux (anonymes, `zeros(1e10)`, creux, `histcounts`, `webread`, `system`, `addpath`, opérandes évalués deux fois), injection de commande dans `webread`, dix-huit courses de `parfor` (TSan), lecture hors bornes d'un `.mat`, lexeur bouclant sur `%{`, quatorze plantages de natives, perte d'un onglet du bureau — et l'indexation quadratique du chemin (démarrage 0,3 → 0,03 s, `parfor` vide 0,39 → 0,012 s). |

## 4. Les pièces récentes, et où elles sont

- **Rendu graphique** — `include/matlibre/Toile.h` déclare la toile
  (traits, polygones, rectangles, cercles, textes en morceaux, découpe).
  `src/graphique/Dessin.cpp` dessine un axe plan ; `Espace.cpp` un axe en
  perspective (projection de `viewmtx`, boîte étirée, tri du peintre) ;
  `Tex.cpp` coupe un texte en morceaux selon le TeX de MATLAB ;
  `ToileSVG.cpp` écrit le SVG ; `src/bureau/VueFigure.cpp` contient la
  toile Qt. `src/graphique/Commun.h` partage les aides entre plan et
  espace. Le modèle (séries, axes, figure) est dans
  `include/matlibre/Graphique.h` ; les fonctions de tracé dans
  `src/bibliotheque/TracesGraphiques.cpp` ; les poignées et leurs
  propriétés dans `src/bibliotheque/PoigneesGraphiques.cpp`.
- **Les tests du SVG lisent des formes précises** : la boîte d'un axe
  s'écrit `<rect ... fill="white" stroke="#222"/>`, une ligne `<path`,
  la couleur d'un texte est son dernier attribut (`fill="#FFFFFF">blanc`),
  un exposant `<tspan baseline-shift="super"`. `ToileSVG` les garde ;
  les changer casse `test_graphique`.
- **Générateur aléatoire** — `include/matlibre/Aleatoire.h` et
  `src/coeur/Aleatoire.cpp` ; `rng`, `rand`, `randn`, `randi`,
  `randperm` dans `src/bibliotheque/Base.cpp`.
- **Copie sur écriture** — `include/matlibre/Tampon.h`. Une fonction
  native qui ne fait que lire son argument le prend par référence const
  (`const Valeur& v = args[0]`) : lu par une copie non const, `v.re[k]`
  détache le tampon (voir `architecture.md`).
- **Calcul parallèle** — `src/coeur/Parallele.cpp` (`analyserParfor`, les
  fils sont créés à chaque `parfor`), `src/bibliotheque/Parallele.cpp`.
- **Base de données** — `toolbox/base-de-donnees/` : des tables en
  mémoire (`dbTable`, `dbSelect`...) sauvées en CSV.

## 5. L'audit de reprise

**L'audit des 21 et 22 novembre 2026 est fait** : `audit-reprise.md`.
Ce qui suit en reste la méthode, pour le prochain ; les faits cités sont
ceux d'avant cet audit, et le rapport dit ce qu'ils sont devenus.

Avant d'ajouter quoi que ce soit, une session qui reprend fait le point
sur tout ce qui peut profiter à l'application, et le rend écrit dans
`documentation/audit-reprise.md`. Chaque constat y porte : ce qui a été
vu, la preuve (commande, mesure, capture, scénario qui le déclenche), la
gravité, et ce qui a été fait — corrigé, avec le commit, ou proposé, avec
un coût estimé.

### Outils d'analyse disponibles dans le conteneur

ASan, UBSan et TSan (`-fsanitize=address,undefined`, `-fsanitize=thread`
avec gcc), `valgrind` (memcheck, callgrind pour le profil), `clang-tidy`,
`clang-format`, `gcov`, Xvfb et ImageMagick (`import`), Playwright et
Chromium (`outils/capturer.js`). Absents : `cppcheck`, `lcov`, `perf`,
la chaîne MinGW (la construction pour Windows ne s'éprouve donc pas ici).
Le CMake a ses options pour les assainisseurs et la couverture
(`-DMATLIBRE_ASSAINIR=ON` ou `thread`, `-DMATLIBRE_COUVERTURE=ON`), et
`outils/fuzz/` ses fuzzeurs. L'exécution de code MATLAB téléchargé a été
refusée par le garde-fou de la session pendant l'audit : du code réel se
passe dans `analyseSeule` (analyse sans exécution).

### Les douze volets

1. **Construire** et vérifier qu'aucun avertissement nouveau n'apparaît
   (ceux de `Base.cpp`, `Mat.cpp`, `Math.cpp`, `Statistiques.cpp` sont
   connus), puis la même chose avec `-Wall -Wextra -Wshadow
   -Wconversion` pour mesurer la dette, sans tout corriger.
2. **La batterie complète** (49 tests) et le bureau (`ctest -R bureau`).
   Un test rouge est le premier travail : en trouver la cause — défaut
   réel, ou test qui ne tenait qu'au hasard — avant toute autre chose.
3. **La santé de la mémoire et des fils** : construire avec ASan et
   UBSan et repasser la batterie (au moins le cœur, les graphiques,
   Simulink et le bureau) ; TSan sur `test_parallele.m` et `parfor` ;
   `valgrind` sur quelques scripts longs pour les fuites. Toute lecture
   hors bornes, tout comportement indéfini, toute course est un défaut à
   corriger.
4. **La robustesse** : `outils/eprouverNatives.sh` (chaque native appelée
   avec des arguments absurdes : une erreur MATLAB est juste, un plantage
   jamais) ; un fuzzeur maison de l'analyseur et de l'interpréteur
   (fichiers `.m` tronqués, mutés, imbriqués à l'excès, très longs) ;
   les cas limites (vide, NaN, Inf, complexe, entiers, tailles énormes,
   chaînes Unicode) ; des fichiers abîmés en lecture (`.mat`, `.csv`,
   `.json`, `.slx`, images, audio) ; l'application de bureau devant un
   calcul qui ne finit pas, une figure de dix millions de points, un
   fichier qui disparaît.
5. **Le banc** (`outils/banc.m`) : comparer aux références ; une mesure
   plus lente d'un facteur 1,5 se regarde, d'un facteur 3 se cherche
   (régression, ou machine différente : le dire). Puis profiler les
   points chauds (`valgrind --tool=callgrind`) et dire ce qui les
   accélérerait. Le banc du 21 novembre 2026 montre déjà où MatLibre est
   lent face à MATLAB :
   - l'algèbre linéaire dense est écrite à la main, sans LAPACK : `eig`
     d'une matrice symétrique 300×300 prend 0,27 s, `svd` 0,44 s, quand
     MATLAB y met quelques millisecondes ;
   - `jsondecode` de 4000 nombres prend 0,6 s ;
   - un `parfor` coûte 0,23 s de démarrage, même vide (section 6) —
     l'audit l'a ramené à 0,012 s : c'était l'indexation quadratique du
     chemin, non la création des fils ;
   - une boucle scalaire tourne à 0,4 µs le tour : c'est un interpréteur
     à parcours d'arbre, sans compilation à la volée.
   La durée de la batterie elle-même (`test_simulink` : 25 minutes) freine
   chaque correction : la raccourcir sans rien perdre est un gain.
6. **Les conflits** :
   - avec la branche par défaut : `git fetch origin main` puis
     `git rev-list --left-right --count origin/main...HEAD` et
     `git merge-tree --write-tree origin/main HEAD` (le 21 novembre :
     0 commit de retard, 29 d'avance, fusion sans conflit) ;
   - de noms : `outils/verifierDoublons.m` (doublons, masquages du
     natif), et les collisions de casse que `test_aide.m` refuse ;
   - de comportements : deux chemins qui devraient s'accorder et ne le
     font pas. Un exemple, réglé depuis (décision D1) : un modèle
     Simulink créé par `m = new_system('m')` partait en `ode1` au pas de
     0,01, quand `new_system('m')` partait, comme Simulink, en
     `VariableStepAuto` — d'où un intégrateur faux de 5e-3 sur un sinus,
     là où ode45 donne 3e-10. Les deux partent désormais en
     `VariableStepAuto`.
7. **La fidélité à MATLAB sur du vrai code** : faire tourner des
   programmes MATLAB réels — les exemples de la documentation publique
   de MathWorks, des projets libres sous licence permissive — et relever
   ce qui échoue ou diffère ; confronter les résultats numériques à des
   références indépendantes (NumPy, SciPy, statsmodels) ; relire des
   fichiers produits par MATLAB et Simulink (`.mat` v5 et v7, `.slx`).
   MatLibre est sous licence MIT : rien ne se copie d'un code GPL (les
   tests d'Octave, par exemple) ni de MathWorks — on s'en sert comme
   référence de comportement, on n'en reprend pas une ligne.
8. **Le logiciel** : relire le code des grands ajouts récents (`Toile`,
   `Dessin.cpp`, `Espace.cpp`, `Tex.cpp`, `Tampon.h`, `Aleatoire.cpp`)
   en cherchant les défauts réels, avec le scénario qui les déclenche ;
   `clang-tidy` sur ces fichiers ; mesurer la couverture des tests
   (`gcov`) pour trouver le code que rien n'exerce ; repérer les fichiers
   devenus trop gros (`TracesGraphiques.cpp` dépasse trois mille lignes)
   et le code mort ; vérifier la couverture fonctionnelle
   (`outils/manques.m`, `outils/audit.m`).
9. **Le design** :
   - les figures : rendre en PNG un corpus varié (tracés plans, barres,
     images, contours, légendes, sous-figures, 3D, TeX) et le regarder
     face à ce que MATLAB montre (couleurs, polices, marges, graduations,
     vues 3D) ; comparer la fenêtre (`outils/vueFigure.sh`) au SVG ;
   - l'application de bureau : capturer la fenêtre principale, l'éditeur,
     la console, l'aide, l'éditeur Simulink, et juger lisibilité,
     cohérence visuelle, encombrement, contrastes, tailles de police,
     thème sombre, écrans à haute densité.
10. **L'ergonomie pour l'utilisateur** : se mettre à la place de trois
    personnes — l'utilisateur de MATLAB qui change d'outil, l'étudiant
    qui découvre, l'ingénieur qui lance des scripts en ligne de
    commande — et parcourir ce qu'elles font, en notant chaque friction :
    - **premier contact** : installer, lancer la console et le bureau,
      trouver de l'aide (`help`, `doc`, le navigateur d'aide, la
      recherche), comprendre ce qui manque par rapport à MATLAB ;
    - **le travail courant** : écrire un script dans l'éditeur,
      l'exécuter, lire une erreur et aller à la ligne fautive, déboguer
      (points d'arrêt, pas à pas, espace de travail), tracer et
      retoucher une figure, l'exporter, bâtir et simuler un modèle
      Simulink, ne rien perdre si l'application se ferme ;
    - **les messages** : une erreur dit-elle quoi, où, et comment s'en
      sortir ? MATLAB propose « Did you mean: plot? » pour une faute de
      frappe (`plt(1:3)`) ; MatLibre ne le fait pas. Les messages de
      MATLAB sont en anglais, ceux propres à MatLibre en français : le
      mélange se voit, et se discute ;
    - **la ligne de commande** : options, codes de retour, sortie lisible
      dans un terminal et dans un journal, historique et complétion de
      la console ;
    - **la rapidité ressentie** : démarrage de la console (0,2 à 0,26 s
      le 21 novembre, 0,03 s depuis l'audit), premier tracé, première simulation, ouverture du
      bureau, réactivité pendant un long calcul, possibilité de
      l'interrompre ;
    - **l'accessibilité** : clavier seul, contrastes, agrandissement,
      lecteur d'écran.
    Un défaut était déjà trouvé : `matlibre -q` (et `--quiet`), annoncé
    par `matlibre --help`, n'était pas lu — corrigé par l'audit
    (`81ee733`).
11. **La documentation** : le README et les comptes qu'il annonce sont-ils
    justes ? Manque-t-il un guide de démarrage pour qui vient de MATLAB,
    un guide de migration (ce qui diffère, ce qui manque), des tutoriels
    par domaine ? Les fiches d'aide ont-elles des exemples utiles, et
    pas seulement exécutables ? Le vocabulaire français est-il le même
    d'une fiche à l'autre ?
12. **La distribution et la maintenance** : construire depuis zéro en
    suivant `installation.md`, avec et sans Qt ; regarder ce que donnent
    l'installation et la désinstallation ; le dépôt n'a pas
    d'intégration continue (pas de `.github/workflows`) — proposer
    l'ensemble qui construit et passe les tests rapides à chaque
    poussée, et la batterie complète chaque nuit ; un journal des
    versions, un guide de contribution ; ce qui touche au système, au
    réseau et aux fichiers (`system`, `webread`, l'écriture de fichiers)
    se fait-il sans surprise et sans danger pour l'utilisateur ?

### Rendre compte

Corriger tout de suite ce qui est un défaut avéré — test rouge, résultat
faux, plantage, lecture hors bornes, course, conflit, régression du
banc, option ou commande qui ne fait pas ce qu'elle annonce —, chacun
dans son commit, la batterie repassée avant de pousser. Pour le reste —
améliorations du logiciel, de la performance, du design, de
l'ergonomie, de la documentation, de la distribution —, un tableau
classé par intérêt pour l'utilisateur, par coût et par risque, à
soumettre avant de s'y mettre. Ce qui ajoute une dépendance (LAPACK,
SQLite, HDF5), change un comportement que l'utilisateur voit, ou
remanie un gros fichier se décide avec l'utilisateur. À la fin, mettre
à jour cette fiche et `etat.md`.

## 6. Ce qui reste, par ordre d'intérêt

**Les quatre décisions de l'audit sont appliquées** (`audit-reprise.md`,
section 14, dit ce qui a été fait) : D1, un modèle Simulink neuf part en
`VariableStepAuto`, par valeur comme par nom ; D2, MatLibre démarre en
`format short` ; D3, les erreurs et avertissements des fonctions de
MATLAB et des toolboxes sont en anglais — l'aide, l'interface et les
identifiants `MatLibre:` restent en français —, et les tracés de
l'automatique portent les titres de MATLAB ; D4, ni invite ni bannière
quand l'entrée n'est pas un terminal. Un test qui vérifie un message
cherche un fragment de l'anglais, ou l'identifiant.

**Puis les propositions de l'audit**, classées dans son tableau, en
tête : corriger les trente fiches d'aide dont la valeur annoncée est
fausse et faire tourner `outils/verifierValeurs.m` dans la batterie (P2),
« Did you mean » (P4), l'intégration continue à la racine du dépôt (P6),
un guide pour qui vient de MATLAB (P7), l'édition de ligne dans la
console (P3), une batterie de douze minutes (P9), LAPACK (P5).

Les suites d'avant l'audit restent, avec ce qu'il en a appris :

1. **Un pool de travailleurs persistant pour `parfor`.** Le coût fixe
   d'un `parfor` vide est tombé de 0,23 s à 0,012 s quand l'audit a
   supprimé l'indexation quadratique du chemin (`c16566f`) : il venait de
   là, non de la création des fils. Un pool garde un intérêt — un état et
   une table des fichiers propres à chaque travailleur, comme les
   processus de MATLAB —, mais il n'est plus pressé (P1 de l'audit).
2. **L'algèbre linéaire dense** : `eig`, `svd` et `A\b` à la vitesse de
   MATLAB demanderaient LAPACK (OpenBLAS ou la référence), en dépendance
   facultative, la version écrite à la main restant le repli — ce qui
   touche aussi la construction pour Windows.
3. **L'interface SQL de la Database Toolbox** : `sqlite`, `database`,
   `fetch`, `sqlread`, `sqlwrite`, `execute`, `close`. `libsqlite3-dev`
   est installé dans le conteneur ; la construction pour Windows
   (`outils/mingw.cmake`) devra soit trouver SQLite, soit embarquer
   l'amalgame `sqlite3.c`, soit construire sans ces fonctions en le
   disant. Les tables en mémoire existantes (`dbTable`...) restent.
4. **`get(h,'Color')` rend un code `'#FF0000'`** là où MATLAB rend le
   triplet `[1 0 0]` (idem `MarkerFaceColor`, `FaceColor` quand c'est
   une couleur). Les deux s'écrivent déjà ; changer la lecture touche
   `findobj` et des tests qui comparent des chaînes.
5. **L'API d'acquisition de MATLAB** : `addinput`, `read`, `write`,
   `start` manquent ; `addAnalogInput`, `readData`, `writeData` en
   tiennent lieu (`toolbox/acquisition`).
6. **Les limites du rendu**, toutes écrites dans `hors-fonctions.md` :
   - perspective : deux faces qui se traversent ne sont pas découpées
     (algorithme du peintre) ; `shading interp` donne la moyenne d'une
     maille au lieu d'un dégradé ; pas d'éclairage ; `bar3h` garde des
     barres verticales ; `slice` coupe sur le plan de grille le plus
     proche au lieu d'interpoler ;
   - texte : l'interprète `'latex'` n'est que du TeX sans dollars
     (`\frac`, `\sqrt{}` ne sont pas mis en page) ; un texte en cellule
     s'écrit sur une ligne ;
   - légende : `AutoUpdate` et `NumColumns` acceptés sans effet ; une
     légende de surface montre un trait ;
   - les étiquettes de graduation ne s'inclinent pas d'elles-mêmes quand
     elles se chevauchent ;
   - axes polaires sans graduation angulaire du cadre, `histogram2` en
     carte et non en barres, bandes de `contourf` posées en champ
     continu ;
   - pas d'interaction à la souris (zoom, rotation 3D, curseur), pas de
     format `.fig`.
7. **Interface utilisateur** : `uicontrol`, `uifigure` et App Designer
   absents ; pas de boucle d'événements modale (`uiwait` n'attend pas).

## 7. Pour démarrer un nouveau chat

Pour **la suite de l'audit**, coller ce message :

> Reprends le projet MatLibre (dépôt `addjellal/yo`, dossier
> `matlab-libre`, branche `claude/matlab-libre-reprise-lgnad9`). Lis
> d'abord `matlab-libre/documentation/reprise.md` en entier, puis
> `audit-reprise.md`, `etat.md` et `architecture.md`.
>
> Les décisions D1 à D4 de l'audit sont appliquées (section 14
> d'`audit-reprise.md`). Prends les propositions du tableau de cette
> section dans l'ordre, en commençant par P2
> (corriger les fiches dont la valeur annoncée est fausse, puis faire
> tourner `outils/verifierValeurs.m` dans la batterie). Un commit par
> sujet, la batterie complète repassée avant de pousser ; demande-moi
> avant d'ajouter une dépendance, de changer un comportement visible ou
> de remanier un gros fichier. À la fin, mets à jour `reprise.md` et
> `etat.md`.

Pour **un nouvel audit complet**, coller celui-ci :

> Reprends le projet MatLibre (dépôt `addjellal/yo`, dossier
> `matlab-libre`, branche `claude/matlab-libre-reprise-lgnad9`). Lis
> d'abord `matlab-libre/documentation/reprise.md` en entier, puis
> `etat.md` et `architecture.md`.
>
> Ta mission : faire un audit complet de tout ce qui peut profiter à
> l'application, corriger ce qui est cassé, et me proposer le reste. Suis
> les douze volets de la section 5 de `reprise.md` :
>
> 1. **Construction** : `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`
>    puis `cmake --build build -j4` ; aucun avertissement nouveau, et la
>    dette mesurée avec des avertissements plus stricts.
> 2. **Tests** : la batterie complète (`cd build && ctest -j2 --timeout
>    7000`, une demi-heure) et le bureau ; un test rouge passe avant tout.
> 3. **Mémoire et fils** : la batterie sous ASan et UBSan, `parfor` sous
>    TSan, `valgrind` pour les fuites.
> 4. **Robustesse** : `outils/eprouverNatives.sh`, un fuzzeur de
>    l'analyseur et de l'interpréteur, les cas limites, des fichiers
>    abîmés, l'application de bureau mise à l'épreuve.
> 5. **Performance** : le benchmark avec `outils/banc.m` comparé aux
>    références, un profil des points chauds, et la durée de la batterie
>    elle-même ; dis où MatLibre est lent, pourquoi, et ce qui
>    l'accélérerait.
> 6. **Conflits** : avec la branche `main`, entre noms de fichiers et
>    fonctions natives, et entre comportements qui devraient s'accorder
>    (la section 5 en donne un exemple à trancher).
> 7. **Fidélité à MATLAB** : du vrai code MATLAB (exemples publics,
>    projets libres sous licence permissive), des résultats confrontés à
>    des références indépendantes, des fichiers `.mat` et `.slx` réels.
>    Rien ne se copie de code GPL ni de MathWorks.
> 8. **Logiciel** : relecture du code récent, `clang-tidy`, couverture des
>    tests, code mort, fichiers trop gros, architecture.
> 9. **Design** : les figures rendues en PNG face à MATLAB, et les
>    captures de l'application de bureau (lisibilité, cohérence visuelle,
>    contrastes, thème, haute densité).
> 10. **Ergonomie pour l'utilisateur** : à la place d'un utilisateur de
>     MATLAB, d'un étudiant et d'un ingénieur en ligne de commande —
>     premier contact, aide, scripts, erreurs et débogage, figures,
>     Simulink, ligne de commande, rapidité ressentie, accessibilité.
>     Note chaque friction (la section 5 en donne déjà une, l'option
>     `-q`).
> 11. **Documentation** : justesse du README, guide de démarrage et de
>     migration depuis MATLAB, qualité des exemples, vocabulaire.
> 12. **Distribution et maintenance** : construction depuis zéro,
>     installation, intégration continue (il n'y en a pas), journal des
>     versions, guide de contribution, sûreté de ce qui touche au système,
>     au réseau et aux fichiers.
>
> Corrige directement les défauts avérés — test rouge, résultat faux,
> plantage, lecture hors bornes, course, conflit, régression du banc,
> option ou commande qui ne fait pas ce qu'elle annonce —, un commit par
> correction, la batterie repassée avant de pousser. Écris le rapport
> dans `documentation/audit-reprise.md`, chaque constat avec sa preuve.
> Puis propose-moi, dans un tableau classé par intérêt pour
> l'utilisateur, par coût et par risque, toutes les améliorations et
> corrections restantes — logiciel, performance, design, ergonomie,
> documentation, distribution. Demande-moi avant d'ajouter une
> dépendance, de changer un comportement visible ou de remanier un gros
> fichier. À la fin, mets à jour `reprise.md` et `etat.md`.
